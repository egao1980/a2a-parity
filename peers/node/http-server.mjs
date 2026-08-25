import express from "express";
import { AGENT_CARD_PATH, Role, TaskState } from "@a2a-js/sdk";
import { AgentEvent, DefaultRequestHandler, InMemoryTaskStore } from "@a2a-js/sdk/server";
import { agentCardHandler, jsonRpcHandler, UserBuilder } from "@a2a-js/sdk/server/express";
import { randomUUID } from "node:crypto";

function textPart(text) {
  return {
    content: { $case: "text", value: text },
    mediaType: "text/plain",
  };
}

function messageText(message) {
  const parts = message?.parts ?? [];
  for (const part of parts) {
    if (typeof part?.text === "string" && part.text) return part.text;
    if (part?.content?.$case === "text") return part.content.value ?? "";
  }
  return "";
}

class EchoExecutor {
  async cancelTask() {}

  async execute(requestContext, eventBus) {
    const userMessage = requestContext.userMessage;
    const taskId = requestContext.taskId;
    const contextId = requestContext.contextId;
    const text = messageText(userMessage);

    const task = requestContext.task ?? {
      id: taskId,
      contextId,
      status: { state: TaskState.TASK_STATE_SUBMITTED, timestamp: new Date().toISOString() },
      history: [userMessage],
      artifacts: [],
    };
    eventBus.publish(AgentEvent.task(task));
    eventBus.publish(
      AgentEvent.statusUpdate({
        taskId,
        contextId,
        status: { state: TaskState.TASK_STATE_WORKING, timestamp: new Date().toISOString() },
      }),
    );
    eventBus.publish(
      AgentEvent.artifactUpdate({
        taskId,
        contextId,
        artifact: {
          artifactId: "echo",
          name: "echo",
          parts: [textPart(text)],
        },
        lastChunk: true,
      }),
    );
    eventBus.publish(
      AgentEvent.statusUpdate({
        taskId,
        contextId,
        status: {
          state: TaskState.TASK_STATE_COMPLETED,
          timestamp: new Date().toISOString(),
          message: {
            role: Role.ROLE_AGENT,
            messageId: randomUUID(),
            parts: [textPart("echoed")],
            taskId,
            contextId,
          },
        },
      }),
    );
    eventBus.finished?.();
  }
}

const port = Number(process.argv[2] || 0);
if (!port) {
  console.error("usage: http-server.mjs <port>");
  process.exit(2);
}

const url = `http://127.0.0.1:${port}`;
const card = {
  name: "echo",
  description: "A2A parity echo agent",
  version: "0.1.0",
  supportedInterfaces: [{ url, protocolBinding: "JSONRPC", protocolVersion: "1.0" }],
  capabilities: { streaming: true, pushNotifications: false },
  defaultInputModes: ["text/plain"],
  defaultOutputModes: ["text/plain"],
  skills: [
    {
      id: "echo",
      name: "Echo",
      description: "Echoes the first text part",
      tags: ["echo"],
    },
  ],
};

const handler = new DefaultRequestHandler(card, new InMemoryTaskStore(), new EchoExecutor());
const app = express();
app.use(`/${AGENT_CARD_PATH}`, agentCardHandler({ agentCardProvider: handler }));
app.use(jsonRpcHandler({ requestHandler: handler, userBuilder: UserBuilder.noAuthentication }));

app.listen(port, "127.0.0.1", () => {
  process.stdout.write(`A2A_HTTP_LISTEN ${port}\n`);
});
