import { ClientFactory, JsonRpcTransportFactory } from "@a2a-js/sdk/client";
import { Role, TaskState, taskStateToJSON } from "@a2a-js/sdk";
import { randomUUID } from "node:crypto";

function partText(part) {
  if (!part) return "";
  if (typeof part === "string") return part;
  if (typeof part.text === "string") return part.text;
  if (part.content?.$case === "text") return part.content.value ?? "";
  if (typeof part.content?.value === "string") return part.content.value;
  if (part.root?.text) return String(part.root.text);
  return "";
}

function firstEcho(obj) {
  if (!obj) return "";
  const artifacts = obj.artifacts ?? obj.task?.artifacts ?? obj.payload?.value?.artifacts ?? [];
  for (const art of artifacts) {
    for (const part of art?.parts ?? []) {
      const text = partText(part);
      if (text) return text;
    }
  }
  const parts = obj.parts ?? obj.task?.parts ?? obj.message?.parts ?? [];
  for (const part of parts) {
    const text = partText(part);
    if (text) return text;
  }
  return "";
}

function wireState(state) {
  if (state == null || state === "") return "";
  if (typeof state === "number") {
    try {
      return taskStateToJSON(state);
    } catch {
      return String(state);
    }
  }
  if (state === TaskState.TASK_STATE_COMPLETED) return "TASK_STATE_COMPLETED";
  return String(state);
}

function taskEcho(result) {
  const task = result?.task ?? result?.payload?.value ?? result;
  const echo = firstEcho(task) || firstEcho(result);
  const state = wireState(task?.status?.state ?? result?.status?.state);
  return { echo, state };
}

const url = process.argv[2];
const stream = process.argv[3] === "stream";
if (!url) {
  console.error("usage: http-client.mjs <url> [stream]");
  process.exit(2);
}

const factory = new ClientFactory({
  transports: [new JsonRpcTransportFactory()],
});
const client = await factory.createFromUrl(url);
const card = (await client.getAgentCard?.()) ?? { name: "echo" };
const message = {
  messageId: randomUUID(),
  role: Role.ROLE_USER,
  parts: [{ content: { $case: "text", value: "pong" }, mediaType: "text/plain" }],
};

function streamEcho(events) {
  let echo = "";
  let state = "";
  for (const ev of events) {
    const payload = ev?.payload ?? ev;
    const caseName = payload?.$case;
    const value = payload?.value ?? payload;
    const fromTask = taskEcho(caseName === "task" || ev?.task ? (value ?? ev.task ?? ev) : ev);
    if (fromTask.echo) echo = fromTask.echo;
    if (fromTask.state) state = fromTask.state;
    const artifact = value?.artifact ?? ev?.artifactUpdate?.artifact ?? ev?.artifact;
    if (artifact) {
      for (const part of artifact.parts ?? []) {
        const text = partText(part);
        if (text) echo = text;
      }
    }
    const st = value?.status?.state ?? ev?.statusUpdate?.status?.state;
    if (st != null && st !== "") state = wireState(st);
  }
  return { echo, state };
}

let echo;
let state;
if (stream) {
  const events = [];
  for await (const ev of client.sendMessageStream({ message })) {
    events.push(ev);
  }
  ({ echo, state } = streamEcho(events));
} else {
  const result = await client.sendMessage({ message });
  ({ echo, state } = taskEcho(result));
}
process.stdout.write(`${JSON.stringify({ card: card.name ?? "echo", echo, state })}\n`);
await client.close?.();
process.exit(0);
