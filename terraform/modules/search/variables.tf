variable "name" {
  description = "Name of the search service"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "sku" {
  description = "SKU for the search service"
  type        = string
  default     = "free"

  validation {
    condition     = contains(["free", "basic", "standard", "standard2", "standard3", "storage_optimized_l1", "storage_optimized_l2"], var.sku)
    error_message = "SKU must be one of: free, basic, standard, standard2, standard3, storage_optimized_l1, storage_optimized_l2."
  }
}

variable "partition_count" {
  description = "Number of partitions (data divisions)"
  type        = number
  default     = 1
}

variable "replica_count" {
  description = "Number of replicas (for HA)"
  type        = number
  default     = 1
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "semantic_search_sku" {
  description = "Semantic search SKU (free, standard)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
