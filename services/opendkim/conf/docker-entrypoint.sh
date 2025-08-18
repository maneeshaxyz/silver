#!/bin/bash
DKIM_KEY_DIR="/etc/opendkim/keys"
DKIM_SELECTOR="mail"

# Generate DKIM keys if they don't exist
if [ ! -f "$DKIM_KEY_DIR/$MYHOSTNAME/$DKIM_SELECTOR.private" ]; then
    echo "Generating DKIM keys for $MYHOSTNAME..."
    mkdir -p "$DKIM_KEY_DIR/$MYHOSTNAME"
    opendkim-genkey -t -s $DKIM_SELECTOR -d $MYHOSTNAME -D "$DKIM_KEY_DIR/$MYHOSTNAME"
    chown opendkim:opendkim "$DKIM_KEY_DIR/$MYHOSTNAME"/*
    chmod 600 "$DKIM_KEY_DIR/$MYHOSTNAME/$DKIM_SELECTOR.private"

    sleep 2

    # sed -i "s/#Domain.*/Domain $MYHOSTNAME/" /etc/opendkim.conf
    # sed -i "s/#Selector.*/Selector $DKIM_SELECTOR/" /etc/opendkim.conf
    # sed -i "s|#KeyFile.*|KeyFile $DKIM_KEY_DIR/$MYHOSTNAME/$DKIM_SELECTOR.private|" /etc/opendkim.conf
fi

exec opendkim -f