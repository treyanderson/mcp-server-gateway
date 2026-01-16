#!/bin/bash

# MCP Gateway Docker Runner
# This script runs the MCP gateway in a Docker container with proper stdio handling

set -e

CONTAINER_NAME="mcp-gateway"
IMAGE_NAME="mcp-gateway:latest"

echo "🐳 Starting MCP Gateway in Docker..."

# Build the image if it doesn't exist
if ! docker images | grep -q "^mcp-gateway"; then
    echo "📦 Building Docker image..."
    docker build -t $IMAGE_NAME .
fi

# Stop and remove existing container if running
if docker ps -a | grep -q $CONTAINER_NAME; then
    echo "🛑 Stopping existing container..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
fi

# Run the container with stdio (interactive mode)
echo "🚀 Starting MCP Gateway container..."
docker run -it \
    --name $CONTAINER_NAME \
    --rm \
    -v "$(pwd)/.env:/app/.env:ro" \
    -v "$(pwd)/config.json:/app/config.json:ro" \
    $IMAGE_NAME

# Note: For Claude Desktop integration, you'll configure the MCP server to use:
# "command": "docker",
# "args": ["run", "-i", "--rm", "-v", "$(pwd)/.env:/app/.env:ro", "mcp-gateway:latest"]
