#!/bin/bash

# --- Sanity Checks & Configuration ---
set -euo pipefail

# Define constant paths
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(dirname "$SCRIPT_DIR")"
readonly LETSENCRYPT_PATH="${ROOT_DIR}/silver-config/data/certbot/keys"

cp "${LETSENCRYPT_DIR}/fullchain.pem" "./thunder/certs/server.cert"
cp "${LETSENCRYPT_DIR}/privkey.pem" "./thunder/certs/server.key"

# Set ownership to user ID 802 (thunder user in container)
sudo chown 802:802 ./thunder/certs/server.key ./thunder/certs/server.cert

chmod 600 ./thunder/certs/server.key
chmod 644 ./thunder/certs/server.cert
