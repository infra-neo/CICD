#!/bin/bash

# CI/CD Stack Stop Script

echo "Stopping CI/CD Stack..."
docker compose stop

echo ""
echo "CI/CD Stack stopped successfully"
echo ""
echo "To start again: ./start.sh"
echo "To remove all data: docker compose down -v"
