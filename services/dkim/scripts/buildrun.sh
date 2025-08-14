#!/bin/bash

# Build the docker container for DKIM service [requires docker daemon running]
CONTAINER_NAME="opendkim-server"

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

# Building the Docker image from the Dockerfile
echo "--- Building new Docker image... ---"
docker build -t opendkim-server .

# Start OpenDKIM
docker run \
    --env-file conf/.env.conf \
    -d \
    -v dkim-keys:/etc/opendkim/keys \
    --name opendkim-server \
    --network mail-network \
    opendkim-server &


echo "--- Waiting for containers to start... ---"
sleep 10

# Show DKIM public key for DNS setup
echo "=== DKIM DNS Record ==="
docker exec opendkim-server cat /etc/opendkim/keys/$MAIL_DOMAIN/$DKIM_SELECTOR.txt 2>/dev/null || echo "DKIM keys not ready yet. Check logs with: docker logs opendkim-server"