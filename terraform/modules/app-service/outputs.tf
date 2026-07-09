# Cet output est utilisé dans outputs.tf racine pour construire l'URL

output "default_hostname" {
  value = azurerm_linux_web_app.app.default_hostname
}
