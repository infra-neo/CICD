#!/bin/bash

set -e

echo "========================================="
echo "CI/CD Environment Setup Script"
echo "========================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "ERROR: Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Determine docker compose command
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo "Step 1: Stopping any existing containers..."
$DOCKER_COMPOSE down -v 2>/dev/null || true

echo ""
echo "Step 2: Starting services (this may take several minutes)..."
$DOCKER_COMPOSE up -d

echo ""
echo "Step 3: Waiting for services to be ready..."

# Wait for Jenkins
echo "  - Waiting for Jenkins..."
until curl -s http://localhost:8080 > /dev/null 2>&1; do
    sleep 5
done
echo "    Jenkins is up!"

# Wait for SonarQube
echo "  - Waiting for SonarQube..."
until curl -s http://localhost:9000 > /dev/null 2>&1; do
    sleep 5
done
echo "    SonarQube is up!"

# Wait for Nexus
echo "  - Waiting for Nexus..."
until curl -s http://localhost:8081 > /dev/null 2>&1; do
    sleep 5
done
echo "    Nexus is up!"

echo ""
echo "Step 4: Additional service configuration..."

# Wait a bit more for services to fully initialize
echo "  - Allowing services to fully initialize (60 seconds)..."
sleep 60

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Services are now running:"
echo "  - Jenkins:   http://localhost:8080"
echo "    Username: admin"
echo "    Password: admin"
echo ""
echo "  - SonarQube: http://localhost:9000"
echo "    Username: admin"
echo "    Password: admin"
echo ""
echo "  - Nexus:     http://localhost:8081"
echo "    Username: admin"
echo "    Password: Check container logs with:"
echo "              docker exec nexus cat /nexus-data/admin.password"
echo ""
echo "Network: cicd-network (bridge)"
echo ""
echo "To stop all services:"
echo "  $DOCKER_COMPOSE down"
echo ""
echo "To view logs:"
echo "  $DOCKER_COMPOSE logs -f [service-name]"
echo ""
echo "To restart all services:"
echo "  $DOCKER_COMPOSE restart"
echo ""
echo "========================================="
