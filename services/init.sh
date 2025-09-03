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
EOF

echo "Successfully created .env file."
echo "You can now run the other scripts that depend on this file."

# Check if the target directory exists and create it if it doesn't.
TARGET_DIR="../services/smtp/conf"
if [ ! -d "$TARGET_DIR" ]; then
    echo "Directory '$TARGET_DIR' does not exist. Creating it now..."
    mkdir -p "$TARGET_DIR"
fi


# Create virtual-domains file
echo "${MAIL_DOMAIN} OK" > "$TARGET_DIR/virtual-domains"

# Create virtual-aliases file (map postmaster to admin email)
echo "postmaster@${MAIL_DOMAIN} ${USER_USERNAME}@${MAIL_DOMAIN}" > "$TARGET_DIR/virtual-aliases"

# Create virtual-users file
echo -e "${USER_USERNAME}@${MAIL_DOMAIN}\t${MAIL_DOMAIN}/${USER_USERNAME}" > "$TARGET_DIR/virtual-users"

echo "SMTP configuration files created successfully:"
echo " - $TARGET_DIR/virtual-domains"
echo " - $TARGET_DIR/virtual-aliases"
echo " - $TARGET_DIR/virtual-users"

# -------------------------------
# Add worker-controller.inc to ../services/spam/conf

if [ ! -d "../services/spam/conf" ]; then
    mkdir -p "../services/spam/conf"
fi
echo "password = \"\$2\$8hn4c88rmafsueo4h3yckiirwkieidb3\$uge4i3ynbba89qpo1gqmqk9gqjy8ysu676z1p8ss5qz5y1773zgb\";" > ../services/spam/conf/worker-controller.inc
echo "Added worker-controller.inc to ../services/spam/conf"

# -------------------------------
# Run docker compose and wait for services
echo "Starting Docker services..."
docker compose up -d --build --force-recreate

if [ $? -ne 0 ]; then
    echo "Docker compose failed. Please check the logs."
    exit 1
fi

echo "Waiting for all services to become healthy..."
# Wait until all containers are running
while [ "$(docker compose ps --services --filter "status=running" | wc -l)" -lt "$(docker compose ps --services | wc -l)" ]; do
    echo "Some services are not yet running. Retrying in 5s..."
    sleep 5
done

echo "All services are up and running."

sleep 10 # Additional wait time for services to stabilize

# -------------------------------
# Make Thunder init.sh executable
chmod +x ../services/thunder/scripts/init.sh

# Run Thunder initialization script
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

printf "%s\n%s" \
    "postmaster@${MAIL_DOMAIN} ${USER_MAIL}" \
    > ../services/smtp/conf/virtual_aliases

echo "Smtp files created has been created successfully."

