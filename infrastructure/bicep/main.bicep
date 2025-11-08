@description('The name of the resource group')
param resourceGroupName string = 'rg-csom-platform-prod'

@description('The location for all resources')
param location string = 'westeurope'

@description('AKS cluster name')
param aksClusterName string = 'aks-csom-platform-prod'

@description('PostgreSQL server name')
param postgresServerName string = 'psql-csom-platform-prod'

@description('PostgreSQL admin username')
param postgresAdminUsername string = 'csomadmin'

@description('PostgreSQL admin password')
@secure()
param postgresAdminPassword string

@description('ACR name')
param acrName string = 'acrcsomplatform'

@description('Key Vault name')
param keyVaultName string = 'kv-csom-platform-prod'

@description('Service Bus namespace name')
param serviceBusNamespaceName string = 'sb-csom-platform-prod'

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

// Azure Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    accessPolicies: []
  }
}

// PostgreSQL Flexible Server
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: postgresServerName
  location: location
  sku: {
    name: 'Standard_B2s'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: postgresAdminUsername
    administratorLoginPassword: postgresAdminPassword
    version: '15'
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    network: {
      publicNetworkAccess: 'Disabled'
    }
  }
}

// Service Bus Namespace
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Premium'
    tier: 'Premium'
  }
}

// Service Bus Topics
resource orderEventsTopic 'Microsoft.ServiceBus/namespaces/topics@2022-01-01-preview' = {
  parent: serviceBusNamespace
  name: 'order-events'
  properties: {
    maxSizeInMegabytes: 5120
    defaultMessageTimeToLive: 'P7D'
  }
}

resource paymentEventsTopic 'Microsoft.ServiceBus/namespaces/topics@2022-01-01-preview' = {
  parent: serviceBusNamespace
  name: 'payment-events'
  properties: {
    maxSizeInMegabytes: 5120
    defaultMessageTimeToLive: 'P7D'
  }
}

resource notificationEventsTopic 'Microsoft.ServiceBus/namespaces/topics@2022-01-01-preview' = {
  parent: serviceBusNamespace
  name: 'notification-events'
  properties: {
    maxSizeInMegabytes: 5120
    defaultMessageTimeToLive: 'P7D'
  }
}

resource gdprEventsTopic 'Microsoft.ServiceBus/namespaces/topics@2022-01-01-preview' = {
  parent: serviceBusNamespace
  name: 'gdpr-events'
  properties: {
    maxSizeInMegabytes: 5120
    defaultMessageTimeToLive: 'P7D'
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'csom-platform-insights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

// Outputs
output acrLoginServer string = acr.properties.loginServer
output keyVaultUri string = keyVault.properties.vaultUri
output postgresFqdn string = postgresServer.properties.fullyQualifiedDomainName
output serviceBusConnectionString string = 'Connection string should be retrieved from Azure Portal'
output appInsightsConnectionString string = appInsights.properties.ConnectionString

