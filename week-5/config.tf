resource "kubernetes_config_map_v1" "app_config" {
  metadata {
    name = "app-config"
  }

  data = {
    POSTGRES_USER = var.postgres_user
    POSTGRES_DB   = var.postgres_db
  }
}

resource "kubernetes_secret_v1" "app_secrets" {
  metadata {
    name = "app-secrets"
  }

  data = {
    POSTGRES_PASSWORD = var.postgres_password
    FLASK_SECRET_KEY  = var.flask_secret_key
  }
}
