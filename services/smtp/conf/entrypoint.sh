#!/bin/bash

MAIL_DOMAIN=${MAIL_DOMAIN:-example.org}
MAIL_HOSTNAME=${MAIL_HOSTNAME:-$MAIL_DOMAIN}
RELAYHOST=${RELAYHOST:-}

echo "=== Configuring Postfix with minimal receiving support ==="

# Use the mail domain as in the mailname file
echo "$MAIL_DOMAIN" > /etc/mailname

# Basic configuration
postconf -e "myhostname = $MAIL_HOSTNAME"
postconf -e "myorigin = /etc/mailname"
postconf -e "mydestination = localhost.localdomain, localhost"
postconf -e "inet_interfaces = all"
postconf -e "inet_protocols = ipv4"
postconf -e "mydomain = $MAIL_DOMAIN"
postconf -e "mynetworks = 127.0.0.0/8"
postconf -e "relayhost = $RELAYHOST"

# Logging to stdout (for Docker)
postconf -e "maillog_file = /var/log/mail.log"

# SASL authentication
postconf -e "smtpd_sasl_type = dovecot"
postconf -e "smtpd_sasl_path = private/auth"
postconf -e "smtpd_sasl_auth_enable = yes"
postconf -e "smtpd_sasl_security_options = noanonymous"
postconf -e "broken_sasl_auth_clients = yes"

# TLS configuration
postconf -e "smtpd_tls_cert_file = /etc/letsencrypt/live/$MAIL_DOMAIN/fullchain.pem"
postconf -e "smtpd_tls_key_file = /etc/letsencrypt/live/$MAIL_DOMAIN/privkey.pem"
postconf -e "smtpd_use_tls = yes"
postconf -e "smtpd_tls_security_level = may"
postconf -e "smtpd_tls_CAfile = /etc/ssl/certs/ca-certificates.crt"

# Submission service
postconf -M submission/inet="submission inet n - y - - smtpd"
postconf -P submission/inet/syslog_name="postfix/submission"
postconf -P submission/inet/smtpd_tls_security_level="encrypt"
postconf -P submission/inet/smtpd_sasl_auth_enable="yes"
postconf -P submission/inet/smtpd_tls_auth_only="yes"
postconf -P submission/inet/smtpd_relay_restrictions="permit_sasl_authenticated,reject"

# DKIM configuration
postconf -e "milter_protocol = 6"
postconf -e "milter_default_action = accept"
postconf -e "smtpd_milters = inet:rspamd-server:11332,inet:opendkim-server:8891"
postconf -e "non_smtpd_milters = inet:rspamd-server:11332,inet:opendkim-server:8891"
postconf -P "submission/inet/smtpd_milters=inet:rspamd-server:11332,inet:opendkim-server:8891"

# Adding throttling to prevent abuse
postconf -e "smtpd_client_connection_rate_limit = 10"
postconf -e "smtpd_client_message_rate_limit = 100"
postconf -e "smtpd_client_recipient_rate_limit = 200"
postconf -e "smtpd_recipient_limit = 50"
postconf -e "anvil_rate_time_unit = 60s"
postconf -e "smtpd_client_connection_count_limit = 20"

# Canonical mapping for recipient addresses
cat <<EOF > /etc/postfix/recipient_canonical
$EMAIL_TO    $EMAIL_MAPPING
EOF
chmod 644 /etc/postfix/recipient_canonical
postmap /etc/postfix/recipient_canonical


mkdir -p /etc/postfix

# Define virtual domains, mailboxes, and aliases
cat > /etc/postfix/virtual_domains << EOF
$MAIL_DOMAIN OK
EOF

# Create virtual mailbox file 
cat > /etc/postfix/virtual_mailbox << EOF
aravinda@$MAIL_DOMAIN aravinda/
testuser@$MAIL_DOMAIN testuser/
admin@$MAIL_DOMAIN admin/
postmaster@$MAIL_DOMAIN postmaster/
EOF

# Create virtual aliases file
cat > /etc/postfix/virtual_aliases << EOF
info@$MAIL_DOMAIN aravinda@$MAIL_DOMAIN
support@$MAIL_DOMAIN aravinda@$MAIL_DOMAIN
postmaster@$MAIL_DOMAIN aravinda@$MAIL_DOMAIN
admin@$MAIL_DOMAIN aravinda@$MAIL_DOMAIN
EOF

# Generate the hash maps
postmap /etc/postfix/virtual_domains
postmap /etc/postfix/virtual_mailbox
postmap /etc/postfix/virtual_aliases

# Configure virtual domain handling properly
postconf -e "virtual_mailbox_domains = hash:/etc/postfix/virtual_domains"
postconf -e "virtual_mailbox_maps = hash:/etc/postfix/virtual_mailbox"
postconf -e "virtual_alias_maps = hash:/etc/postfix/virtual_aliases"

# Set the virtual transport to use Dovecot LMTP
postconf -e "virtual_transport = lmtp:unix:private/dovecot-lmtp"

# Virtual mailbox settings
postconf -e "virtual_minimum_uid = 5000"
postconf -e "virtual_uid_maps = static:5000"
postconf -e "virtual_gid_maps = static:8"

# Create vmail user/group correctly
if ! getent group mail >/dev/null; then
    groupadd -g 8 mail
fi
if ! id "vmail" &>/dev/null; then
    useradd -r -u 5000 -g 8 -d /var/mail/vmail -s /sbin/nologin -c "Virtual Mail User" vmail
fi

for user in aravinda admin postmaster testuser; do
    # Main INBOX maildir
    mkdir -p /var/mail/vmail/$user/{new,cur,tmp}

    # Spam folder maildir
    mkdir -p /var/mail/vmail/$user/.Spam/{new,cur,tmp}

    # Drafts, Sent, Trash (optional, helps Thunderbird auto-detect)
    mkdir -p /var/mail/vmail/$user/.Drafts/{new,cur,tmp}
    mkdir -p /var/mail/vmail/$user/.Sent/{new,cur,tmp}
    mkdir -p /var/mail/vmail/$user/.Trash/{new,cur,tmp}

    # Set permissions
    chown -R vmail:mail /var/mail/vmail/$user
    chmod -R 755 /var/mail/vmail/$user
done

# Fix for DNS resolution in postfix chroot
mkdir -p /var/spool/postfix/etc
cp /etc/host.conf /etc/resolv.conf /etc/services /var/spool/postfix/etc/
chmod 644 /var/spool/postfix/etc/*

# Verify our configuration before starting
echo "=== Configuration verification ==="
echo "Virtual domains file content:"
cat /etc/postfix/virtual_domains
echo "Virtual mailbox file content:"
cat /etc/postfix/virtual_mailbox

echo "Starting postfix..."
service postfix start

sleep 5

# Check if postfix loaded the config correctly
echo "=== Postfix configuration check ==="
postconf virtual_mailbox_domains
postconf virtual_transport
postconf mydestination

postfix check || echo "Postfix config errors!"

echo "=== Testing local domain recognition ==="
postmap -q "$MAIL_DOMAIN" hash:/etc/postfix/virtual_domains
postmap -q "testuser@$MAIL_DOMAIN" hash:/etc/postfix/virtual_mailbox

echo "=== Minimal Postfix configured with receiving and sending ==="

sleep infinity