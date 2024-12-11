#!/bin/bash

# Replace these with your values
DOCKER_USERNAME="gwwc"
REPOSITORY_NAME="postgres"
VERSION="1.0.0"

# Login to Docker Hub
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

# Setup buildx
docker buildx create --use

# Build and push base image (amd64)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --target base \
  -t $DOCKER_USERNAME/$REPOSITORY_NAME:15 \
  -t $DOCKER_USERNAME/$REPOSITORY_NAME:${VERSION}-15 \
  --push \
  .

# Build and push testing image (amd64)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --target testing \
  -t $DOCKER_USERNAME/$REPOSITORY_NAME:testing-15 \
  -t $DOCKER_USERNAME/$REPOSITORY_NAME:${VERSION}-testing-15 \
  --push \
  .