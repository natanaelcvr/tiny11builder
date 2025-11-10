#!/bin/bash
# Script to build and run the Red Hat UBI 9 container with PowerShell

set -e

CONTAINER_NAME="ubi9-powershell"
IMAGE_NAME="ubi9-powershell:latest"

echo "🔨 Building container image..."
podman build -f Dockerfile.ubi9-powershell -t $IMAGE_NAME .

echo ""
echo "✅ Image built successfully!"
echo ""
echo "🚀 Running container..."
podman run -it --rm --name $CONTAINER_NAME $IMAGE_NAME

# Alternative: To keep the container running in the background:
# podman run -d --name $CONTAINER_NAME $IMAGE_NAME sleep infinity
# podman exec -it $CONTAINER_NAME pwsh

