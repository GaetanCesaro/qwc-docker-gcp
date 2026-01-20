# Guide de déploiement des services QWC Eauphrate via Terraform

## Prérequis

1. Projet GCP configuré **atlas-qwc-{env}**
2. gcloud CLI installé et authentifié **gcloud auth login**
3. Docker installé localement
4. Terraform installé localement
5. Avoir créé la configuration du projet dans **./terraform/{env}**

## Étapes de déploiement

### 1. Build & push l'image Docker personnalisée qwc-qgis-server

#### Prérequis (au 1er run)

Activer les APIs Artifact Registry

```bash
gcloud services enable artifactregistry.googleapis.com --project=atlas-qwc-poc
gcloud services enable artifactregistry.googleapis.com containerregistry.googleapis.com --project=atlas-qwc-poc
```

```bash
cd qwc-gcp/cloud-run/qgis-server

# Syntaxe: ./build-qgis-server.sh <project-id> [environment] [tag]
./build-qgis-server.sh atlas-qwc-poc poc latest
```

Cette commande va :
- Builder l'image Docker avec **gcsfuse** installé
- Tagger l'image avec `gcr.io/atlas-qwc-poc/qwc-qgis-server:latest` et `gcr.io/atlas-qwc-poc/qwc-qgis-server:poc`
- Pusher l'image vers Google Container Registry

### 2. Déployer avec Terraform

```bash
cd qwc-gcp/terraform

# Définir l'environnement
export ENVIRONMENT=poc
gcloud config set project atlas-qwc-$ENVIRONMENT

# Initialiser Terraform (si pas déjà fait)
terraform init -backend-config=$ENVIRONMENT/backend.conf -backend=true

# Vérifier le plan
terraform plan -var-file=$ENVIRONMENT/variables.tfvars

# Appliquer
terraform apply -var-file=$ENVIRONMENT/variables.tfvars
```

### 3. Uploader les ressources QGIS et Layouts dans Cloud Storage

Après avoir fait le 1er déploiement (et création entre des buckets Cloud Storage dédiés via Terraform) on peut uploader les ressources QGIS et print layouts.

```bash
gsutil -m rsync -r ./volumes/qgs-resources/ gs://atlas-qwc-poc-qgis-resources/
gsutil -m rsync -r ./volumes/print-layouts/ gs://atlas-qwc-poc-print-layouts/

# Redémarrer le service Cloud Run pour recharger (optionnel)
gcloud run services update qwc-qgis-server-poc --region=europe-west1
```

### 4. Vérifier le déploiement

```bash
# Obtenir l'URL du service
terraform output qgis_server_url
# https://qwc-qgis-server-poc-gbvamcurxq-ew.a.run.app

# Vérifier les logs
gcloud run services logs read qwc-qgis-server-poc --region=europe-west1 --limit=50

# Tester le service
curl "$(terraform output -raw qgis_server_ip)/?SERVICE=WMS&REQUEST=GetCapabilities"
curl "https://35.195.127.107/?SERVICE=WMS&REQUEST=GetCapabilities"
```

## Architecture déployée

### Service qwc-qgis-server

1. **Cloud Storage Buckets**
   - `{project-name}-qgis-resources` : Ressources QGIS (projets .qgs, données, etc.)
   - `{project-name}-print-layouts` : Templates d'impression

2. **Service Account**
   - `qwc-qgis-server-{env}@{project}.iam.gserviceaccount.com`
   - Permissions :
     - Cloud SQL Client
     - Storage Object Viewer (sur les 2 buckets)
     - Secret Manager Secret Accessor

3. **Secret Manager**
   - `pg-service-conf-{env}` : Configuration PostgreSQL

4. **Cloud Run Service**
   - Image personnalisée avec gcsfuse
   - Montage automatique des buckets Cloud Storage via FUSE
   - Connexion Cloud SQL
   - Scaling 0-10 instances
   - 2 vCPUs, 4 GiB RAM

### Focus sur le fonctionnement de Cloud Storage FUSE

Au démarrage du conteneur :
1. Le script `docker-entrypoint-qgis.sh` s'exécute
2. Il récupère les noms des buckets depuis les variables d'environnement
3. Il monte les buckets avec `gcsfuse` :
   - `gs://{project}-qgis-resources` → `/data`
   - `gs://{project}-print-layouts` → `/layouts`
4. Les fichiers dans Cloud Storage sont accessibles comme des fichiers locaux
5. QGIS Server démarre normalement avec accès aux ressources

### Avantages de cette solution

- ✅ Pas besoin d'inclure les ressources dans l'image Docker
- ✅ Mises à jour des ressources sans rebuild de l'image
- ✅ Partage facile des ressources entre plusieurs services
- ✅ Versioning et backup automatique via Cloud Storage
- ✅ Lecture seule pour plus de sécurité

### Limitations

- Les performances de lecture sont légèrement inférieures à un stockage local
- Les opérations d'écriture sont limitées
- Nécessite que le conteneur tourne avec des privilèges suffisants pour monter FUSE

## Mise à jour de l'image Docker

Si vous modifiez le Dockerfile ou le script d'entrypoint :

```bash
# Rebuild et push avec un nouveau tag
./build-qgis-server.sh atlas-qwc-poc poc v1.1

# Mettre à jour la variable dans Terraform ou modifier directement
# terraform/qwc-qgis-server.tf: image = "gcr.io/${var.project-name}/qwc-qgis-server:v1.1"

# Redéployer
cd terraform
terraform apply -var-file="poc/poc.tfvars"
```

## Troubleshooting

### Le service ne démarre pas

```bash
# Vérifier les logs détaillés
gcloud run services logs read qwc-qgis-server-poc --region=europe-west1 --limit=100

# Vérifier que l'image existe
gcloud container images list --repository=gcr.io/atlas-qwc-poc
```

### Les buckets ne se content pas

Vérifier que :
1. Les buckets existent et contiennent des fichiers
2. Le service account a les bonnes permissions
3. Les noms de buckets sont corrects dans les variables d'environnement

```bash
# Lister les fichiers dans le bucket
gsutil ls -r gs://atlas-qwc-poc-qgis-resources/

# Vérifier les permissions
gsutil iam get gs://atlas-qwc-poc-qgis-resources/
```

### Erreur de connexion à la base de données

```bash
# Vérifier que Cloud SQL est accessible
gcloud sql instances describe eauphrate

# Vérifier le secret pg_service.conf
gcloud secrets versions access latest --secret=pg-service-conf-poc
```

## Nettoyage

Pour supprimer toutes les ressources :

```bash
cd terraform
terraform destroy -var-file="poc/poc.tfvars"

# Supprimer les buckets (si nécessaire)
gsutil -m rm -r gs://atlas-qwc-poc-qgis-resources/
gsutil -m rm -r gs://atlas-qwc-poc-print-layouts/

# Supprimer l'image Docker
gcloud container images delete gcr.io/atlas-qwc-poc/qwc-qgis-server:poc --quiet
```

## Coûts estimés

- **Cloud Run** : ~0.04€ par million de requêtes + CPU/mémoire utilisé
- **Cloud Storage** : ~0.020€/GB/mois (stockage) + ~0.12€/GB (sortie réseau)
- **Container Registry** : ~0.020€/GB/mois
- Avec scaling à 0 : pas de coût quand non utilisé

Pour 100GB de ressources et 10 000 requêtes/mois : ~5-10€/mois
