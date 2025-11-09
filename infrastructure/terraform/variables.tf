variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "rg-csom-platform-prod"
}

variable "location" {
  description = "The location for all resources"
  type        = string
  default     = "westeurope"
}

variable "aks_cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "aks-csom-platform-prod"
}

variable "postgres_server_name" {
  description = "PostgreSQL server name"
  type        = string
  default     = "psql-csom-platform-prod"
}

variable "postgres_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
  default     = "csomadmin"
  sensitive   = true
}

variable "postgres_admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.postgres_admin_password) >= 8
    error_message = "PostgreSQL admin password must be at least 8 characters long."
  }
}

variable "acr_name" {
  description = "ACR name"
  type        = string
  default     = "acrcsomplatform"
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.acr_name)) && length(var.acr_name) >= 5 && length(var.acr_name) <= 50
    error_message = "ACR name must be between 5 and 50 characters and contain only lowercase letters and numbers."
  }
}

variable "key_vault_name" {
  description = "Key Vault name"
  type        = string
  default     = "kv-csom-platform-prod"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.key_vault_name)) && length(var.key_vault_name) >= 3 && length(var.key_vault_name) <= 24
    error_message = "Key Vault name must be between 3 and 24 characters and contain only alphanumeric characters and hyphens."
  }
}

variable "service_bus_namespace_name" {
  description = "Service Bus namespace name"
  type        = string
  default     = "sb-csom-platform-prod"
}

variable "redis_cache_name" {
  description = "Redis Cache name"
  type        = string
  default     = "redis-csom-platform-prod"
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.redis_cache_name)) && length(var.redis_cache_name) >= 1 && length(var.redis_cache_name) <= 63
    error_message = "Redis Cache name must be between 1 and 63 characters and contain only lowercase letters and numbers."
  }
}

variable "functions_app_name" {
  description = "Azure Functions App name"
  type        = string
  default     = "func-csom-platform-prod"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.functions_app_name)) && length(var.functions_app_name) >= 2 && length(var.functions_app_name) <= 60
    error_message = "Functions App name must be between 2 and 60 characters and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "blob_storage_account_name" {
  description = "Blob Storage account name for archiving"
  type        = string
  default     = "stcsomarchiveprod"
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.blob_storage_account_name)) && length(var.blob_storage_account_name) >= 3 && length(var.blob_storage_account_name) <= 24
    error_message = "Storage account name must be between 3 and 24 characters and contain only lowercase letters and numbers."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "CSOM Platform"
    ManagedBy   = "Terraform"
  }
}

