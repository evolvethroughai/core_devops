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

module "uat_storage" {
  count                    = 1
  source                   = "../../modules/storage"
  storage_account_name     = "stappuat987654"
  resource_group_name      = azurerm_resource_group.uat.name
  location                 = azurerm_resource_group.uat.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
