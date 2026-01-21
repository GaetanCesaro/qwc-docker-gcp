# Commandes utiles - qwc-config-service sur Cloud Run

## Variables d'environnement

```bash
# À définir avant toute opération
export PROJECT_ID="votre-project-id"
export ENV="dev"  # ou staging, prod
export REGION="europe-west1"
```

## Build et Push de l'image

```bash
# Build et push automatique
cd qwc-gcp/cloud-run/qwc-config-service
./build-config-service.sh $PROJECT_ID $ENV

# Build manuel
docker build -t gcr.io/${PROJECT_ID}/qwc-config-service:${ENV} .
docker push gcr.io/${PROJECT_ID}/qwc-config-service:${ENV}

# Lister les images
gcloud container images list --repository=gcr.io/${PROJECT_ID}

# Voir les tags d'une image
gcloud container images list-tags gcr.io/${PROJECT_ID}/qwc-config-service
```

## Terraform

```bash
cd qwc-gcp/terraform

# Initialiser
terraform init

# Valider la configuration
terraform validate

# Formater les fichiers
terraform fmt

# Planifier
terraform plan

# Appliquer
terraform apply

# Voir les outputs
terraform output
terraform output -raw config_service_url

# Détruire (attention !)
terraform destroy
```

## Cloud Run

```bash
# Décrire le service
gcloud run services describe qwc-config-service-${ENV} \
  --region=${REGION} \
  --format=yaml

# Lister les révisions
gcloud run revisions list \
  --service=qwc-config-service-${ENV} \
  --region=${REGION}

# Mettre à jour le service (redéploiement)
gcloud run services update qwc-config-service-${ENV} \
  --region=${REGION}

# Définir le trafic sur une révision spécifique
gcloud run services update-traffic qwc-config-service-${ENV} \
  --region=${REGION} \
  --to-revisions=REVISION_NAME=100

# Supprimer le service
gcloud run services delete qwc-config-service-${ENV} \
  --region=${REGION}
```

## Logs

```bash
# Logs en temps réel
gcloud run services logs tail qwc-config-service-${ENV} \
  --region=${REGION}

# Derniers logs
gcloud run services logs read qwc-config-service-${ENV} \
  --region=${REGION} \
  --limit=100

# Logs avec filtre
gcloud run services logs read qwc-config-service-${ENV} \
  --region=${REGION} \
  --filter="severity>=ERROR"

# Logs entre deux dates
gcloud run services logs read qwc-config-service-${ENV} \
  --region=${REGION} \
  --filter='timestamp>="2026-01-20T00:00:00Z" AND timestamp<="2026-01-20T23:59:59Z"'
```

## Cloud Storage

```bash
# Lister les buckets
gsutil ls -p ${PROJECT_ID} | grep qwc

# Voir le contenu d'un bucket
gsutil ls -r gs://${PROJECT_ID}-config-in/

# Upload un fichier
gsutil cp local-file.json gs://${PROJECT_ID}-config-in/

# Upload un dossier
gsutil -m rsync -r volumes/config-in gs://${PROJECT_ID}-config-in/

# Download un fichier
gsutil cp gs://${PROJECT_ID}-config/output.json ./

# Supprimer un fichier
gsutil rm gs://${PROJECT_ID}-config-in/file.json

# Vider un bucket
gsutil -m rm -r gs://${PROJECT_ID}-config-in/**

# Voir les permissions d'un bucket
gsutil iam get gs://${PROJECT_ID}-config-in

# Changer les permissions
gsutil iam ch serviceAccount:SA_EMAIL:roles/storage.objectViewer \
  gs://${PROJECT_ID}-config-in
```

## Secrets Manager

```bash
# Lister les secrets
gcloud secrets list --filter="name:${ENV}"

# Créer un secret
echo -n "ma-valeur-secrete" | gcloud secrets create mon-secret-${ENV} \
  --data-file=- \
  --replication-policy=automatic

# Voir la valeur d'un secret
gcloud secrets versions access latest --secret=jwt-secret-key-${ENV}

# Ajouter une nouvelle version
echo -n "nouvelle-valeur" | gcloud secrets versions add jwt-secret-key-${ENV} \
  --data-file=-

# Lister les versions
gcloud secrets versions list jwt-secret-key-${ENV}

# Supprimer un secret
gcloud secrets delete jwt-secret-key-${ENV}

# Donner accès à un service account
gcloud secrets add-iam-policy-binding jwt-secret-key-${ENV} \
  --member="serviceAccount:qwc-config-service-${ENV}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

## Cloud SQL

```bash
# Lister les instances
gcloud sql instances list

# Décrire une instance
gcloud sql instances describe INSTANCE_NAME

# Se connecter à l'instance
gcloud sql connect INSTANCE_NAME --user=postgres

# Voir les bases de données
gcloud sql databases list --instance=INSTANCE_NAME

# Créer une base de données
gcloud sql databases create eauphrate --instance=INSTANCE_NAME

# Voir les logs
gcloud sql operations list --instance=INSTANCE_NAME
```

## IAM et Service Accounts

```bash
# Lister les service accounts
gcloud iam service-accounts list | grep qwc

# Décrire un service account
gcloud iam service-accounts describe \
  qwc-config-service-${ENV}@${PROJECT_ID}.iam.gserviceaccount.com

# Voir les permissions d'un service account
gcloud projects get-iam-policy ${PROJECT_ID} \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:qwc-config-service-${ENV}@${PROJECT_ID}.iam.gserviceaccount.com"

# Ajouter une permission
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:qwc-config-service-${ENV}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"

# Créer une clé de service account (pour tests locaux)
gcloud iam service-accounts keys create key.json \
  --iam-account=qwc-config-service-${ENV}@${PROJECT_ID}.iam.gserviceaccount.com
```

## Tests et Debug

```bash
# Tester l'endpoint de santé
curl $(cd qwc-gcp/terraform && terraform output -raw config_service_url)/ready

# Tester avec authentification
TOKEN=$(gcloud auth print-identity-token)
curl -H "Authorization: Bearer $TOKEN" \
  $(cd qwc-gcp/terraform && terraform output -raw config_service_url)/ready

# Tester depuis un container local
docker run --rm -it \
  -e GOOGLE_APPLICATION_CREDENTIALS=/key.json \
  -v $PWD/key.json:/key.json \
  gcr.io/${PROJECT_ID}/qwc-config-service:${ENV} \
  /bin/bash

# Exécuter une commande dans le container Cloud Run (via Cloud Shell)
gcloud run services proxy qwc-config-service-${ENV} \
  --region=${REGION} \
  --port=9090
```

## Monitoring

```bash
# Voir les métriques
gcloud monitoring dashboards list

# Créer une alerte
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="qwc-config-service-errors" \
  --condition-display-name="Error rate > 5%" \
  --condition-threshold-value=0.05

# Voir les alertes actives
gcloud alpha monitoring policies list
```

## Nettoyage

```bash
# Supprimer le service Cloud Run
gcloud run services delete qwc-config-service-${ENV} --region=${REGION}

# Supprimer les buckets
gsutil -m rm -r gs://${PROJECT_ID}-config-in
gsutil -m rm -r gs://${PROJECT_ID}-config
gsutil -m rm -r gs://${PROJECT_ID}-qwc2
gsutil -m rm -r gs://${PROJECT_ID}-qgis-resources
gsutil -m rm -r gs://${PROJECT_ID}-print-layouts
gsutil -m rm -r gs://${PROJECT_ID}-reports

# Supprimer les secrets
gcloud secrets delete jwt-secret-key-${ENV}
gcloud secrets delete pg-service-conf-${ENV}

# Supprimer le service account
gcloud iam service-accounts delete \
  qwc-config-service-${ENV}@${PROJECT_ID}.iam.gserviceaccount.com

# Supprimer l'image
gcloud container images delete gcr.io/${PROJECT_ID}/qwc-config-service:${ENV}

# Ou tout détruire avec Terraform
cd qwc-gcp/terraform
terraform destroy
```

## Astuces

```bash
# Formater JSON dans les logs
gcloud run services logs read qwc-config-service-${ENV} \
  --region=${REGION} \
  --limit=1 \
  --format=json | jq

# Exporter les logs vers un fichier
gcloud run services logs read qwc-config-service-${ENV} \
  --region=${REGION} \
  --limit=1000 > logs.txt

# Surveiller l'utilisation des ressources
watch -n 5 "gcloud run services describe qwc-config-service-${ENV} \
  --region=${REGION} \
  --format='value(status.conditions)'"

# Générer un JWT pour les tests (nécessite le secret)
JWT_SECRET=$(gcloud secrets versions access latest --secret=jwt-secret-key-${ENV})
# Utiliser un outil comme jwt.io ou une bibliothèque Python/Node pour générer le token

# Forcer un redéploiement immédiat
gcloud run deploy qwc-config-service-${ENV} \
  --image=gcr.io/${PROJECT_ID}/qwc-config-service:${ENV} \
  --region=${REGION} \
  --platform=managed
```

## Alias utiles

```bash
# Ajouter dans ~/.bashrc ou ~/.zshrc

alias qwc-logs="gcloud run services logs tail qwc-config-service-\${ENV} --region=\${REGION}"
alias qwc-describe="gcloud run services describe qwc-config-service-\${ENV} --region=\${REGION}"
alias qwc-url="cd qwc-gcp/terraform && terraform output -raw config_service_url"
alias qwc-deploy="cd qwc-gcp/terraform && ./deploy-config-service.sh \${PROJECT_ID} \${ENV}"
```

## Pipelines CI/CD

Exemple avec Cloud Build :

```bash
# Créer cloudbuild.yaml
cat > cloudbuild.yaml <<EOF
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/\$PROJECT_ID/qwc-config-service:\$SHORT_SHA', '.']
    dir: 'qwc-gcp/cloud-run/qwc-config-service'
  
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/\$PROJECT_ID/qwc-config-service:\$SHORT_SHA']
  
  - name: 'hashicorp/terraform'
    args: ['init']
    dir: 'qwc-gcp/terraform'
  
  - name: 'hashicorp/terraform'
    args: ['apply', '-auto-approve']
    dir: 'qwc-gcp/terraform'
    env:
      - 'TF_VAR_project_name=\$PROJECT_ID'
      - 'TF_VAR_project_env=\$_ENV'
EOF

# Lancer un build
gcloud builds submit --config=cloudbuild.yaml
```
