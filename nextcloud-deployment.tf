#
# Dependance:
#  google_container_node_pool.primary_nodes
#  null_resource.export-custom-routes
#

resource "null_resource" "configure_kubectl" {
  depends_on = [
    google_container_node_pool.primary_nodes,
    google_sql_database_instance.master,
    google_filestore_instance.instance,
    null_resource.export-custom-routes,
    data.external.get_onion_address
  ]

  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --project ${google_container_cluster.primary.project}"
  }
}

provider "kubernetes" {
}

resource "kubernetes_secret" "database-credentials" {
  depends_on = [null_resource.configure_kubectl]

  metadata {
    name = "database-credentials-${random_id.cluster_name_suffix.hex}"
  }

  data = {
    MYSQL_USER = google_sql_user.users.name
    MYSQL_PASSWORD = google_sql_user.users.password
  }
}

resource "kubernetes_secret" "tor-secret" {
  depends_on = [null_resource.configure_kubectl]

  metadata {
    name = "tor-secret-${random_id.cluster_name_suffix.hex}"
  }

  data = {
    TOR_PRIVATE_KEY = data.external.get_onion_address.result.privatekey
  }
}

resource "kubernetes_deployment" "application" {
  depends_on = [kubernetes_secret.database-credentials, data.external.get_onion_address]

  metadata {
    name = "${var.app-name}-deployment"
    labels = {
      app = var.app-name
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.app-name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app-name
        }
      }

      spec {
        container {
          image = "nextcloud:latest"
          name  = var.app-name
          port {
            container_port = 80
          }
          volume_mount {
            name       = "nfs-volume"
            mount_path = "/var/www/html"
          }
          liveness_probe {
            http_get {
              path = "/status.php"
              port = 80
            }
            initial_delay_seconds = 360
            period_seconds        = 3
          }
          env {
            name  = "NEXTCLOUD_ADMIN_USER"
            value = var.nextcloud_admin_user
          }
          env {
            name  = "NEXTCLOUD_ADMIN_PASSWORD"
            value = random_id.nextcloud_admin_password.b64_url
          }
          env {
            name  = "NEXTCLOUD_TRUSTED_DOMAINS"
            value = data.external.get_onion_address.result.hostname
          }
          env {
            name  = "MYSQL_HOST"
            value = google_sql_database_instance.master.private_ip_address
          }
          env {
            name  = "MYSQL_DATABASE"
            value = google_sql_database.database.name
          }
          env {
            name = "MYSQL_USER"
            value_from {
              secret_key_ref {
                name = "database-credentials-${random_id.cluster_name_suffix.hex}"
                key  = "MYSQL_USER"
              }
            }
          }
          env {
            name = "MYSQL_PASSWORD"
            value_from {
              secret_key_ref {
                name = "database-credentials-${random_id.cluster_name_suffix.hex}"
                key  = "MYSQL_PASSWORD"
              }
            }
          }
          resources {
            limits {
              cpu    = "2"
              memory = "512Mi"
            }
            requests {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }
        volume {
          name = "nfs-volume"
          nfs {
            path   = "/${google_filestore_instance.instance.file_shares[0].name}"
            server = google_filestore_instance.instance.networks[0].ip_addresses[0]
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "tor-hidden-service" {
  depends_on = [kubernetes_secret.database-credentials,kubernetes_secret.tor-secret]

  metadata {
    name = "tor-hidden-service-deployment"
    labels = {
      app = "tor"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "tor"
      }
    }

    template {
      metadata {
        labels = {
          app = "tor"
        }
      }

      spec {
        container {
          image = "goldy/tor-hidden-service:latest"
          name  = "tor"
          env {
            name = "WEBSITE_TOR_SERVICE_KEY"
            value_from {
              secret_key_ref {
                name = "tor-secret-${random_id.cluster_name_suffix.hex}"
                key  = "TOR_PRIVATE_KEY"
              }
            }
          }
          env {
            name  = "WEBSITE_TOR_SERVICE_HOSTS"
            value = "80:${kubernetes_service.website.spec[0].cluster_ip}:80"
          }

          resources {
            limits {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "website" {
  metadata {
    name = "${var.app-name}-deployment-service"
  }
  spec {
    selector = {
      app = var.app-name
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

output "Website_Public_Address" {
  value       = data.external.get_onion_address.result.hostname
  description = "The name of the databse user"
  sensitive   = false
}

output "Website_Admin_user" {
  depends_on = [kubernetes_service.expose]

  value       = var.nextcloud_admin_user
  description = "The name of the databse user"
  sensitive   = false
}

output "Website_Admin_password" {
  depends_on = [kubernetes_service.expose]
  
  value       = random_id.nextcloud_admin_password.b64_url
  description = "The name of the databse user"
  sensitive   = false
}



