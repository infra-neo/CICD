#!/bin/bash

set -e

echo "========================================="
echo "CI/CD Environment Validation Script"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test results
test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Determine docker compose command
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo "Step 1: Checking if Docker services are running..."
echo ""

# Test 1: Jenkins container
docker ps | grep -q jenkins
test_result $? "Jenkins container is running"

# Test 2: SonarQube container
docker ps | grep -q sonarqube
test_result $? "SonarQube container is running"

# Test 3: Nexus container
docker ps | grep -q nexus
test_result $? "Nexus container is running"

# Test 4: PostgreSQL container
docker ps | grep -q postgres
test_result $? "PostgreSQL container is running"

echo ""
echo "Step 2: Checking network connectivity..."
echo ""

# Test 5: Jenkins to SonarQube
docker exec jenkins curl -sf http://sonarqube:9000 > /dev/null 2>&1
test_result $? "Jenkins can reach SonarQube"

# Test 6: Jenkins to Nexus
docker exec jenkins curl -sf http://nexus:8081 > /dev/null 2>&1
test_result $? "Jenkins can reach Nexus"

echo ""
echo "Step 3: Checking external accessibility..."
echo ""

# Test 7: Jenkins HTTP
curl -sf http://localhost:8080 > /dev/null 2>&1
test_result $? "Jenkins is accessible on http://localhost:8080"

# Test 8: SonarQube HTTP
curl -sf http://localhost:9000 > /dev/null 2>&1
test_result $? "SonarQube is accessible on http://localhost:9000"

# Test 9: Nexus HTTP
curl -sf http://localhost:8081 > /dev/null 2>&1
test_result $? "Nexus is accessible on http://localhost:8081"

echo ""
echo "Step 4: Checking service health..."
echo ""

# Test 10: Jenkins system info
JENKINS_VERSION=$(docker exec jenkins java -jar /usr/share/jenkins/jenkins.war --version 2>/dev/null)
if [ ! -z "$JENKINS_VERSION" ]; then
    test_result 0 "Jenkins version: $JENKINS_VERSION"
else
    test_result 1 "Jenkins version check"
fi

# Test 11: PostgreSQL connection
docker exec postgres psql -U sonar -d sonarqube -c "SELECT 1;" > /dev/null 2>&1
test_result $? "PostgreSQL database connection"

# Test 12: SonarQube API
SONAR_STATUS=$(curl -sf http://localhost:9000/api/system/status 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
if [ "$SONAR_STATUS" = "UP" ]; then
    test_result 0 "SonarQube status: $SONAR_STATUS"
else
    test_result 1 "SonarQube status check (got: $SONAR_STATUS)"
fi

echo ""
echo "Step 5: Checking volumes..."
echo ""

# Test 13: Jenkins volume
docker volume inspect cicd_jenkins_home > /dev/null 2>&1
test_result $? "Jenkins data volume exists"

# Test 14: Nexus volume
docker volume inspect cicd_nexus_data > /dev/null 2>&1
test_result $? "Nexus data volume exists"

# Test 15: SonarQube volume
docker volume inspect cicd_sonarqube_data > /dev/null 2>&1
test_result $? "SonarQube data volume exists"

echo ""
echo "Step 6: Checking configuration files..."
echo ""

# Test 16: Groovy scripts
if [ -d "jenkins/init.groovy.d" ] && [ "$(ls -A jenkins/init.groovy.d/*.groovy 2>/dev/null | wc -l)" -gt 0 ]; then
    test_result 0 "Jenkins init.groovy.d scripts exist ($(ls jenkins/init.groovy.d/*.groovy | wc -l) files)"
else
    test_result 1 "Jenkins init.groovy.d scripts"
fi

# Test 17: docker-compose.yml
if [ -f "docker-compose.yml" ]; then
    $DOCKER_COMPOSE config > /dev/null 2>&1
    test_result $? "docker-compose.yml is valid"
else
    test_result 1 "docker-compose.yml exists"
fi

# Test 18: build-config.yml
if [ -f "build-config.yml" ]; then
    test_result 0 "build-config.yml exists"
else
    test_result 1 "build-config.yml exists"
fi

# Test 19: Jenkinsfile
if [ -f "Jenkinsfile" ]; then
    test_result 0 "Jenkinsfile exists"
else
    test_result 1 "Jenkinsfile exists"
fi

echo ""
echo "Step 7: Optional - Testing example project..."
echo ""

if [ -f "examples/pom.xml" ]; then
    test_result 0 "Example Maven project exists"
    
    # Test 20: Maven build (optional, only if Maven is installed)
    if command -v mvn &> /dev/null; then
        cd examples
        mvn clean test > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            test_result 0 "Example project builds successfully"
        else
            echo -e "${YELLOW}⚠ SKIP${NC}: Example project build (Maven test failed, but this is optional)"
        fi
        cd ..
    else
        echo -e "${YELLOW}⚠ SKIP${NC}: Example project build (Maven not installed locally)"
    fi
else
    test_result 1 "Example Maven project"
fi

echo ""
echo "========================================="
echo "Validation Summary"
echo "========================================="
echo ""
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "Your CI/CD environment is ready to use!"
    echo ""
    echo "Access URLs:"
    echo "  - Jenkins:   http://localhost:8080 (admin/admin)"
    echo "  - SonarQube: http://localhost:9000 (admin/admin)"
    echo "  - Nexus:     http://localhost:8081 (admin/[generated])"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some tests failed!${NC}"
    echo ""
    echo "Please check the errors above and refer to TROUBLESHOOTING.md"
    echo ""
    echo "Common fixes:"
    echo "  1. Wait a few more minutes for services to fully initialize"
    echo "  2. Check logs: docker compose logs <service-name>"
    echo "  3. Restart services: docker compose restart"
    echo "  4. Full reset: docker compose down -v && ./setup.sh"
    echo ""
    exit 1
fi
