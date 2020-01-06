#
# Dependance:
#  google_container_node_pool.primary_nodes
#  null_resource.export-custom-routes
#


resource "null_resource" "configure_kubectl" {
  depends_on = [null_resource.configure_kubectl,google_container_node_pool.primary_nodes,null_resource.export-custom-routes]

  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --project ${google_container_cluster.primary.project}"
  }
}


provider "kubernetes" {
}

resource "kubernetes_secret" "database-credentials" {
  depends_on = [null_resource.configure_kubectl,google_container_node_pool.primary_nodes]

  metadata {
    name = "database-credentials"
  }

  data = {
    OWNCLOUD_DB_USERNAME = google_sql_user.users.name
    OWNCLOUD_DB_PASSWORD = google_sql_user.users.password
  }
}


resource "kubernetes_deployment" "application" {
  depends_on = [null_resource.configure_kubectl,google_container_node_pool.primary_nodes]

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
        container {
          image = "owncloud/server:latest"
          name  = var.app-name
          port {
            container_port = 8080
          }
          volume_mount {
            name = "nfs-volume"
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
            name  = "OWNCLOUD_DB_USERNAME"
            value_from {
              secret_key_ref {
              name = "database-credentials"
              key = "OWNCLOUD_DB_USERNAME"
              }
            }
          }
          env {
            name  = "OWNCLOUD_DB_PASSWORD"
            value_from {
              secret_key_ref {
              name = "database-credentials"
              key = "OWNCLOUD_DB_PASSWORD"
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
            path = "/${google_filestore_instance.instance.file_shares[0].name}"
            server = google_filestore_instance.instance.networks[0].ip_addresses[0]
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "expose" {
  depends_on = [null_resource.configure_kubectl,google_container_node_pool.primary_nodes]

  metadata {
    name = "expose-${var.app-name}"
  }
  spec {
    selector = {
      app = var.app-name
    }
    session_affinity = "ClientIP"
    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}

