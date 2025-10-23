#!/bin/bash

# ============================================
#  Silver Mail - Add Users from users.yaml + Thunder Initialization
# ============================================

# -------------------------------
# Configuration
# -------------------------------
# Colors
CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Directories & files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Services directory contains docker-compose.yaml and silver-config
SERVICES_DIR="$(cd "${SCRIPT_DIR}/../../services" && pwd)"
# Conf directory contains config files
CONF_DIR="$(cd "${SCRIPT_DIR}/../../conf" && pwd)"
VIRTUAL_USERS_FILE="${SERVICES_DIR}/silver-config/gen/postfix/virtual-users"
VIRTUAL_DOMAINS_FILE="${SERVICES_DIR}/silver-config/gen/postfix/virtual-domains"
CONFIG_FILE="${CONF_DIR}/silver.yaml"
USERS_FILE="${CONF_DIR}/users.yaml"
PASSWORDS_DIR="${SCRIPT_DIR}/../../scripts/decrypt"
PASSWORDS_FILE="${PASSWORDS_DIR}/user_passwords.txt"

# Docker container paths
CONTAINER_VIRTUAL_USERS_FILE="/etc/postfix/virtual-users"
CONTAINER_VIRTUAL_DOMAINS_FILE="/etc/postfix/virtual-domains"

# -------------------------------
# Prompt for encryption key
# -------------------------------
echo -e "${YELLOW}Enter encryption key for storing passwords:${NC}"
read -s ENCRYPT_KEY
echo ""
if [ -z "$ENCRYPT_KEY" ]; then
	echo -e "${RED}✗ Encryption key cannot be empty${NC}"
	exit 1
fi

echo -e "${CYAN}---------------------------------------------${NC}"
echo -e " 🚀 ${GREEN}Silver Mail - Bulk Add Users${NC}"
echo -e "${CYAN}---------------------------------------------${NC}\n"

# -------------------------------
# Helper Functions
# -------------------------------

# Generate a random strong password
generate_password() {
	openssl rand -base64 24 | tr -d '\n' | head -c 16
}

# Simple XOR encryption
encrypt_password() {
	local password="$1"
	local key="$ENCRYPT_KEY"
	local encrypted=""
	local i=0
	local key_len=${#key}

	while [ $i -lt ${#password} ]; do
		local char="${password:$i:1}"
		local key_char="${key:$((i % key_len)):1}"
		local char_code=$(printf '%d' "'$char")
		local key_code=$(printf '%d' "'$key_char")
		local xor_result=$((char_code ^ key_code))
		encrypted="${encrypted}$(printf '%02x' $xor_result)"
		i=$((i + 1))
	done

	echo "$encrypted"
}

# Check if Docker Compose services are running
check_services() {
	echo -e "${YELLOW}Checking Docker Compose services...${NC}"

	if ! (cd "${SERVICES_DIR}" && docker compose ps smtp-server) | grep -q "Up\|running"; then
		echo -e "${RED}✗ SMTP server container is not running${NC}"
		echo -e "${YELLOW}Starting services with: docker compose up -d${NC}"
		(cd "${SERVICES_DIR}" && docker compose up -d)
		sleep 10
	else
		echo -e "${GREEN}✓ SMTP server container is running${NC}"
	fi
}

# Add user to SQLite database
update_container_virtual_users() {
	local smtp_container="$1"
	local user_email="$2"
	local username="$3"
	local mail_domain="$4"

	echo -e "${YELLOW}Adding $user_email to SQLite database...${NC}"

	docker exec "$smtp_container" bash -c "
        DB_PATH='/app/data/mails.db'

        # Get domain_id
        domain_id=\$(sqlite3 \"\$DB_PATH\" \"SELECT id FROM domains WHERE domain='${mail_domain}' AND enabled=1;\")

        if [ -z \"\$domain_id\" ]; then
            echo 'Error: Domain ${mail_domain} not found in database'
            exit 1
        fi

        # Insert user into database
        sqlite3 \"\$DB_PATH\" \"INSERT OR REPLACE INTO users (username, domain_id, enabled) VALUES ('${username}', \$domain_id, 1);\"

        if [ \$? -eq 0 ]; then
            echo 'User added to database successfully'
        else
            echo 'Failed to add user to database'
            exit 1
        fi
    "
}

# Check user count in container (from SQLite database)
get_container_user_count() {
	local smtp_container="$1"
	local count=$(docker exec "$smtp_container" bash -c "sqlite3 /app/data/mails.db 'SELECT COUNT(*) FROM users WHERE enabled=1;' 2>/dev/null || echo '0'" | tr -d '\n\r' | head -c 10)
	echo ${count:-0}
}

# Maildir creation removed - using Raven IMAP server for mail storage

# -------------------------------
# Step 0: Read domain from YAML first
# -------------------------------
if [ ! -f "$CONFIG_FILE" ]; then
	echo -e "${RED}✗ Configuration file not found: $CONFIG_FILE${NC}"
	exit 1
fi

MAIL_DOMAIN=$(grep -m 1 '^domain:' "$CONFIG_FILE" | sed 's/domain: //' | xargs)

if [ -z "$MAIL_DOMAIN" ]; then
	echo -e "${RED}✗ Domain not defined in $CONFIG_FILE${NC}"
	exit 1
fi

if ! [[ "$MAIL_DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
	echo -e "${RED}✗ Invalid domain: $MAIL_DOMAIN${NC}"
	exit 1
fi

echo -e "${GREEN}✓ Domain name is valid: $MAIL_DOMAIN${NC}"

# -------------------------------
# Step 1: Check services and maximum user limit
# -------------------------------
check_services

MAX_USERS=100

# Find the smtp container
SMTP_CONTAINER=$(cd "${SERVICES_DIR}" && docker compose ps -q smtp-server 2>/dev/null)
if [ -z "$SMTP_CONTAINER" ]; then
	echo -e "${RED}✗ SMTP container not found. Is Docker Compose running?${NC}"
	echo -e "${YELLOW}Try running: docker compose up -d${NC}"
	exit 1
fi

# Ensure SQLite database exists in container
docker exec "$SMTP_CONTAINER" bash -c "
    if [ ! -f /app/data/mails.db ]; then
        echo 'Error: Database does not exist at /app/data/mails.db'
        echo 'Please ensure raven-server is running and has created the database'
        exit 1
    fi
"

if [ $? -ne 0 ]; then
	echo -e "${RED}✗ SQLite database not found. Please start raven-server first.${NC}"
	exit 1
fi

# Ensure the domain exists in the database
echo -e "${YELLOW}Ensuring domain ${MAIL_DOMAIN} exists in database...${NC}"
DOMAIN_CHECK=$(docker exec "$SMTP_CONTAINER" bash -c "
    sqlite3 /app/data/mails.db \"SELECT COUNT(*) FROM domains WHERE domain='${MAIL_DOMAIN}';\"
" 2>/dev/null | tr -d '\n\r')

if [ "$DOMAIN_CHECK" = "0" ]; then
	echo -e "${YELLOW}Domain ${MAIL_DOMAIN} not found. Adding to database...${NC}"
	docker exec "$SMTP_CONTAINER" bash -c "
        sqlite3 /app/data/mails.db \"INSERT INTO domains (domain, enabled, created_at) VALUES ('${MAIL_DOMAIN}', 1, datetime('now'));\"
    "

	if [ $? -eq 0 ]; then
		echo -e "${GREEN}✓ Domain ${MAIL_DOMAIN} added to database${NC}"
	else
		echo -e "${RED}✗ Failed to add domain to database${NC}"
		exit 1
	fi
else
	echo -e "${GREEN}✓ Domain ${MAIL_DOMAIN} already exists in database${NC}"
fi

# Get current user count
CURRENT_USER_COUNT=$(get_container_user_count "$SMTP_CONTAINER")
CURRENT_USER_COUNT=${CURRENT_USER_COUNT:-0}
echo -e "${CYAN}Current users: ${GREEN}$CURRENT_USER_COUNT${NC}. Maximum allowed: $MAX_USERS${NC}"

# -------------------------------
# Step 2: Set Thunder host
# -------------------------------
THUNDER_HOST=${MAIL_DOMAIN}
THUNDER_PORT="8090"
echo -e "${GREEN}✓ Thunder host set to: $THUNDER_HOST:$THUNDER_PORT${NC}"

# -------------------------------
# Step 2: Validate users.yaml
# -------------------------------
if [ ! -f "$USERS_FILE" ]; then
	echo -e "${RED}✗ Users file not found: $USERS_FILE${NC}"
	exit 1
fi

YAML_USER_COUNT=$(grep -c "username:" "$USERS_FILE" 2>/dev/null || echo "0")
if [ "$YAML_USER_COUNT" -eq 0 ]; then
	echo -e "${RED}✗ No users defined in $USERS_FILE${NC}"
	exit 1
fi

# Initialize passwords file
mkdir -p "$PASSWORDS_DIR"
echo "# Silver Mail User Passwords - Generated on $(date)" >"$PASSWORDS_FILE"
echo "# Passwords are encrypted. Use decrypt_password.sh to view them." >>"$PASSWORDS_FILE"
echo "" >>"$PASSWORDS_FILE"

# -------------------------------
# Step 3: Process each user
# -------------------------------
ADDED_COUNT=0
USER_USERNAME=""

while IFS= read -r line; do
	trimmed_line=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

	if [[ $trimmed_line =~ ^-\ username:\ (.+)$ ]] || [[ $trimmed_line =~ ^username:\ (.+)$ ]]; then
		USER_USERNAME="${BASH_REMATCH[1]}"

		if [ -n "$USER_USERNAME" ]; then
			USER_EMAIL="${USER_USERNAME}@${MAIL_DOMAIN}"

			# Check user limit
			CURRENT_USER_COUNT=$(get_container_user_count "$SMTP_CONTAINER")
			if [ "$CURRENT_USER_COUNT" -ge "$MAX_USERS" ]; then
				echo -e "${RED}✗ Cannot add ${USER_USERNAME}: maximum user limit ($MAX_USERS) reached. Skipping.${NC}"
				USER_USERNAME=""
				continue
			fi

			# Check if user already exists in database
			USER_EXISTS=$(docker exec "$SMTP_CONTAINER" bash -c "sqlite3 /app/data/mails.db \"SELECT COUNT(*) FROM users u INNER JOIN domains d ON u.domain_id = d.id WHERE u.username='${USER_USERNAME}' AND d.domain='${MAIL_DOMAIN}' AND u.enabled=1;\"" 2>/dev/null || echo "0")
			if [ "$USER_EXISTS" != "0" ]; then
				echo -e "${YELLOW}⚠ User ${USER_EMAIL} already exists. Skipping.${NC}"
				USER_USERNAME=""
				continue
			fi

			# Generate password
			USER_PASSWORD=$(generate_password)

			echo -e "\n${YELLOW}Creating user $USER_EMAIL in Thunder...${NC}"

			USER_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
				-H "Content-Type: application/json" \
				-H "Accept: application/json" \
				https://$THUNDER_HOST:$THUNDER_PORT/users \
				-d "{
                \"organizationUnit\": \"456e8400-e29b-41d4-a716-446655440001\",
                \"type\": \"emailuser\",
                \"attributes\": {
                  \"username\": \"$USER_USERNAME\",
                  \"password\": \"$USER_PASSWORD\",
                  \"email\": \"$USER_EMAIL\"
                }
              }")

			USER_BODY=$(echo "$USER_RESPONSE" | head -n -1)
			USER_STATUS=$(echo "$USER_RESPONSE" | tail -n1)

			if [ "$USER_STATUS" -eq 201 ] || [ "$USER_STATUS" -eq 200 ]; then
				echo -e "${GREEN}✓ User $USER_EMAIL created successfully in Thunder (HTTP $USER_STATUS)${NC}"

				# Update virtual configuration
				if update_container_virtual_users "$SMTP_CONTAINER" "$USER_EMAIL" "$USER_USERNAME" "$MAIL_DOMAIN"; then

					echo -e "${GREEN}✓ User $USER_EMAIL added to SQLite database (no hash rebuild needed)${NC}"

					# Store encrypted password
					ENCRYPTED_PASSWORD=$(encrypt_password "$USER_PASSWORD")
					echo "EMAIL: $USER_EMAIL" >>"$PASSWORDS_FILE"
					echo "ENCRYPTED: $ENCRYPTED_PASSWORD" >>"$PASSWORDS_FILE"
					echo "" >>"$PASSWORDS_FILE"

					# Display info
					echo -e "${BLUE}📧 Email: ${GREEN}$USER_EMAIL${NC}"
					echo -e "${BLUE}🔐 Encrypted Password: ${YELLOW}$ENCRYPTED_PASSWORD${NC}"
					echo -e "${CYAN}   Use './decrypt_password.sh $USER_EMAIL' to view the plain password${NC}"

					ADDED_COUNT=$((ADDED_COUNT + 1))
				else
					echo -e "${RED}✗ Failed to add $USER_EMAIL to virtual configuration${NC}"
				fi
			else
				echo -e "${RED}✗ Failed to create user $USER_EMAIL in Thunder (HTTP $USER_STATUS)${NC}"
				if [ -n "$USER_BODY" ]; then
					echo -e "${RED}Response: $USER_BODY${NC}"
				fi
			fi

			USER_USERNAME=""
		fi
	fi
done <"$USERS_FILE"

# -------------------------------
# Step 4: Final Postfix configuration reload
# -------------------------------
if [ "$ADDED_COUNT" -gt 0 ]; then
	echo -e "\n${YELLOW}Applying final Postfix configuration changes...${NC}"

	# Hot reload postfix configuration (SQLite queries are dynamic, no rebuild needed)
	echo -e "${YELLOW}Reloading Postfix configuration...${NC}"
	if docker exec "$SMTP_CONTAINER" postfix reload; then
		echo -e "${GREEN}✓ Postfix configuration reloaded successfully${NC}"
	else
		echo -e "${RED}✗ Failed to reload Postfix configuration${NC}"
		exit 1
	fi

	# Verify the changes from SQLite database
	echo -e "${YELLOW}Verifying SQLite database contents...${NC}"
	echo "Active domains:"
	docker exec "$SMTP_CONTAINER" sqlite3 /app/data/mails.db "SELECT domain FROM domains WHERE enabled=1;"
	echo "Active users (last 5):"
	docker exec "$SMTP_CONTAINER" sqlite3 /app/data/mails.db "SELECT u.username || '@' || d.domain as email FROM users u INNER JOIN domains d ON u.domain_id = d.id WHERE u.enabled=1 ORDER BY u.id DESC LIMIT 5;"

	# Reload Dovecot if available
	DOVECOT_CONTAINER=$(cd "${SERVICES_DIR}" && docker compose ps -q dovecot-server 2>/dev/null)
	if [ -n "$DOVECOT_CONTAINER" ]; then
		echo -e "${YELLOW}Reloading Dovecot configuration...${NC}"
		if docker exec "$DOVECOT_CONTAINER" dovecot reload 2>/dev/null; then
			echo -e "${GREEN}✓ Dovecot configuration reloaded${NC}"
		else
			echo -e "${YELLOW}⚠ Dovecot reload failed or not needed${NC}"
		fi
	fi

	echo -e "${GREEN}✓ All configuration changes applied successfully${NC}"
else
	echo -e "${YELLOW}No new users added, skipping configuration reload.${NC}"
fi

# -------------------------------
# Final Summary
# -------------------------------
TOTAL_USERS=$(get_container_user_count "$SMTP_CONTAINER")
echo -e "\n${CYAN}==============================================${NC}"
echo -e " 🎉 ${GREEN}User Setup Complete!${NC}"
echo " Total new users added: $ADDED_COUNT"
echo " Domain: $MAIL_DOMAIN"
echo " Total users now: $TOTAL_USERS"
echo ""
echo -e "${BLUE}🔐 Security Information:${NC}"
echo -e " Encrypted passwords: ${YELLOW}$PASSWORDS_FILE${NC}"
echo -e " Admin decryption tool: ${YELLOW}./decrypt_password.sh${NC}"
echo ""
echo -e "${CYAN}Admin Usage Examples:${NC}"
echo -e " View specific user password: ${YELLOW}./decrypt_password.sh alice@$MAIL_DOMAIN${NC}"
echo -e " View all passwords: ${YELLOW}./decrypt_password.sh all${NC}"
echo -e " Decrypt hex string: ${YELLOW}./decrypt_password.sh '1a2b3c4d...'${NC}"
echo ""
echo -e "${GREEN}✅ All users are active immediately - no container rebuild required!${NC}"
echo -e "${CYAN}==============================================${NC}"
