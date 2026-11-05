# A small program that reads numbers from Postgres and publishes them for Prometheus.
resource "kubernetes_deployment_v1" "db_exporter" {
  metadata {
    name   = "db-exporter"
    labels = { app = "db-exporter" }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "db-exporter" }
    }

    template {
      metadata {
        labels = { app = "db-exporter" }
      }

      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = "65534"
          run_as_group    = "65534"
        }

        container {
          name  = "db-exporter"
          image = "quay.io/prometheuscommunity/postgres-exporter:v0.20.1"

          port {
            container_port = 9187
          }

          security_context {
            allow_privilege_escalation = false

            capabilities {
              drop = ["ALL"]
            }
          }

          resources {
            requests = {
              cpu    = "10m"
              memory = "32Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          env {
            name = "POSTGRES_DB"

            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.app_config.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }

          env {
            name  = "DATA_SOURCE_URI"
            value = "db:5432/$(POSTGRES_DB)?sslmode=disable"
          }

          env {
            name = "DATA_SOURCE_USER"

            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.app_config.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "DATA_SOURCE_PASS"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.app_secrets.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = "9187"
            }

            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 5
          }
        }
      }
    }
  }

  depends_on = [kubernetes_deployment_v1.db]
}

# The two annotations tell Prometheus to scrape this Service.
resource "kubernetes_service_v1" "db_exporter" {
  metadata {
    name = "db-exporter"

    annotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/port"   = "9187"
    }
  }

  spec {
    selector = { app = "db-exporter" }

    port {
      port        = 9187
      target_port = 9187
    }
  }
}
