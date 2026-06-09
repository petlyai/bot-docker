#!/bin/bash
# Source the supervisor-synthesized env file before launching claude.
#
# `$HOME/.claude/env` is served by the host FUSE mount: the supervisor
# merges every cloud `env` loadout-item body plus the host-local
# `.claude-local/env` into one .env-style file, generated at read time.
# Sourcing it with `set -a` exports each KEY=VALUE into claude's process
# environment (e.g. OPENAI_API_KEY for transcribe-voice). The file is
# absent when no env source has content — then we just exec claude.
set -a
[ -f "$HOME/.claude/env" ] && . "$HOME/.claude/env"
set +a
exec claude "$@"
