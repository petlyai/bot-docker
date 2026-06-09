FROM alpine:3.21

RUN apk add --no-cache \
      nodejs npm \
      python3 \
      git bash ncdu curl unzip \
      libstdc++ libgcc

RUN npm install -g @anthropic-ai/claude-code

RUN curl -fsSL https://bun.sh/install | bash && \
    mv /root/.bun/bin/bun /usr/local/bin/bun && \
    rm -rf /root/.bun

ENV DISABLE_AUTOUPDATER=1

RUN adduser -D -s /bin/bash agent && \
    mkdir -p /workdir && chown agent:agent /workdir

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

USER agent
WORKDIR /workdir

# Host supervisor owns FUSE, WS, PTY-IO. Container's only job is to run
# claude (and whatever bun-backed plugin servers claude itself spawns).
# The entrypoint wrapper sources the FUSE-served `.claude/env` (merged
# env loadout-items) into the process environment, then execs claude.
# Args are supplied by the `docker run` invocation — the host builds them
# from the agent's loadout snapshot — and reach claude as "$@".
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
