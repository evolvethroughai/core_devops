variable "org_name" {
  type    = string
  default = "aidevopscore"
}

variable "project_name" {
  type    = string
  default = "core_devops"
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
