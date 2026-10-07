variable "postgres_user" {
  type        = string
  description = "Postgres username the app connects as"

  validation {
    condition     = var.postgres_user != "replace-me"
    error_message = "Set postgres_user in terraform.tfvars, it is still the replace-me placeholder."
  }
}

variable "postgres_password" {
  type        = string
  description = "Postgres password for that user"
  sensitive   = true

  validation {
    condition     = var.postgres_password != "replace-me" && length(var.postgres_password) >= 16
    error_message = "Set postgres_password in terraform.tfvars to a real value of at least 16 characters, not the replace-me placeholder."
  }
}

variable "postgres_db" {
  type        = string
  description = "Name of the Postgres database the app uses"

  validation {
    condition     = var.postgres_db != "replace-me"
    error_message = "Set postgres_db in terraform.tfvars, it is still the replace-me placeholder."
  }
}

variable "flask_secret_key" {
  type        = string
  description = "Secret key Flask uses to sign session cookies"
  sensitive   = true

  validation {
    condition     = var.flask_secret_key != "replace-me" && length(var.flask_secret_key) >= 16
    error_message = "Set flask_secret_key in terraform.tfvars to a real value of at least 16 characters, not the replace-me placeholder."
  }
}
