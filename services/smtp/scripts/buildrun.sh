#!/bin/bash

# Builds and runs a docker container [requires docker daemon running]

CONTAINER_NAME="smtp-server-container"

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
docker build -t smtp-server .

echo "--- Running new container... ---"
docker run \
    --env-file conf/.env.conf \
    -d \
    -p 25:25 \
    -p 587:587 \
    -p 80:80 \
    -v $(pwd)/cert:/etc/letsencrypt/live/aravindahwk.org:ro \
    -v $(pwd)/cert:/etc/letsencrypt/archive/aravindahwk.org:ro \
    -v postfix-sasl:/var/spool/postfix/private \
    --name $CONTAINER_NAME \
    --hostname "$(grep MAIL_DOMAIN conf/.env.conf | cut -d '=' -f2 | tr -d '\r')" \
    --network mail-network \
    smtp-server

echo "--- Done. Container '$CONTAINER_NAME' is running. ---"