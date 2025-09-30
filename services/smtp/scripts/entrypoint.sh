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

# Path for vmail
VMAIL_DIR="/var/mail/vmail"

# Compile hash maps (this is essential)
postmap /etc/postfix/virtual-domains
postmap /etc/postfix/virtual-users
postmap /etc/postfix/virtual-aliases

echo "=== Hash maps compiled successfully ==="

# -------------------------------
# Submission service overrides
# -------------------------------
postconf -M submission/inet="submission inet n - y - - smtpd"
postconf -P submission/inet/syslog_name="postfix/submission"
postconf -P submission/inet/smtpd_tls_security_level="encrypt"
postconf -P submission/inet/smtpd_sasl_auth_enable="yes"
postconf -P submission/inet/smtpd_tls_auth_only="yes"
postconf -P submission/inet/smtpd_relay_restrictions="permit_sasl_authenticated,reject"
postconf -P submission/inet/smtpd_milters="inet:rspamd-server:11332,inet:opendkim-server:8891"

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