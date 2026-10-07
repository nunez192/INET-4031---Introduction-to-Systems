resource "kubernetes_persistent_volume_claim_v1" "db_data" {
  metadata {
    name = "db-data"
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }

  wait_until_bound = false
}

resource "kubernetes_deployment_v1" "db" {
  metadata {
    name   = "db"
    labels = { app = "db" }
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = { app = "db" }
    }

    template {
      metadata {
        labels = { app = "db" }
      }

      spec {
        container {
          name  = "db"
          image = "postgres:16"

          port {
            container_port = 5432
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.app_config.metadata[0].name
            }
          }

          env {
            name = "POSTGRES_PASSWORD"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.app_secrets.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          volume_mount {
            name       = "db-data"
            mount_path = "/var/lib/postgresql/data"
          }

          readiness_probe {
            exec {
              command = ["sh", "-c", "pg_isready -U $POSTGRES_USER -d $POSTGRES_DB"]
            }

            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 5
          }
        }

        volume {
          name = "db-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.db_data.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "db" {
  metadata {
    name = "db"
  }

  spec {
    selector = { app = "db" }

    port {
      port        = 5432
      target_port = 5432
    }
  }
}
