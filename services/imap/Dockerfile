FROM debian:bookworm-slim

# Set DEBIAN_FRONTEND to noninteractive to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install Dovecot, ca-certificates, and bash
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dovecot-core \
        dovecot-imapd \
        dovecot-lmtpd \
        ca-certificates \
        procps \
        bash \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

RUN groupadd -g 5000 vmail && \
    useradd -u 5000 -g vmail -s /usr/sbin/nologin vmail && \
    groupadd -g 12345 postfix && \
    useradd -u 12345 -g postfix -s /usr/sbin/nologin postfix

# Expose IMAP, IMAPS ports
EXPOSE 143 993 

COPY --chmod=0755 ./conf/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Command to run Dovecot in the foreground
CMD ["dovecot", "-F"]