terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Documentation : https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app

resource "azurerm_linux_web_app" "app" {
  name                    = "app-${var.owner}-tf"
  resource_group_name     = var.resource_group_name
  location                = data.azurerm_service_plan.plan.location
  service_plan_id         = var.service_plan_id
  https_only              = true
  client_certificate_mode = "Required"

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version               = "1.2"
    health_check_path                 = "/"
    health_check_eviction_time_in_min = 10
    http2_enabled                     = true
    ftps_state                        = "FtpsOnly"
    application_stack {
      python_version = "3.11"
    }
  }

  logs {
    application_logs {
      file_system_level = "Information"
    }

    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }

  auth_settings {
    enabled                       = true
    unauthenticated_client_action = "RedirectToLoginPage"
  }

  tags = var.tags
}

# Data source to retrieve the location of the service plan from its ID
data "azurerm_service_plan" "plan" {
  name                = split("/", var.service_plan_id)[8]
  resource_group_name = split("/", var.service_plan_id)[4]
}
