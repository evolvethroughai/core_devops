variable "workspace_name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "key_vault_id" { type = string }
variable "storage_account_id" { type = string }

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "kv_diag" {
  name                       = "diag-kv-to-law"
  target_resource_id         = var.key_vault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "storage_diag" {
  name                       = "diag-storage-to-law"
  target_resource_id         = var.storage_account_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  metric {
    category = "Transaction"
    enabled  = true
  }
}

output "log_analytics_workspace_id" { value = azurerm_log_analytics_workspace.this.id }
