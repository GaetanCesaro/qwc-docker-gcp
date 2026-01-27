# QWC sur Google Cloud Platform

Ce dossier contient la configuration pour déployer les services QWC (QGIS Web Client) sur Google Cloud Platform.

## 📂 Structure

```
qwc-gcp/
├── cloud-run/              # Images Docker personnalisées pour Cloud Run (legacy)
├── kubernetes/             # Configuration Kubernetes (WIP) 
├── kompose/                # Projet de configuration Kubernetes depuis Kompose (WIP)
└── terraform/              # Infrastructure as Code (IaC)
    ├── *.tf                # Configuration Terraform
    ├── *.sh                # Scripts de déploiement
    └── *.md                # Documentation
```

### Fichiers Terraform

| Fichier | Description |
|---------|-------------|
| [main.tf](terraform/main.tf) | Configuration provider et backend |
| [variables.tf](terraform/variables.tf) | Variables Terraform |
| [cloud-run.tf](terraform/cloud-run.tf) | Services Cloud Run |
| [storage.tf](terraform/storage.tf) | Buckets Cloud Storage |
| [service-accounts.tf](terraform/service-accounts.tf) | Service Accounts et IAM |
| [secrets.tf](terraform/secrets.tf) | Secret Manager |
| [database.tf](terraform/database.tf) | Cloud SQL |

## 🔧 Prérequis

- Docker
- gcloud CLI
- Terraform >= 1.14.0
- Compte GCP avec permissions suffisantes

## 🚦 Déploiement

### Configuration

```bash
export TF_VAR_project_name="my-gcp-project"
export TF_VAR_project_env="dev"
export TF_VAR_postgres_password="secure_password"
# JWT_SECRET_KEY est chargé depuis .env automatiquement
```

### Upload des fichiers vers bucket GCS

```bash
# Synchroniser les volumes locaux vers les buckets GCS
gsutil -m rsync -r ../../volumes/config-in gs://${TF_VAR_project_name}-config-in/
gsutil -m rsync -r ../../volumes/qwc2 gs://${TF_VAR_project_name}-qwc2/
# ... etc
```

## 🔐 Sécurité

### Secrets

Les secrets sensibles sont stockés dans Secret Manager :
- `jwt-secret-key-{env}` - Clé JWT
- `pg-service-conf-{env}` - Configuration PostgreSQL

**⚠️ Important** : Ne jamais commiter `terraform.tfvars` !

### Permissions IAM

Chaque service utilise un service account dédié avec le principe du moindre privilège :
- Cloud SQL Client
- Storage Object Viewer/Admin
- Secret Manager Accessor

## 📊 Monitoring

### Logs

```bash
# Logs en temps réel
gcloud run services logs tail qwc-config-service-dev --region=europe-west1

# Logs avec filtre
gcloud run services logs read qwc-config-service-dev \
  --region=europe-west1 \
  --filter="severity>=ERROR"
```

## 🐛 Dépannage

### Problème de connexion DB

```bash
# Vérifier Cloud SQL
gcloud sql instances list

# Vérifier le secret
gcloud secrets versions access latest --secret=pg-service-conf-dev
```

### Problème d'accès aux buckets

```bash
# Vérifier les permissions
gsutil iam get gs://<project-id>-config-in

# Vérifier le contenu
gsutil ls -r gs://<project-id>-config-in
```

## 📚 Ressources

- [QWC2 Documentation](https://github.com/qgis/qwc2)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Storage FUSE](https://cloud.google.com/storage/docs/gcs-fuse)

## ✅ Checklist

- [ ] Prérequis installés
- [ ] Variables d'environnement configurées
- [ ] Image Docker buildée
- [ ] Terraform appliqué
- [ ] Buckets remplis
- [ ] Service opérationnel
- [ ] Tests réussis
