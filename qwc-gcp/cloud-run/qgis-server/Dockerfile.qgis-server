FROM sourcepole/qwc-qgis-server:3.40

USER root

# Install dependencies for gcsfuse
RUN mkdir -p /var/lib/apt/lists/partial && \
    apt-get update && \
    apt-get install -y gnupg lsb-release wget curl ca-certificates && \
    # Add gcsfuse repository using the new method (signed-by)
    export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s` && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt $GCSFUSE_REPO main" | tee /etc/apt/sources.list.d/gcsfuse.list && \
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    apt-get update && \
    apt-get install -y gcsfuse && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create mount points
RUN mkdir -p /data /layouts

# Copy custom entrypoint script
COPY docker-entrypoint-qgis.sh /docker-entrypoint-qgis.sh
RUN chmod +x /docker-entrypoint-qgis.sh

ENTRYPOINT ["/docker-entrypoint-qgis.sh"]
