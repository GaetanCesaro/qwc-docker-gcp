# Infrastructure (via Terraform)

## First deployment
* Manually create a bucket **{GCP_PROJECT}-terraform** to store the terraform state 

## Prerequisites
Install terraform
'''
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt-get install terraform
'''

## Every deployments
To deploy the infrastructure manually, go to the infrastructure folder and apply the following command line with the good ENV :

```
cd terraform
export ENVIRONMENT=poc
gcloud config set project atlas-qwc-$ENVIRONMENT
terraform init -backend-config=$ENVIRONMENT/backend.conf -backend=true
terraform plan -var-file=$ENVIRONMENT/variables.tfvars
terraform apply -var-file=$ENVIRONMENT/variables.tfvars
```

## Manual configuration
- All IAM configuration (users, service accounts habilitations, etc...) has actually been set manually
- IAP consent screes has been set manually
- Manualy run cloud-sql-proxy if you need to connect to the DB without running docker-compose-gcp : 
```
cloud_sql_proxy -instances=atlas-qwc-poc:europe-west1:eauphrate=tcp:5432
```