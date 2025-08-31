#!/bin/bash
set -e

# Load .env from grandparent folder (if present)
ENV_FILE="/etc/dovecot/../../.env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

# Default values if not set
DB_HOST=${DB_HOST:-mariadb-server}
DB_USER=${DB_USER:-mailuser}
DB_PASS=${DB_PASS:-mailpass}
DB_NAME=${DB_NAME:-mailserver}

echo "=== Generating Postfix MySQL map files ==="

# Virtual domains
cat > /etc/postfix/mysql-virtual-domains.cf <<EOF
user = $DB_USER
password = $DB_PASS
hosts = $DB_HOST
dbname = $DB_NAME
query = SELECT 1 FROM virtual_domains WHERE name='%s'
EOF

# Virtual users
cat > /etc/postfix/mysql-virtual-users.cf <<EOF
user = $DB_USER
password = $DB_PASS
hosts = $DB_HOST
dbname = $DB_NAME
query = SELECT 1 FROM virtual_users WHERE email='%s'
EOF

# Virtual aliases
cat > /etc/postfix/mysql-virtual-aliases.cf <<EOF
user = $DB_USER
password = $DB_PASS
hosts = $DB_HOST
dbname = $DB_NAME
query = SELECT destination FROM virtual_aliases WHERE source='%s'
EOF

# Fix permissions
chmod 640 /etc/postfix/mysql-virtual-*.cf
chown root:postfix /etc/postfix/mysql-virtual-*.cf

echo "=== MySQL map files created successfully ==="