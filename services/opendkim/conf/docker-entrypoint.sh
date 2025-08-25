#!/bin/bash

PRIVATE_KEY="/etc/dkimkeys/${DKIM_SELECTOR}.private"
PUBLIC_KEY="/etc/dkimkeys/${DKIM_SELECTOR}.txt"
KEY_TABLE="/etc/opendkim/KeyTable"
SIGNING_TABLE="/etc/opendkim/SigningTable"
TRUSTED_HOSTS="/etc/opendkim/TrustedHosts"

mkdir -p /etc/dkimkeys
mkdir -p /etc/opendkim

if [ ! -f "$PRIVATE_KEY" ]; then
    echo "DKIM private key not found. Generating new keys for ${DKIM_DOMAIN}..."
    opendkim-genkey -D /etc/dkimkeys -d "${DKIM_DOMAIN}" -s "${DKIM_SELECTOR}"
    echo "Key generation complete."
else
    echo "DKIM keys for ${DKIM_DOMAIN} already exist. Skipping generation."
fi

# --- 2. Create Configuration Files (Only if they don't exist) ---
if [ ! -f "$KEY_TABLE" ]; then
    echo "KeyTable not found. Creating..."
    echo "${DKIM_SELECTOR}._domainkey.${DKIM_DOMAIN} ${DKIM_DOMAIN}:${DKIM_SELECTOR}:${PRIVATE_KEY}" > "$KEY_TABLE"
else
    echo "KeyTable already exists."
fi

if [ ! -f "$SIGNING_TABLE" ]; then
    echo "SigningTable not found. Creating..."
    # This line signs emails from any user at your domain.
    echo "*@${DKIM_DOMAIN} ${DKIM_SELECTOR}._domainkey.${DKIM_DOMAIN}" > "$SIGNING_TABLE"
else
    echo "SigningTable already exists."
fi

if [ ! -f "$TRUSTED_HOSTS" ]; then
    echo "TrustedHosts not found. Creating..."
    # 127.0.0.1 and localhost are for local services.
    # The 0.0.0.0/0 is a broad setting for Docker networks.
    # For better security, replace 0.0.0.0/0 with your mail server's Docker network (e.g., 172.16.0.0/12).
    echo -e "127.0.0.1\nlocalhost\n0.0.0.0/0" > "$TRUSTED_HOSTS"
else
    echo "TrustedHosts already exists."
fi

# --- 3. Set Correct Permissions (On every run) ---
echo "Setting final permissions..."
chown -R opendkim:opendkim /etc/dkimkeys /etc/opendkim
# Set read-only for the private key for the owner (opendkim)
chmod 600 "$PRIVATE_KEY"
# Set read-write for owner on other config files
chmod 644 "$PUBLIC_KEY" "$KEY_TABLE" "$SIGNING_TABLE" "$TRUSTED_HOSTS"
echo "Permissions set."

# --- 4. Output Public Key for DNS ---
echo "--------------------------------------------------"
echo "Your public DKIM key for DNS:"
if [ -f "$PUBLIC_KEY" ]; then
    cat "$PUBLIC_KEY"
else
    echo "Public key file not found at $PUBLIC_KEY"
fi
echo "--------------------------------------------------"

echo "Configuration complete. Starting OpenDKIM daemon."
exec opendkim -f
