#!/bin/bash

# -------------------------------
# Load existing .env
ENV_FILE="../services/thunder/scripts/.env"
ENV_FILE_LOCAL=".env"

if [ -f "$ENV_FILE" ]; then
  set -o allexport
  source "$ENV_FILE"
  set +o allexport
  echo "Environment variables loaded from existing Thunder .env file"
else
  echo "Thunder .env file not found!"
  exit 1
fi

if [ -f "$ENV_FILE_LOCAL" ]; then
  set -o allexport
  source "$ENV_FILE_LOCAL"
  set +o allexport
  echo "Environment variables loaded from local .env file"
else
  echo "Local .env file not found!"
  exit 1
fi

echo "Main domain detected: $MAIL_DOMAIN"

echo "Please enter the new user information"

# User Configuration
read -p "Enter username: " USER_USERNAME
read -s -p "Enter password: " USER_PASSWORD
echo ""
read -p "Enter first name: " USER_FIRST_NAME
read -p "Enter last name: " USER_LAST_NAME
read -p "Enter age: " USER_AGE
read -p "Enter phone number: " USER_PHONE

# User Address
echo ""
echo "Enter the user's address."
read -p "Street: " USER_ADDRESS_STREET
read -p "City: " USER_ADDRESS_CITY
read -p "State: " USER_ADDRESS_STATE
read -p "Zip code: " USER_ADDRESS_ZIPCODE
read -p "Country: " USER_ADDRESS_COUNTRY

# Combine address into JSON string
USER_ADDRESS_JSON="{\"street\":\"${USER_ADDRESS_STREET}\",\"city\":\"${USER_ADDRESS_CITY}\",\"state\":\"${USER_ADDRESS_STATE}\",\"zipCode\":\"${USER_ADDRESS_ZIPCODE}\",\"country\":\"${USER_ADDRESS_COUNTRY}\"}"

# -------------------------------
# Function to update or add key=value in .env
update_or_add_env() {
    local key="$1"
    local value="$2"

    if grep -q "^$key=" "$ENV_FILE"; then
        sed -i "s|^$key=.*|$key=\"$value\"|" "$ENV_FILE"
    else
        echo "$key=\"$value\"" >> "$ENV_FILE"
    fi
}

# Update or add user variables
update_or_add_env "USER_USERNAME" "$USER_USERNAME"
update_or_add_env "USER_PASSWORD" "$USER_PASSWORD"
update_or_add_env "USER_EMAIL" "${USER_USERNAME}@${MAIL_DOMAIN}"
update_or_add_env "USER_FIRST_NAME" "$USER_FIRST_NAME"
update_or_add_env "USER_LAST_NAME" "$USER_LAST_NAME"
update_or_add_env "USER_AGE" "$USER_AGE"
update_or_add_env "USER_PHONE" "$USER_PHONE"
update_or_add_env "USER_ADDRESS" "'$USER_ADDRESS_JSON'"

echo "User info updated in Thunder .env file."

# -------------------------------
# Run Thunder initialization script
chmod +x ../services/thunder/scripts/init.sh
echo "Running Thunder initialization script..."
( cd ../services && ./thunder/scripts/init.sh )

# -------------------------------
# Force recreate only the SMTP service
echo "Rebuilding and recreating only the SMTP service..."
docker compose up -d --build --force-recreate smtp-server

if [ $? -eq 0 ]; then
    echo "SMTP service has been successfully rebuilt and recreated."
else
    echo "Failed to recreate SMTP service. Please check the logs."
    exit 1
fi