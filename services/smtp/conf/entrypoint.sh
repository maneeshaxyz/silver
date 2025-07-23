#!/bin/bash

# Default fallback values (optional)
MAIL_DOMAIN=${MAIL_DOMAIN:-example.org}
MAIL_HOSTNAME=${MAIL_HOSTNAME:-$MAIL_DOMAIN}
RELAYHOST=${RELAYHOST:-}

# Configure Postfix
postconf -e "myhostname = $MAIL_HOSTNAME"
postconf -e "myorigin = /etc/mailname"
postconf -e "mydestination = $MAIL_DOMAIN, localhost.localdomain, localhost"
postconf -e "inet_interfaces = all"
postconf -e "inet_protocols = all"
postconf -e "mydomain = $MAIL_DOMAIN"
postconf -e "mynetworks = 127.0.0.0/8"
postconf -e "relayhost = $RELAYHOST"

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

# Run the email script
/sendmail.sh