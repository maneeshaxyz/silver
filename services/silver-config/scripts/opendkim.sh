#!/bin/bash
#
# This script initializes the OpenDKIM trusted hosts file based on a domain
# name found in a configuration YAML file.
#

# --- Sanity Checks & Configuration ---

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# The return value of a pipeline is the status of the last command to exit with a non-zero status.
set -o pipefail

# Define constant paths
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
readonly SILVER_YAML_FILE="${ROOT_DIR}/silver.yaml"
readonly DKIM_DATA_PATH="${ROOT_DIR}/silver-config/gen/opendkim"
readonly DKIM_SELECTOR=mail
# --- Main Logic ---
readonly MAIL_DOMAIN=$(grep -m 1 '^domain:' "${SILVER_YAML_FILE}" | sed 's/domain: //' | xargs)

# Generate the TrustedHosts file.
mkdir -p ${DKIM_DATA_PATH}
cat >"${DKIM_DATA_PATH}/TrustedHosts" <<EOF
127.0.0.1
localhost
192.168.65.0/16
172.16.0.0/12
10.0.0.0/8
*.${MAIL_DOMAIN}
EOF

echo "Successfully generated OpenDKIM TrustedHosts file for domain: ${MAIL_DOMAIN}"

cat >"${DKIM_DATA_PATH}/SigningTable" <<EOF
*@$MAIL_DOMAIN $DKIM_SELECTOR._domainkey.$MAIL_DOMAIN
EOF

echo "Successfully generated OpenDKIM SigningTable file for domain: ${MAIL_DOMAIN}"

# Write KeyTable
cat > "${DKIM_DATA_PATH}/KeyTable" <<EOF
$DKIM_SELECTOR._domainkey.$MAIL_DOMAIN $MAIL_DOMAIN:$DKIM_SELECTOR:/etc/opendkim/keys/$MAIL_DOMAIN/$DKIM_SELECTOR.private
EOF

echo "Successfully generated OpenDKIM KeyTable file for domain: ${MAIL_DOMAIN}"

# # if keys missing
# if [ ! -f /etc/opendkim/keys/$MAIL_DOMAIN/$DKIM_SELECTOR.private ]; then
#     echo "Generating DKIM keys for $MAIL_DOMAIN..."
#     opendkim-genkey -b $DKIM_KEY_SIZE -s $DKIM_SELECTOR -d $MAIL_DOMAIN -D /etc/opendkim/keys/$MAIL_DOMAIN/
#     chmod 600 /etc/opendkim/keys/$MAIL_DOMAIN/$DKIM_SELECTOR.private
#     chmod 644 /etc/opendkim/keys/$MAIL_DOMAIN/$DKIM_SELECTOR.txt
#     echo "DKIM keys ready."
# fi

# # Write TrustedHosts

# # Output DKIM record
# echo "Starting OpenDKIM..."
# echo ""
# echo "========== DKIM DNS Record =========="
# echo "Record name: $DKIM_SELECTOR._domainkey.$MAIL_DOMAIN"
# echo "Record value:"
# cat /etc/opendkim/keys/$MAIL_DOMAIN/$DKIM_SELECTOR.txt
# echo "====================================="
# echo ""

# # Start OpenDKIM
# exec opendkim -f
