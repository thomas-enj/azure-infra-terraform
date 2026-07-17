output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "storage_account_principal_id" {
  value = azurerm_storage_account.sa.identity[0].principal_id
}
