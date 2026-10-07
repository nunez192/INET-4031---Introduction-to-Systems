output "port_forward_command" {
  description = "Run this in a second terminal to reach the app at http://localhost:8080"
  value       = "kubectl port-forward --address 0.0.0.0 service/${kubernetes_service_v1.web.metadata[0].name} 8080:${kubernetes_service_v1.web.spec[0].port[0].port}"
}
