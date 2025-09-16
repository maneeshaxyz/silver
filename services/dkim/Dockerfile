FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    opendkim \
    opendkim-tools \
    openssl \
    ca-certificates \
    curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install yq for YAML parsing
RUN curl -L -o /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" && \
    chmod +x /usr/local/bin/yq

RUN mkdir -p /etc/opendkim/keys /var/run/opendkim && \
    chown -R opendkim:opendkim /etc/opendkim /var/run/opendkim && \
    chmod 700 /etc/opendkim/keys

COPY conf/opendkim.conf /etc/opendkim.conf
COPY scripts/entrypoint.sh /entrypoint.sh

# Set script permissions
RUN chmod 750 /entrypoint.sh && chown opendkim:opendkim /entrypoint.sh

EXPOSE 8891

ENTRYPOINT ["/entrypoint.sh"]
