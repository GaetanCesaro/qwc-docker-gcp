# Image Docker qwc-config-service pour Cloud Run

Cette image Docker personnalisée étend l'image officielle `sourcepole/qwc-config-generator:latest-2025-lts` avec le support de Cloud Storage FUSE pour monter des buckets GCS comme des volumes.

## Fonctionnalités

- ✅ Basée sur l'image officielle QWC Config Generator
- ✅ Support de Cloud Storage FUSE (gcsfuse)
- ✅ Montage automatique des buckets GCS au démarrage
- ✅ Configuration via variables d'environnement
- ✅ Optimisée pour Cloud Run

## Structure

```
qwc-config-service/
├── Dockerfile              # Définition de l'image
├── startup.sh             # Script de démarrage avec montage GCS
├── build-config-service.sh # Script de build et push
└── README.md              # Cette documentation
```

## Construction de l'image

### Prérequis en local pour builder et déployer

- Docker installé
- gcloud CLI configuré avec les droits sur le projet GCP
- Authentification Docker pour GCR :
  ```bash
  gcloud auth configure-docker
  ```

### Build et Push

```bash
# Utiliser le script automatique
./build-config-service.sh <project-id> <env>

# Exemple
./build-config-service.sh atlas-qwc-poc poc
```

Ou manuellement :

```bash
export PROJECT_ID="atlas-qwc-poc"
export ENV="poc"

docker build -t gcr.io/${PROJECT_ID}/qwc-config-service:${ENV} .
docker push gcr.io/${PROJECT_ID}/qwc-config-service:${ENV}
```

## Variables d'environnement

L'image utilise les variables d'environnement suivantes pour configurer les montages GCS :

| Variable | Description |
|----------|-------------|
| `GCS_CONFIG_IN_BUCKET` | Bucket pour config-in (lecture seule) |
| `GCS_CONFIG_BUCKET` | Bucket pour config (lecture/écriture) |
| `GCS_QWC2_BUCKET` | Bucket pour qwc2 assets (lecture seule) |
| `GCS_QGIS_RESOURCES_BUCKET` | Bucket pour ressources QGIS (lecture seule) |
| `GCS_PRINT_LAYOUTS_BUCKET` | Bucket pour layouts d'impression (lecture seule) |
| `GCS_REPORTS_BUCKET` | Bucket pour rapports (lecture seule) |

Les autres variables d'environnement de l'image de base QWC sont également supportées.

## Points de montage

Les buckets GCS sont montés aux emplacements suivants :

| Bucket | Point de montage | Mode |
|--------|-----------------|------|
| `GCS_CONFIG_IN_BUCKET` | `/srv/qwc_service/config-in` | Lecture seule |
| `GCS_CONFIG_BUCKET` | `/srv/qwc_service/config-out` | Lecture/Écriture |
| `GCS_QWC2_BUCKET` | `/qwc2` | Lecture seule |
| `GCS_QGIS_RESOURCES_BUCKET` | `/data` | Lecture seule |
| `GCS_PRINT_LAYOUTS_BUCKET` | `/layouts` | Lecture seule |
| `GCS_REPORTS_BUCKET` | `/reports` | Lecture seule |

## Fonctionnement

### Au démarrage

1. Le script `startup.sh` crée les répertoires de montage
2. Pour chaque variable `GCS_*_BUCKET` définie, gcsfuse monte le bucket correspondant
3. Les buckets en lecture seule sont montés avec `--file-mode=0444 --dir-mode=0555`
4. Le service attend 10 secondes pour que tous les montages soient prêts
5. Le service vérifie que les montages gcsfuse sont OK
6. L'application QWC Config Service démarre

### Logs attendu si tout est OK

```
Starting qwc-config-service with Cloud Storage FUSE support...
Creating mount directories...
Mounting GCS buckets...
Mounting config-in bucket: my-project-config-in
Mounting config bucket: my-project-config
Mounting qwc2 bucket: my-project-qwc2
Waiting for GCS mounts to be ready...
Checking mounts...
Starting QWC Config Service...
```

## TODO Test local

Pour tester l'image localement avec émulation GCS :

```bash
# Build l'image
docker build -t qwc-config-service-test .

# Créer des répertoires locaux pour simuler les buckets
mkdir -p test-volumes/{config-in,config,qwc2,data,layouts,reports}

# Run avec montage de volumes locaux
docker run -p 9090:9090 \
  -v $(pwd)/test-volumes/config-in:/srv/qwc_service/config-in:ro \
  -v $(pwd)/test-volumes/config:/srv/qwc_service/config-out \
  -v $(pwd)/test-volumes/qwc2:/qwc2:ro \
  -v $(pwd)/test-volumes/data:/data:ro \
  -v $(pwd)/test-volumes/layouts:/layouts:ro \
  -v $(pwd)/test-volumes/reports:/reports:ro \
  -e JWT_SECRET_KEY="test-secret-key" \
  qwc-config-service-test
```

## Troubleshooting

### L'image ne se build pas

1. Vérifier que Docker est en cours d'exécution
2. Vérifier que vous avez accès à l'image de base :
   ```bash
   docker pull sourcepole/qwc-config-generator:latest-2025-lts
   ```

### Le push vers GCR échoue

1. Vérifier l'authentification :
   ```bash
   gcloud auth list
   gcloud auth configure-docker
   ```

2. Vérifier les permissions sur le projet :
   ```bash
   gcloud projects get-iam-policy <project-id>
   ```

### Les montages GCS ne fonctionnent pas

1. **Vérifier les permissions du service account** :
   - Le service account doit avoir `roles/storage.objectViewer` sur les buckets

2. **Vérifier les logs Cloud Run** :
   ```bash
   gcloud run services logs read qwc-config-service-dev --region=europe-west1
   ```

3. **Vérifier que les buckets existent** :
   ```bash
   gsutil ls -p <project-id>
   ```

### Performance lente

Cloud Storage FUSE peut avoir une latence plus élevée que le stockage local. Pour améliorer les performances :

1. **Activer le cache** (optionnel dans startup.sh) :
   ```bash
   gcsfuse --stat-cache-ttl=60s --type-cache-ttl=60s ...
   ```

2. **Utiliser des instances avec plus de CPU** dans la config Terraform

3. **Considérer l'utilisation de Persistent Disks** pour les données fréquemment accédées

## Maintenance

### Mise à jour de l'image de base

Lorsque Sourcepole publie une nouvelle version :

```bash
# Pull la nouvelle image de base
docker pull sourcepole/qwc-config-generator:latest-2025-lts

# Rebuild et push
./build-config-service.sh <project-id> <env>

# Redéployer via Terraform
cd ../../terraform
terraform apply
```

## Sécurité

### Bonnes pratiques

1. **Ne jamais inclure de secrets dans l'image**
   - Utiliser Secret Manager pour les secrets
   - Passer les secrets via variables d'environnement

2. **Utiliser des images taggées**
   - Éviter `:latest` en production
   - Utiliser des tags versionnés (`v1.0.0`)

3. **Scanner les vulnérabilités**
   ```bash
   gcloud container images scan gcr.io/${PROJECT_ID}/qwc-config-service:${ENV}
   ```

4. **Limiter les permissions**
   - Le service account ne doit avoir que les permissions nécessaires
   - Utiliser le principe du moindre privilège

## Ressources

- [QWC2 Documentation](https://github.com/qgis/qwc2)
- [Cloud Storage FUSE](https://cloud.google.com/storage/docs/gcs-fuse)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Container Registry](https://cloud.google.com/container-registry)
