#!/bin/bash
set -e

echo "Starting QWC QGIS Server with Cloud Storage FUSE..."

# Get project name from environment or metadata
if [ -z "$GCS_PROJECT_NAME" ]; then
    # Try to get from GCP metadata server
    GCS_PROJECT_NAME=$(curl -s "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google" || echo "")
fi

if [ -z "$GCS_PROJECT_NAME" ]; then
    echo "ERROR: GCS_PROJECT_NAME environment variable is not set and could not be retrieved from metadata"
    echo "Please set GCS_PROJECT_NAME to your GCP project name"
    exit 1
fi

echo "Using GCS project: $GCS_PROJECT_NAME"

# Bucket names
QGIS_RESOURCES_BUCKET="${GCS_QGIS_RESOURCES_BUCKET:-${GCS_PROJECT_NAME}-qgis-resources}"
PRINT_LAYOUTS_BUCKET="${GCS_PRINT_LAYOUTS_BUCKET:-${GCS_PROJECT_NAME}-print-layouts}"

echo "Mounting Cloud Storage buckets..."

# Mount QGIS resources bucket
if [ -n "$QGIS_RESOURCES_BUCKET" ]; then
    echo "Mounting QGIS resources from gs://$QGIS_RESOURCES_BUCKET to /data"
    gcsfuse --implicit-dirs --file-mode=444 --dir-mode=555 "$QGIS_RESOURCES_BUCKET" /data
    if [ $? -eq 0 ]; then
        echo "Successfully mounted QGIS resources"
    else
        echo "WARNING: Failed to mount QGIS resources bucket"
    fi
fi

# Mount print layouts bucket
if [ -n "$PRINT_LAYOUTS_BUCKET" ]; then
    echo "Mounting print layouts from gs://$PRINT_LAYOUTS_BUCKET to /layouts"
    gcsfuse --implicit-dirs --file-mode=444 --dir-mode=555 "$PRINT_LAYOUTS_BUCKET" /layouts
    if [ $? -eq 0 ]; then
        echo "Successfully mounted print layouts"
    else
        echo "WARNING: Failed to mount print layouts bucket"
    fi
fi

echo "Cloud Storage buckets mounted successfully !"

# List mounted directories for verification
echo "Contents of /data:"
ls -la /data || echo "  (empty or not accessible)"

echo "Contents of /layouts:"
ls -la /layouts || echo "  (empty or not accessible)"

# Find the original entrypoint or start command
# The qwc-qgis-server image typically uses Apache/FastCGI
if [ -f /usr/local/bin/start-server.sh ]; then
    echo "Starting QGIS Server with start-server.sh..."
    exec /usr/local/bin/start-server.sh
elif [ -f /etc/apache2/envvars ]; then
    echo "Starting Apache with QGIS FastCGI..."
    source /etc/apache2/envvars
    exec apache2 -D FOREGROUND
else
    echo "ERROR: Could not find the original QGIS server startup script"
    echo "Available files in /usr/local/bin:"
    ls -la /usr/local/bin/ || true
    exit 1
fi
