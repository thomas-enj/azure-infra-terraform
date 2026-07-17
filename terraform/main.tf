# ──────────────────────────────────────────────────────────────────────────────
# main.tf — Ressources Azure à provisionner avec Terraform
# ──────────────────────────────────────────────────────────────────────────────

# ── Tags communs à toutes les ressources ──────────────────────────────────────
# Ces tags sont mergés automatiquement dans chaque module via var.tags

locals {
  tags = merge(
    {
      managed_by  = "terraform"
      environment = "tp"
      owner       = var.owner
    },
    var.tags
  )
}

# ── Data sources ──────────────────────────────────────────────────────────────
# Un data source LIT une ressource existante sans la créer.

# Resource Group pré-créé par le formateur — ne jamais le gérer en Terraform
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Plan App Service partagé (dans un Resource Group séparé)
data "azurerm_service_plan" "shared" {
  name                = var.shared_plan_name
  resource_group_name = var.shared_rg_name
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "cmk" {
  name                     = "kv${replace(var.owner, "-", "")}tf"
  location                 = var.location
  resource_group_name      = data.azurerm_resource_group.rg.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  soft_delete_enabled      = true
  purge_protection_enabled = false
  access_policy            = []
}

resource "azurerm_key_vault_key" "cmk" {
  name         = "key-${replace(var.owner, "-", "")}"
  key_vault_id = azurerm_key_vault.cmk.id
  key_type     = "RSA"
  key_size     = 2048
}

# ── Storage ───────────────────────────────────────────────────────────────────

module "storage" {
  source              = "./modules/storage"
  owner               = var.owner # passage des variables
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  tags                = local.tags
  key_vault_key_id    = azurerm_key_vault_key.cmk.id
}

# ── App Service ───────────────────────────────────────────────────────────────

module "app_service" {
  source              = "./modules/app-service"
  owner               = var.owner
  resource_group_name = data.azurerm_resource_group.rg.name
  service_plan_id     = data.azurerm_service_plan.shared.id
  tags                = local.tags
}

# ── Function App ──────────────────────────────────────────────────────────────

module "function_app" {
  source              = "./modules/function-app"
  owner               = var.owner
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  service_plan_id     = data.azurerm_service_plan.shared.id
  tags                = local.tags
  key_vault_key_id    = azurerm_key_vault_key.cmk.id
}

resource "azurerm_key_vault_access_policy" "storage_account" {
  key_vault_id = azurerm_key_vault.cmk.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = module.storage.storage_account_principal_id

  key_permissions = [
    "get",
    "wrapKey",
    "unwrapKey",
  ]
}

resource "azurerm_key_vault_access_policy" "function_app_storage_account" {
  key_vault_id = azurerm_key_vault.cmk.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = module.function_app.storage_account_principal_id

  key_permissions = [
    "get",
    "wrapKey",
    "unwrapKey",
  ]
}

# ── Container Instance ────────────────────────────────────────────────────────

module "container" {
  source              = "./modules/container"
  owner               = var.owner
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  tags                = local.tags
}

# ── Network (Étape 7) ─────────────────────────────────────────────────────────

module "network" {
  source              = "./modules/network"
  owner               = var.owner
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  tags                = local.tags
}
