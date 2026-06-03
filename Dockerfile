FROM rust:1.83-alpine3.21 AS supervisor-builder

RUN apk add --no-cache musl-dev pkgconfig fuse3-dev

ARG SUPERVISOR_SRC=./supervisor
COPY ${SUPERVISOR_SRC} /src
WORKDIR /src
RUN cargo build --release --features fuse --bin supervisor


FROM alpine:3.21

RUN apk add --no-cache \
      nodejs npm \
      git bash ncdu curl unzip \
      libstdc++ libgcc \
      fuse3

RUN npm install -g @anthropic-ai/claude-code

RUN curl -fsSL https://bun.sh/install | bash && \
    mv /root/.bun/bin/bun /usr/local/bin/bun && \
    rm -rf /root/.bun

ENV DISABLE_AUTOUPDATER=1

RUN adduser -D -s /bin/bash agent && \
    mkdir -p /workdir && chown agent:agent /workdir

COPY --from=supervisor-builder /src/target/release/supervisor /usr/local/bin/supervisor

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER agent
WORKDIR /workdir

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
