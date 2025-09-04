#!/bin/bash

# ============================================
#  Thunder Init Script - Setup Application & User
# ============================================

# Colors
CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

ENV_FILE="../services/thunder/scripts/.env"

echo -e "${CYAN}---------------------------------------------${NC}"
echo -e " 🚀 ${GREEN}Starting Thunder Initialization${NC}"
echo -e "${CYAN}---------------------------------------------${NC}\n"

# Step 1: Load Environment Variables
echo -e "${YELLOW}Step 1/2: Loading environment variables...${NC}"
if [ -f "$ENV_FILE" ]; then
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
    echo -e "${GREEN}✓ Environment variables loaded from $ENV_FILE${NC}"
else
    echo -e "${RED}✗ $ENV_FILE not found! Aborting.${NC}"
    exit 1
fi

# Step 2: Create Application
echo -e "\n${YELLOW}Step 2/2: Creating Application...${NC}"
APP_RESPONSE=$(curl -sk -w "\n%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  https://$THUNDER_HOST:$THUNDER_PORT/applications \
  -d "{
    \"name\": \"$APP_NAME\",
    \"description\": \"$APP_DESCRIPTION\",
    \"client_id\": \"$APP_CLIENT_ID\",
    \"client_secret\": \"$APP_CLIENT_SECRET\",
    \"redirect_uris\": [\"https://localhost:3000\"],
    \"grant_types\": [\"client_credentials\"],
    \"token_endpoint_auth_method\": [\"client_secret_basic\", \"client_secret_post\"],
    \"auth_flow_graph_id\": \"auth_flow_config_basic\"
  }")

APP_BODY=$(echo "$APP_RESPONSE" | head -n -1)
APP_STATUS=$(echo "$APP_RESPONSE" | tail -n1)

if [ "$APP_STATUS" -eq 201 ] || [ "$APP_STATUS" -eq 200 ]; then
    echo -e "${GREEN}✓ Application created successfully (HTTP $APP_STATUS)${NC}"
else
    echo -e "${RED}✗ Failed to create application (HTTP $APP_STATUS)${NC}"
    echo "Response: $APP_BODY"
    exit 1
fi

# Step 3: Create User
echo -e "\n${YELLOW}Step 3/3: Creating Admin User...${NC}"
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
      \"age\": \"$USER_AGE\",
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

# Final Summary
echo -e "\n${CYAN}---------------------------------------------${NC}"
echo -e " 🎉 ${GREEN}Thunder Initialization Complete${NC}"
echo -e "${CYAN}---------------------------------------------${NC}"
echo " Application Name:   $APP_NAME"
echo " Client ID:          $APP_CLIENT_ID"
echo " Admin Username:     $USER_USERNAME"
echo " Admin Email:        $USER_EMAIL"
echo -e "${CYAN}---------------------------------------------${NC}"