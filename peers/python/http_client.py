#!/usr/bin/env python3
from __future__ import annotations

import asyncio
import json
import sys

import httpx
from a2a.client import A2ACardResolver, ClientConfig, create_client
from a2a.helpers import new_text_message
from a2a.types import Role, SendMessageRequest


def _part_text(part: object) -> str:
    text = getattr(part, "text", None)
    if text:
        return str(text)
    root = getattr(part, "root", None)
    if root is not None:
        return str(getattr(root, "text", root))
    return str(part)


def _task_echo(chunk: object) -> tuple[str, str]:
    task = getattr(chunk, "task", None) or chunk
    artifacts = getattr(task, "artifacts", None) or []
    text = ""
    if artifacts:
        parts = getattr(artifacts[0], "parts", None) or []
        if parts:
            text = _part_text(parts[0])
    status = getattr(task, "status", None)
    state = getattr(status, "state", None)
    if hasattr(state, "value"):
        state = state.value
    return text, str(state or "")


async def main() -> None:
    if len(sys.argv) < 2:
        print("usage: http_client.py <url>", file=sys.stderr)
        raise SystemExit(2)
    base = sys.argv[1].rstrip("/")
    async with httpx.AsyncClient() as http:
        resolver = A2ACardResolver(httpx_client=http, base_url=base)
        card = await resolver.get_agent_card()
        client = await create_client(agent=card, client_config=ClientConfig(streaming=False))
        try:
            request = SendMessageRequest(message=new_text_message("pong", role=Role.ROLE_USER))
            last = None
            async for chunk in client.send_message(request):
                last = chunk
        finally:
            await client.close()
    echo, state = _task_echo(last)
    rec = {"card": card.name, "echo": echo, "state": state}
    print(json.dumps(rec, ensure_ascii=False), flush=True)


if __name__ == "__main__":
    asyncio.run(main())
