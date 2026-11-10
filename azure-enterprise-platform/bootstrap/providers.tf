terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-test"
    storage_account_name = "sttfstate123jm70nk"
    container_name       = "tfstate"
    key                  = "bootstrap.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "ff54df86-5dd4-4938-8bb2-a2ad33102314"
}

provider "azuread" {}
