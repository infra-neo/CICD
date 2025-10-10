#!/bin/bash

# CI/CD Stack Startup Script
# This script configures the system and starts the CI/CD stack

set -e

echo "================================================"
echo "   CI/CD Stack - Setup and Startup Script      "
echo "================================================"
echo ""

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  This script needs sudo privileges for system configuration."
    echo "   Re-running with sudo..."
    sudo bash "$0" "$@"
    exit $?
fi

echo "Step 1: Configuring system parameters for SonarQube..."
echo "   Setting vm.max_map_count=262144"
sysctl -w vm.max_map_count=262144

echo "   Setting fs.file-max=65536"
sysctl -w fs.file-max=65536

echo "   Making changes persistent..."
if ! grep -q "vm.max_map_count" /etc/sysctl.conf; then
    echo "vm.max_map_count=262144" >> /etc/sysctl.conf
fi

if ! grep -q "fs.file-max" /etc/sysctl.conf; then
    echo "fs.file-max=65536" >> /etc/sysctl.conf
fi

echo "✅ System parameters configured"
echo ""

echo "Step 2: Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed!"
    echo "   Please install Docker first using:"
    echo "   curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "   sudo sh get-docker.sh"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose plugin is not installed!"
    echo "   Please install Docker Compose plugin"
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"
echo ""

echo "Step 3: Building and starting services..."
echo "   This may take several minutes on first run..."
echo ""

# Switch to the directory containing docker-compose.yml
cd "$(dirname "$0")"

# Build and start services
docker compose up -d --build

echo ""
echo "✅ Services started successfully"
echo ""

echo "Step 4: Waiting for services to be ready..."
echo "   Jenkins: http://localhost:8080"
echo "   SonarQube: http://localhost:9000"
echo "   Nexus: http://localhost:8081"
echo ""

echo "⏳ Waiting for Jenkins (this may take 2-3 minutes)..."
timeout=180
elapsed=0
while ! docker exec cicd-jenkins curl -s http://localhost:8080 > /dev/null 2>&1; do
    if [ $elapsed -ge $timeout ]; then
        echo "⚠️  Timeout waiting for Jenkins"
        break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
    echo "   Still waiting... (${elapsed}s)"
done

echo ""
echo "================================================"
echo "            CI/CD Stack is Starting             "
echo "================================================"
echo ""
echo "📋 Access Information:"
echo ""
echo "Jenkins:    http://localhost:8080"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "SonarQube:  http://localhost:9000"
echo "  Username: admin"
echo "  Password: admin (change on first login)"
echo ""
echo "Nexus:      http://localhost:8081"
echo "  Username: admin"
echo "  Password: Run this command to get it:"
echo "  docker exec cicd-nexus cat /nexus-data/admin.password"
echo ""
echo "================================================"
echo ""
echo "📝 Next Steps:"
echo "1. Wait 5-10 minutes for all services to fully initialize"
echo "2. Access each service and complete initial setup"
echo "3. Configure credentials in Jenkins (see README.md)"
echo "4. Create your first pipeline using example-app/Jenkinsfile"
echo ""
echo "📚 For detailed instructions, see README.md"
echo ""
echo "To view logs: docker compose logs -f"
echo "To stop:      docker compose stop"
echo "To restart:   docker compose restart"
echo ""
