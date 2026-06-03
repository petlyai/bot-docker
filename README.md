# sibatabot/bot-docker

Container image for the docker-deployed variant of a sibatabot agent.

The host-side supervisor manages everything outside the container:
the per-agent FUSE mount, the cloud WS session, the rolling PTY
buffer, and command injection. The image's only job is to run claude
(and whatever bun-backed plugin servers claude itself spawns).

## Contents

- `claude` (`@anthropic-ai/claude-code`) — the agent's CLI
- `bun` — runtime for MCP plugins (e.g. telegram channel server.ts)

No supervisor binary inside, no in-container FUSE: those move host-side.

## Build

```bash
docker build -t sibatabot-bot-docker:dev .
```

## Run (manual)

The container expects to be invoked by the host supervisor. For a
manual probe pass claude args directly:

```bash
docker run --rm -it --name sibatabot-test \
  -v $HOST_FUSE_MOUNT:/workdir/.claude \
  -v $HOST_CLAUDE_LOCAL:/workdir/.claude-local \
  -v $HOST_CLAUDE_JSON:/workdir/.claude.json \
  ghcr.io/sibatabot/bot-docker:latest \
  --dangerously-skip-permissions
```
