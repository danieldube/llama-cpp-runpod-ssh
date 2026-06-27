FROM ghcr.io/ggml-org/llama.cpp:server-cuda

USER root

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      openssh-server \
      ca-certificates && \
    mkdir -p /run/sshd && \
    rm -rf /var/lib/apt/lists/*

COPY start.sh /start.sh
RUN chmod +x /start.sh

# The official server-cuda image accepts llama-server arguments directly.
# This wrapper preserves the same external syntax by forwarding "$@" to /llama-server.
ENTRYPOINT ["/start.sh"]