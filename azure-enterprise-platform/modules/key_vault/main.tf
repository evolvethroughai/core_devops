variable "key_vault_name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "pe_subnet_id" { type = string }
variable "kv_dns_zone_id" { type = string }
variable "storage_conn_string" {
  type      = string
  sensitive = true
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                          = var.key_vault_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  purge_protection_enabled      = false
  soft_delete_retention_days    = 7
  enable_rbac_authorization     = true
  public_network_access_enabled = true
}

# Private Endpoint for Key Vault in UAT PE Subnet
resource "azurerm_private_endpoint" "kv_pe" {
  name                = "pe-${var.key_vault_name}-vault"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id

  private_service_connection {
    name                           = "psc-${var.key_vault_name}"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.kv_dns_zone_id]
  }
}

# User-Assigned Managed Identity for UAT App workloads
resource "azurerm_user_assigned_identity" "app_uami" {
  name                = "id-uat-app-kv-reader"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Grant current deployment identity permission to manage secrets
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Grant UAT App Managed Identity read-only secret access
resource "azurerm_role_assignment" "kv_secrets_user_app" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app_uami.principal_id
}

# Dynamically store the Storage Connection String inside Key Vault
resource "azurerm_key_vault_secret" "storage_secret" {
  name         = "uat-storage-connection-string"
  value        = var.storage_conn_string
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [
    azurerm_role_assignment.kv_secrets_officer,
    azurerm_private_endpoint.kv_pe
  ]
}

output "key_vault_id" { value = azurerm_key_vault.this.id }
output "key_vault_uri" { value = azurerm_key_vault.this.vault_uri }
output "app_identity_client_id" { value = azurerm_user_assigned_identity.app_uami.client_id }
