#!/bin/bash

# Script to build and push the custom QWC QGIS Server image with Cloud Storage FUSE support
# Usage: ./build-qgis-server.sh <project-id> [environment] [tag]

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <project-id> [environment] [tag]"
    echo "Example: $0 atlas-qwc-poc poc v1.0"
    exit 1
fi

PROJECT_ID=$1
ENVIRONMENT=${2:-"poc"}
TAG=${3:-"latest"}

# Image name in Google Container Registry
IMAGE_NAME="gcr.io/${PROJECT_ID}/qwc-qgis-server"
FULL_IMAGE_NAME="${IMAGE_NAME}:${TAG}"

# Also tag with environment
ENV_IMAGE_NAME="${IMAGE_NAME}:${ENVIRONMENT}"

echo "======================================"
echo "Building QWC QGIS Server Docker Image"
echo "======================================"
echo "Project ID: $PROJECT_ID"
echo "Environment: $ENVIRONMENT"
echo "Tag: $TAG"
echo "Image: $FULL_IMAGE_NAME"
echo "======================================"

# Change to the qwc-gcp directory
cd "$(dirname "$0")"

# Verify required files exist
if [ ! -f "Dockerfile.qgis-server" ]; then
    echo "ERROR: Dockerfile.qgis-server not found in current directory"
    exit 1
fi

if [ ! -f "docker-entrypoint-qgis.sh" ]; then
    echo "ERROR: docker-entrypoint-qgis.sh not found in current directory"
    exit 1
fi

# Ensure gcloud is authenticated
echo "Checking gcloud authentication..."
gcloud auth print-access-token > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: gcloud is not authenticated. Run: gcloud auth login"
    exit 1
fi

# Configure Docker to use gcloud as a credential helper
echo "Configuring Docker authentication for GCR..."
gcloud auth configure-docker --quiet

# Build the Docker image
echo ""
echo "Building Docker image..."
docker build -f Dockerfile.qgis-server -t "$FULL_IMAGE_NAME" .

if [ $? -ne 0 ]; then
    echo "ERROR: Docker build failed"
    exit 1
fi

echo ""
echo "Build successful!"

# Tag with environment
echo "Tagging image with environment: $ENV_IMAGE_NAME"
docker tag "$FULL_IMAGE_NAME" "$ENV_IMAGE_NAME"

# Push to Google Container Registry
echo ""
echo "Pushing image to Google Container Registry..."
docker push "$FULL_IMAGE_NAME"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to push image"
    exit 1
fi

# Push environment tag
echo "Pushing environment tag..."
docker push "$ENV_IMAGE_NAME"

echo ""
echo "======================================"
echo "✓ Image successfully built and pushed!"
echo "======================================"
echo "Image: $FULL_IMAGE_NAME"
echo "Environment tag: $ENV_IMAGE_NAME"
echo ""
echo "To use this image, update cloud-run.tf with:"
echo "  image = \"$FULL_IMAGE_NAME\""
echo ""
echo "Or run:"
echo "  terraform apply -var-file=\"${ENVIRONMENT}/${ENVIRONMENT}.tfvars\""
echo "======================================"
