# kubectl get po -A
# minilube start
# minikube dashboard
# ... minikube stop

# Shared ConfigMaps
kubectl apply -f atlas-qwc-db-config-configmap.yaml -n default
kubectl apply -f atlas-qwc-folder-config-configmap.yaml -n default
kubectl apply -f atlas-qwc-print-layouts-config-configmap.yaml -n default
kubectl apply -f atlas-qwc-qgis-ressources-config-configmap.yaml -n default
kubectl apply -f atlas-qwc-report-config-configmap.yaml -n default

# Persistent Volume Claims
kubectl apply -f atlas-qwc-volume-read-only-many-persistentvolumeclaim.yaml -n default
kubectl apply -f atlas-qwc-volume-read-write-once-persistentvolumeclaim.yaml -n default

# Postgis Database
kubectl apply -f atlas-qwc-postgis-demo-data-config-configmap.yaml -n default
kubectl apply -f qwc-postgis-deployment.yaml -n default
kubectl apply -f qwc-postgis-service.yaml -n default

# Config DB migration
kubectl apply -f atlas-qwc-config-db-migrate-demo-data-config-configmap.yaml -n default
kubectl apply -f qwc-config-db-migrate-deployment.yaml -n default

# QGIS Server
kubectl apply -f qwc-qgis-server-deployment.yaml -n default

# Config Service
kubectl apply -f atlas-qwc-folder-config-out-configmap.yaml -n default
kubectl apply -f qwc-config-service-deployment.yaml -n default

# Admin GUI
kubectl apply -f qwc-admin-gui-deployment.yaml -n default

# Auth Service
kubectl apply -f qwc-auth-service-deployment.yaml -n default

# Data Service
kubectl apply -f atlas-qwc-folder-attachments-configmap.yaml -n default
kubectl apply -f qwc-data-service-deployment.yaml -n default

# Document Service
kubectl apply -f qwc-document-service-deployment.yaml -n default

# Elevation Service
kubectl apply -f qwc-elevation-service-deployment.yaml -n default

# Feature info Service
kubectl apply -f qwc-feature-info-service-deployment.yaml -n default

# Fulltext Service
kubectl apply -f qwc-fulltext-service-deployment.yaml -n default

# Solr Service
kubectl apply -f atlas-qwc-solr-config-configmap.yaml -n default
kubectl apply -f qwc-solr-deployment.yaml -n default
kubectl apply -f qwc-solr-service.yaml -n default

# Legend Service
kubectl apply -f qwc-legend-service-deployment.yaml -n default

# Mapinfo Service
kubectl apply -f qwc-mapinfo-service-deployment.yaml -n default

# QWC Map Viewer
kubectl apply -f atlas-qwc-map-viewer-config-configmap.yaml -n default
kubectl apply -f qwc-map-viewer-deployment.yaml -n default

# OGC Service
kubectl apply -f qwc-ogc-service-deployment.yaml -n default

# Permalink Service
kubectl apply -f qwc-permalink-service-deployment.yaml -n default

# Print Service
kubectl apply -f qwc-print-service-deployment.yaml -n default

# API Gateway
kubectl apply -f atlas-qwc-api-gateway-config-configmap.yaml -n default
kubectl apply -f qwc-api-gateway-deployment.yaml -n default
kubectl apply -f qwc-api-gateway-service.yaml -n default