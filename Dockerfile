FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# claude-code requires Node >= 22 and Ubuntu's own nodejs package is v18, so
# Node comes from NodeSource rather than the distro.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg \
      python3 git bash ncdu unzip \
      libstdc++6 && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get purge -y --auto-remove gnupg && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code && \
    npm cache clean --force

RUN curl -fsSL https://bun.sh/install | bash && \
    mv /root/.bun/bin/bun /usr/local/bin/bun && \
    rm -rf /root/.bun

ENV DISABLE_AUTOUPDATER=1

# The agent owns the host-side bind mounts, which on Linux hosts carry the
# host user's numeric uid — 1000 in practice. ubuntu:24.04 already parks a
# stock `ubuntu` user on 1000, so it is removed to keep the agent on that uid.
RUN userdel --remove ubuntu && \
    useradd --uid 1000 --create-home --shell /bin/bash agent && \
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
