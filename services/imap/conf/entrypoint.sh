#!/bin/bash
set -e

# Load environment variables from grandparent .env
if [ -f /etc/dovecot/../../.env ]; then
    echo "Loading environment variables from ../../.env"
    export $(grep -v '^#' /etc/dovecot/../../.env | xargs)
fi

MAIL_DOMAIN=${MAIL_DOMAIN:-example.org}

# Generate Dovecot configuration dynamically
cat > /etc/dovecot/dovecot.conf <<EOF
service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    mode = 0600
    user = postfix
    group = postfix
  }
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0666
    user = postfix
    group = postfix
  }
}

disable_plaintext_auth = no

mail_location = maildir:/var/mail/vmail/%n
mail_uid = 5000
mail_gid = 8

auth_mechanisms = plain login oauthbearer xoauth2
protocols = imap lmtp

ssl = required
ssl_cert = </etc/letsencrypt/live/${MAIL_DOMAIN}/fullchain.pem
ssl_key  = </etc/letsencrypt/live/${MAIL_DOMAIN}/privkey.pem

ssl_protocols = !SSLv2 !SSLv3
ssl_min_protocol = TLSv1.2
ssl_cipher_list = HIGH:!aNULL:!MD5

passdb {
  driver = lua
  args = file=/etc/dovecot/auth_api.lua blocking=yes
}

userdb {
  driver = lua
  args = file=/etc/dovecot/auth_api.lua blocking=yes
}

service imap-login {
  inet_listener imap {
    port = 143
  }

  inet_listener imaps {
    port = 993
    ssl = yes
  }
}

log_path = /dev/stderr
info_log_path = /dev/stderr
debug_log_path = /dev/stderr

auth_debug = yes
auth_debug_passwords = yes
auth_verbose = yes
auth_verbose_passwords = yes
mail_debug = yes
EOF

# Start Dovecot
echo "Starting Dovecot..."
exec dovecot -F