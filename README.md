# a2a-parity

Interop canary: **[`a2a-protocol`](https://github.com/egao1980/a2a-protocol)** + **[`a2a-backend-jsonrpc`](https://github.com/egao1980/a2a-backend-jsonrpc)** vs official **Python [`a2a-sdk`](https://github.com/a2aproject/a2a-python)** and **Node [`@a2a-js/sdk`](https://github.com/a2aproject/a2a-js)** (A2A **1.0** JSON-RPC over HTTP).

Lisp owns the harness. Node/Python peers are the SUT. **CI-only — not published to GHCR.**

```
JSON-RPC HTTP
  Lisp client  →  Lisp server   (in-process + hunchentoot / make-a2a-app)
  Lisp client  →  Node server   (@a2a-js/sdk Express)
  Lisp client  →  Python server (a2a-sdk Starlette)
  Node client  →  Lisp server   (ClientFactory + JsonRpcTransport)
  Python client → Lisp server   (A2ACardResolver + create_client)
```

A pass is GET `/.well-known/agent-card.json` plus `SendMessage` echo (`pong` → completed artifact).

## Run

```bash
cd peers/node && npm install
cd ../python && uv sync
export A2A_PARITY_PEERS=1
CL_SOURCE_REGISTRY="/path/to/cl-workspace//:" ros -e '(asdf:test-system "a2a-parity")' -q
```

Lisp↔Lisp only:

```bash
export A2A_PARITY_PEERS=0
ros -e '(asdf:test-system "a2a-parity")' -q
```

## Matrix

See [MATRIX.md](MATRIX.md).

## Env

| Variable | Default | Meaning |
|----------|---------|---------|
| `A2A_PARITY_PEERS` | on | `0` skips Node/Python peers |

Tracks [cl-stack#186](https://github.com/egao1980/cl-stack/issues/186).

## License

MIT
