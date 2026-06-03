#!/bin/bash
set -euo pipefail

# Hand off to supervisor's run-agent. The host-side control daemon
# spawns this container with --workdir /workdir already prepared:
#   - FUSE mount point /workdir/.claude is created by supervisor
#   - /workdir/.claude-local is bind-mounted from host's
#     ~/.supervisor/agents/<name>/claude-local for persistent state
#   - any trailing claude args are appended by the caller
exec /usr/local/bin/supervisor "$@"
