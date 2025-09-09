FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        postfix \
        mailutils \
        iputils-ping \
        ca-certificates \
        wget \
    && wget -O /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" && \
    chmod +x /usr/local/bin/yq && \
    apt-get purge -y --auto-remove wget ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


COPY --chmod=755 ./scripts/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# Provide the default command for the entrypoint.
# Entrypoint.sh script ends with 'exec "$@"'

CMD ["postfix", "start-fg"]
