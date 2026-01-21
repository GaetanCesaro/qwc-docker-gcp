#!/bin/bash
set -e

# Créer les répertoires de montage
echo "Creating mount directories..."
mkdir -p /srv/qwc_service/config-in
mkdir -p /srv/qwc_service/config-out
mkdir -p /qwc2
mkdir -p /data
mkdir -p /layouts
mkdir -p /reports

# Monter les buckets GCS si les variables d'environnement sont définies
echo "Mounting GCS buckets..."
if [ -n "$GCS_CONFIG_IN_BUCKET" ]; then
    echo "Mounting config-in bucket: $GCS_CONFIG_IN_BUCKET"
    gcsfuse --implicit-dirs --file-mode=0444 --dir-mode=0555 "$GCS_CONFIG_IN_BUCKET" /srv/qwc_service/config-in &
fi
if [ -n "$GCS_CONFIG_BUCKET" ]; then
    echo "Mounting config bucket: $GCS_CONFIG_BUCKET"
    gcsfuse --implicit-dirs "$GCS_CONFIG_BUCKET" /srv/qwc_service/config-out &
fi
if [ -n "$GCS_QWC2_BUCKET" ]; then
    echo "Mounting qwc2 bucket: $GCS_QWC2_BUCKET"
    gcsfuse --implicit-dirs --file-mode=0444 --dir-mode=0555 "$GCS_QWC2_BUCKET" /qwc2 &
fi
if [ -n "$GCS_QGIS_RESOURCES_BUCKET" ]; then
    echo "Mounting QGIS resources bucket: $GCS_QGIS_RESOURCES_BUCKET"
    gcsfuse --implicit-dirs --file-mode=0444 --dir-mode=0555 "$GCS_QGIS_RESOURCES_BUCKET" /data &
fi
if [ -n "$GCS_PRINT_LAYOUTS_BUCKET" ]; then
    echo "Mounting print layouts bucket: $GCS_PRINT_LAYOUTS_BUCKET"
    gcsfuse --implicit-dirs --file-mode=0444 --dir-mode=0555 "$GCS_PRINT_LAYOUTS_BUCKET" /layouts &
fi
if [ -n "$GCS_REPORTS_BUCKET" ]; then
    echo "Mounting reports bucket: $GCS_REPORTS_BUCKET"
    gcsfuse --implicit-dirs --file-mode=0444 --dir-mode=0555 "$GCS_REPORTS_BUCKET" /reports &
fi

# Attendre que tous les montages en arrière-plan soient prêts
echo "Waiting for GCS mounts to be ready..."
sleep 10

# Vérifier que les répertoires sont montés
echo "Checking mounts..."
if [ -n "$GCS_CONFIG_IN_BUCKET" ]; then
    ls -la /srv/qwc_service/config-in || echo "Warning: config-in mount may not be ready"
fi
if [ -n "$GCS_CONFIG_BUCKET" ]; then
    ls -la /srv/qwc_service/config-out || echo "Warning: config mount may not be ready"
fi
if [ -n "$GCS_QWC2_BUCKET" ]; then
    ls -la /qwc2 || echo "Warning: qwc2 mount may not be ready"
fi
if [ -n "$GCS_QGIS_RESOURCES_BUCKET" ]; then
    ls -la /data || echo "Warning: QGIS resources mount may not be ready"
fi
if [ -n "$GCS_PRINT_LAYOUTS_BUCKET" ]; then
    ls -la /layouts || echo "Warning: print layouts mount may not be ready"
fi
if [ -n "$GCS_REPORTS_BUCKET" ]; then
    ls -la /reports || echo "Warning: reports mount may not be ready"
fi

# TODO - Démarrer un service pour qwc-config-service ?