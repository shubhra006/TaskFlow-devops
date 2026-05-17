#!/bin/bash
set -e   # Stop immediately if any command fails

APP_DIR="/home/ubuntu/TaskFlow-devops"
echo "Starting deployment..."
cd "$APP_DIR"

echo "Pulling latest code from GitHub..."
git pull origin main

echo "Building Docker images..."
docker compose build --no-cache

echo "Restarting containers..."
docker compose down
docker compose up -d

echo "Waiting 20s for services to start..."
sleep 20

echo "Running health check..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health)
if [ "$STATUS" = "200" ]; then
    echo "Deployment successful!"
else
    echo "Health check FAILED — HTTP $STATUS"
    docker compose logs --tail=30
    exit 1
fi

docker compose ps