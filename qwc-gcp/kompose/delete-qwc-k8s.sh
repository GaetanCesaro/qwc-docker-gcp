# Shared ConfigMaps
kubectl delete -f atlas-qwc-db-config-configmap.yaml
kubectl delete -f atlas-qwc-folder-config-configmap.yaml
kubectl delete -f atlas-qwc-print-layouts-config-configmap.yaml
kubectl delete -f atlas-qwc-qgis-ressources-config-configmap.yaml
kubectl delete -f atlas-qwc-report-config-configmap.yaml

# Persistent Volume Claims
kubectl delete -f atlas-qwc-volume-read-only-many-persistentvolumeclaim.yaml
kubectl delete -f atlas-qwc-volume-read-write-once-persistentvolumeclaim.yaml

# Postgis Database
kubectl delete -f atlas-qwc-postgis-demo-data-config-configmap.yaml
kubectl delete -f qwc-postgis-deployment.yaml
kubectl delete -f qwc-postgis-service.yaml

# Config DB migration
kubectl delete -f atlas-qwc-config-db-migrate-demo-data-config-configmap.yaml
kubectl delete -f qwc-config-db-migrate-deployment.yaml

# QGIS Server
kubectl delete -f qwc-qgis-server-deployment.yaml

# Config Service
kubectl delete -f atlas-qwc-folder-config-out-configmap.yaml
kubectl delete -f qwc-config-service-deployment.yaml

# Admin GUI
kubectl delete -f qwc-admin-gui-deployment.yaml

# Auth Service
kubectl delete -f qwc-auth-service-deployment.yaml

# Data Service
kubectl delete -f atlas-qwc-folder-attachments-configmap.yaml
kubectl delete -f qwc-data-service-deployment.yaml

# Document Service
kubectl delete -f qwc-document-service-deployment.yaml

# Elevation Service
kubectl delete -f qwc-elevation-service-deployment.yaml

# Feature info Service
kubectl delete -f qwc-feature-info-service-deployment.yaml

# Fulltext Service
kubectl delete -f qwc-fulltext-service-deployment.yaml

# Solr Service
kubectl delete -f atlas-qwc-solr-config-configmap.yaml
kubectl delete -f qwc-solr-deployment.yaml
kubectl delete -f qwc-solr-service.yaml

# Legend Service
kubectl delete -f qwc-legend-service-deployment.yaml

# Mapinfo Service
kubectl delete -f qwc-mapinfo-service-deployment.yaml

# QWC Map Viewer
kubectl delete -f atlas-qwc-map-viewer-config-configmap.yaml
kubectl delete -f qwc-map-viewer-deployment.yaml

# OGC Service
kubectl delete -f qwc-ogc-service-deployment.yaml

# Permalink Service
kubectl delete -f qwc-permalink-service-deployment.yaml

# Print Service
kubectl delete -f qwc-print-service-deployment.yaml

# API Gateway
kubectl delete -f atlas-qwc-api-gateway-config-configmap.yaml
kubectl delete -f qwc-api-gateway-deployment.yaml
kubectl delete -f qwc-api-gateway-service.yaml