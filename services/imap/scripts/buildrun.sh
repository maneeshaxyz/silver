#!/bin/bash

# Create network and volumes
docker network create mail-network 2>/dev/null || true
docker volume create maildata 2>/dev/null || true
docker volume create postfix-sasl 2>/dev/null || true
docker volume create dkim-keys 2>/dev/null || true

# Load environment variables from file so MAIL_DOMAIN is available here
set -a
source conf/.env.conf
set +a

CONTAINER_NAME="dovecot-server"

# Remove container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "--- Container '$CONTAINER_NAME' already exists. Removing it... ---"
    docker rm -f "$CONTAINER_NAME"
fi

# Stop running container if needed
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "--- Container '$CONTAINER_NAME' is already running. Stopping it... ---"
    docker stop "$CONTAINER_NAME"
    docker rm -f "$CONTAINER_NAME"
fi

# Build the Dovecot image
echo "--- Building Dovecot image... ---"
docker build -t dovecot-server .

# Run the Dovecot container
echo "--- Running Dovecot container... ---"
docker run \
    -d \
    -p 143:143 \
    -v maildata:/var/mail/vmail \
    -v postfix-sasl:/var/spool/postfix/private \
    -v $(pwd)/cert:/etc/letsencrypt/live/$MAIL_DOMAIN:ro \
    -v $(pwd)/cert:/etc/letsencrypt/archive/$MAIL_DOMAIN:ro \
    --name dovecot-server \
    --network mail-network \
    dovecot-server

echo "--- Done. Container '$CONTAINER_NAME' is running. ---"