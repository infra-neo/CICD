#!/bin/bash

# CI/CD Stack Health Check Script
# Validates that all services are running correctly

echo "================================================"
echo "     CI/CD Stack - Health Check                "
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check service health
check_service() {
    local service_name=$1
    local container_name=$2
    local port=$3
    local url=$4
    
    echo -n "Checking $service_name... "
    
    # Check if container is running
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo -e "${RED}❌ Container not running${NC}"
        return 1
    fi
    
    # Check if port is accessible
    if ! nc -z localhost $port 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Container running but port $port not accessible${NC}"
        return 1
    fi
    
    # Check HTTP endpoint if URL provided
    if [ -n "$url" ]; then
        if curl -sf "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Healthy${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  Port accessible but service not ready${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✅ Running${NC}"
        return 0
    fi
}

# Check Docker
echo "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker installed${NC}"
echo ""

# Check Docker Compose
echo "Checking Docker Compose..."
if ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker Compose installed${NC}"
echo ""

# Check system parameters
echo "Checking system parameters..."
current_max_map_count=$(sysctl -n vm.max_map_count)
if [ "$current_max_map_count" -lt 262144 ]; then
    echo -e "${YELLOW}⚠️  vm.max_map_count is $current_max_map_count (should be >= 262144)${NC}"
    echo "   Run: sudo sysctl -w vm.max_map_count=262144"
else
    echo -e "${GREEN}✅ vm.max_map_count is correct ($current_max_map_count)${NC}"
fi
echo ""

# Check services
echo "Checking services..."
echo ""

check_service "PostgreSQL" "cicd-postgres" "5432" ""
check_service "SonarQube" "cicd-sonarqube" "9000" "http://localhost:9000"
check_service "Nexus" "cicd-nexus" "8081" "http://localhost:8081"
check_service "Jenkins" "cicd-jenkins" "8080" "http://localhost:8080"

echo ""
echo "================================================"
echo ""

# Check volumes
echo "Checking persistent volumes..."
volumes=(
    "cicd_postgres-data"
    "cicd_sonarqube-data"
    "cicd_nexus-data"
    "cicd_jenkins-data"
    "cicd_maven-cache"
)

for volume in "${volumes[@]}"; do
    if docker volume ls --format '{{.Name}}' | grep -q "^${volume}$"; then
        echo -e "  ${GREEN}✅${NC} $volume"
    else
        echo -e "  ${RED}❌${NC} $volume (not found)"
    fi
done

echo ""
echo "================================================"
echo ""

# Container stats
echo "Container resource usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" \
    cicd-jenkins cicd-sonarqube cicd-nexus cicd-postgres 2>/dev/null || echo "Unable to get container stats"

echo ""
echo "================================================"
echo ""

# Show logs command
echo "To view logs:"
echo "  All services:      docker compose logs -f"
echo "  Jenkins only:      docker compose logs -f jenkins"
echo "  SonarQube only:    docker compose logs -f sonarqube"
echo "  Nexus only:        docker compose logs -f nexus"
echo ""

# Access URLs
echo "Access URLs:"
echo "  Jenkins:    http://localhost:8080 (admin/admin123)"
echo "  SonarQube:  http://localhost:9000 (admin/admin)"
echo "  Nexus:      http://localhost:8081 (admin/see README)"
echo ""
