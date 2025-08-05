#!/bin/bash

# Create network and volume
docker network create mail-network 2>/dev/null || true
docker volume create postfix-sasl 2>/dev/null || true

# Build the Dovecot image
echo "--- Building Dovecot image... ---"
docker build -t dovecot-server .

# Start both containers
docker run \
    -d \
    -p 143:143 \
    -v postfix-sasl:/var/spool/postfix/private \
    --name dovecot-server \
    --network mail-network \
    dovecot-server &