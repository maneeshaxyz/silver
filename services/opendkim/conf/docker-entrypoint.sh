#! /bin/bash

echo "Starting key generation for ${DKIM_DOMAIN}"
opendkim-genkey -D /etc/dkimkeys -d ${DKIM_DOMAIN} -s ${DKIM_SELECTOR}

# Create KeyTable
cat > /etc/opendkim/KeyTable << EOF
${DKIM_SELECTOR}._domainkey.${DKIM_DOMAIN} ${DKIM_DOMAIN}:${DKIM_SELECTOR}:/etc/dkimkeys/${DKIM_SELECTOR}.private
EOF

# Create SigningTable  
cat > /etc/opendkim/SigningTable << EOF
*@${DKIM_DOMAIN} ${DKIM_SELECTOR}._domainkey.${DKIM_DOMAIN}
EOF

# Create TrustedHosts
cat > /etc/opendkim/TrustedHosts << EOF
127.0.0.1
localhost
0.0.0.0/0
EOF

chown opendkim:opendkim /etc/dkimkeys/${DKIM_SELECTOR}.private && \
chown opendkim:opendkim /etc/opendkim/KeyTable && \
chown opendkim:opendkim /etc/opendkim/SigningTable && \
chown opendkim:opendkim /etc/opendkim/TrustedHosts

chmod 600 /etc/dkimkeys/${DKIM_SELECTOR}.private && \
chmod 644 /etc/opendkim/KeyTable && \
chmod 644 /etc/opendkim/SigningTable && \
chmod 644 /etc/opendkim/TrustedHosts

exec opendkim -f