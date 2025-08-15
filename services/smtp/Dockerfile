FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

EXPOSE 25 587 

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        postfix \
        ca-certificates \
        bash && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN groupadd -g 2000 postfix && \
    useradd -u 2000 -g postfix -s /usr/sbin/nologin postfix

COPY --chmod=0755 conf/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["postfix", "start-fg"]
