#!/bin/bash

# ============================================
#  Silver Mail - Add User Wizard
# ============================================

# Colors
CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${CYAN}---------------------------------------------${NC}"
echo -e " 🚀 ${GREEN}Silver Mail - Add New User${NC}"
echo -e "${CYAN}---------------------------------------------${NC}\n"

# -------------------------------
# Step 1: Load existing .env files
# -------------------------------
echo -e "${YELLOW}Step 1/3: Loading environment variables...${NC}"

# Get the script directory (where add_user.sh is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define paths relative to script location
ENV_FILE="${SCRIPT_DIR}/thunder/scripts/.env"

CONFIG_FILE="silver.yaml"

echo "Looking for Thunder .env at: $ENV_FILE"

if [ -f "$ENV_FILE" ]; then
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
    echo -e "${GREEN}✓ Environment variables loaded from Thunder .env${NC}"
else
    echo -e "${RED}✗ Thunder .env file not found at: $ENV_FILE${NC}"
    echo -e "${RED}Please run initial setup first!${NC}"
    exit 1
fi

MAIL_DOMAIN=$(grep -m 1 '^domain:' "$CONFIG_FILE" | sed 's/domain: //' | xargs)

if [ -z "$MAIL_DOMAIN" ]; then
    echo -e "${RED}Error: Domain name is not configured or is empty. Please add it in silver.yaml.${NC}"
    exit 1 
fi

if ! [[ "$MAIL_DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo -e "${RED}Error: '${MAIL_DOMAIN}' is not a valid domain name.${NC}"
    exit 1 
fi

echo -e "${GREEN}✓ Domain name is valid: $MAIL_DOMAIN${NC}"
# -------------------------------
# Step 2: Collect new user info
# -------------------------------
echo -e "${YELLOW}Step 2/3: Enter new user information${NC}"

read -p "Enter username: " USER_USERNAME
read -s -p "Enter password: " USER_PASSWORD
echo ""

echo -e "${GREEN}✓ User input collected${NC}"

# -------------------------------
# Step 3: Update .env with new user info
# -------------------------------
echo -e "\n${YELLOW}Step 3/3: Updating Thunder .env file...${NC}"

update_or_add_env() {
    local key="$1"
    local value="$2"

    if grep -q "^$key=" "$ENV_FILE"; then
        sed -i "s|^$key=.*|$key=\"$value\"|" "$ENV_FILE"
    else
        echo "$key=\"$value\"" >> "$ENV_FILE"
    fi
}

update_or_add_env "USER_USERNAME" "$USER_USERNAME"
update_or_add_env "USER_PASSWORD" "$USER_PASSWORD"

echo -e "${GREEN}✓ User info updated in Thunder .env file${NC}"

# -------------------------------
# Step 4: Update SMTP configuration
# -------------------------------
echo -e "\n${YELLOW}Step 4/5: Updating SMTP configuration...${NC}"

TARGET_DIR="${SCRIPT_DIR}/smtp/conf"
if [ ! -d "$TARGET_DIR" ]; then
    echo "Creating SMTP conf directory: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
fi

# Add new user to SMTP configuration
echo -e "${USER_USERNAME}@${MAIL_DOMAIN}\t${MAIL_DOMAIN}/${USER_USERNAME}" >> "$TARGET_DIR/virtual-users"

echo -e "${GREEN}✓ SMTP configuration updated${NC}"

# -------------------------------
# Step 5: Run Thunder initialization script
# -------------------------------
echo -e "\n${YELLOW}Step 5/5: Running Thunder initialization script...${NC}"
chmod +x "${SCRIPT_DIR}/thunder/scripts/add_user_init.sh"
( cd "${SCRIPT_DIR}" && ./thunder/scripts/add_user_init.sh )
echo -e "${GREEN}✓ Thunder initialization completed${NC}"

# # -------------------------------
# # Step 6: Recreate SMTP service
# # -------------------------------
# echo -e "\n${YELLOW}Rebuilding and recreating only the SMTP service...${NC}"
# ( cd "${SCRIPT_DIR}" && docker compose up -d --build --force-recreate smtp-server )

# if [ $? -eq 0 ]; then
#     echo -e "${GREEN}✓ SMTP service successfully rebuilt and running${NC}"
# else
#     echo -e "${RED}✗ Failed to recreate SMTP service. Please check the logs.${NC}"
#     exit 1
# fi

# # -------------------------------
# # Final Summary
# # -------------------------------
# echo -e "\n${CYAN}---------------------------------------------${NC}"
# echo -e " 🎉 ${GREEN}New User Setup Complete!${NC}"
# echo " Username: $USER_USERNAME"
# echo " Email:    ${USER_USERNAME}@${MAIL_DOMAIN}"
# echo -e "${CYAN}---------------------------------------------${NC}"