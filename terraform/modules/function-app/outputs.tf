output "default_hostname" {
  value = azurerm_linux_function_app.fn.default_hostname
}

output "storage_account_principal_id" {
  value = azurerm_storage_account.fn_storage.identity[0].principal_id
}
