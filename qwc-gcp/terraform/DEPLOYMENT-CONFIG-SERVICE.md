# Guide de déploiement de qwc-config-service sur Cloud Run

Ce guide vous explique comment déployer le service `qwc-config-service` sur Google Cloud Run.

## Vue d'ensemble

Le déploiement comprend :
- ✅ Buckets Cloud Storage (config-in, config, qwc2, qgis-resources, print-layouts, reports)
- ✅ Service Account avec permissions appropriées
- ✅ Secrets Manager (JWT secret, pg_service.conf)
- ✅ Service Cloud Run avec connexion Cloud SQL
- ✅ Image Docker personnalisée avec Cloud Storage FUSE

## Étapes de déploiement

### 1. Configurer les variables d'environnement

Avoir bien rempli les fichiers postgres.env et .env

TODO : Mettre des templates de ces fichiers car ils sont gitignored

### 2. Construire l'image Docker personnalisée

Le service nécessite une image personnalisée avec Cloud Storage FUSE pour monter les buckets GCS.

```bash
cd qwc-gcp/cloud-run/qwc-config-service

# Build et push l'image
export ENV=poc
export PROJECT_ID=atlas-qwc-$ENV
./build-config-service.sh $PROJECT_ID $ENV
```

### 3. Vérifier le fichier pg_service.gcp.conf

Assurez-vous que le fichier [pg_service.gcp.conf](../../pg_service.gcp.conf) est correctement configuré :

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

### 4. Déployer avec Terraform

```bash
cd qwc-gcp/terraform
$ENV=poc
gcloud config set project atlas-qwc-$ENV
terraform init -backend-config=$ENV/backend.conf -backend=true
terraform plan -var-file=$ENV/variables.tfvars
terraform apply -var-file=$ENV/variables.tfvars
```

Terraform va créer :
- 6 buckets Cloud Storage
- 1 service account avec permissions IAM
- 2 secrets (JWT et pg_service.conf)
- 1 service Cloud Run

### 5. Uploader les fichiers dans les buckets

```bash
export PROJECT_ID=$TF_VAR_project_name

# Config-in (configuration d'entrée)
gsutil -m rsync -r ../../volumes/config-in gs://${PROJECT_ID}-config-in/

# QWC2 assets
gsutil -m rsync -r ../../volumes/qwc2 gs://${PROJECT_ID}-qwc2/

# QGIS resources
gsutil -m rsync -r ../../volumes/qgs-resources gs://${PROJECT_ID}-qgis-resources/

# Print layouts
gsutil -m rsync -r ../../volumes/print-layouts gs://${PROJECT_ID}-print-layouts/

# Reports
gsutil -m rsync -r ../../volumes/reports gs://${PROJECT_ID}-reports/
```

### 6. Vérifier le déploiement

```bash
# Obtenir l'URL du service
terraform output config_service_url

# Tester le service
curl $(terraform output -raw config_service_url)/ready

# Voir les logs
gcloud run services logs read qwc-config-service-${TF_VAR_project_env} \
  --region=europe-west1 \
  --limit=50
```

## Architecture détaillée

### Ressources créées

#### Buckets Cloud Storage

| Bucket | Usage | Permissions |
|--------|-------|-------------|
| `config-in` | Configuration d'entrée | Lecture seule |
| `config` | Configuration générée | Lecture/Écriture |
| `qwc2` | Assets QWC2 | Lecture seule |
| `qgis-resources` | Ressources QGIS | Lecture seule |
| `print-layouts` | Modèles d'impression | Lecture seule |
| `reports` | Rapports | Lecture seule |

#### Service Account

Service Account : `qwc-config-service-{env}@{project}.iam.gserviceaccount.com`

Permissions :
- `roles/cloudsql.client` : Connexion à Cloud SQL
- `roles/storage.objectViewer` : Lecture des buckets
- `roles/storage.objectAdmin` : Écriture sur le bucket `config`
- `roles/secretmanager.secretAccessor` : Accès aux secrets

#### Secrets

- `jwt-secret-key-{env}` : Clé secrète pour JWT
- `pg-service-conf-{env}` : Configuration PostgreSQL

#### Cloud Run

- **Service** : `qwc-config-service-{env}`
- **Région** : `europe-west1`
- **CPU** : 2 vCPU
- **Mémoire** : 2 Gi
- **Scaling** : 0-5 instances
- **Timeout** : 300s

### Variables d'environnement du service

Le service Cloud Run est configuré avec les variables suivantes :

```yaml
SERVICE_MOUNTPOINT: /api/v1/config
INPUT_CONFIG_PATH: /srv/qwc_service/config-in
OUTPUT_CONFIG_PATH: /srv/qwc_service/config-out
GENERATE_DYNAMIC_KVRELS: 1
JWT_COOKIE_CSRF_PROTECT: True
JWT_COOKIE_SAMESITE: Strict
JWT_SECRET_KEY: <depuis Secret Manager>
GCS_PROJECT_NAME: <project-id>
GCS_CONFIG_IN_BUCKET: <project-id>-config-in
GCS_CONFIG_BUCKET: <project-id>-config
GCS_QWC2_BUCKET: <project-id>-qwc2
GCS_QGIS_RESOURCES_BUCKET: <project-id>-qgis-resources
GCS_PRINT_LAYOUTS_BUCKET: <project-id>-print-layouts
GCS_REPORTS_BUCKET: <project-id>-reports
```

## Mise à jour du service

### Mettre à jour l'image Docker

```bash
cd qwc-gcp/cloud-run/qwc-config-service
./build-config-service.sh $TF_VAR_project_name $TF_VAR_project_env
```

### Redéployer avec Terraform

```bash
cd qwc-gcp/terraform
terraform apply
```

### Forcer un nouveau déploiement Cloud Run

```bash
gcloud run services update qwc-config-service-${TF_VAR_project_env} \
  --region=europe-west1
```

## Dépannage

### Le service ne démarre pas

1. **Vérifier les logs** :
   ```bash
   gcloud run services logs read qwc-config-service-${TF_VAR_project_env} \
     --region=europe-west1
   ```

2. **Vérifier que l'image existe** :
   ```bash
   gcloud container images list --repository=gcr.io/${TF_VAR_project_name}
   ```

3. **Vérifier les secrets** :
   ```bash
   gcloud secrets versions access latest --secret=jwt-secret-key-${TF_VAR_project_env}
   ```

### Problème de connexion à la base de données

1. **Tester la connexion Cloud SQL** :
   ```bash
   gcloud sql connect <instance-name> --user=postgres
   ```

2. **Vérifier le pg_service.conf** :
   ```bash
   gcloud secrets versions access latest --secret=pg-service-conf-${TF_VAR_project_env}
   ```

### Problème d'accès aux buckets

1. **Vérifier les permissions** :
   ```bash
   gsutil iam get gs://${TF_VAR_project_name}-config-in
   ```

2. **Tester l'accès** :
   ```bash
   gsutil ls gs://${TF_VAR_project_name}-config-in
   ```

### Les montages GCS ne fonctionnent pas

1. **Vérifier les logs de gcsfuse** dans les logs Cloud Run
2. **Vérifier que l'image a bien gcsfuse installé** :
   ```bash
   gcloud run services describe qwc-config-service-${TF_VAR_project_env} \
     --region=europe-west1 \
     --format=json | jq '.spec.template.spec.containers[0].image'
   ```

## Sécurité

### Accès au service

Par défaut, le service est accessible publiquement (`allUsers`). Pour restreindre l'accès :

1. **Modifier la configuration Terraform** dans [cloud-run.tf](cloud-run.tf) :
   ```terraform
   resource "google_cloud_run_v2_service_iam_member" "config_service_invoker" {
     # Remplacer allUsers par un service account spécifique
     member = "serviceAccount:mon-service@project.iam.gserviceaccount.com"
   }
   ```

2. **Appliquer les changements** :
   ```bash
   terraform apply
   ```

### Rotation des secrets

Pour faire tourner le JWT secret :

```bash
# Générer une nouvelle clé
export NEW_JWT_SECRET=$(openssl rand -base64 32)

# Mettre à jour le secret
gcloud secrets versions add jwt-secret-key-${TF_VAR_project_env} \
  --data-file=- <<< "$NEW_JWT_SECRET"

# Redémarrer le service
gcloud run services update qwc-config-service-${TF_VAR_project_env} \
  --region=europe-west1
```

## Monitoring

### Metrics Cloud Run

Accédez à :
- **Console GCP** > Cloud Run > qwc-config-service-{env}
- Onglet **Metrics** pour voir :
  - Nombre de requêtes
  - Latence
  - Utilisation CPU/Mémoire
  - Erreurs

### Alertes recommandées

Créez des alertes pour :
- Taux d'erreur > 5%
- Latence P95 > 2s
- Utilisation mémoire > 90%

## Coûts

### Optimisation

- **min_instance_count = 0** : Pas de coût en idle
- **cpu_idle = true** : Réduit les coûts CPU
- **Scaling** : 0-5 instances limite les coûts

### Estimation mensuelle

Pour un usage modéré :
- Cloud Run : ~10-50€/mois
- Cloud Storage : ~5-20€/mois
- Cloud SQL : selon la configuration
- Secret Manager : ~0.06€/secret/mois

## Support

Pour plus d'informations :
- [Documentation détaillée](README-config-service.md)
- [Terraform Cloud Run](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service)
- [QWC2 Documentation](https://github.com/qgis/qwc2)
