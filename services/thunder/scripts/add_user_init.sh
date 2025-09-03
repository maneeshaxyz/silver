#!/bin/bash

ENV_FILE="../services/thunder/scripts/.env"
if [ -f "$ENV_FILE" ]; then
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
    echo "Environment variables loaded from $ENV_FILE"
else
    echo "$ENV_FILE not found!"
    exit 1
fi

echo "Creating application..."
curl -k -X POST \
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
  }"

echo -e "\n\nCreating user..."
curl -k -X POST \
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
  }"

# -------------------------------
# Append the new user to virtual-users file
# Path to virtual-users
VIRTUAL_USERS_FILE="./smtp/conf/virtual-users"

# Ensure directory exists
mkdir -p "$(dirname "$VIRTUAL_USERS_FILE")"

# Ensure the virtual-users file exists
mkdir -p "$(dirname "$VIRTUAL_USERS_FILE")"
touch "$VIRTUAL_USERS_FILE"

# Remove old entry for this user if it exists
grep -v "^${USER_USERNAME}@${MAIL_DOMAIN}" "$VIRTUAL_USERS_FILE" > "${VIRTUAL_USERS_FILE}.tmp" && mv "${VIRTUAL_USERS_FILE}.tmp" "$VIRTUAL_USERS_FILE"

# Append the new user on a new line
echo -e "${USER_USERNAME}@${MAIL_DOMAIN}\t${MAIL_DOMAIN}/${USER_USERNAME}" >> "$VIRTUAL_USERS_FILE"

# Ensure file ends with a newline
sed -i -e '$a\' "$VIRTUAL_USERS_FILE"

echo "Added ${USER_USERNAME}@${MAIL_DOMAIN} to virtual-users file."