#!/bin/bash

# Check if container name is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <container-name>"
    echo "Example: $0 my-container"
    exit 1
fi

CONTAINER_NAME="$1"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running or not accessible"
    exit 1
fi

# Check if container exists and is running
if ! docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Error: Container '$CONTAINER_NAME' is not running"
    echo ""
    echo "Available running containers:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    exit 1
fi

echo "Showing logs of '$CONTAINER_NAME'..." 

docker compose logs -f $CONTAINER_NAME