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
    OWNCLOUD_DB_USERNAME = google_sql_user.users.name
    OWNCLOUD_DB_PASSWORD = google_sql_user.users.password
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
  depends_on = [kubernetes_secret.database-credentials,kubernetes_secret.tor-secret]

  metadata {
    name = "${var.app-name}-deployment"
    labels = {
      app = var.app-name
    }
  }

  spec {
    replicas = 2

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
        hostname = "website"
        container {
          image = "owncloud/server:latest"
          name  = var.app-name
          
          port {
            container_port = 8080
          }
          volume_mount {
            name       = "nfs-volume"
            mount_path = "/mnt/data"
          }
          env {
            name  = "OWNCLOUD_DB_TYPE"
            value = "mysql"
          }
          env {
            name  = "OWNCLOUD_DB_HOST"
            value = google_sql_database_instance.master.private_ip_address
          }
          env {
            name  = "OWNCLOUD_DB_NAME"
            value = google_sql_database.database.name
          }
          env {
            name  = "OWNCLOUD_DB_PREFIX"
            value = "oc_"
          }
          env {
            name  = "OWNCLOUD_MYSQL_UTF8MB4"
            value = "true"
          }
          env {
            name = "OWNCLOUD_DB_USERNAME"
            value_from {
              secret_key_ref {
                name = "database-credentials-${random_id.cluster_name_suffix.hex}"
                key  = "OWNCLOUD_DB_USERNAME"
              }
            }
          }
          env {
            name = "OWNCLOUD_DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = "database-credentials-${random_id.cluster_name_suffix.hex}"
                key  = "OWNCLOUD_DB_PASSWORD"
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
      target_port = 8080
    }

    type = "ClusterIP"
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
            value = "80:website:8080"
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
