FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt update && \
    apt install -y postfix mailutils iputils-ping \
                   libsasl2-2 sasl2-bin libsasl2-modules \
                   default-mysql-client libmysqlclient-dev \
                   postfix-mysql && \
    apt clean

# Copy configuration script from conf folder
COPY conf/entrypoint.sh /entrypoint.sh

# Give execution permission to the entrypoint script and sendmail script
RUN chmod +x /entrypoint.sh

# Copy SQL map configs into postfix directory
COPY sql/mysql-virtual-domains.cf /etc/postfix/mysql-virtual-domains.cf
COPY sql/mysql-virtual-users.cf   /etc/postfix/mysql-virtual-users.cf
COPY sql/mysql-virtual-aliases.cf /etc/postfix/mysql-virtual-aliases.cf

RUN chmod 640 /etc/postfix/mysql-virtual-*.cf && \
    chown root:postfix /etc/postfix/mysql-virtual-*.cf

# Start Postfix service and run the entrypoint script
CMD ["/entrypoint.sh"]