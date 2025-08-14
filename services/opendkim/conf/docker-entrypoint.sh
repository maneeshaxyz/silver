#!/bin/bash


DKIM_KEY_DIR="/etc/opendkim/keys"
DKIM_SELECTOR="mail"

# Generate DKIM keys if they don't exist
if [ ! -f "$DKIM_KEY_DIR/$DOMAIN/$DKIM_SELECTOR.private" ]; then
    echo "Generating DKIM keys for $DOMAIN..."
    mkdir -p "$DKIM_KEY_DIR/$DOMAIN"
    opendkim-genkey -t -s $DKIM_SELECTOR -d $DOMAIN -D "$DKIM_KEY_DIR/$DOMAIN"
    chown opendkim:opendkim "$DKIM_KEY_DIR/$DOMAIN"/*
    chmod 600 "$DKIM_KEY_DIR/$DOMAIN/$DKIM_SELECTOR.private"
fi

exec "$@"