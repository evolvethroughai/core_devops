terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  subscription_id = "ff54df86-5dd4-4938-8bb2-a2ad33102314"
}

resource "azurerm_resource_group" "uat" {
  name     = "rg-uat-app-resources"
  location = "East US"
}

module "uat_network" {
  source              = "../../modules/network"
  resource_group_name = azurerm_resource_group.uat.name
  location            = azurerm_resource_group.uat.location
}

module "uat_storage" {
  source                   = "../../modules/storage"
  storage_account_name     = "stappuat987654"
  resource_group_name      = azurerm_resource_group.uat.name
  location                 = azurerm_resource_group.uat.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  pe_subnet_id             = module.uat_network.pe_subnet_id
  blob_dns_zone_id         = module.uat_network.blob_dns_zone_id
}

module "uat_key_vault" {
  source              = "../../modules/key_vault"
  key_vault_name      = "kv-uat-ent-987654"
  resource_group_name = azurerm_resource_group.uat.name
  location            = azurerm_resource_group.uat.location
  storage_conn_string = module.uat_storage.primary_connection_string
}
