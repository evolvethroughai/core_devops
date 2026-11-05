# 1. Resource Group for Terraform State
resource "azurerm_resource_group" "state_rg" {
  name     = "rg-terraform-state-dev"
  location = "East US"
}

# 2. Random suffix for globally unique storage account name
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 3. Storage Account & Container for Remote State Locking
resource "azurerm_storage_account" "state_sa" {
  name                            = "sttfstate${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.state_rg.name
  location                        = azurerm_resource_group.state_rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "state_container" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state_sa.id
  container_access_type = "private"
}

# 4. Entra ID App Registration for Passwordless OIDC Auth
resource "azuread_application" "oidc_app" {
  display_name = "app-azure-devops-oidc"
}

resource "azuread_service_principal" "oidc_sp" {
  client_id = azuread_application.oidc_app.client_id
}

# 5. Assign Contributor Role to the Service Principal
data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "contrib" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.oidc_sp.object_id
}

# 6. Establish OIDC Federated Credential with Azure DevOps
resource "azuread_application_federated_identity_credential" "oidc_cred" {
  application_id = azuread_application.oidc_app.id
  display_name   = "azdevops-main-branch-federation"
  description    = "OIDC connection for Azure DevOps pipeline"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://vstoken.dev.azure.com/${var.org_name}"
  subject        = "sc://${var.org_name}/${var.project_name}/${var.service_connection_name}"
}

output "storage_account_name" {
  value = azurerm_storage_account.state_sa.name
}
