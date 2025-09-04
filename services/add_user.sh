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
ENV_FILE_LOCAL="${SCRIPT_DIR}/.env"

echo "Looking for Thunder .env at: $ENV_FILE"
echo "Looking for local .env at: $ENV_FILE_LOCAL"

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

if [ -f "$ENV_FILE_LOCAL" ]; then
    set -o allexport
    source "$ENV_FILE_LOCAL"
    set +o allexport
    echo -e "${GREEN}✓ Environment variables loaded from local .env${NC}"
else
    echo -e "${RED}✗ Local .env file not found at: $ENV_FILE_LOCAL${NC}"
    echo -e "${RED}Please run initial setup first!${NC}"
    exit 1
fi

echo -e "${CYAN}Main domain detected: ${GREEN}$MAIL_DOMAIN${NC}\n"

# -------------------------------
# Step 2: Collect new user info
# -------------------------------
echo -e "${YELLOW}Step 2/3: Enter new user information${NC}"

read -p "Enter username: " USER_USERNAME
read -s -p "Enter password: " USER_PASSWORD
echo ""
read -p "Enter first name: " USER_FIRST_NAME
read -p "Enter last name: " USER_LAST_NAME
read -p "Enter age: " USER_AGE
read -p "Enter phone number: " USER_PHONE

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
update_or_add_env "USER_EMAIL" "${USER_USERNAME}@${MAIL_DOMAIN}"
update_or_add_env "USER_FIRST_NAME" "$USER_FIRST_NAME"
update_or_add_env "USER_LAST_NAME" "$USER_LAST_NAME"
update_or_add_env "USER_AGE" "$USER_AGE"
update_or_add_env "USER_PHONE" "$USER_PHONE"

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

# -------------------------------
# Step 6: Recreate SMTP service
# -------------------------------
echo -e "\n${YELLOW}Rebuilding and recreating only the SMTP service...${NC}"
( cd "${SCRIPT_DIR}" && docker compose up -d --build --force-recreate smtp-server )

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SMTP service successfully rebuilt and running${NC}"
else
    echo -e "${RED}✗ Failed to recreate SMTP service. Please check the logs.${NC}"
    exit 1
fi

# -------------------------------
# Final Summary
# -------------------------------
echo -e "\n${CYAN}---------------------------------------------${NC}"
echo -e " 🎉 ${GREEN}New User Setup Complete!${NC}"
echo " Username: $USER_USERNAME"
echo " Email:    ${USER_USERNAME}@${MAIL_DOMAIN}"
echo " Name:     $USER_FIRST_NAME $USER_LAST_NAME"
echo " Age:      $USER_AGE"
echo " Phone:    $USER_PHONE"
echo -e "${CYAN}---------------------------------------------${NC}"