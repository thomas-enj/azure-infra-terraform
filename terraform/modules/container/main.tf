terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Documentation : https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_group

# Creation of the Azure Container Instance (ACI)
resource "azurerm_container_group" "aci" {
  name                = "aci-${var.owner}-tf"
  resource_group_name = var.resource_group_name
  location            = var.location
  ip_address_type     = "Public"
  dns_name_label      = "aci-${var.owner}-tf"
  os_type             = "Linux"

  container {
    name   = "nginx"
    image  = "nginx:1.25"
    cpu    = 0.5
    memory = 0.5

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  tags = var.tags
}
