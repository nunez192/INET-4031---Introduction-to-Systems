# Only the web pods may open connections to the database pods.
resource "kubernetes_network_policy_v1" "db_from_web_only" {
  metadata {
    name = "db-from-web-only"
  }

  spec {
    pod_selector {
      match_labels = { app = "db" }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = { app = "web" }
        }
      }

      ports {
        port     = "5432"
        protocol = "TCP"
      }
    }
  }
}
