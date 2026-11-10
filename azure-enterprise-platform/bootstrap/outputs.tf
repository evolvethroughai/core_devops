output "storage_account_name" {
  value = azurerm_storage_account.state_sa.name
}

output "client_id" {
  value = azuread_application.oidc_app.client_id
}
