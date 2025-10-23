FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive

# Install everything in one RUN to maintain package manager state
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        gnupg \
        wget \
        sqlite3 \
        libsqlite3-0 \
        postfix \
        mailutils \
        iputils-ping && \
    # Install postfix-sqlite separately to ensure proper configuration
    apt-get install -y postfix-sqlite && \
    # Manually ensure the SQLite module is registered
    if ! grep -q "^sqlite" /etc/postfix/dynamicmaps.cf; then \
        echo "sqlite	postfix-sqlite.so	dict_sqlite_open" >> /etc/postfix/dynamicmaps.cf; \
    fi && \
    # Download yq
    wget -O /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" && \
    chmod +x /usr/local/bin/yq && \
    # Clean up
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy entrypoint script
COPY ./smtp/scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create data directory
RUN mkdir -p /app/data

CMD ["/entrypoint.sh"]