# Configuration du provider Kubernetes pour utiliser le cluster GKE
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.qwc_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.qwc_cluster.master_auth[0].cluster_ca_certificate)
}

# Créer le namespace qwc-services
resource "kubernetes_namespace_v1" "qwc_services" {
  metadata {
    name = "qwc-services"
    labels = {
      name = "qwc-services"
    }
  }

  depends_on = [google_container_cluster.qwc_cluster]
}
