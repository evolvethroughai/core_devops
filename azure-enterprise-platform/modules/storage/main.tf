resource "azurerm_storage_account" "this" {
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

variable "storage_account_name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "account_tier" { type = string }
variable "account_replication_type" { type = string }

output "storage_account_id" {
  value = azurerm_storage_account.this.id
}
