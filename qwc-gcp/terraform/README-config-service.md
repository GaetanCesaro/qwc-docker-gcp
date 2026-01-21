# Déploiement de qwc-config-service sur Cloud Run

Ce document explique comment déployer le service `qwc-config-service` sur Google Cloud Run en utilisant Terraform.

## Architecture

Le service `qwc-config-service` est déployé avec :
- **Cloud Run** : pour l'exécution du service
- **Cloud SQL** : connexion via le proxy Cloud SQL configuré dans `pg_service.gcp.conf`
- **Cloud Storage** : plusieurs buckets GCS pour les volumes :
  - `config-in` : configuration d'entrée (lecture seule)
  - `config` : configuration générée (lecture/écriture)
  - `qwc2` : assets QWC2 (lecture seule)
  - `qgis-resources` : ressources QGIS (lecture seule)
  - `print-layouts` : modèles d'impression (lecture seule)
  - `reports` : rapports (lecture seule)
- **Secret Manager** : pour stocker les secrets sensibles

## Prérequis

### 1. Secrets à configurer

Avant de déployer, vous devez définir les variables suivantes :

```bash
# Générer une clé JWT secrète forte
export TF_VAR_jwt_secret_key=$(openssl rand -base64 32)

# Mot de passe PostgreSQL
export TF_VAR_postgres_password="votre_mot_de_passe"

# Nom du projet GCP
export TF_VAR_project_name="votre-project-id"

# Environnement (dev, staging, prod)
export TF_VAR_project_env="dev"
```

### 2. Image Docker avec support Cloud Storage FUSE

Pour que le service puisse monter les buckets GCS comme des volumes, vous devez créer une image Docker personnalisée qui inclut Cloud Storage FUSE. 

Exemple de Dockerfile (à placer dans `qwc-gcp/cloud-run/qwc-config-service/Dockerfile`) :

```dockerfile
FROM sourcepole/qwc-config-generator:latest-2025-lts

# Installer Cloud Storage FUSE
RUN apt-get update && \
    apt-get install -y gnupg lsb-release wget && \
    echo "deb http://packages.cloud.google.com/apt gcsfuse-$(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/gcsfuse.list && \
    wget -O - https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update && \
    apt-get install -y gcsfuse && \
    rm -rf /var/lib/apt/lists/*

# Script de démarrage pour monter les buckets GCS
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

ENTRYPOINT ["/startup.sh"]
```

Script `startup.sh` :

```bash
#!/bin/bash
set -e

# Créer les répertoires de montage
mkdir -p /srv/qwc_service/config-in
mkdir -p /srv/qwc_service/config-out
mkdir -p /qwc2
mkdir -p /data
mkdir -p /layouts
mkdir -p /reports

# Monter les buckets GCS si les variables d'environnement sont définies
if [ -n "$GCS_CONFIG_IN_BUCKET" ]; then
    gcsfuse --implicit-dirs "$GCS_CONFIG_IN_BUCKET" /srv/qwc_service/config-in &
fi

if [ -n "$GCS_CONFIG_BUCKET" ]; then
    gcsfuse --implicit-dirs "$GCS_CONFIG_BUCKET" /srv/qwc_service/config-out &
fi

if [ -n "$GCS_QWC2_BUCKET" ]; then
    gcsfuse --implicit-dirs "$GCS_QWC2_BUCKET" /qwc2 &
fi

if [ -n "$GCS_QGIS_RESOURCES_BUCKET" ]; then
    gcsfuse --implicit-dirs "$GCS_QGIS_RESOURCES_BUCKET" /data &
fi

if [ -n "$GCS_PRINT_LAYOUTS_BUCKET" ]; then
    gcsfuse --implicit-dirs "$GCS_PRINT_LAYOUTS_BUCKET" /layouts &
fi

if [ -n "$GCS_REPORTS_BUCKET" ]; then
    gcsfuse --implicit-dirs "$GCS_REPORTS_BUCKET" /reports &
fi

# Attendre que les montages soient prêts
sleep 5

# Démarrer l'application
exec python src/server.py
```

### 3. Build et Push de l'image

```bash
cd qwc-gcp/cloud-run/qwc-config-service
export PROJECT_ID="votre-project-id"
export ENV="dev"

# Build l'image
docker build -t gcr.io/${PROJECT_ID}/qwc-config-service:${ENV} .

# Push vers GCR
docker push gcr.io/${PROJECT_ID}/qwc-config-service:${ENV}
```

### 4. Mettre à jour le Terraform

Modifiez le fichier `cloud-run.tf` pour utiliser votre image personnalisée :

```terraform
containers {
  # Image personnalisée avec Cloud Storage FUSE
  image = "gcr.io/${var.project-name}/qwc-config-service:${var.project_env}"
  # ...
}
```

## Déploiement

### 1. Initialiser Terraform

```bash
cd qwc-gcp/terraform
terraform init
```

### 2. Planifier le déploiement

```bash
terraform plan
```

### 3. Appliquer la configuration

```bash
terraform apply
```

### 4. Vérifier le déploiement

Une fois le déploiement terminé, Terraform affichera l'URL du service :

```
Outputs:
config_service_url = "https://qwc-config-service-dev-xxxxxxxxx-ew.a.run.app"
```

## Configuration de la base de données

Le service utilise la configuration définie dans `pg_service.gcp.conf` :

```ini
[qwc_configdb]
host=cloud-sql-proxy
port=5432
dbname=eauphrate
sslmode=disable

[qwc_geodb]
host=cloud-sql-proxy
port=5432
dbname=eauphrate
sslmode=disable
```

La connexion à Cloud SQL se fait via le socket Unix monté dans `/cloudsql`.

## Remplir les buckets

Vous devez uploader vos fichiers de configuration dans les buckets GCS :

```bash
# Upload config-in
gsutil -m rsync -r volumes/config-in gs://${PROJECT_ID}-config-in/

# Upload qwc2
gsutil -m rsync -r volumes/qwc2 gs://${PROJECT_ID}-qwc2/

# Upload qgs-resources
gsutil -m rsync -r volumes/qgs-resources gs://${PROJECT_ID}-qgis-resources/

# Upload print-layouts
gsutil -m rsync -r volumes/print-layouts gs://${PROJECT_ID}-print-layouts/

# Upload reports
gsutil -m rsync -r volumes/reports gs://${PROJECT_ID}-reports/
```

## Monitoring et Logs

### Voir les logs

```bash
gcloud run services logs read qwc-config-service-${ENV} \
  --region=europe-west1 \
  --limit=50
```

### Monitoring Cloud Run

Accédez à la console GCP :
- Cloud Run > qwc-config-service-${ENV}
- Onglet "Logs"
- Onglet "Metrics"

## Sécurité

### IAM

Le service utilise un service account dédié avec les permissions minimales :
- `roles/cloudsql.client` : pour se connecter à Cloud SQL
- `roles/storage.objectViewer` : pour lire les buckets en lecture seule
- `roles/storage.objectAdmin` : pour écrire dans le bucket `config`
- `roles/secretmanager.secretAccessor` : pour lire les secrets

### Accès au service

Par défaut, le service est public (`allUsers`). Pour un accès restreint, modifiez :

```terraform
resource "google_cloud_run_v2_service_iam_member" "config_service_invoker" {
  # ...
  # Remplacer allUsers par un service account spécifique
  member = "serviceAccount:mon-service@project.iam.gserviceaccount.com"
}
```

## Dépannage

### Le service ne démarre pas

1. Vérifier les logs :
   ```bash
   gcloud run services logs read qwc-config-service-${ENV} --region=europe-west1
   ```

2. Vérifier que l'image existe :
   ```bash
   gcloud container images list --repository=gcr.io/${PROJECT_ID}
   ```

3. Vérifier les secrets :
   ```bash
   gcloud secrets versions access latest --secret=jwt-secret-key-${ENV}
   gcloud secrets versions access latest --secret=pg-service-conf-${ENV}
   ```

### Problème de connexion à la base de données

1. Vérifier que Cloud SQL est accessible
2. Vérifier le contenu de `pg_service.gcp.conf`
3. Vérifier les permissions du service account

### Problème d'accès aux buckets

1. Vérifier les permissions IAM du service account
2. Vérifier que les buckets existent et contiennent des données
3. Vérifier les logs pour les erreurs de montage gcsfuse

## Notes importantes

1. **Cloud Storage FUSE** : L'image Docker standard de `sourcepole/qwc-config-generator` ne supporte pas nativement Cloud Storage FUSE. Vous devez créer une image personnalisée.

2. **Performance** : Cloud Storage FUSE peut avoir une latence plus élevée que des volumes locaux. Pour de meilleures performances, considérez l'utilisation de Persistent Disks ou de l'optimisation du cache.

3. **Coûts** : Cloud Run facture en fonction du temps d'exécution et des ressources utilisées. Configurez `min_instance_count` à 0 pour éviter les coûts en idle.

4. **Mise à jour** : Pour déployer une nouvelle version, buildez et pushez une nouvelle image, puis redéployez avec Terraform.
