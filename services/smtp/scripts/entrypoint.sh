#!/bin/bash
set -e

CONFIG_FILE="/etc/postfix/silver.yaml"

export MAIL_DOMAIN=$(yq -e '.domain' "$CONFIG_FILE")

# -------------------------------
# Environment variables
# -------------------------------
MAIL_DOMAIN=${MAIL_DOMAIN:-example.org}
MAIL_HOSTNAME=${MAIL_HOSTNAME:-mail.$MAIL_DOMAIN}
RELAYHOST=${RELAYHOST:-}

echo "$MAIL_DOMAIN" > /etc/mailname

# Path for vmail
VMAIL_DIR="/var/mail/vmail"

# -------------------------------
# Check SQLite database
# -------------------------------
DB_PATH="/app/data/mails.db"

echo "=== Checking SQLite database ==="
if [ -f "$DB_PATH" ]; then
    echo "✓ SQLite database found at $DB_PATH"

    # Ensure domain exists in database
    sqlite3 "$DB_PATH" "INSERT OR IGNORE INTO domains (domain, enabled) VALUES ('${MAIL_DOMAIN}', 1);" 2>/dev/null || echo "Note: Could not insert domain (may already exist)"

    # Set proper permissions
    chown vmail:mail "$DB_PATH" 2>/dev/null || true
    chmod 644 "$DB_PATH"
else
    echo "⚠ Warning: SQLite database not found at $DB_PATH"
    echo "  Database should be created by raven-server"
    echo "  Postfix will start but mail delivery may fail until database is available"
fi

# -------------------------------
# vmail user/group and directories
# -------------------------------
if ! getent group mail >/dev/null; then
    groupadd -g 8 mail
fi

if ! id "vmail" &>/dev/null; then
    useradd -r -u 5000 -g 8 -d "$VMAIL_DIR" -s /sbin/nologin -c "Virtual Mail User" vmail
fi

mkdir -p "$VMAIL_DIR"
chown vmail:mail "$VMAIL_DIR"
chmod 755 "$VMAIL_DIR"

echo "=== vmail directory setup completed ==="

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