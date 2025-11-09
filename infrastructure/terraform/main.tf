terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
  
  backend "azurerm" {
    # Configure backend in backend.tf or via environment variables
    # resource_group_name  = "rg-terraform-state"
    # storage_account_name = "stterraformstate"
    # container_name       = "tfstate"
    # key                  = "csom-platform.terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_deleted_keys_on_destroy = true
      recover_soft_deleted_keys          = true
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = true

  tags = var.tags
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = var.key_vault_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  soft_delete_retention_days      = 7
  purge_protection_enabled        = false

  tags = var.tags
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = var.postgres_server_name
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "15"
  administrator_login    = var.postgres_admin_username
  administrator_password = var.postgres_admin_password

  sku_name = "B_Standard_B2s"

  storage_mb = 32768

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  public_network_access_enabled = false

  tags = var.tags
}

# Service Bus Namespace
resource "azurerm_servicebus_namespace" "main" {
  name                = var.service_bus_namespace_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Premium"
  capacity            = 1

  tags = var.tags
}

# Service Bus Topics
resource "azurerm_servicebus_topic" "order_events" {
  name         = "order-events"
  namespace_id = azurerm_servicebus_namespace.main.id

  max_size_in_megabytes = 5120
  default_message_ttl   = "P7D"
}

resource "azurerm_servicebus_topic" "payment_events" {
  name         = "payment-events"
  namespace_id = azurerm_servicebus_namespace.main.id

  max_size_in_megabytes = 5120
  default_message_ttl   = "P7D"
}

resource "azurerm_servicebus_topic" "notification_events" {
  name         = "notification-events"
  namespace_id = azurerm_servicebus_namespace.main.id

  max_size_in_megabytes = 5120
  default_message_ttl   = "P7D"
}

resource "azurerm_servicebus_topic" "gdpr_events" {
  name         = "gdpr-events"
  namespace_id = azurerm_servicebus_namespace.main.id

  max_size_in_megabytes = 5120
  default_message_ttl   = "P7D"
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "csom-platform-insights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"

  tags = var.tags
}

# Redis Cache
resource "azurerm_redis_cache" "main" {
  name                = var.redis_cache_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
    maxmemory_reserved = 50
    maxmemory_policy   = "allkeys-lru"
  }

  tags = var.tags
}

# Storage Account for Azure Functions
resource "azurerm_storage_account" "functions" {
  name                     = lower("${var.functions_app_name}stor")
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = var.tags
}

# App Service Plan for Azure Functions
resource "azurerm_service_plan" "functions" {
  name                = "${var.functions_app_name}-plan"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"

  tags = var.tags
}

# Azure Functions App
resource "azurerm_linux_function_app" "main" {
  name                = var.functions_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.functions.id

  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key

  site_config {
    application_stack {
      java_version = "17"
    }
    always_on = false
  }

  app_settings = {
    "AzureWebJobsStorage"                         = azurerm_storage_account.functions.primary_connection_string
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING"    = azurerm_storage_account.functions.primary_connection_string
    "WEBSITE_CONTENTSHARE"                        = lower(var.functions_app_name)
    "FUNCTIONS_EXTENSION_VERSION"                 = "~4"
    "FUNCTIONS_WORKER_RUNTIME"                    = "java"
    "POSTGRES_HOST"                               = azurerm_postgresql_flexible_server.main.fqdn
    "POSTGRES_USER"                               = var.postgres_admin_username
    "REDIS_CACHE_HOST"                            = azurerm_redis_cache.main.hostname
    "REDIS_CACHE_PORT"                            = tostring(azurerm_redis_cache.main.port)
    "SERVICE_BUS_CONNECTION_STRING"               = "Connection string should be set from Key Vault"
    "BLOB_STORAGE_CONNECTION_STRING"              = "Connection string should be set from Key Vault"
    "APPINSIGHTS_INSTRUMENTATIONKEY"              = azurerm_application_insights.main.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING"       = azurerm_application_insights.main.connection_string
  }

  https_only = true

  tags = var.tags
}

# Storage Account for Archiving (Blob Storage)
resource "azurerm_storage_account" "archive" {
  name                     = lower(var.blob_storage_account_name)
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  access_tier              = "Hot"

  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  public_network_access_enabled = true

  tags = var.tags
}

# Blob Storage Containers
resource "azurerm_storage_container" "archive" {
  name                  = "archive"
  storage_account_name  = azurerm_storage_account.archive.name
  container_access_type = "private"

  metadata = {
    description = "Archived files and documents"
  }
}

resource "azurerm_storage_container" "audit_logs" {
  name                  = "audit-logs"
  storage_account_name  = azurerm_storage_account.archive.name
  container_access_type = "private"

  metadata = {
    description = "Archived audit logs for compliance"
  }
}

resource "azurerm_storage_container" "gdpr_data" {
  name                  = "gdpr-data"
  storage_account_name  = azurerm_storage_account.archive.name
  container_access_type = "private"

  metadata = {
    description = "GDPR export and anonymized data"
  }
}

resource "azurerm_storage_container" "customer_documents" {
  name                  = "customer-documents"
  storage_account_name  = azurerm_storage_account.archive.name
  container_access_type = "private"

  metadata = {
    description = "Customer documents and attachments"
  }
}

# Blob Storage Lifecycle Management Policy
resource "azurerm_storage_management_policy" "archive" {
  storage_account_id = azurerm_storage_account.archive.id

  rule {
    name    = "ArchiveToCoolAfter30Days"
    enabled = true
    filters {
      blob_types = ["blockBlob"]
      prefix_match = ["archive/"]
    }
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = 2555
      }
    }
  }

  rule {
    name    = "DeleteOldAuditLogs"
    enabled = true
    filters {
      blob_types = ["blockBlob"]
      prefix_match = ["audit-logs/"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 2555
      }
    }
  }
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

