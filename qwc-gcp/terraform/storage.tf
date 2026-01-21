# Cloud Storage bucket for QGIS resources
resource "google_storage_bucket" "qgis_resources" {
  name          = "${var.project-name}-qgis-resources"
  location      = var.location
  storage_class = var.storage-class

  uniform_bucket_level_access = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }
}

# Cloud Storage bucket for print layouts
resource "google_storage_bucket" "print_layouts" {
  name          = "${var.project-name}-print-layouts"
  location      = var.location
  storage_class = var.storage-class

  uniform_bucket_level_access = true
}

# Cloud Storage bucket for QGIS server plugins
resource "google_storage_bucket" "qgis_server_plugins" {
  name          = "${var.project-name}-qgis-server-plugins"
  location      = var.location
  storage_class = var.storage-class

  uniform_bucket_level_access = true
}

# Cloud Storage bucket for config-in (input configuration)
resource "google_storage_bucket" "config_in" {
  name          = "${var.project-name}-config-in"
  location      = var.location
  storage_class = var.storage-class

  uniform_bucket_level_access = true
}

# Cloud Storage bucket for config (generated configuration)
resource "google_storage_bucket" "config" {
  name          = "${var.project-name}-config"
  location      = var.location
  storage_class = var.storage-class

  uniform_bucket_level_access = true
}

# Cloud Storage bucket for QWC2 assets
resource "google_storage_bucket" "qwc2" {
  name          = "${var.project-name}-qwc2"
  location      = var.location
  storage_class = var.storage-class

  uniform_bucket_level_access = true
}

# Cloud Storage bucket for reports
resource "google_storage_bucket" "reports" {
  name          = "${var.project-name}-reports"
  location      = var.location
  storage_class = var.storage-class

  uniform_bucket_level_access = true
}
