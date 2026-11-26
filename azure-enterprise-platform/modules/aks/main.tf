variable "cluster_name_prefix" { type = string }
variable "resource_group_name" { type = string }
variable "primary_location" { type = string }
variable "secondary_location" { type = string }
variable "acr_id" { type = string }

resource "azurerm_kubernetes_cluster" "primary_active" {
  name                = "${var.cluster_name_prefix}-primary-aks"
  location            = var.primary_location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.cluster_name_prefix}-pri"
  oidc_issuer_enabled = true

  default_node_pool {
    name       = "systempool"
    node_count = 1
    vm_size    = "Standard_D2s_v7" # 2 vCPUs, 8 GB (was standard_d128alds_v7 = 128 vCPUs)
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    failover_role = "active"
    region_tier   = "primary"
  }
}

resource "azurerm_kubernetes_cluster" "secondary_passive" {
  name                = "${var.cluster_name_prefix}-secondary-aks"
  location            = var.secondary_location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.cluster_name_prefix}-sec"
  oidc_issuer_enabled = true

  default_node_pool {
    name       = "systempool"
    node_count = 1
    vm_size    = "Standard_D2s_v7" # 2 vCPUs, 8 GB (was standard_b16as_v2 = 16 vCPUs)
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    failover_role = "passive"
    region_tier   = "secondary"
  }
}

resource "azurerm_role_assignment" "primary_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.primary_active.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "secondary_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.secondary_passive.kubelet_identity[0].object_id
}

output "primary_aks_name" { value = azurerm_kubernetes_cluster.primary_active.name }
output "secondary_aks_name" { value = azurerm_kubernetes_cluster.secondary_passive.name }

output "primary_kube_config_host" {
  value     = azurerm_kubernetes_cluster.primary_active.kube_config[0].host
  sensitive = true
}

output "primary_kube_config_client_certificate" {
  value     = azurerm_kubernetes_cluster.primary_active.kube_config[0].client_certificate
  sensitive = true
}

output "primary_kube_config_client_key" {
  value     = azurerm_kubernetes_cluster.primary_active.kube_config[0].client_key
  sensitive = true
}

output "primary_kube_config_cluster_ca_certificate" {
  value     = azurerm_kubernetes_cluster.primary_active.kube_config[0].cluster_ca_certificate
  sensitive = true
}

output "primary_kube_config" {
  value     = azurerm_kubernetes_cluster.primary_active.kube_config_raw
  sensitive = true
}

output "secondary_kube_config" {
  value     = azurerm_kubernetes_cluster.secondary_passive.kube_config_raw
  sensitive = true
}
