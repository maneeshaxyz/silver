#!/bin/bash

# ============================================
#  Silver Mail Setup Wizard
# ============================================

# Colors
CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# ASCII Banner
echo -e "${CYAN}"
cat <<'EOF'
                                                                                                
                                                                                                
   SSSSSSSSSSSSSSS   iiii  lllllll                                                              
 SS:::::::::::::::S i::::i l:::::l                                                              
S:::::SSSSSS::::::S  iiii  l:::::l                                                              
S:::::S     SSSSSSS        l:::::l                                                              
S:::::S            iiiiiii  l::::lvvvvvvv           vvvvvvv eeeeeeeeeeee    rrrrr   rrrrrrrrr   
S:::::S            i:::::i  l::::l v:::::v         v:::::vee::::::::::::ee  r::::rrr:::::::::r  
 S::::SSSS          i::::i  l::::l  v:::::v       v:::::ve::::::eeeee:::::eer:::::::::::::::::r 
  SS::::::SSSSS     i::::i  l::::l   v:::::v     v:::::ve::::::e     e:::::err::::::rrrrr::::::r
    SSS::::::::SS   i::::i  l::::l    v:::::v   v:::::v e:::::::eeeee::::::e r:::::r     r:::::r
       SSSSSS::::S  i::::i  l::::l     v:::::v v:::::v  e:::::::::::::::::e  r:::::r     rrrrrrr
            S:::::S i::::i  l::::l      v:::::v:::::v   e::::::eeeeeeeeeee   r:::::r            
            S:::::S i::::i  l::::l       v:::::::::v    e:::::::e            r:::::r            
SSSSSSS     S:::::Si::::::il::::::l       v:::::::v     e::::::::e           r:::::r            
S::::::SSSSSS:::::Si::::::il::::::l        v:::::v       e::::::::eeeeeeee   r:::::r            
S:::::::::::::::SS i::::::il::::::l         v:::v         ee:::::::::::::e   r:::::r            
 SSSSSSSSSSSSSSS   iiiiiiiillllllll          vvv            eeeeeeeeeeeeee   rrrrrrr            
                                                                                                 
EOF
echo -e "${NC}"

echo ""
echo -e " 🚀 ${GREEN}Welcome to Silver Mail System Setup${NC}"
echo "---------------------------------------------" 

MAIL_DOMAIN=""

# ================================
# Step 1: Domain Configuration
# ================================
echo -e "\n${YELLOW}Step 1/6: Configure domain name${NC}"
while [ -z "$MAIL_DOMAIN" ]; do
  read -p "Please enter the domain name: " MAIL_DOMAIN
  if [ -z "$MAIL_DOMAIN" ]; then
    echo -e "${RED}✗ Domain name cannot be empty. Please try again.${NC}"
  fi
done

if ! [[ "$MAIL_DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo -e "${RED}✗ Warning: '${MAIL_DOMAIN}' does not look like a valid domain name.${NC}"
    exit 1
fi

echo "MAIL_DOMAIN=${MAIL_DOMAIN}" > .env
echo -e "${GREEN}✓ .env file created successfully for ${MAIL_DOMAIN}${NC}"

# ================================
# Step 2: Admin User Configuration
# ================================
echo -e "\n${YELLOW}Step 2/6: Configure Admin User${NC}"

read -p "Enter username: " USER_USERNAME
read -s -p "Enter password: " USER_PASSWORD
echo "" # newline

read -p "Enter first name: " USER_FIRST_NAME
read -p "Enter last name: " USER_LAST_NAME
read -p "Enter age: " USER_AGE
read -p "Enter phone number: " USER_PHONE

echo -e "${GREEN}✓ Admin user information collected${NC}"

# ================================
# Step 3: Writing Thunder .env
# ================================
echo -e "\n${YELLOW}Step 3/6: Creating Thunder configuration file${NC}"

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

echo -e "${GREEN}✓ Thunder .env file created${NC}"

# ================================
# Step 4: SMTP Configuration
# ================================
echo -e "\n${YELLOW}Step 4/6: Creating SMTP configuration${NC}"

TARGET_DIR="../services/smtp/conf"
if [ ! -d "$TARGET_DIR" ]; then
    echo "Directory '$TARGET_DIR' does not exist. Creating it now..."
    mkdir -p "$TARGET_DIR"
fi

echo "${MAIL_DOMAIN} OK" > "$TARGET_DIR/virtual-domains"
echo "postmaster@${MAIL_DOMAIN} ${USER_USERNAME}@${MAIL_DOMAIN}" > "$TARGET_DIR/virtual-aliases"
echo -e "${USER_USERNAME}@${MAIL_DOMAIN}\t${MAIL_DOMAIN}/${USER_USERNAME}" > "$TARGET_DIR/virtual-users"

echo -e "${GREEN}✓ SMTP configuration files created${NC}"
echo " - $TARGET_DIR/virtual-domains"
echo " - $TARGET_DIR/virtual-aliases"
echo " - $TARGET_DIR/virtual-users"

# ================================
# Step 5: Spam Filter Configuration
# ================================
echo -e "\n${YELLOW}Step 5/6: Configuring Spam Filter${NC}"

if [ ! -d "../services/spam/conf" ]; then
    mkdir -p "../services/spam/conf"
fi
echo "password = \"\$2\$8hn4c88rmafsueo4h3yckiirwkieidb3\$uge4i3ynbba89qpo1gqmqk9gqjy8ysu676z1p8ss5qz5y1773zgb\";" > ../services/spam/conf/worker-controller.inc
echo -e "${GREEN}✓ worker-controller.inc created for spam filter${NC}"

# ================================
# Step 6: Docker Setup
# ================================
echo -e "\n${YELLOW}Step 6/6: Starting Docker services${NC}"

docker compose up -d --build --force-recreate
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Docker compose failed. Please check the logs.${NC}"
    exit 1
fi

echo -n "⏳ Waiting for services to become healthy"
while [ "$(docker compose ps --services --filter "status=running" | wc -l)" -lt "$(docker compose ps --services | wc -l)" ]; do
    echo -n "."
    sleep 5
done
echo -e " ${GREEN}done${NC}"

sleep 10

chmod +x ../services/thunder/scripts/init.sh
echo "Running Thunder initialization script..."
( cd ../services && ./thunder/scripts/init.sh )

echo "Rebuilding and recreating only the SMTP service..."
docker compose up -d --build --force-recreate smtp-server

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SMTP service rebuilt and running${NC}"
else
    echo -e "${RED}✗ Failed to recreate SMTP service. Please check the logs.${NC}"
    exit 1
fi

# ================================
# Final Summary
# ================================
echo ""
echo -e "🎉 ${GREEN}Setup Complete!${NC}"
echo "---------------------------------------------"
echo " Domain:        ${MAIL_DOMAIN}"
echo " Admin User:    ${USER_USERNAME}"
echo " Admin Email:   ${USER_USERNAME}@${MAIL_DOMAIN}"
echo " Thunder API:   http://localhost:8090"
echo "---------------------------------------------"


# ================================
# Public DKIM Key Instructions
# ================================
chmod +x ./get-dkim.sh
./get-dkim.sh
