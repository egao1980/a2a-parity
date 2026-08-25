#!/usr/bin/env python3
from __future__ import annotations

import sys

import uvicorn
from a2a.helpers import get_message_text, new_task_from_user_message, new_text_message, new_text_part
from a2a.server.agent_execution import AgentExecutor, RequestContext
from a2a.server.events import EventQueue
from a2a.server.request_handlers import DefaultRequestHandler
from a2a.server.routes import create_agent_card_routes, create_jsonrpc_routes
from a2a.server.tasks import InMemoryTaskStore, TaskUpdater
from a2a.types import AgentCapabilities, AgentCard, AgentInterface, AgentSkill, TaskState
from starlette.applications import Starlette


class EchoExecutor(AgentExecutor):
    async def execute(self, context: RequestContext, event_queue: EventQueue) -> None:
        task = context.current_task or new_task_from_user_message(context.message)
        if context.current_task is None:
            await event_queue.enqueue_event(task)
        updater = TaskUpdater(event_queue=event_queue, task_id=task.id, context_id=task.context_id)
        await updater.update_status(state=TaskState.TASK_STATE_WORKING)
        text = get_message_text(context.message) or ""
        await updater.add_artifact(parts=[new_text_part(text=text, media_type="text/plain")])
        await updater.update_status(
            state=TaskState.TASK_STATE_COMPLETED,
            message=new_text_message("echoed"),
        )

    async def cancel(self, context: RequestContext, event_queue: EventQueue) -> None:
        raise NotImplementedError("cancel is not supported")


def make_app(url: str) -> Starlette:
    skill = AgentSkill(
        id="echo",
        name="Echo",
        description="Echoes the first text part",
        tags=["echo"],
        examples=["pong"],
        input_modes=["text/plain"],
        output_modes=["text/plain"],
    )
    card = AgentCard(
        name="echo",
        description="A2A parity echo agent",
        version="0.1.0",
        default_input_modes=["text/plain"],
        default_output_modes=["text/plain"],
        capabilities=AgentCapabilities(streaming=True, push_notifications=False),
        supported_interfaces=[
            AgentInterface(protocol_binding="JSONRPC", url=url, protocol_version="1.0"),
        ],
        skills=[skill],
    )
    handler = DefaultRequestHandler(
        agent_executor=EchoExecutor(),
        task_store=InMemoryTaskStore(),
        agent_card=card,
    )
    routes = []
    routes.extend(create_agent_card_routes(card))
    routes.extend(create_jsonrpc_routes(handler, "/"))
    return Starlette(routes=routes)


def main() -> None:
    port = int(sys.argv[1] if len(sys.argv) > 1 else 0)
    if port <= 0:
        print("usage: http_server.py <port>", file=sys.stderr)
        raise SystemExit(2)
    url = f"http://127.0.0.1:{port}"
    uvicorn.run(make_app(url), host="127.0.0.1", port=port, log_level="warning")


if __name__ == "__main__":
    main()
