#!/bin/bash

DKIM_KEY_DIR="/etc/opendkim/keys"
DKIM_SELECTOR="mail"

# Generate DKIM keys if they don't exist
if [ ! -f "$DKIM_KEY_DIR/$URL/$DKIM_SELECTOR.private" ]; then
    echo "Generating DKIM keys for $URL..."
    mkdir -p "$DKIM_KEY_DIR/$URL"
    opendkim-genkey -t -s $DKIM_SELECTOR -d $URL -D "$DKIM_KEY_DIR/$URL"
    chown opendkim:opendkim "$DKIM_KEY_DIR/$URL"/*
    chmod 600 "$DKIM_KEY_DIR/$URL/$DKIM_SELECTOR.private"
fi

exec opendkim -f