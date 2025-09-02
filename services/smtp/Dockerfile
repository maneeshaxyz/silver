FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt update && \
    apt install -y postfix mailutils iputils-ping \
                   libsasl2-2 sasl2-bin libsasl2-modules \
                   default-mysql-client libmysqlclient-dev \
                   postfix-mysql && \
    apt clean

# Copy entrypoint file and generating sql maps
COPY scripts/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh


# Start Postfix service and run the entrypoint script
CMD ["/entrypoint.sh"]