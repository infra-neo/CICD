#!/bin/bash
# Script to upload and build source code from ZIP file
# Usage: ./upload-source.sh <path-to-zip> <environment> <target-server>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Source Code Upload and Build Script ===${NC}"
echo

# Validate arguments
if [ "$#" -lt 1 ]; then
    echo -e "${RED}Error: Missing required arguments${NC}"
    echo "Usage: $0 <path-to-zip> [environment] [target-server]"
    echo
    echo "Arguments:"
    echo "  path-to-zip    : Path to ZIP file containing source code"
    echo "  environment    : Target environment (dev|staging|prod) [default: dev]"
    echo "  target-server  : Target server (wildfly|jboss) [default: wildfly]"
    echo
    echo "Example:"
    echo "  $0 myapp-source.zip dev wildfly"
    exit 1
fi

ZIP_FILE=$1
ENVIRONMENT=${2:-dev}
TARGET_SERVER=${3:-wildfly}

# Validate ZIP file exists
if [ ! -f "$ZIP_FILE" ]; then
    echo -e "${RED}Error: ZIP file not found: $ZIP_FILE${NC}"
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo -e "${RED}Error: Invalid environment. Must be dev, staging, or prod${NC}"
    exit 1
fi

# Validate target server
if [[ ! "$TARGET_SERVER" =~ ^(wildfly|jboss)$ ]]; then
    echo -e "${RED}Error: Invalid target server. Must be wildfly or jboss${NC}"
    exit 1
fi

echo -e "${GREEN}Configuration:${NC}"
echo "  ZIP File: $ZIP_FILE"
echo "  Environment: $ENVIRONMENT"
echo "  Target Server: $TARGET_SERVER"
echo

# Create temporary directory
TEMP_DIR=$(mktemp -d)
echo -e "${YELLOW}Creating temporary directory: $TEMP_DIR${NC}"

# Extract ZIP file
echo -e "${YELLOW}Extracting source code...${NC}"
unzip -q "$ZIP_FILE" -d "$TEMP_DIR"

# Find pom.xml
POM_FILE=$(find "$TEMP_DIR" -name "pom.xml" | head -1)
if [ -z "$POM_FILE" ]; then
    echo -e "${RED}Error: No pom.xml found in ZIP file${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

PROJECT_DIR=$(dirname "$POM_FILE")
echo -e "${GREEN}Found project at: $PROJECT_DIR${NC}"

# Change to project directory
cd "$PROJECT_DIR"

# Load environment properties
ENV_PROPS="../config/environments/$ENVIRONMENT/application.properties"
if [ -f "$ENV_PROPS" ]; then
    echo -e "${GREEN}Loading environment properties from $ENV_PROPS${NC}"
    export $(grep -v '^#' "$ENV_PROPS" | xargs)
fi

# Create local Maven repository
M2_REPO="$PROJECT_DIR/.m2/repository-$ENVIRONMENT"
mkdir -p "$M2_REPO"
echo -e "${GREEN}Using Maven repository: $M2_REPO${NC}"

# Check for hardcoded passwords
echo -e "${YELLOW}Scanning for hardcoded passwords...${NC}"
if grep -r -i "password.*=.*['\"][^$]" src/ 2>/dev/null; then
    echo -e "${RED}ERROR: Hardcoded passwords detected!${NC}"
    echo -e "${RED}Please use environment variables for sensitive data${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi
echo -e "${GREEN}No hardcoded passwords found${NC}"

# Build the project
echo -e "${YELLOW}Building project with Maven...${NC}"
mvn clean install \
    -Dmaven.repo.local="$M2_REPO" \
    -Denvironment="$ENVIRONMENT" \
    -Dapp.version="${BUILD_NUMBER:-1.0.0}-$(date +%Y%m%d-%H%M%S)"

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed!${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Run tests
echo -e "${YELLOW}Running tests...${NC}"
mvn test -Dmaven.repo.local="$M2_REPO"

if [ $? -ne 0 ]; then
    echo -e "${RED}Tests failed!${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Find WAR file
WAR_FILE=$(find target -name "*.war" | head -1)
if [ -z "$WAR_FILE" ]; then
    echo -e "${RED}Error: No WAR file generated${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo -e "${GREEN}WAR file created: $WAR_FILE${NC}"

# Deploy to target server
echo -e "${YELLOW}Deploying to $TARGET_SERVER...${NC}"

if ! docker ps | grep -q "$TARGET_SERVER"; then
    echo -e "${RED}Error: $TARGET_SERVER container is not running${NC}"
    echo "Please start the CI/CD stack: ./setup.sh"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Copy WAR to server
docker cp "$WAR_FILE" "$TARGET_SERVER:/opt/jboss/wildfly/standalone/deployments/"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Deployment successful!${NC}"
    
    # Get server port
    if [ "$TARGET_SERVER" = "wildfly" ]; then
        PORT="8090"
    else
        PORT="8070"
    fi
    
    echo
    echo -e "${GREEN}=== Deployment Complete ===${NC}"
    echo "Application URL: http://localhost:$PORT/$(basename $WAR_FILE .war)/"
    echo "Server Admin: http://localhost:$((PORT + 1900))"
    echo
    echo "Monitoring deployment..."
    sleep 5
    
    # Check deployment status
    docker exec "$TARGET_SERVER" ls -la /opt/jboss/wildfly/standalone/deployments/
else
    echo -e "${RED}Deployment failed!${NC}"
fi

# Cleanup
echo -e "${YELLOW}Cleaning up temporary files...${NC}"
rm -rf "$TEMP_DIR"

echo -e "${GREEN}Done!${NC}"
