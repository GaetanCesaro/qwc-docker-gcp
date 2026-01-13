resource "google_sql_database_instance" "instance" {
  name   = "atlas-qwc"
  region = var.region-serverless
  database_version = "POSTGRES_15"
  settings {
    tier = "db-custom-1-3840"
    backup_configuration {
      enabled = true
      point_in_time_recovery_enabled = true
    }
    database_flags {
        name = "max_connections"
        value = 300
    }
  }
}

resource "google_sql_database" "database" {
  name     = "atlas-qwc"
  instance = "atlas-qwc"
}

resource "google_sql_user" "postgres" {
  name     = "postgres"
  instance = google_sql_database_instance.instance.name
  password = var.postgres-password
}
