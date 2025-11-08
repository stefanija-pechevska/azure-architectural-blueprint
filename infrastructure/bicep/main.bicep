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

@description('Redis Cache name')
param redisCacheName string = 'redis-csom-platform-prod'

@description('Azure Functions App name')
param functionsAppName string = 'func-csom-platform-prod'

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

// Redis Cache
resource redisCache 'Microsoft.Cache/redis@2023-08-01' = {
  name: redisCacheName
  location: location
  properties: {
    sku: {
      name: 'Standard'
      family: 'C'
      capacity: 1
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    redisConfiguration: {
      maxmemoryReserved: '50'
      maxmemoryPolicy: 'allkeys-lru'
    }
  }
}

// Storage Account for Azure Functions
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${toLower(functionsAppName)}stor'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// App Service Plan for Azure Functions
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${functionsAppName}-plan'
  location: location
  kind: 'functionapp'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
}

// Azure Functions App
resource functionsApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionsAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionsAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'java'
        }
        {
          name: 'POSTGRES_HOST'
          value: postgresServer.properties.fullyQualifiedDomainName
        }
        {
          name: 'POSTGRES_USER'
          value: postgresAdminUsername
        }
        {
          name: 'REDIS_CACHE_HOST'
          value: '${redisCache.properties.hostName}'
        }
        {
          name: 'REDIS_CACHE_PORT'
          value: string(redisCache.properties.port)
        }
        {
          name: 'SERVICE_BUS_CONNECTION_STRING'
          value: 'Connection string should be set from Key Vault'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
      ]
      javaVersion: '17'
    }
    httpsOnly: true
  }
}

// Outputs
output acrLoginServer string = acr.properties.loginServer
output keyVaultUri string = keyVault.properties.vaultUri
output postgresFqdn string = postgresServer.properties.fullyQualifiedDomainName
output serviceBusConnectionString string = 'Connection string should be retrieved from Azure Portal'
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output redisCacheHostName string = redisCache.properties.hostName
output redisCachePort string = string(redisCache.properties.port)
output redisCachePrimaryKey string = redisCache.listKeys().primaryKey
output functionsAppName string = functionsApp.name
output functionsAppUrl string = 'https://${functionsApp.properties.defaultHostName}'

