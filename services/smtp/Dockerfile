FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt update && \
    apt install -y postfix mailutils iputils-ping \
                   libsasl2-2 sasl2-bin libsasl2-modules && \
    apt clean

# Copy configuration script from conf folder
COPY conf/entrypoint.sh /entrypoint.sh

# Give execution permission to the entrypoint script and sendmail script
RUN chmod +x /entrypoint.sh

# Start Postfix service and run the entrypoint script
CMD ["/entrypoint.sh"]