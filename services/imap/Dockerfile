# Dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dovecot and mail utilities
RUN apt-get update && \
    apt-get install -y dovecot-core dovecot-imapd dovecot-lmtpd mailutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create vmail user and group for virtual mailboxes
RUN groupadd -g 5000 vmail && \
    useradd -u 5000 -g vmail -s /bin/false -d /var/mail/vmail -M vmail

# Create virtual mail directory structure
RUN mkdir -p /var/mail/vmail && \
    chown -R vmail:vmail /var/mail/vmail && \
    chmod -R 755 /var/mail/vmail

# Copy Dovecot password file into container
COPY users /etc/dovecot/users
RUN chown dovecot:dovecot /etc/dovecot/users && \
    chmod 600 /etc/dovecot/users

# Copy custom Dovecot config
COPY dovecot.conf /etc/dovecot/dovecot.conf

# Expose IMAP port
EXPOSE 143

# Run Dovecot in foreground
CMD ["dovecot", "-F"]