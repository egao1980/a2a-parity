#!/usr/bin/env python3
from __future__ import annotations

import asyncio
import json
import sys

import httpx
from a2a.client import A2ACardResolver, ClientConfig, create_client
from a2a.helpers import new_text_message
from a2a.types import Role, SendMessageRequest, TaskState


def _part_text(part: object) -> str:
    text = getattr(part, "text", None)
    if text:
        return str(text)
    content = getattr(part, "content", None)
    if content is not None:
        nested = getattr(content, "text", None) or getattr(content, "value", None)
        if nested:
            return str(nested)
    which = getattr(part, "WhichOneof", None)
    if callable(which):
        field = which("content")
        if field:
            return str(getattr(part, field))
    root = getattr(part, "root", None)
    if root is not None:
        return str(getattr(root, "text", root))
    return ""


def _wire_state(state: object) -> str:
    if state is None:
        return ""
    name = getattr(state, "name", None)
    if isinstance(name, str) and name:
        return name
    try:
        return TaskState.Name(int(state))
    except (TypeError, ValueError):
        return str(state)


def _task_echo(chunk: object) -> tuple[str, str]:
    task = getattr(chunk, "task", None) or chunk
    artifacts = getattr(task, "artifacts", None) or []
    text = ""
    if artifacts:
        parts = getattr(artifacts[0], "parts", None) or []
        if parts:
            text = _part_text(parts[0])
    artifact = getattr(chunk, "artifact", None)
    if artifact is not None:
        parts = getattr(artifact, "parts", None) or []
        if parts:
            text = text or _part_text(parts[0])
    status = getattr(task, "status", None) or getattr(chunk, "status", None)
    return text, _wire_state(getattr(status, "state", None) if status is not None else None)


async def main() -> None:
    if len(sys.argv) < 2:
        print("usage: http_client.py <url> [stream]", file=sys.stderr)
        raise SystemExit(2)
    base = sys.argv[1].rstrip("/")
    streaming = len(sys.argv) > 2 and sys.argv[2] == "stream"
    async with httpx.AsyncClient() as http:
        resolver = A2ACardResolver(httpx_client=http, base_url=base)
        card = await resolver.get_agent_card()
        client = await create_client(agent=card, client_config=ClientConfig(streaming=streaming))
        try:
            request = SendMessageRequest(message=new_text_message("pong", role=Role.ROLE_USER))
            echo = ""
            state = ""
            async for chunk in client.send_message(request):
                text, st = _task_echo(chunk)
                if text:
                    echo = text
                if st:
                    state = st
        finally:
            await client.close()
    rec = {"card": card.name, "echo": echo, "state": state}
    print(json.dumps(rec, ensure_ascii=False), flush=True)


if __name__ == "__main__":
    asyncio.run(main())
