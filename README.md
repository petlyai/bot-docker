# sibatabot/bot-docker

Container image for the docker-deployed variant of a sibatabot agent.

The host-side supervisor manages everything outside the container: the
per-agent FUSE mount and the cloud WS session. Inside, AgentMaster
(`svora-am`) owns claude's process and terminal and hands control of
it to the supervisor over a port; the supervisor never touches the
process directly.

## Contents

- `svora-am` — owns the agent's process under a terminal of its own
- `claude` (`@anthropic-ai/claude-code`) — the agent's CLI
- `bun` — runtime for MCP plugins (e.g. telegram channel server.ts)

No supervisor binary inside, no in-container FUSE: those stay host-side.

## Build

```bash
docker build -t ghcr.io/sibatabot/bot-docker:latest .
```

## Run (manual)

The container expects to be invoked by the host supervisor, which runs
`svora-am` and then asks it to start claude. For a manual probe:

```bash
docker run -d --name sibatabot-test \
  -e HOME=/workdir \
  -p 127.0.0.1:27620:27620 \
  -v $HOST_FUSE_MOUNT:/workdir/.claude \
  -v $HOST_CLAUDE_LOCAL:/workdir/.claude-local \
  -v $HOST_CLAUDE_JSON:/workdir/.claude.json \
  ghcr.io/sibatabot/bot-docker:latest \
  svora-am --listen 0.0.0.0:27620

amctl --server 127.0.0.1:27620 start --cwd /workdir -- claude --dangerously-skip-permissions
amctl --server 127.0.0.1:27620 window
```
