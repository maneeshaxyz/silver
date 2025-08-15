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

RUN groupadd -g 5000 dovecot && \
    useradd -u 5000 -g dovecot -s /usr/sbin/nologin dovecot && \
    groupadd -g 2000 postfix && \
    useradd -u 2000 -g postfix -s /usr/sbin/nologin postfix

# Expose IMAP, IMAPS ports
EXPOSE 143 993 

COPY --chmod=0755 ./conf/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Command to run Dovecot in the foreground
CMD ["dovecot", "-F"]