#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for passed/failed tests
PASSED=0
FAILED=0

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $2${NC}"
        ((FAILED++))
    fi
}

echo "================================================"
echo "       INCEPTION PROJECT VERIFICATION SCRIPT     "
echo "================================================"
echo ""

# 1. Check for srcs folder
echo -e "${YELLOW}1. Checking project structure...${NC}"
if [ -d "srcs" ]; then
    print_result 0 "srcs folder exists"
else
    print_result 1 "srcs folder missing"
fi

# 2. Check for Makefile
if [ -f "Makefile" ]; then
    print_result 0 "Makefile exists"
else
    print_result 1 "Makefile missing"
fi

# 3. Check docker-compose.yml
echo -e "\n${YELLOW}2. Checking docker-compose.yml...${NC}"
if [ -f "srcs/docker-compose.yml" ]; then
    print_result 0 "docker-compose.yml exists"
    
    # Check for forbidden configurations
    if grep -q "network: host" srcs/docker-compose.yml; then
        print_result 1 "Found 'network: host' (FORBIDDEN)"
    else
        print_result 0 "No 'network: host' found"
    fi
    
    if grep -q "links:" srcs/docker-compose.yml; then
        print_result 1 "Found 'links:' (FORBIDDEN)"
    else
        print_result 0 "No 'links:' found"
    fi
    
    if grep -q "networks:" srcs/docker-compose.yml; then
        print_result 0 "Networks defined"
    else
        print_result 1 "No networks defined"
    fi
else
    print_result 1 "docker-compose.yml missing"
fi

# 4. Check for .env file
echo -e "\n${YELLOW}3. Checking environment variables...${NC}"
if [ -f "srcs/.env" ]; then
    print_result 0 ".env file exists"
else
    print_result 1 ".env file missing"
fi

# Check for exposed credentials in common files
CRED_FOUND=0
for file in $(find . -name "*.yml" -o -name "*.yaml" -o -name "*.sh" -o -name "Dockerfile*" | grep -v ".env"); do
    if grep -E "(PASSWORD|SECRET|KEY)=" "$file" 2>/dev/null | grep -v "ARG\|ENV" > /dev/null; then
        CRED_FOUND=1
        echo -e "${RED}  Warning: Possible credential in $file${NC}"
    fi
done
if [ $CRED_FOUND -eq 0 ]; then
    print_result 0 "No exposed credentials found"
else
    print_result 1 "Possible exposed credentials found"
fi

# 5. Check Dockerfiles
echo -e "\n${YELLOW}4. Checking Dockerfiles...${NC}"
DOCKERFILES=$(find srcs -name "Dockerfile*" -type f)
DOCKERFILE_COUNT=$(echo "$DOCKERFILES" | wc -l)

if [ $DOCKERFILE_COUNT -ge 3 ]; then
    print_result 0 "Found $DOCKERFILE_COUNT Dockerfiles"
else
    print_result 1 "Insufficient Dockerfiles (found $DOCKERFILE_COUNT, need at least 3)"
fi

# Check each Dockerfile
for dockerfile in $DOCKERFILES; do
    echo -e "\n  Checking $dockerfile:"
    
    # Check if empty
    if [ ! -s "$dockerfile" ]; then
        print_result 1 "  $dockerfile is empty"
        continue
    fi
    
    # Check FROM statement
    if grep -E "^FROM (alpine:[0-9]+\.[0-9]+|debian:[a-z]+)" "$dockerfile" > /dev/null; then
        print_result 0 "  Valid FROM statement"
    else
        print_result 1 "  Invalid or missing FROM statement"
    fi
    
    # Check for forbidden commands
    if grep -E "tail -f|sleep infinity" "$dockerfile" > /dev/null; then
        print_result 1 "  Contains forbidden infinite loop commands"
    else
        print_result 0 "  No infinite loops found"
    fi
done

# 7. Test if services are running (if docker compose is up)
echo -e "\n${YELLOW}6. Checking running services...${NC}"
if command -v docker &> /dev/null; then
    RUNNING=$(docker compose ps --services 2>/dev/null | wc -l)
    if [ $RUNNING -gt 0 ]; then
        echo "  Found $RUNNING running services:"
        docker compose ps
        
        # Check NGINX SSL
        echo -e "\n${YELLOW}7. Checking NGINX SSL/TLS...${NC}"
        if docker compose ps | grep -q nginx; then
            # Test HTTPS
            if curl -k -s -o /dev/null -w "%{http_code}" https://localhost 2>/dev/null | grep -q "200\|301\|302"; then
                print_result 0 "HTTPS (443) accessible"
            else
                print_result 1 "HTTPS (443) not accessible"
            fi
            
            # Test HTTP (should fail)
            if curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null | grep -q "200"; then
                print_result 1 "HTTP (80) accessible (should be blocked)"
            else
                print_result 0 "HTTP (80) properly blocked"
            fi
            
            # Check TLS version
            TLS_INFO=$(echo | openssl s_client -connect localhost:443 2>/dev/null | grep "Protocol")
            if echo "$TLS_INFO" | grep -E "TLSv1.[23]" > /dev/null; then
                print_result 0 "TLS v1.2/1.3 detected: $TLS_INFO"
            else
                print_result 1 "Invalid TLS version"
            fi
        fi
        
        # Check Docker networks
        echo -e "\n${YELLOW}8. Checking Docker networks...${NC}"
        NETWORK_COUNT=$(docker network ls --format "{{.Name}}" | grep -v "bridge\|host\|none" | wc -l)
        if [ $NETWORK_COUNT -gt 0 ]; then
            print_result 0 "Custom Docker networks found: $NETWORK_COUNT"
        else
            print_result 1 "No custom Docker networks found"
        fi
        
        # Check volumes
        echo -e "\n${YELLOW}9. Checking Docker volumes...${NC}"
        VOLUME_COUNT=$(docker volume ls -q | wc -l)
        if [ $VOLUME_COUNT -ge 2 ]; then
            print_result 0 "Docker volumes found: $VOLUME_COUNT"
            # Check volume paths
            for vol in $(docker volume ls -q); do
                MOUNT=$(docker volume inspect $vol --format '{{.Mountpoint}}' 2>/dev/null)
                echo "    Volume $vol mounted at: $MOUNT"
            done
        else
            print_result 1 "Insufficient Docker volumes (found $VOLUME_COUNT, need at least 2)"
        fi
    else
        echo "  No services running. Run 'make' or 'docker compose up' first for complete testing."
    fi
else
    echo "  Docker not installed or not running"
fi

# Final summary
echo -e "\n================================================"
echo -e "${YELLOW}SUMMARY:${NC}"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All automated tests passed! 🎉${NC}"
    echo "Remember to manually verify:"
    echo "- WordPress installation and admin access"
    echo "- MariaDB database content"
    echo "- Persistence after reboot"
else
    echo -e "\n${RED}Some tests failed. Please fix the issues above.${NC}"
fi

echo "================================================"


echo "=== SSL/TLS Certificate Check ==="
echo | openssl s_client -connect localhost:443 -servername login.42.fr 2>/dev/null | \
awk '
/Certificate chain/ {cert=1}
/^---/ {cert=0}
cert {print}
/Protocol  :/ {print}
/Cipher    :/ {print}
'

echo "================================================"
