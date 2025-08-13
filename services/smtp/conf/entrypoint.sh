#!/bin/bash

MAIL_DOMAIN=${MAIL_DOMAIN:-example.org}
MAIL_HOSTNAME=${MAIL_HOSTNAME:-$MAIL_DOMAIN}
RELAYHOST=${RELAYHOST:-}

echo "=== Configuring Postfix with minimal receiving support ==="

# Create /etc/mailname ASAP (before any postmap)
echo "$MAIL_DOMAIN" > /etc/mailname

# Basic config (your working sending config)
postconf -e "myhostname = $MAIL_HOSTNAME"
postconf -e "myorigin = /etc/mailname"
postconf -e "mydestination = $MAIL_DOMAIN, localhost.localdomain, localhost"
postconf -e "inet_interfaces = all"
postconf -e "inet_protocols = ipv4"
postconf -e "mydomain = $MAIL_DOMAIN"
postconf -e "mynetworks = 127.0.0.0/8"
postconf -e "relayhost = $RELAYHOST"

# SASL & TLS (keep as in working config)
postconf -e "smtpd_sasl_type = dovecot"
postconf -e "smtpd_sasl_path = private/auth"
postconf -e "smtpd_sasl_auth_enable = yes"
postconf -e "smtpd_sasl_security_options = noanonymous"
postconf -e "broken_sasl_auth_clients = yes"

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

# DKIM
postconf -e "milter_protocol = 6"
postconf -e "milter_default_action = accept"
postconf -e "smtpd_milters = inet:opendkim-server:8891"
postconf -e "non_smtpd_milters = inet:opendkim-server:8891"
postconf -P submission/inet/smtpd_milters="inet:opendkim-server:8891"

# Canonical mapping (keep as is)
cat <<EOF > /etc/postfix/recipient_canonical
$EMAIL_TO    $EMAIL_MAPPING
EOF
chmod 644 /etc/postfix/recipient_canonical
postmap /etc/postfix/recipient_canonical

# --- Minimal receiving setup starts here ---

mkdir -p /etc/postfix

cat > /etc/postfix/virtual_domains << EOF
$MAIL_DOMAIN
EOF

cat > /etc/postfix/virtual_mailbox << EOF
aravinda@$MAIL_DOMAIN    aravinda/
testuser@$MAIL_DOMAIN    testuser/
admin@$MAIL_DOMAIN       admin/
postmaster@$MAIL_DOMAIN  postmaster/
EOF

cat > /etc/postfix/virtual_aliases << EOF
testuser@$MAIL_DOMAIN   testuser@$MAIL_DOMAIN
info@$MAIL_DOMAIN       aravinda@$MAIL_DOMAIN
support@$MAIL_DOMAIN    aravinda@$MAIL_DOMAIN
postmaster@$MAIL_DOMAIN aravinda@$MAIL_DOMAIN
admin@$MAIL_DOMAIN      aravinda@$MAIL_DOMAIN
EOF

postmap /etc/postfix/virtual_domains
postmap /etc/postfix/virtual_mailbox
postmap /etc/postfix/virtual_aliases

postconf -e "virtual_mailbox_domains = hash:/etc/postfix/virtual_domains"
postconf -e "virtual_mailbox_maps = hash:/etc/postfix/virtual_mailbox"
postconf -e "virtual_alias_maps = hash:/etc/postfix/virtual_aliases"

postconf -e "virtual_transport = lmtp:unix:private/dovecot-lmtp"

# Create vmail user/group and maildirs minimally for delivery
if ! getent group mail >/dev/null; then
    groupadd -g 8 mail
fi
if ! id "vmail" &>/dev/null; then
    useradd -r -u 5000 -g 8 -d /var/mail/vmail -s /sbin/nologin -c "Virtual Mail User" vmail
fi

mkdir -p /var/mail/vmail/{aravinda,admin,postmaster,testuser}
chown -R vmail:mail /var/mail/vmail
chmod -R 755 /var/mail/vmail

for user in aravinda admin postmaster testuser; do
    mkdir -p /var/mail/vmail/$user/{new,cur,tmp}
    chown -R vmail:mail /var/mail/vmail/$user
    chmod -R 755 /var/mail/vmail/$user
done

# Fix for DNS resolution in postfix chroot (optional)
mkdir -p /var/spool/postfix/etc
cp /etc/host.conf /etc/resolv.conf /etc/services /var/spool/postfix/etc/
chmod 1777 -R /var/spool/postfix/etc
chmod o+r /etc/resolv.conf

echo "Starting postfix..."
service postfix start

sleep 5

postfix check || echo "Postfix config errors!"

echo "=== Minimal Postfix configured with receiving and sending ==="

sleep infinity
