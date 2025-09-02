#!/bin/bash

# This script creates a .env file with a domain name provided by the user.

MAIL_DOMAIN=""

# Loop until a non-empty value is provided
while [ -z "$MAIL_DOMAIN" ]; do
  echo "Please enter the domain name:"
  read MAIL_DOMAIN
  if [ -z "$MAIL_DOMAIN" ]; then
    echo "Domain name cannot be empty. Please try again."
  fi
done

# Exit if not valid
if ! [[ "$MAIL_DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "Warning: '${MAIL_DOMAIN}' does not look like a valid domain name."
    exit 1
fi


# Create or overwrite the .env file
echo "MAIL_DOMAIN=${MAIL_DOMAIN}" > .env

echo ".env file created successfully for ${MAIL_DOMAIN}"


echo "Please enter the required information for an admin user"

# User Configuration
read -p "Enter username: " USER_USERNAME
read -s -p "Enter password: " USER_PASSWORD
echo "" # New line after password prompt

read -p "Enter first name: " USER_FIRST_NAME
read -p "Enter last name: " USER_LAST_NAME
read -p "Enter age: " USER_AGE
read -p "Enter phone number: " USER_PHONE

# User Address
echo ""
echo "Now, let's enter the user's address."
read -p "Enter street: " USER_ADDRESS_STREET
read -p "Enter city: " USER_ADDRESS_CITY
read -p "Enter state: " USER_ADDRESS_STATE
read -p "Enter zip code: " USER_ADDRESS_ZIPCODE
read -p "Enter country: " USER_ADDRESS_COUNTRY

# Combine address into a JSON string
USER_ADDRESS_JSON="{\"street\":\"${USER_ADDRESS_STREET}\",\"city\":\"${USER_ADDRESS_CITY}\",\"state\":\"${USER_ADDRESS_STATE}\",\"zipCode\":\"${USER_ADDRESS_ZIPCODE}\",\"country\":\"${USER_ADDRESS_COUNTRY}\"}"

# Create the .env file
echo "Creating .env file in the Thunder directory..."

# The file is being created in the parent directory to match the desired location.
cat > ../services/thunder/scripts/.env <<EOF
# Thunder Server Configuration
THUNDER_HOST="localhost"
THUNDER_PORT="8090"

# Application Configuration
APP_NAME="MyThunderApp"
APP_DESCRIPTION="Thunder application for API testing and development"
APP_CLIENT_ID="************"
APP_CLIENT_SECRET="************"

# User Configuration
USER_USERNAME="${USER_USERNAME}"
USER_PASSWORD="${USER_PASSWORD}"
USER_EMAIL="${USER_USERNAME}@${MAIL_DOMAIN}"
USER_FIRST_NAME="${USER_FIRST_NAME}"
USER_LAST_NAME="${USER_LAST_NAME}"
USER_AGE="${USER_AGE}"
USER_PHONE="${USER_PHONE}"

# User Address (JSON format)
USER_ADDRESS='${USER_ADDRESS_JSON}'
EOF

echo "Successfully created .env file."
echo "You can now run the other scripts that depend on this file."

# SMTP FILES
cat > email_mappings.txt << 'EOF'
postmaster@${MAIL_DOMAIN}  ${USER_EMAIL}
EOF

echo "Smtp files created has been created successfully."
