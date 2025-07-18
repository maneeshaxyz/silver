#!/bin/bash

CONTAINER_NAME=$1

if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null)" == "true" ]; then
  echo "$CONTAINER_NAME is up and running."
  exit 0
else
  echo "$CONTAINER_NAME is not running or does not exist."
  exit 1
fi