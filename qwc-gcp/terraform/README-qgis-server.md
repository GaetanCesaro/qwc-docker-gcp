# Déploiement QWC QGIS Server sur Cloud Run

## Configuration

Le service `qwc-qgis-server` a été configuré pour Cloud Run avec les caractéristiques suivantes :

### Image Docker
- **Image**: `sourcepole/qwc-qgis-server:3.40`

### Variables d'environnement
Configurées selon le fichier **docker-compose.yml** :
- `FCGID_EXTRA_ENV=PRINT_LAYOUT_DIR`
- `PRINT_LAYOUT_DIR=/layouts`
- `QGIS_SERVER_LOG_LEVEL=0`
- `LOCALE=fr_FR`
- `QGIS_SERVER_IGNORE_BAD_LAYERS=1`

### Ressources créées

1. **Cloud Storage Buckets** :
   - `${project-name}-qgis-resources` : Pour les ressources QGIS (/data)
   - `${project-name}-print-layouts` : Pour les layouts d'impression

2. **Service Account** :
   - `qwc-qgis-server-${env}` avec les rôles :
     - Cloud SQL Client (pour la connexion à la base de données)
     - Storage Object Viewer (pour lire les ressources)

3. **Secret Manager** :
   - `pg-service-conf-${env}` : Contient le contenu du fichier **pg_service.conf**

4. **Cloud Run Service** :
   - Connexion à Cloud SQL via Unix socket
   - Scaling : 0-10 instances
   - CPU : 2 vCPUs
   - Mémoire : 4 GiB
   - Timeout : 300s

## Montage des volumes dans Cloud Run

⚠️ **Limitation importante** : Cloud Run ne supporte pas les volumes comme Docker Compose.

### Solutions alternatives :

1. **Cloud Storage FUSE** (recommandé) :
   - Utiliser gcsfuse pour monter les buckets Cloud Storage
   - Modifier l'image Docker pour inclure gcsfuse

2. **Inclure les ressources dans l'image Docker** :
   - Ajouter les ressources directement dans l'image
   - Rebuild l'image à chaque changement

3. **Télécharger au démarrage** :
   - Script d'initialisation qui télécharge les ressources depuis Cloud Storage
   - Stockage dans `/tmp` (éphémère)

## Prérequis

### 1. Préparer les fichiers de configuration

Le fichier `pg_service.gcp.conf` doit être présent dans le répertoire racine du projet.

### 2. Uploader les ressources dans Cloud Storage

#### Ressources QGIS
```bash
gsutil -m rsync -r ./volumes/qgs-resources gs://${PROJECT_NAME}-qgis-resources/
```

#### Print Layouts
```bash
gsutil -m rsync -r ./volumes/print-layouts gs://${PROJECT_NAME}-print-layouts/
```

#### NB : Plugins QGIS (à adapter selon vos besoins)
Les plugins QGIS ne peuvent pas être montés directement dans Cloud Run. Si besoin, il faudra les ajouter à l'image customisée **qwc-gcp/cloud-run/qgis-server/Dockerfile.qgis-server** (déjà customisée pour la mise en place de **gcsfuse**)

## Déploiement

### 1. Initialiser Terraform

```bash
cd qwc-gcp/terraform
terraform init
```

### 2. Planifier le déploiement

```bash
terraform plan -var-file="poc/poc.tfvars"
```

### 3. Appliquer la configuration

```bash
terraform apply -var-file="poc/poc.tfvars"
```

### 4. Récupérer l'URL du service

```bash
terraform output qgis_server_url
```

## Monitoring

### Logs
```bash
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=qwc-qgis-server-${ENV}" --limit 50 --format json
```

### Métriques
Consultez les métriques dans la console Cloud Run :
- Nombre de requêtes
- Latence
- Utilisation CPU/Mémoire
- Instances actives

## Mise à jour

Pour mettre à jour l'image :

1. Modifier la version dans `qwc-qgis-server.tf`
2. Appliquer :
```bash
terraform apply -var-file="poc/poc.tfvars"
```

## Troubleshooting

### Le service ne démarre pas
- Vérifier les logs : `gcloud run services logs read qwc-qgis-server-${ENV}`
- Vérifier que Cloud SQL est accessible
- Vérifier que le Secret Manager contient le bon pg_service.conf

### Erreur de connexion à la base de données
- Vérifier que le service account a le rôle `roles/cloudsql.client`
- Vérifier que la connexion Cloud SQL est correctement configurée
- Vérifier le contenu du fichier pg_service.conf

### Problème de permissions sur Cloud Storage
- Vérifier que le service account a le rôle `roles/storage.objectViewer`
- Vérifier que les buckets existent et contiennent les données

## Sécurité

### Authentification

Par défaut, le service est public (`allUsers`). Pour le sécuriser :

1. Supprimer la ressource `google_cloud_run_v2_service_iam_member.qgis_server_public`

2. Ajouter une authentification via IAP ou un autre mécanisme

3. Ou restreindre l'accès à des comptes de service spécifiques :
```terraform
resource "google_cloud_run_v2_service_iam_member" "qgis_server_invoker" {
  name     = google_cloud_run_v2_service.qgis_server.name
  location = google_cloud_run_v2_service.qgis_server.location
  project  = var.project-name
  role     = "roles/run.invoker"
  member   = "serviceAccount:my-service@${var.project-name}.iam.gserviceaccount.com"
}
```

## Coûts

Estimation mensuelle (selon usage) :
- Cloud Run : Pay-per-use (requêtes + CPU/Mémoire)
- Cloud Storage : ~0.020€/GB/mois (Europe)
- Cloud SQL : Voir configuration existante
- Secret Manager : Gratuit pour les 6 premiers secrets

Avec scaling à 0, pas de coût quand le service n'est pas utilisé.
