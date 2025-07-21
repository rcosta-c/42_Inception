#!/bin/bash

# show_credentials.sh - Display current credentials from secrets

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Current Credentials              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Change to project root
cd "$PROJECT_ROOT"

# Check if secrets directory exists
if [ ! -d "secrets" ]; then
    echo -e "${RED}Error: secrets directory not found!${NC}"
    echo "Run ./srcs/requirements/tools/eval_configtotest.sh first"
    exit 1
fi

# Read .env
if [ -f "srcs/.env" ]; then
    source srcs/.env
    echo -e "${GREEN}Domain:${NC} ${DOMAIN_NAME}"
    echo -e "${GREEN}Database:${NC} ${MYSQL_DATABASE}"
    echo ""
fi

# Read secrets
echo -e "${CYAN}=== Database Credentials ===${NC}"
if [ -f "secrets/mysql_rootpassword" ]; then
    echo -e "Root Password: ${YELLOW}$(cat secrets/mysql_rootpassword)${NC}"
fi
if [ -f "secrets/mysql_user" ] && [ -f "secrets/mysql_password" ]; then
    echo -e "User: ${YELLOW}$(cat secrets/mysql_user)${NC}"
    echo -e "Password: ${YELLOW}$(cat secrets/mysql_password)${NC}"
fi

echo ""
echo -e "${CYAN}=== WordPress Admin ===${NC}"
if [ -f "secrets/wp_admin_user" ] && [ -f "secrets/wp_adminpassword" ]; then
    echo -e "Username: ${YELLOW}$(cat secrets/wp_admin_user)${NC}"
    echo -e "Password: ${YELLOW}$(cat secrets/wp_adminpassword)${NC}"
    echo -e "Email: ${YELLOW}$(cat secrets/wp_admin_mail)${NC}"
fi

echo ""
echo -e "${CYAN}=== WordPress User ===${NC}"
echo -e "Username: ${YELLOW}${WP_USER}${NC}"
echo -e "Password: ${YELLOW}${WP_USER_PASSWORD}${NC}"
echo -e "Email: ${YELLOW}${WP_USER_EMAIL}${NC}"

echo ""
echo -e "${GREEN}URLs:${NC}"
echo -e "  Site: https://${DOMAIN_NAME}"
echo -e "  Admin: https://${DOMAIN_NAME}/wp-admin"
