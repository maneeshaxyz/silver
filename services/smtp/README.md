# Testing Local SMTP Server

This directory contains a set of scripts designed to build, run, and test our local email functionality in a containerized environment.

## Dependencies
- Running these tests require [Docker](https://www.docker.com/products/docker-desktop/) installed and running.

## Setup the Environment file
- Create a `.env.conf` file in the `conf` directory with the following content:

```bash
# Email configuration
EMAIL_TO="recipient"
EMAIL_MAPPING="recipient@example.com"
EMAIL_SUBJECT="Test Email"
EMAIL_BODY="This is a test email sent from the local SMTP server."

# Mail server configuration
MAIL_DOMAIN="localhost"
MAIL_HOST="localhost"
RELAYHOST="localhost"
```


## Quick Start

To run the complete test sequence, ensure the scripts are executable and run them from the smtp directory, the email will be sent to the email address specified in the `.env.conf` file.

```bash
cd services/smtp
chmod +x ./scripts/*.sh
./scripts/init.sh
```

## Add database data for SMTP server
- The SMTP server uses a database to manage virtual users, domains, and aliases. You need to add initial data to the database to test the SMTP server functionality. You can use the provided SQL scripts located in the `sql` directory to create the necessary tables and insert initial data.
- Create the below files in the `sql` directory.
1. `mysql-virtual-domains.sql`
```
user = testuser
password = $$$$$$$$$$
hosts = mariadb-server
dbname = mailserver
query = SELECT 1 FROM virtual_domains WHERE name='%s'
```
2. `mysql-virtual-users.sql`
```
user = testuser
password = $$$$$$$$$$
hosts = mariadb-server
dbname = mailserver
query = SELECT 1 FROM virtual_users WHERE email='%s'
```
3. `mysql-virtual-aliases.sql`
```
user = testuser
password = $$$$$$$$$$
hosts = mariadb-server
dbname = mailserver
query = SELECT destination FROM virtual_aliases WHERE source='%s'
```

