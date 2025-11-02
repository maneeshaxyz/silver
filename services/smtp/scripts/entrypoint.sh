#!/bin/bash
set -e

CONFIG_FILE="/etc/postfix/silver.yaml"

# Extract primary (first) domain from the domains list
export MAIL_DOMAIN=$(yq -e '.domains[0].domain' "$CONFIG_FILE")

# -------------------------------
# Environment variables
# -------------------------------
MAIL_DOMAIN=${MAIL_DOMAIN:-example.org}
MAIL_HOSTNAME=${MAIL_HOSTNAME:-mail.$MAIL_DOMAIN}
RELAYHOST=${RELAYHOST:-}

echo "$MAIL_DOMAIN" > /etc/mailname

# -------------------------------
# Check SQLite database
# -------------------------------
DB_PATH="/app/data/databases/shared.db"

echo "=== Checking SQLite database ==="
if [ -f "$DB_PATH" ]; then
    echo "✓ SQLite database found at $DB_PATH"

    # Ensure domain exists in database
    sqlite3 "$DB_PATH" "INSERT OR IGNORE INTO domains (domain, enabled) VALUES ('${MAIL_DOMAIN}', 1);" 2>/dev/null || echo "Note: Could not insert domain (may already exist)"

    # Set proper permissions
    chmod 644 "$DB_PATH"
else
    echo "⚠ Warning: SQLite database not found at $DB_PATH"
    echo "  Database should be created by raven-server"
    echo "  Postfix will start but mail delivery may fail until database is available"
fi

echo "=== Database setup completed ==="

# -------------------------------
# Fix for DNS resolution in chroot
# -------------------------------
mkdir -p /var/spool/postfix/etc
cp /etc/host.conf /etc/resolv.conf /etc/services /var/spool/postfix/etc/
chmod 644 /var/spool/postfix/etc/*

# -------------------------------
# Verify configuration
# -------------------------------
echo "=== Verifying Postfix configuration ==="
postconf virtual_mailbox_domains
postconf virtual_mailbox_maps
postconf virtual_mailbox_base
postconf virtual_transport

# -------------------------------
# Start Postfix
# -------------------------------
echo "=== Starting Postfix ==="
service postfix start

# Keep container running
sleep infinity