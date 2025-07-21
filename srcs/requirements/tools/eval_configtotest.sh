#!/bin/bash

# setup_env.sh - Interactive setup for .env and secrets files

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Header
clear
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Inception Environment Setup        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Change to project root
cd "$PROJECT_ROOT"

# Check if secrets directory exists
if [ -d "secrets" ]; then
    echo -e "${YELLOW}⚠️  Warning: secrets directory already exists!${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Setup cancelled.${NC}"
        exit 1
    fi
fi

# Get user login
echo -e "${CYAN}=== Basic Configuration ===${NC}"
read -p "Enter your 42 login: " LOGIN
if [ -z "$LOGIN" ]; then
    echo -e "${RED}Error: Login cannot be empty!${NC}"
    exit 1
fi

# Domain configuration
DOMAIN_NAME="${LOGIN}.42.fr"
echo -e "${GREEN}✓ Domain will be: ${DOMAIN_NAME}${NC}"
echo ""

# Database configuration
echo -e "${CYAN}=== Database Configuration ===${NC}"
echo -e "${YELLOW}Leave empty for default values${NC}"

# Database name
read -p "Database name (default: wordpress): " MYSQL_DATABASE
MYSQL_DATABASE=${MYSQL_DATABASE:-wordpress}

# MySQL Root Password
read -sp "MySQL Root Password (default: auto-generate): " MYSQL_ROOT_PASSWORD
echo
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12)
    echo -e "${GREEN}✓ Generated root password${NC}"
fi

# Database user
read -p "Database username (default: wpuser): " MYSQL_USER
MYSQL_USER=${MYSQL_USER:-wpuser}

# Database user password
read -sp "Database user password (default: auto-generate): " MYSQL_PASSWORD
echo
if [ -z "$MYSQL_PASSWORD" ]; then
    MYSQL_PASSWORD=$(openssl rand -base64 12)
    echo -e "${GREEN}✓ Generated database password${NC}"
fi

echo ""

# WordPress configuration
echo -e "${CYAN}=== WordPress Admin Configuration ===${NC}"

# Admin username (must not contain 'admin')
while true; do
    read -p "WordPress admin username (cannot contain 'admin'): " WP_ADMIN_USER
    if [ -z "$WP_ADMIN_USER" ]; then
        echo -e "${RED}Username cannot be empty!${NC}"
    elif [[ "${WP_ADMIN_USER,,}" == *"admin"* ]]; then
        echo -e "${RED}Username cannot contain 'admin'! Try something like: supervisor, manager, chief${NC}"
    else
        break
    fi
done

# Admin password
read -sp "WordPress admin password (default: auto-generate): " WP_ADMIN_PASSWORD
echo
if [ -z "$WP_ADMIN_PASSWORD" ]; then
    WP_ADMIN_PASSWORD=$(openssl rand -base64 12)
    echo -e "${GREEN}✓ Generated admin password${NC}"
fi

# Admin email
read -p "WordPress admin email (default: ${WP_ADMIN_USER}@${DOMAIN_NAME}): " WP_ADMIN_EMAIL
WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL:-${WP_ADMIN_USER}@${DOMAIN_NAME}}

# Regular user
echo ""
echo -e "${CYAN}=== WordPress Regular User ===${NC}"
read -p "WordPress regular username (default: user): " WP_USER
WP_USER=${WP_USER:-user}

read -sp "WordPress regular user password (default: auto-generate): " WP_USER_PASSWORD
echo
if [ -z "$WP_USER_PASSWORD" ]; then
    WP_USER_PASSWORD=$(openssl rand -base64 12)
    echo -e "${GREEN}✓ Generated user password${NC}"
fi

read -p "WordPress regular user email (default: ${WP_USER}@${DOMAIN_NAME}): " WP_USER_EMAIL
WP_USER_EMAIL=${WP_USER_EMAIL:-${WP_USER}@${DOMAIN_NAME}}

# WordPress site title
read -p "WordPress site title (default: Inception Project): " WP_TITLE
WP_TITLE=${WP_TITLE:-Inception Project}

# Create secrets directory
echo ""
echo -e "${BLUE}Creating secrets directory and files...${NC}"
mkdir -p secrets

# Create individual secret files
echo -n "${MYSQL_ROOT_PASSWORD}" > secrets/mysql_rootpassword
echo -n "${MYSQL_USER}" > secrets/mysql_user
echo -n "${MYSQL_PASSWORD}" > secrets/mysql_password
echo -n "${WP_ADMIN_USER}" > secrets/wp_admin_user
echo -n "${WP_ADMIN_PASSWORD}" > secrets/wp_adminpassword
echo -n "${WP_ADMIN_EMAIL}" > secrets/wp_admin_mail

# Set permissions
chmod 600 secrets/*
echo -e "${GREEN}✓ Secret files created${NC}"

# Create .env file with minimal information
echo -e "${BLUE}Creating .env file...${NC}"

cat > srcs/.env << EOF
#MariaDB configuration
MYSQL_DATABASE=${MYSQL_DATABASE}
#WP configuration
DOMAIN_NAME=${DOMAIN_NAME}
WP_TITLE=${WP_TITLE}
WP_USER=${WP_USER}
WP_USER_PASSWORD=${WP_USER_PASSWORD}
WP_USER_EMAIL=${WP_USER_EMAIL}
EOF

echo -e "${GREEN}✓ .env file created${NC}"

# Update .gitignore
if ! grep -q "secrets/" .gitignore 2>/dev/null; then
    echo -e "${BLUE}Updating .gitignore...${NC}"
    echo -e "\n# Environment and secrets\n.env\nsrcs/.env\nsecrets/" >> .gitignore
    echo -e "${GREEN}✓ .gitignore updated${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Setup Complete!              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Configuration Summary:${NC}"
echo -e "  Domain: ${CYAN}${DOMAIN_NAME}${NC}"
echo -e "  Database: ${CYAN}${MYSQL_DATABASE}${NC}"
echo -e "  DB User: ${CYAN}${MYSQL_USER}${NC}"
echo -e "  WP Admin: ${CYAN}${WP_ADMIN_USER}${NC}"
echo -e "  WP User: ${CYAN}${WP_USER}${NC}"
echo ""
echo -e "${YELLOW}Secret files created in secrets/:${NC}"
ls -la secrets/
echo ""
echo -e "${YELLOW}Important:${NC}"
echo -e "  - Your passwords are in the secrets/ directory"
echo -e "  - Keep these files secure and NEVER commit them!"
echo -e "  - Add to /etc/hosts: ${CYAN}127.0.0.1 ${DOMAIN_NAME}${NC}"
echo ""
echo -e "${GREEN}You can now run 'make' to start the project!${NC}"

# Save credentials summary
echo -e "${BLUE}Saving credentials summary...${NC}"
cat > inception_credentials.txt << EOF
Inception Credentials
====================
Generated on: $(date)

Domain: https://${DOMAIN_NAME}

Database Access:
- Root Password: ${MYSQL_ROOT_PASSWORD}
- Database Name: ${MYSQL_DATABASE}
- Database User: ${MYSQL_USER}
- Database Pass: ${MYSQL_PASSWORD}

WordPress Admin:
- Username: ${WP_ADMIN_USER}
- Password: ${WP_ADMIN_PASSWORD}
- Email: ${WP_ADMIN_EMAIL}
- Login URL: https://${DOMAIN_NAME}/wp-admin

WordPress User:
- Username: ${WP_USER}
- Password: ${WP_USER_PASSWORD}
- Email: ${WP_USER_EMAIL}

Secret files location: ./secrets/

IMPORTANT: Delete this file after noting down the credentials!
EOF

chmod 600 inception_credentials.txt
echo -e "${GREEN}✓ Credentials saved to inception_credentials.txt${NC}"
echo -e "${YELLOW}⚠️  Remember to delete this file after saving the passwords!${NC}"