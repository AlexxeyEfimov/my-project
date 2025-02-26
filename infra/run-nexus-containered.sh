#!/bin/bash

# Variables
CONTAINER_NAME="nexus"
NEXUS_PORT="8081"
DATA_DIR="/nexus-data"
IMAGE_NAME="sonatype/nexus3"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Create the Nexus data directory if it doesn't exist
if [ ! -d "$DATA_DIR" ]; then
    echo "Creating Nexus data directory: $DATA_DIR"
    sudo mkdir -p "$DATA_DIR"
    sudo chown -R 200:200 "$DATA_DIR"
fi

# Check if a container with the name "nexus" already exists
if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    echo "A container with the name $CONTAINER_NAME already exists."
    echo "Do you want to remove it and start a new one? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Stopping and removing the container $CONTAINER_NAME..."
        docker stop "$CONTAINER_NAME" && docker rm "$CONTAINER_NAME"
    else
        echo "Startup canceled."
        exit 0
    fi
fi

# Run the Nexus container
echo "Starting Nexus 3 in Docker..."
docker run -d \
    --name "$CONTAINER_NAME" \
    -p "$NEXUS_PORT:8081" \
    -v "$DATA_DIR:/nexus-data" \
    --restart unless-stopped \
    "$IMAGE_NAME"

# Check the container status
if docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    echo "Nexus 3 started successfully!"
    echo "Access it at: http://localhost:$NEXUS_PORT"
    echo "To get the admin password, run:"
    echo "docker exec -it $CONTAINER_NAME cat /nexus-data/admin.password"
else
    echo "Failed to start Nexus. Check the logs with:"
    echo "docker logs $CONTAINER_NAME"
fi