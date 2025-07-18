# Dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dovecot and mail utilities
RUN apt-get update && \
    apt-get install -y dovecot-core dovecot-imapd mailutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create test user and Maildir structure
RUN useradd -m testuser && \
    echo "testuser:testpass" | chpasswd && \
    mkdir -p /home/testuser/Maildir/{cur,new,tmp} && \
    chown -R testuser:testuser /home/testuser/Maildir && \
    chmod -R 700 /home/testuser/Maildir

# Copy custom Dovecot config
COPY dovecot.conf /etc/dovecot/dovecot.conf

# Copy sample mail (should already be in Maildir format)
COPY testmail /home/testuser/Maildir/cur/1711031200.M001234.localhost

# Set correct ownership and permissions again (in case COPY reset it)
RUN chown -R testuser:testuser /home/testuser/Maildir && \
    chmod -R 700 /home/testuser/Maildir

# Expose IMAP port
EXPOSE 143

# Run Dovecot in foreground
CMD ["dovecot", "-F"]
