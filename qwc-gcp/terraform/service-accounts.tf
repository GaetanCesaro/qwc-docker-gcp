# Add a cloud-sql-proxy service account granted with Cloud SQL Client role
resource "google_service_account" "cloud_sql_proxy" {
  account_id   = "cloud-sql-proxy"
  display_name = "Service Account for Cloud SQL Proxy"
}

resource "google_project_iam_member" "cloud_sql_proxy_sql_client" {
  project = var.project-name
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_sql_proxy.email}"
}

# Add a terraform service account granted with Cloud Scheduler Admin role
resource "google_service_account" "terraform_sa" {
  account_id   = "terraform-sa"
  display_name = "Service Account for Terraform"
}

resource "google_project_iam_member" "terraform_sa_scheduler_admin" {
  project = var.project-name
  role    = "roles/cloudscheduler.admin"
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}
resource "google_project_iam_member" "terraform_sa_editor" {
  project = var.project-name
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}