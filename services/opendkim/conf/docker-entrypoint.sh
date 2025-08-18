#!/bin/bash
set -e

# This directory is a volume mount. See compose.yaml
DKIM_KEY_DIR="/etc/dkimkeys"
DKIM_SELECTOR="mail"
OPENDKIM_CONF="/etc/opendkim.conf"

# Check for required environment variable
if [ -z "$MYHOSTNAME" ]; then
    echo "FATAL: MYHOSTNAME environment variable is not set."
    exit 1
fi

# Generate DKIM keys if they don't exist
# The key path includes the domain name to support multiple domains in the future.
KEY_PATH="$DKIM_KEY_DIR/$MYHOSTNAME/$DKIM_SELECTOR.private"
if [ ! -f "$KEY_PATH" ]; then
    echo "INFO: Private key not found at $KEY_PATH. Generating new DKIM keys..."
    mkdir -p "$(dirname "$KEY_PATH")"
    opendkim-genkey -t -s "$DKIM_SELECTOR" -d "$MYHOSTNAME" -D "$(dirname "$KEY_PATH")"
    
    chown opendkim:opendkim "$(dirname "$KEY_PATH")"/*
    chmod 600 "$KEY_PATH"

    echo "INFO: DKIM keys generated. You must add the following TXT record to your DNS for '$MYHOSTNAME':"
    echo "-------------------------------------------------------------------------------"
    cat "$(dirname "$KEY_PATH")/$DKIM_SELECTOR.txt"
    echo "-------------------------------------------------------------------------------"
fi

# Update opendkim.conf with dynamic values from environment
# NOTE: This requires /etc/opendkim.conf to be writable in the container.
echo "INFO: Updating opendkim.conf..."
sed -i "s/^\(Domain\s*\).*/\1$MYHOSTNAME/" "$OPENDKIM_CONF"
sed -i "s/^\(Selector\s*\).*/\1$DKIM_SELECTOR/" "$OPENDKIM_CONF"
sed -i "s|^\(KeyFile\s*\).*|\1$KEY_PATH|" "$OPENDKIM_CONF"

echo "INFO: Starting OpenDKIM service..."
exec opendkim -f