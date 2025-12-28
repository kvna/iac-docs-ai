variable "name" {
  description = "Name of the OpenAI service"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region (must support OpenAI)"
  type        = string
}

variable "sku_name" {
  description = "SKU name (S0 for standard)"
  type        = string
  default     = "S0"
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "model_deployments" {
  description = "List of model deployments"
  type = list(object({
    name          = string
    model_name    = string
    model_version = string
    scale_type    = string
    capacity      = number
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
