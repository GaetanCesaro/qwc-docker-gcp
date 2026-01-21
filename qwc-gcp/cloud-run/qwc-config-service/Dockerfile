FROM sourcepole/qwc-config-generator:latest-2025-lts

# Installer Cloud Storage FUSE pour monter les buckets GCS
RUN apk update && apk add --no-cache ca-certificates git fuse go bash
RUN go install github.com/googlecloudplatform/gcsfuse/v2@v2.3.2
ENV GOPATH="/root/go"
RUN cp $GOPATH/bin/gcsfuse /usr/bin/gcsfuse

# Copier le script de démarrage
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Utiliser le script de démarrage comme entrypoint
ENTRYPOINT ["/entrypoint.sh"]

