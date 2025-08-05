#!/bin/bash

# Default fallback values (optional)
MAIL_DOMAIN=${MAIL_DOMAIN:-example.org}
MAIL_HOSTNAME=${MAIL_HOSTNAME:-$MAIL_DOMAIN}
RELAYHOST=${RELAYHOST:-}

# Start saslauthd in the background
mkdir -p /var/run/saslauthd
rm -f /var/run/saslauthd/mux
saslauthd -a pam -n 5 -m /var/run/saslauthd
sleep 2
saslauthd -a pam -n 5 -m /var/run/saslauthd  # start again to be safe

# Create symlink expected by Postfix
mkdir -p /var/spool/postfix/var/run
ln -s /var/run/saslauthd /var/spool/postfix/var/run/saslauthd

# Add postfix to sasl group (needed for socket access)
adduser postfix sasl

# Configure Postfix
postconf -e "myhostname = $MAIL_HOSTNAME"
postconf -e "myorigin = /etc/mailname"
postconf -e "mydestination = $MAIL_DOMAIN, localhost.localdomain, localhost"
postconf -e "inet_interfaces = all"
postconf -e "inet_protocols = all"
postconf -e "mydomain = $MAIL_DOMAIN"
postconf -e "mynetworks = 127.0.0.0/8"
postconf -e "relayhost = $RELAYHOST"
postconf -e "smtpd_sasl_type = cyrus"
postconf -e "smtpd_sasl_path = smtpd"
postconf -e "smtpd_sasl_auth_enable = yes"
postconf -e "smtpd_sasl_security_options = noanonymous"
postconf -e "broken_sasl_auth_clients = yes"

# Enable TLS for ports 25 and 587
postconf -e "smtpd_tls_cert_file = /etc/letsencrypt/live/$MAIL_DOMAIN/fullchain.pem"
postconf -e "smtpd_tls_key_file = /etc/letsencrypt/live/$MAIL_DOMAIN/privkey.pem"
postconf -e "smtpd_use_tls = yes"
postconf -e "smtpd_tls_security_level = may"
postconf -e "smtpd_tls_CAfile = /etc/ssl/certs/ca-certificates.crt"

# Configure Submission (587) in master.cf
echo "Enabling submission service..."
postconf -M submission/inet="submission inet n - y - - smtpd"
postconf -P submission/inet/syslog_name="postfix/submission"
postconf -P submission/inet/smtpd_tls_security_level="encrypt"
postconf -P submission/inet/smtpd_sasl_auth_enable="yes"
postconf -P submission/inet/smtpd_tls_auth_only="yes"
postconf -P submission/inet/smtpd_relay_restrictions="permit_sasl_authenticated,reject"


# Canonical address mapping
postconf -e "recipient_canonical_maps = hash:/etc/postfix/recipient_canonical"

# Create recipient canonical file dynamically
cat <<EOF > /etc/postfix/recipient_canonical
$EMAIL_TO    $EMAIL_MAPPING
EOF

# Ensure the recipient canonical file is readable by Postfix
chmod 644 /etc/postfix/recipient_canonical

# Fix for DNS resolution in Postfix chroot
mkdir -p /var/spool/postfix/etc
cp /etc/host.conf /etc/resolv.conf /etc/services /var/spool/postfix/etc/
chmod 1777 -R /var/spool/postfix/etc
chmod o+r /etc/resolv.conf

# Set mailname
echo "$MAIL_DOMAIN" > /etc/mailname

# Start postfix
service postfix start

# Wait for Postfix to start
echo "Waiting for Postfix to start..."
sleep 5

# Create db file for recipient canonical mapping
postmap /etc/postfix/recipient_canonical

sleep 1000000

# Run the email script
# /sendmail.sh