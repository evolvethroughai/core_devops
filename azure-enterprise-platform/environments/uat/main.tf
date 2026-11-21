terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "helm" {
  kubernetes = {
    host                   = module.uat_aks.primary_kube_config_host
    client_certificate     = base64decode(module.uat_aks.primary_kube_config_client_certificate)
    client_key             = base64decode(module.uat_aks.primary_kube_config_client_key)
    cluster_ca_certificate = base64decode(module.uat_aks.primary_kube_config_cluster_ca_certificate)
  }
}

resource "azurerm_resource_group" "uat" {
  name     = var.app_rg_name
  location = var.location
}

resource "azurerm_resource_group" "uat_compute" {
  name     = var.compute_rg_name
  location = var.location
}

module "uat_network" {
  source              = "../../modules/network"
  resource_group_name = azurerm_resource_group.uat.name
  location            = azurerm_resource_group.uat.location
}

module "uat_storage" {
  source                   = "../../modules/storage"
  storage_account_name     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.uat.name
  location                 = azurerm_resource_group.uat.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  pe_subnet_id             = module.uat_network.pe_subnet_id
  blob_dns_zone_id         = module.uat_network.blob_dns_zone_id
}

module "uat_key_vault" {
  source              = "../../modules/key_vault"
  key_vault_name      = var.key_vault_name
  resource_group_name = azurerm_resource_group.uat.name
  location            = azurerm_resource_group.uat.location
  pe_subnet_id        = module.uat_network.pe_subnet_id
  kv_dns_zone_id      = module.uat_network.kv_dns_zone_id
  storage_conn_string = module.uat_storage.primary_connection_string
}

module "uat_monitoring" {
  source              = "../../modules/monitoring"
  workspace_name      = var.log_analytics_workspace_name
  resource_group_name = azurerm_resource_group.uat.name
  location            = azurerm_resource_group.uat.location
  key_vault_id        = module.uat_key_vault.key_vault_id
  storage_account_id  = module.uat_storage.storage_account_id
}

module "uat_acr" {
  source              = "../../modules/acr"
  acr_name            = var.acr_name
  resource_group_name = azurerm_resource_group.uat_compute.name
  location            = azurerm_resource_group.uat_compute.location
}

module "uat_aks" {
  source              = "../../modules/aks"
  cluster_name_prefix = var.aks_cluster_name_prefix
  resource_group_name = azurerm_resource_group.uat_compute.name
  primary_location    = var.location
  secondary_location  = var.secondary_location
  acr_id              = module.uat_acr.acr_id
}

module "uat_gitops" {
  source = "../../modules/gitops"
}
