import { ClientFactory, JsonRpcTransportFactory } from "@a2a-js/sdk/client";
import { Role } from "@a2a-js/sdk";
import { randomUUID } from "node:crypto";

function partText(part) {
  if (!part) return "";
  if (typeof part.text === "string") return part.text;
  if (part.content?.$case === "text") return part.content.value ?? "";
  return "";
}

function taskEcho(result) {
  const task = result?.task ?? result;
  const artifacts = task?.artifacts ?? [];
  const parts = artifacts[0]?.parts ?? [];
  const echo = partText(parts[0]);
  const state = task?.status?.state ?? "";
  return { echo, state };
}

const url = process.argv[2];
if (!url) {
  console.error("usage: http-client.mjs <url>");
  process.exit(2);
}

const factory = new ClientFactory({
  transports: [new JsonRpcTransportFactory()],
});
const client = await factory.createFromUrl(url);
const card = await client.getAgentCard?.() ?? { name: "echo" };
const result = await client.sendMessage({
  message: {
    messageId: randomUUID(),
    role: Role?.ROLE_USER ?? "ROLE_USER",
    parts: [{ text: "pong" }],
  },
});
const { echo, state } = taskEcho(result);
process.stdout.write(`${JSON.stringify({ card: card.name ?? "echo", echo, state })}\n`);
await client.close?.();
process.exit(0);
