FROM certbot/certbot:latest

USER root

RUN apk add --no-cache wget ca-certificates && \
    wget -O /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" && \
    chmod +x /usr/local/bin/yq && \
    apk del wget ca-certificates

COPY ./scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER certbot

ENTRYPOINT [ "/entrypoint.sh" ]