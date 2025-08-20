#! /bin/bash

PRIVATE_KEY="/etc/dkimkeys/${DKIM_SELECTOR}.private"
PUBLIC_KEY="/etc/dkimkeys/${DKIM_SELECTOR}.txt"

if [ -f "$PRIVATE_KEY" ]; then
    echo "DKIM keys for ${DKIM_DOMAIN} already exist. Skipping key generation."
else
    echo "Starting key generation for ${DKIM_DOMAIN}"
    opendkim-genkey -D /etc/dkimkeys -d ${DKIM_DOMAIN} -s ${DKIM_SELECTOR}
    
    chown opendkim:opendkim "$PRIVATE_KEY"
    chmod 600 "$PRIVATE_KEY"
fi

# Ensure key files have correct ownership and permissions
chown -R opendkim:opendkim /etc/opendkim
chmod 644 /etc/opendkim/*

# Create or update KeyTable, SigningTable, and TrustedHosts
echo "${DKIM_SELECTOR}._domainkey.${DKIM_DOMAIN} ${DKIM_DOMAIN}:${DKIM_SELECTOR}:/etc/dkimkeys/${DKIM_SELECTOR}.private" > /etc/opendkim/KeyTable
echo "*@${DKIM_DOMAIN} ${DKIM_SELECTOR}._domainkey.${DKIM_DOMAIN}" > /etc/opendkim/SigningTable
echo -e "127.0.0.1\nlocalhost\n0.0.0.0/0" > /etc/opendkim/TrustedHosts

# Output public key for DNS record
echo "Public key for your DNS record:"
echo "-----------------------------------"
if [ -f "$PUBLIC_KEY" ]; then
    cat "$PUBLIC_KEY"
else
    echo "Public key file not found. It should have been generated at $PUBLIC_KEY"
fi
echo "-----------------------------------"

echo "Configuration complete. Starting OpenDKIM."
exec opendkim -f