#!/bin/bash

# Script pour build et push l'image qwc-config-service vers GCR
# Usage: ./build-config-service.sh <project-id> <env>

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <project-id> <env>"
    echo "Example: $0 my-gcp-project dev"
    exit 1
fi

PROJECT_ID=$1
ENV=$2
IMAGE_NAME="qwc-config-service"
TAG="${ENV}"
FULL_IMAGE="gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG}"

echo "Building Docker image: ${FULL_IMAGE}"

# Build l'image
docker build -t "${FULL_IMAGE}" .

echo "Pushing image to GCR..."

# Configure Docker pour utiliser gcloud comme credential helper
gcloud auth configure-docker

# Push l'image vers GCR
docker push "${FULL_IMAGE}"

echo "Image successfully pushed: ${FULL_IMAGE}"
echo ""
echo "You can now update your Terraform configuration to use this image:"
echo "  image = \"${FULL_IMAGE}\""
