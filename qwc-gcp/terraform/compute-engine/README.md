# Déploiement de QWC QGIS Server sur GCP Compute Engine

Ce document décrit le déploiement du service `qwc-qgis-server` sur Google Cloud Platform via Terraform, en utilisant Compute Engine au lieu de Cloud Run pour simplifier la gestion des volumes et des points de montage.

## Architecture

Le service QGIS Server est déployé en tant que container Docker sur une instance Compute Engine avec :

- **Image Container OS** : Utilise Container-Optimized OS (COS) de Google pour des performances optimales
- **Image Docker personnalisée** : Basée sur `sourcepole/qwc-qgis-server:3.40` avec `gcsfuse` intégré
- **Montage GCS** : Les buckets Google Cloud Storage sont montés automatiquement au démarrage du container via `gcsfuse`
- **Service Account** : Utilise un compte de service dédié avec les permissions minimales requises

## Volumes montés

Les points de montage suivants sont configurés automatiquement par le container via `gcsfuse` :

1. **`/data`** (dans le container) → Bucket `${project-name}-qgis-resources`
   - Contient les ressources QGIS (fichiers .qgs, .qgz, etc.)
   - Monté en lecture seule au démarrage du container

2. **`/layouts`** (dans le container) → Bucket `${project-name}-print-layouts`
   - Contient les modèles d'impression
   - Monté en lecture seule au démarrage du container

3. **`/usr/share/qgis/python/plugins`** (dans le container) → Bucket `${project-name}-qgis-server-plugins`
   - Contient les plugins QGIS Server (print_templates, split_categorized, filter_geom, clear_capabilities)
   - Monté en lecture seule au démarrage du container

4. **`/etc/postgresql-common/pg_service.conf`** (dans le container) → Secret Manager
   - Configuration PostgreSQL récupérée depuis Secret Manager au démarrage
   - Contient les informations de connexion à Cloud SQL

## Structure Terraform

### Fichiers créés

- **`compute-engine.tf`** : Configuration de l'instance Compute Engine
- **`cloud-init.yaml`** : Script de démarrage cloud-init pour configurer l'instance

### Ressources créées

1. `google_compute_instance.qwc_qgis_server` : Instance VM
2. `google_compute_firewall.qwc_qgis_server` : Règle de pare-feu
3. `google_compute_address.qwc_qgis_server` : Adresse IP statique (optionnelle)

## Prérequis

1. **Image Docker personnalisée** : Doit être buildée et pushée sur GCR
   ```bash
   cd qwc-gcp/cloud-run/qgis-server
   gcloud builds submit --tag gcr.io/${project-name}/qwc-qgis-server:${env} --project=${project-name}
   ```

2. **Buckets GCS** : Doivent être créés et remplis avec les ressources nécessaires
   ```bash
   # Upload des ressources QGIS
   gsutil -m cp -r ./volumes/qgs-resources/* gs://${project-name}-qgis-resources/
   
   # Upload des layouts d'impression
   gsutil -m cp -r ./volumes/print-layouts/* gs://${project-name}-print-layouts/
   
   # Upload des plugins QGIS Server
   gsutil -m cp -r ./volumes/qgis-server-plugins/* gs://${project-name}-qgis-server-plugins/
   ```

3. **Secret Manager** : Le fichier `pg_service.gcp.conf` doit être présent et configuré
   - Vérifie que le fichier existe : `/home/gaetan/work/frcl/qwc-docker-gcp/pg_service.gcp.conf`
   - Le secret est automatiquement créé et uploadé via Terraform

4. **Service Account** : Déjà configuré dans `service-accounts.tf` avec les permissions :
   - `roles/cloudsql.client` : Accès à Cloud SQL
   - `roles/storage.objectViewer` : Lecture des buckets GCS
   - `roles/secretmanager.secretAccessor` : Accès aux secrets

## Déploiement Terraform

```bash
export ENVIRONMENT=poc
gcloud config set project atlas-qwc-$ENVIRONMENT

# Initialiser Terraform (si pas déjà fait)
terraform init -backend-config=$ENVIRONMENT/backend.conf -backend=true

# Vérifier le plan
terraform plan -var-file=$ENVIRONMENT/variables.tfvars

# Appliquer
terraform apply -var-file=$ENVIRONMENT/variables.tfvars
```

### Récupérer l'IP du serveur

```bash
terraform output qgis_server_ip
terraform output qgis_server_internal_ip
```

## Configuration réseau

### Règle de pare-feu

Par défaut, le port 80 est autorisé uniquement depuis les réseaux internes (`10.0.0.0/8`). Pour modifier :

```terraform
# Dans compute-engine.tf, ligne ~60
source_ranges = ["0.0.0.0/0"]  # Accès public (à éviter en production)
# OU
source_ranges = ["10.132.0.0/20"]  # Plage spécifique de votre VPC
```

### Utilisation d'une IP statique

L'adresse IP statique est définie mais non utilisée par défaut. Pour l'attacher :

```terraform
# Dans compute-engine.tf, bloc network_interface
access_config {
  nat_ip = google_compute_address.qwc_qgis_server.address
}
```

## Monitoring et Logs

### Vérifier le statut du service

```bash
export env=poc
export zone=europe-west1-b
gcloud compute ssh qwc-qgis-server-${env} --zone=${zone}

# Statut du service systemd
sudo systemctl status qwc-qgis-server --no-pager -l

# Logs du service systemd
sudo journalctl -u qwc-qgis-server -n 50 --no-pager
```

### Vérifier les logs du container

```bash
gcloud compute ssh qwc-qgis-server-${env} --zone=${zone}

# Vérifier que le container est en cours d'exécution
sudo docker ps

# Logs du container (inclut les montages GCS et le démarrage)
sudo docker logs qwc-qgis-server

# Suivre les logs en temps réel
sudo docker logs -f qwc-qgis-server
```

### Vérifier les montages GCS depuis le container

```bash
gcloud compute ssh qwc-qgis-server-${env} --zone=${zone}

# Entrer dans le container
sudo docker exec -it qwc-qgis-server /bin/bash

# Vérifier les montages
df -h | grep fuse
ls -la /data
ls -la /layouts
ls -la /usr/share/qgis/python/plugins
cat /etc/postgresql-common/pg_service.conf

# Sortir du container
exit
```

### Tester le serveur QGIS

```bash
# Récupérer l'IP du serveur
export QGIS_SERVER_IP=$(terraform output -raw qgis_server_ip)

# Tester GetCapabilities
curl "http://${QGIS_SERVER_IP}/?SERVICE=WMS&REQUEST=GetCapabilities" | head -30

# Ou depuis le navigateur
echo "http://${QGIS_SERVER_IP}/?SERVICE=WMS&REQUEST=GetCapabilities"
```

## Intégration avec les autres services

Pour que les autres services QWC (ogc-service, map-viewer, etc.) puissent communiquer avec le serveur QGIS :

1. **Utiliser l'IP interne** si les services sont sur le même réseau GCP
2. **Configurer les variables d'environnement** dans les autres services :
   ```yaml
   QGIS_SERVER_URL: "http://<qgis_server_internal_ip>/ows"
   ```

## Mise à jour du container

Pour mettre à jour vers une nouvelle version de l'image :

```bash
# 1. Rebuilder et pusher l'image Docker
cd qwc-gcp/cloud-run/qgis-server
gcloud builds submit --tag gcr.io/atlas-qwc-poc/qwc-qgis-server:poc --project=atlas-qwc-poc

# 2. Redémarrer le service sur la VM (l'image sera pullée automatiquement)
export env=poc
export zone=europe-west1-b
gcloud compute ssh qwc-qgis-server-${env} --zone=${zone}
sudo systemctl restart qwc-qgis-server

# 3. Vérifier que la nouvelle image est utilisée
sudo docker ps
sudo docker logs qwc-qgis-server | head -20
```

## Dépannage

### Le container ne démarre pas

```bash
# Vérifier les logs systemd
sudo journalctl -u qwc-qgis-server -f

# Vérifier que le container existe
sudo docker ps -a

# Vérifier les logs du container
sudo docker logs qwc-qgis-server

# Si le container a des erreurs de permission pour gcsfuse
# Vérifier que le container tourne avec --privileged
sudo systemctl cat qwc-qgis-server | grep privileged
```

### Erreurs de montage GCS

```bash
# Entrer dans le container et vérifier les montages
sudo docker exec -it qwc-qgis-server /bin/bash
df -h | grep fuse
ls -la /data
ls -la /layouts
ls -la /usr/share/qgis/python/plugins
exit

# Vérifier les permissions du Service Account
gcloud projects get-iam-policy atlas-qwc-poc \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:serviceAccount:qwc-qgis-server-${env}@atlas-qwc-poc.iam.gserviceaccount.com"
```

### Erreurs de connexion à la base de données

```bash
# Vérifier que pg_service.conf existe et est correct dans le container
sudo docker exec -it qwc-qgis-server cat /etc/postgresql-common/pg_service.conf

# Tester la connexion depuis le container
sudo docker exec -it qwc-qgis-server psql service=qwc_configdb -c "SELECT 1"
```

### Problèmes de permissions

```bash
# Vérifier les permissions du Service Account
gcloud projects get-iam-policy ${project-name} \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:serviceAccount:qwc-qgis-server-${env}@${project-name}.iam.gserviceaccount.com"
```

## Coûts estimés

- **Instance e2-medium** : ~$25/mois (si toujours en cours d'exécution)
- **Stockage GCS** : Variable selon le volume de données
- **Trafic sortant** : Selon l'utilisation

Pour réduire les coûts, envisager :
- Utiliser une instance plus petite (e2-small) si les performances le permettent
- Configurer un arrêt automatique pendant les heures creuses via Cloud Scheduler
- Utiliser des disques persistants standard au lieu de SSD

## Sécurité

1. **Firewall** : Restreindre l'accès aux plages IP connues
2. **HTTPS** : Configurer un Load Balancer avec certificat SSL pour l'accès externe
3. **VPC** : Déployer dans un VPC privé avec Cloud NAT pour le trafic sortant
4. **Service Account** : Permissions minimales déjà configurées (principle of least privilege)

## Alternative : Cloud Run

Si vous souhaitez revenir à Cloud Run malgré les limitations de montage :
- Voir `cloud-run.tf` pour la configuration existante
- Les volumes GCS peuvent être montés via Cloud Run volume mounts (feature en beta)
