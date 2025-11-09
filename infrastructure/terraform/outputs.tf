output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "acr_login_server" {
  description = "Azure Container Registry login server"
  value       = azurerm_container_registry.main.login_server
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

output "postgres_fqdn" {
  description = "PostgreSQL server fully qualified domain name"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgres_host" {
  description = "PostgreSQL server hostname"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "service_bus_namespace_name" {
  description = "Service Bus namespace name"
  value       = azurerm_servicebus_namespace.main.name
}

output "service_bus_connection_string" {
  description = "Service Bus connection string (retrieve from Azure Portal or use Key Vault)"
  value       = "Connection string should be retrieved from Azure Portal or stored in Key Vault"
  sensitive   = true
}

output "app_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "redis_cache_hostname" {
  description = "Redis Cache hostname"
  value       = azurerm_redis_cache.main.hostname
}

output "redis_cache_port" {
  description = "Redis Cache port"
  value       = azurerm_redis_cache.main.port
}

output "redis_cache_primary_key" {
  description = "Redis Cache primary access key"
  value       = azurerm_redis_cache.main.primary_access_key
  sensitive   = true
}

output "functions_app_name" {
  description = "Azure Functions App name"
  value       = azurerm_linux_function_app.main.name
}

output "functions_app_url" {
  description = "Azure Functions App URL"
  value       = "https://${azurerm_linux_function_app.main.default_hostname}"
}

output "blob_storage_account_name" {
  description = "Blob Storage account name"
  value       = azurerm_storage_account.archive.name
}

output "blob_storage_primary_key" {
  description = "Blob Storage primary access key"
  value       = azurerm_storage_account.archive.primary_access_key
  sensitive   = true
}

output "blob_storage_connection_string" {
  description = "Blob Storage connection string"
  value       = azurerm_storage_account.archive.primary_connection_string
  sensitive   = true
}

output "blob_storage_containers" {
  description = "Blob Storage container names"
  value = {
    archive           = azurerm_storage_container.archive.name
    audit_logs        = azurerm_storage_container.audit_logs.name
    gdpr_data         = azurerm_storage_container.gdpr_data.name
    customer_documents = azurerm_storage_container.customer_documents.name
  }
}

