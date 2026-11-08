# syntax=docker/dockerfile:1.7

# agent-master is what owns the agent's process and terminal inside the
# container; the host supervisor reaches it on a published port and never
# touches the process itself.
#
# bookworm, not the current rust:1-slim: the runtime below is Ubuntu 24.04
# (glibc 2.39) and a binary linked against a newer glibc will not start there.
FROM rust:1-slim-bookworm AS agent-master

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# The revision is the one the supervisor's own Cargo.lock pins its agent-master
# client at: both ends of the port have to speak the same build of the protocol,
# which has no version handshake to fall back on. It is also what makes a bump
# reach the image — this layer is cached on the command text, so a floating
# branch would keep serving the first build forever.
RUN cargo install --git https://github.com/sibatabot/agent-master.git \
      --rev 761569ba651a6bac8b0958a89f5aa5d5018099ab agent-master --root /out


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

RUN npm install -g @anthropic-ai/claude-code@2.1.311 && \
    npm cache clean --force

RUN curl -fsSL https://bun.sh/install | bash && \
    mv /root/.bun/bin/bun /usr/local/bin/bun && \
    rm -rf /root/.bun

COPY --from=agent-master /out/bin/svora-am /usr/local/bin/svora-am
RUN svora-am --help >/dev/null

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

# Host supervisor owns FUSE, WS and the cloud session. The container runs
# agent-master, and agent-master starts claude (and whatever bun-backed plugin
# servers claude itself spawns). The entrypoint wrapper sources the FUSE-served
# `.claude/env` (merged env loadout-items) into the process environment, then
# execs what the `docker run` invocation asked for — the host builds that from
# the agent's loadout snapshot.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
