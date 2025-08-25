FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        rspamd \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 11332 11334

RUN mkdir -p /var/run/rspamd && \
    chown -R _rspamd:_rspamd /var/run/rspamd /var/lib/rspamd

CMD ["rspamd", "-f", "-u", "_rspamd", "-g", "_rspamd"]

