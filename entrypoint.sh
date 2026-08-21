#!/bin/bash
# Source the supervisor-synthesized env file before launching the container's
# command.
#
# `$HOME/.claude/env` is served by the host FUSE mount: the supervisor
# merges every cloud `env` loadout-item body plus the host-local
# `.claude-local/env` into one .env-style file, generated at read time.
# Sourcing it with `set -a` exports each KEY=VALUE into the environment
# (e.g. OPENAI_API_KEY for transcribe-voice), from where agent-master passes
# it on to claude. The file is absent when no env source has content — then we
# just exec.
set -a
[ -f "$HOME/.claude/env" ] && . "$HOME/.claude/env"
set +a

if [ "$#" -eq 0 ]; then
  echo "entrypoint: nothing to run — the command comes from the docker run invocation" >&2
  exit 2
fi

exec "$@"
