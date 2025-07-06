#!/bin/bash

# quick_setup.sh - Quick setup for evaluation with secrets structure

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Quick Inception Setup${NC}"
echo "===================="

# Get login
read -p "Enter login: " LOGIN

# Create secrets directory
echo -e "${BLUE}Creating secrets...${NC}"
mkdir -p secrets

# Create secret files with default strong passwords
echo -n "RootPass42!Strong" > secrets/mysql_rootpassword
echo -n "wpuser" > secrets/mysql_user
echo -n "WpUser42!Pass" > secrets/mysql_password
echo -n "supervisor" > secrets/wp_admin_user
echo -n "Admin42!Strong" > secrets/wp_adminpassword
echo -n "supervisor@${LOGIN}.42.fr" > secrets/wp_admin_mail

# Set permissions
chmod 600 secrets/*

# Create .env with minimal info
cat > srcs/.env << EOF
#MariaDB configuration
MYSQL_DATABASE=wordpress
#WP configuration
DOMAIN_NAME=${LOGIN}.42.fr
WP_TITLE=Inception Project
WP_USER=editor
WP_USER_PASSWORD=User42!Pass
WP_USER_EMAIL=editor@${LOGIN}.42.fr
EOF

echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo -e "${YELLOW}Credentials:${NC}"
echo "  Admin: supervisor / Admin42!Strong"
echo "  User: editor / User42!Pass"
echo "  DB Root: RootPass42!Strong"
echo "  DB User: wpuser / WpUser42!Pass"
echo ""
echo "Add to /etc/hosts: 127.0.0.1 ${LOGIN}.42.fr"