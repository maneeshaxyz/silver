#!/bin/bash
set -e

CONFIG_FILE="/etc/opendkim/silver.yaml"

# Extract primary (first) domain from the domains list using grep/sed
MAIL_DOMAIN=$(grep -m 1 '^\s*-\s*domain:' "$CONFIG_FILE" | sed 's/.*domain:\s*//' | xargs)

# Fallback if extraction failed
if [ -z "$MAIL_DOMAIN" ]; then
    echo "⚠️  Warning: Could not extract domain from $CONFIG_FILE"
    MAIL_DOMAIN="example.org"
fi

# Extract variables from YAML
export MAIL_DOMAIN
DKIM_SELECTOR=${DKIM_SELECTOR:-mail}
DKIM_KEY_SIZE=${DKIM_KEY_SIZE:-2048}

echo "Using domain: $MAIL_DOMAIN"

# Try to create the domain directory
echo "Attempting to create domain directory for: $MAIL_DOMAIN"
mkdir -p /etc/dkimkeys/$MAIL_DOMAIN


# if keys missing
if [ ! -f /etc/dkimkeys/$MAIL_DOMAIN/$DKIM_SELECTOR.private ]; then
    echo "Generating DKIM keys for $MAIL_DOMAIN..."
    opendkim-genkey -b $DKIM_KEY_SIZE -s $DKIM_SELECTOR -d $MAIL_DOMAIN -D /etc/dkimkeys/$MAIL_DOMAIN/
    chmod 600 /etc/dkimkeys/$MAIL_DOMAIN/$DKIM_SELECTOR.private
    chmod 644 /etc/dkimkeys/$MAIL_DOMAIN/$DKIM_SELECTOR.txt
    echo "DKIM keys ready."
fi


# Output DKIM record
echo "Starting OpenDKIM..."
echo ""
echo "========== DKIM DNS Record =========="
echo "Record name: $DKIM_SELECTOR._domainkey.$MAIL_DOMAIN"
echo "Record value:"
cat /etc/dkimkeys/$MAIL_DOMAIN/$DKIM_SELECTOR.txt
echo "====================================="
echo ""

# Start OpenDKIM
exec opendkim -f -x /etc/opendkim/opendkim.conf