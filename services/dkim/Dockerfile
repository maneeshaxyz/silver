FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install OpenDKIM and dependencies
RUN apt-get update && \
    apt-get install -y opendkim opendkim-tools openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /etc/opendkim/keys /var/run/opendkim

# Copy configuration files
COPY conf/opendkim.conf /etc/opendkim.conf
COPY conf/TrustedHosts /etc/opendkim/TrustedHosts
COPY conf/KeyTable /etc/opendkim/KeyTable
COPY conf/SigningTable /etc/opendkim/SigningTable
COPY conf/entrypoint.sh /entrypoint.sh

# Give execution permissions to the entrypoint script
RUN chmod +x /entrypoint.sh

# Set proper permissions
RUN chown -R opendkim:opendkim /etc/opendkim /var/run/opendkim

# Expose the OpenDKIM port
EXPOSE 8891

# Run the entrypoint script
CMD ["/entrypoint.sh"]