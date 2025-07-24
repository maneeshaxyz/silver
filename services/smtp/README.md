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