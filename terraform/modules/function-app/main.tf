terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Documentation : https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account

# Create a storage account dedicated to the Function App (not included in the storage module)
resource "azurerm_storage_account" "fn_storage" {
  name                     = "stfn${replace(var.owner, "-", "")}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  identity {
    type = "SystemAssigned"
  }

  customer_managed_key {
    key_vault_key_id          = var.key_vault_key_id
    user_assigned_identity_id = null
  }

  tags = merge(var.tags, { purpose = "function-storage" })
}

# Documentation : https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app

# Creation of the Linux Function App
resource "azurerm_linux_function_app" "fn" {
  name                       = "fn-${var.owner}-tf"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  service_plan_id            = var.service_plan_id
  storage_account_name       = azurerm_storage_account.fn_storage.name
  storage_account_access_key = azurerm_storage_account.fn_storage.primary_access_key
  https_only                 = true

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  tags = var.tags
}
