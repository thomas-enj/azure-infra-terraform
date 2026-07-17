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

# Creation of a storage account for the application
resource "azurerm_storage_account" "sa" {
  name                     = "st${replace(var.owner, "-", "")}tf"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  identity {
    type = "SystemAssigned"
  }

  encryption {
    services {
      blob { enabled = true }
      file { enabled = true }
      queue { enabled = true }
      table { enabled = true }
    }

    key_source       = "Microsoft.Keyvault"
    key_vault_key_id = var.key_vault_key_id
  }

  allow_nested_items_to_be_public = true # true pour permettre api-config public
  tags                            = var.tags
}

# Creation of a private storage container for API logs
resource "azurerm_storage_container" "api_logs" {
  name                  = "api-logs"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}

# Creation of a public storage container for API configuration
resource "azurerm_storage_container" "api_config" {
  name                  = "api-config"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "blob"
}
