resource "kubernetes_deployment_v1" "web" {
  metadata {
    name   = "web"
    labels = { app = "web" }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "web" }
    }

    template {
      metadata {
        labels = { app = "web" }
      }

      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = "10001"
          run_as_group    = "10001"
        }

        container {
          name              = "web"
          image             = "docker.io/library/week-4-web:latest"
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 5000
          }

          security_context {
            allow_privilege_escalation = true

            capabilities {
              drop = ["ALL"]
            }
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
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

          env {
            name = "FLASK_SECRET_KEY"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.app_secrets.metadata[0].name
                key  = "FLASK_SECRET_KEY"
              }
            }
          }

          readiness_probe {
            exec {
              command = ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:5000')"]
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

resource "kubernetes_service_v1" "web" {
  metadata {
    name = "web"
  }

  spec {
    selector = { app = "web" }

    port {
      port        = 8080
      target_port = 5000
    }
  }
}
