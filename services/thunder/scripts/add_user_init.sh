#!/bin/bash

# ============================================
#  Thunder Init - Create Add User
# ============================================

# Colors
CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${CYAN}---------------------------------------------${NC}"
echo -e " 🚀 ${GREEN}Thunder - Add User${NC}"
echo -e "${CYAN}---------------------------------------------${NC}\n"

# -------------------------------
# Step 1: Load Environment Variables
# -------------------------------
echo -e "${YELLOW}Step 1/3: Loading environment variables...${NC}"

ENV_FILE="../services/thunder/scripts/.env"
if [ -f "$ENV_FILE" ]; then
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
    echo -e "${GREEN}✓ Environment variables loaded from $ENV_FILE${NC}"
else
    echo -e "${RED}✗ $ENV_FILE not found! Aborting.${NC}"
    exit 1
fi

# -------------------------------
# Step 2: Create User
# -------------------------------

echo -e "\n${YELLOW}Creating user...${NC}"

USER_RESPONSE=$(curl -sk -w "\n%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  https://$THUNDER_HOST:$THUNDER_PORT/users \
  -d "{
    \"organizationUnit\": \"456e8400-e29b-41d4-a716-446655440001\",
    \"type\": \"superhuman\",
    \"attributes\": {
      \"username\": \"$USER_USERNAME\",
      \"password\": \"$USER_PASSWORD\",
      \"email\": \"$USER_EMAIL\",
      \"firstName\": \"$USER_FIRST_NAME\",
      \"lastName\": \"$USER_LAST_NAME\",
      \"age\": $USER_AGE,
      \"mobileNumber\": \"$USER_PHONE\"
    }
  }")

USER_BODY=$(echo "$USER_RESPONSE" | head -n -1)
USER_STATUS=$(echo "$USER_RESPONSE" | tail -n1)

if [ "$USER_STATUS" -eq 201 ] || [ "$USER_STATUS" -eq 200 ]; then
    echo -e "${GREEN}✓ User created successfully (HTTP $USER_STATUS)${NC}"
else
    echo -e "${RED}✗ Failed to create user (HTTP $USER_STATUS)${NC}"
    echo "Response: $USER_BODY"
    exit 1
fi

# -------------------------------
# Step 3: Update virtual-users file
# -------------------------------
echo -e "\n${YELLOW}Step 3/3: Updating virtual-users file...${NC}"

VIRTUAL_USERS_FILE="./smtp/conf/virtual-users"

# Ensure directory exists
mkdir -p "$(dirname "$VIRTUAL_USERS_FILE")"

# Ensure the file exists
touch "$VIRTUAL_USERS_FILE"

# Remove old entry for this user if it exists
grep -v "^${USER_USERNAME}@${MAIL_DOMAIN}" "$VIRTUAL_USERS_FILE" > "${VIRTUAL_USERS_FILE}.tmp" && mv "${VIRTUAL_USERS_FILE}.tmp" "$VIRTUAL_USERS_FILE"

# Append the new user
echo -e "${USER_USERNAME}@${MAIL_DOMAIN}\t${MAIL_DOMAIN}/${USER_USERNAME}" >> "$VIRTUAL_USERS_FILE"

# Ensure file ends with a newline
sed -i -e '$a\' "$VIRTUAL_USERS_FILE"

echo -e "${GREEN}✓ Added ${USER_USERNAME}@${MAIL_DOMAIN} to virtual-users file${NC}"

# -------------------------------
# Final Summary
# -------------------------------
echo -e "\n${CYAN}---------------------------------------------${NC}"
echo -e " 🎉 ${GREEN}Thunder Application & User Setup Complete${NC}"
echo " Username: $USER_USERNAME"
echo " Email:    $USER_EMAIL"
echo " Domain:   $MAIL_DOMAIN"
echo -e "${CYAN}---------------------------------------------${NC}"