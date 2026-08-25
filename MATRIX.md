# a2a-parity matrix

Status: `have` · `partial` · `missing` · `skip`

Catalog: GET `/.well-known/agent-card.json` + `SendMessage` echo (`pong`).

## JSON-RPC HTTP

| Route | Lisp→Lisp | Lisp→Node | Lisp→Python | Node→Lisp | Python→Lisp |
|-------|-----------|-----------|-------------|-----------|-------------|
| agent card | have | have | have | have | have |
| `SendMessage` echo | have | have | have | have | have |

Lisp→Lisp also has an in-process (no HTTP) route.

## skipped

| Route | notes |
|-------|-------|
| `SendStreamingMessage` | wave-2 |
| push-notification webhooks | wave-1 non-goal |
| gRPC / HTTP+JSON REST | later backends |
