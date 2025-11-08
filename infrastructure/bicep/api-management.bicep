@description('API Management instance name')
param apimName string = 'apim-csom-platform-prod'

@description('Resource group name')
param resourceGroupName string = 'rg-csom-platform-prod'

@description('Location')
param location string = 'westeurope'

@description('Publisher email')
param publisherEmail string = 'admin@company.com'

@description('Publisher name')
param publisherName string = 'CSOM Platform'

@description('SKU tier')
@allowed(['Developer', 'Basic', 'Standard', 'Premium'])
param skuTier string = 'Standard'

@description('SKU capacity')
param skuCapacity int = 1

@description('AKS service endpoints')
param aksServiceEndpoints object = {
  orderService: 'http://order-service:80'
  productService: 'http://product-service:80'
  customerService: 'http://customer-service:80'
  paymentService: 'http://payment-service:80'
  notificationService: 'http://notification-service:80'
  auditService: 'http://audit-service:80'
}

// API Management instance
resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: skuTier
    capacity: skuCapacity
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    notificationSenderEmail: publisherEmail
    publicNetworkAccess: 'Enabled'
    virtualNetworkType: 'None'
    apiVersionConstraint: {}
    disableGateway: false
    developerPortalStatus: 'Enabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Outputs
output apimServiceUrl string = 'https://${apiManagement.properties.gatewayUrl}'
output apimManagementUrl string = 'https://${apiManagement.properties.managementApiUrl}'
output apimPortalUrl string = 'https://${apiManagement.properties.developerPortalUrl}'
output apimName string = apiManagement.name

