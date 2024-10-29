#!/bin/bash

# Step 1: Stop the current `expertiza-e2480` container if it is running
if [ "$(docker inspect -f '{{.State.Running}}' expertiza-e2480 2>/dev/null)" == "true" ]; then
echo "Stopping expertiza-e2480 container..."
docker stop expertiza-e2480
fi

CONTAINER_NAME="expertiza-e2480-app-1"

# Step 2: Rebuild and start all containers
# Note: The `--build` flag is used to ensure new changes are applied
echo "Rebuilding $CONTAINER_NAME container..."
docker compose up -d --build

# Step 3: Wait for theh container to start
echo "Waiting for $CONTAINER_NAME container to start..."

# Loop until the container is running
until [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null)" == "true" ]; do
  sleep 2
done

echo "$CONTAINER_NAME container is now running."

# Step 4: Run RSpec tests targeting bookmark-related specs
echo "Running RSpec tests for bookmarks in $CONTAINER_NAME container..."
docker exec -it "$CONTAINER_NAME" rspec --pattern "./spec/**/*bookmark*.rb"

# Step 5. Stop the current `expertiza-e2480` container
echo "Stopping expertiza-e2480 container..."
docker stop expertiza-e2480

echo "Testing complete."
