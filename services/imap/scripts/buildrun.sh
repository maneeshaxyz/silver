#!/bin/bash

# Create network and volume
docker network create mail-network 2>/dev/null || true
docker volume create postfix-sasl 2>/dev/null || true

CONTAINER_NAME="imap-server-container"

# Check if the container is already available
if docker ps -a --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
    echo "--- Container '$CONTAINER_NAME' already exists. Removing it... ---"
    docker rm -f "$CONTAINER_NAME"
# Check if the container is running
elif docker ps --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
    echo "--- Container '$CONTAINER_NAME' is already running. Stopping it... ---"
    docker stop "$CONTAINER_NAME"
    docker rm -f "$CONTAINER_NAME"
fi

# Build the Dovecot image
echo "--- Building Dovecot image... ---"
docker build -t dovecot-server .

# Start the Dovecot container
echo "--- Running Dovecot container... ---"
docker run \
    -d \
    -p 143:143 \
    -v postfix-sasl:/var/spool/postfix/private \
    --name dovecot-server \
    --network mail-network \
    dovecot-server &

echo "--- Done. Container '$CONTAINER_NAME' is running. ---"