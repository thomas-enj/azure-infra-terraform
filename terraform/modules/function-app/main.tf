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
  name                            = substr(lower(replace("stfn${replace(var.owner, "-", "")}", "-", "")), 0, 24)
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true

  blob_properties {
    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }

    versioning_enabled = true
  }

  queue_properties {
    logging {
      delete  = true
      read    = true
      write   = true
      version = "1.0"
    }
  }

  tags = merge(var.tags, { purpose = "function-storage" })
}

# Documentation : https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app

# Creation of the Linux Function App
resource "azurerm_linux_function_app" "fn" {
  name                          = "fn-${var.owner}-tf"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  service_plan_id               = var.service_plan_id
  storage_account_name          = azurerm_storage_account.fn_storage.name
  storage_account_access_key    = azurerm_storage_account.fn_storage.primary_access_key
  https_only                    = true
  public_network_access_enabled = false

  identity {
    type = "SystemAssigned"
  }

  site_config {
    ftps_state = "FtpsOnly"
    application_stack {
      python_version = "3.11"
    }
  }

  tags = var.tags
}
