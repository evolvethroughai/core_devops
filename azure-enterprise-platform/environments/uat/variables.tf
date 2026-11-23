variable "subscription_id" {
  type        = string
  description = "Target Azure subscription ID for UAT"
  default     = "ff54df86-5dd4-4938-8bb2-a2ad33102314"
}

variable "location" {
  type        = string
  description = "Primary Azure region for UAT resources"
  default     = "East US"
}

variable "secondary_location" {
  type        = string
  description = "Secondary DR Azure region for passive AKS cluster"
  default     = "West US 2"
}

variable "app_rg_name" {
  type        = string
  description = "Resource group name for UAT network, storage, key vault, and monitoring"
  default     = "rg-uat-app-resources"
}

variable "compute_rg_name" {
  type        = string
  description = "Resource group name for UAT ACR and AKS clusters"
  default     = "rg-uat-compute-gitops"
}

variable "storage_account_name" {
  type        = string
  description = "Globally unique storage account name"
  default     = "stappuat987654"
}

variable "key_vault_name" {
  type        = string
  description = "Globally unique Key Vault name"
  default     = "kv-uat-ent-987654"
}

variable "log_analytics_workspace_name" {
  type        = string
  description = "Log Analytics workspace name"
  default     = "law-uat-ent-eastus"
}

variable "acr_name" {
  type        = string
  description = "Globally unique Azure Container Registry name"
  default     = "acruatent987654"
}

variable "aks_cluster_name_prefix" {
  type        = string
  description = "Prefix for primary and secondary AKS cluster names"
  default     = "aks-uat-ent"
}

# variable "argocd_namespace" {
#   type        = string
#   description = "Kubernetes namespace for ArgoCD"
#   default     = "argocd"
# }
