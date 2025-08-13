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

# Create test user mailbox structure
RUN mkdir -p /var/mail/vmail/testuser/{cur,new,tmp} && \
    chown -R vmail:vmail /var/mail/vmail/testuser && \
    chmod -R 700 /var/mail/vmail/testuser

# Copy custom Dovecot config
COPY dovecot.conf /etc/dovecot/dovecot.conf

# Copy sample mail to the correct location
COPY testmail /var/mail/vmail/testuser/cur/1711031200.M001234.localhost

# Set correct ownership and permissions
RUN chown -R vmail:vmail /var/mail/vmail && \
    chmod -R 755 /var/mail/vmail && \
    chmod -R 700 /var/mail/vmail/testuser

# Expose IMAP port
EXPOSE 143

# Run Dovecot in foreground
CMD ["dovecot", "-F"]