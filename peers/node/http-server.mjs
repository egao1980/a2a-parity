import express from "express";
import { AGENT_CARD_PATH } from "@a2a-js/sdk";
import { DefaultRequestHandler, InMemoryTaskStore } from "@a2a-js/sdk/server";
import { agentCardHandler, jsonRpcHandler, UserBuilder } from "@a2a-js/sdk/server/express";

class EchoExecutor {
  async cancelTask() {}

  async execute(requestContext, eventBus) {
    const userMessage = requestContext.userMessage;
    const taskId = requestContext.taskId;
    const contextId = requestContext.contextId;
    const text =
      userMessage?.parts?.find((p) => p.text)?.text ??
      userMessage?.parts?.find((p) => p.content?.$case === "text")?.content?.value ??
      "";

    const task = requestContext.task ?? {
      id: taskId,
      contextId,
      status: { state: "TASK_STATE_SUBMITTED" },
      history: [userMessage],
      artifacts: [],
    };
    eventBus.publish(task);
    eventBus.publish({
      taskId,
      contextId,
      status: { state: "TASK_STATE_WORKING" },
    });
    eventBus.publish({
      taskId,
      contextId,
      artifact: {
        artifactId: "echo",
        name: "echo",
        parts: [{ text }],
      },
      lastChunk: true,
    });
    eventBus.publish({
      taskId,
      contextId,
      status: { state: "TASK_STATE_COMPLETED" },
    });
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
  supportedInterfaces: [
    { url, protocolBinding: "JSONRPC", protocolVersion: "1.0" },
  ],
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
