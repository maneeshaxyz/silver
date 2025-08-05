#!/bin/bash
set -e

# Fix permissions on the Postfix spool directory so the auth socket can be created.
# This directory is shared from the Postfix container.
chown dovecot:postfix /var/spool/postfix/private
chmod 770 /var/spool/postfix/private

echo "Starting Dovecot..."
exec "$@"
