# sibatabot/bot-docker

Container image for the docker-deployed variant of a sibatabot agent.

The host-side supervisor's control daemon, when an agent has
`environment=docker` in the cloud, runs this image as a named container
`sibatabot-<agent-symbolic-name>` and lets the in-container supervisor
binary mount FUSE, open the cloud sync session, and supervise claude.

## Contents

- `claude` (`@anthropic-ai/claude-code`) — the agent's CLI
- `bun` — runtime for MCP plugins (e.g. telegram channel server.ts)
- `fuse3` — userspace tools (`fusermount3`, libfuse) for in-container FUSE
- `supervisor` — host's supervisor binary, in `run-agent` mode

Telegram plugin is **not** baked. Plugins arrive over FUSE per the
agent's cloud-attached loadout.

## Build

The `supervisor` source tree is expected at `./supervisor/` (Git
submodule pointing at `sibatabot/supervisor`).

```bash
git submodule update --init --recursive
docker build -t sibatabot-bot-docker:dev .
```

## Run (manual)

The container expects to be invoked by the host supervisor; for a
manual probe pass run-agent args directly:

```bash
docker run --rm \
  --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor:unconfined \
  -v $HOME/.supervisor/agents/test/claude-local:/workdir/.claude-local \
  -e SUPERVISOR_CLOUD_URL=https://cloud.example.com \
  ghcr.io/sibatabot/bot-docker:latest \
  --cloud-url $SUPERVISOR_CLOUD_URL run-agent --workdir /workdir --writer fuse
```
