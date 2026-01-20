resource "google_project_service" "secret" {
  project = var.project-name
  service = "secretmanager.googleapis.com"
  disable_dependent_services = false
}

resource "google_project_service" "sqladmin" {
  project = var.project-name
  service = "sqladmin.googleapis.com"
  disable_dependent_services = false
}

resource "google_project_service" "cloudscheduler" {
  project = var.project-name
  service = "cloudscheduler.googleapis.com"
  disable_dependent_services = false
}

resource "google_project_service" "run" {
  project                    = var.project-name
  service                    = "run.googleapis.com"
  disable_dependent_services = false
}

resource "google_project_service" "compute" {
  project                    = var.project-name
  service                    = "compute.googleapis.com"
  disable_dependent_services = false
}

resource "google_project_service" "cloudbuild" {
  project                    = var.project-name
  service                    = "cloudbuild.googleapis.com"
  disable_dependent_services = false
}