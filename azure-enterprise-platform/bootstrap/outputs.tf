#this is the output for the storage account name created in the bootstrap module
output "storage_account_name" {
  value = azurerm_storage_account.state_sa.name
}
