# ──────────────────────────────────────────────────────────────────────────────
# outputs.tf — Valeurs exposées après terraform apply
#
# Les outputs sont l'équivalent des `echo` à la fin de provision.sh.
# Complétez au fur et à mesure que vous créez les ressources.
# ──────────────────────────────────────────────────────────────────────────────

# App Service URL
output "app_service_url" {
  description = "URL publique de l'App Service"
  value       = "https://${module.app_service.default_hostname}"
}

# Function App URL
output "function_app_url" {
  description = "URL publique de la Function App"
  value       = "https://${module.function_app.default_hostname}"
}

# Container ACI FQDN
output "container_fqdn" {
  description = "FQDN public du container nginx"
  value       = "http://${module.container.fqdn}"
}

# Storage Account Name
output "storage_account_name" {
  description = "Nom du Storage Account"
  value       = module.storage.storage_account_name
}
