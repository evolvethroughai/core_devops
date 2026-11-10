variable "org_name" {
  type    = string
  default = "career2026"
}

variable "project_name" {
  type    = string
  default = "azure_hands"
}

variable "service_connection_name" {
  type    = string
  default = "azure-oidc-service-connection"
}

variable "subscription_id" {
  type        = string
  description = "The target Azure subscription ID"
  default     = "ff54df86-5dd4-4938-8bb2-a2ad33102314"
}
