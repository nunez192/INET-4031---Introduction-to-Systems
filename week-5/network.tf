# Only web pods and the database exporter may connect to the database.
resource "kubernetes_network_policy_v1" "db_clients" {
  metadata {
    name = "db-clients"
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

      from {
        pod_selector {
          match_labels = { app = "db-exporter" }
        }
      }

      ports {
        port     = "5432"
        protocol = "TCP"
      }
    }
  }
}
