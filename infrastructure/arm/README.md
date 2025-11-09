# ARM Templates Infrastructure as Code

This directory contains Azure Resource Manager (ARM) template files for deploying the Azure infrastructure for the Customer Service & Order Management Platform.

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and configured
- Azure subscription with appropriate permissions
- Azure service principal with Contributor role (for CI/CD)

## Quick Start

### 1. Configure Azure Authentication

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "Your-Subscription-Name"

# Verify
az account show
```

### 2. Create Resource Group

```bash
# Create resource group
az group create \
  --name rg-csom-platform-prod \
  --location westeurope
```

### 3. Configure Parameters

Edit `azuredeploy.parameters.json` and update parameter values:

```json
{
  "parameters": {
    "postgresAdminPassword": {
      "value": "YourSecurePassword123!"
    },
    "acrName": {
      "value": "acrcsomplatform"
    }
  }
}
```

**Note**: For production, use Key Vault references for sensitive parameters (see example in `azuredeploy.parameters.json`).

### 4. Validate Template

```bash
# Validate template
az deployment group validate \
  --resource-group rg-csom-platform-prod \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json
```

### 5. Deploy Template

```bash
# Deploy template
az deployment group create \
  --resource-group rg-csom-platform-prod \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json \
  --name csom-platform-deployment
```

### 6. View Outputs

```bash
# View deployment outputs
az deployment group show \
  --resource-group rg-csom-platform-prod \
  --name csom-platform-deployment \
  --query properties.outputs

# View specific output
az deployment group show \
  --resource-group rg-csom-platform-prod \
  --name csom-platform-deployment \
  --query properties.outputs.acrLoginServer.value
```

## Configuration Files

- **azuredeploy.json** - Main ARM template with all resource definitions
- **azuredeploy.parameters.json** - Parameter values file (customize for your environment)
- **README.md** - This file

## Resources Created

This ARM template creates the following Azure resources:

- **Azure Container Registry (ACR)** - Docker image storage
- **Azure Key Vault** - Secrets management
- **PostgreSQL Flexible Server** - Database server
- **Azure Service Bus** - Message broker with topics (order-events, payment-events, notification-events, gdpr-events)
- **Application Insights** - Application monitoring
- **Azure Redis Cache** - In-memory cache
- **Azure Functions** - Serverless compute for housekeeping jobs
- **Azure Storage Account** - For Functions and Blob Storage
- **Blob Storage Containers** - Archive, audit-logs, gdpr-data, customer-documents

**Note**: Blob Storage lifecycle management policies are not included in this ARM template due to complexity. Configure lifecycle management policies via Azure CLI or Azure Portal after deployment. See the [Bicep template](../bicep/main.bicep) or [Terraform configuration](../terraform/main.tf) for automated lifecycle management setup.

## Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `resourceGroupName` | Resource group name | `rg-csom-platform-prod` | No |
| `location` | Azure region | `westeurope` | No |
| `postgresAdminPassword` | PostgreSQL admin password | - | Yes |
| `acrName` | ACR name | `acrcsomplatform` | No |
| `keyVaultName` | Key Vault name | `kv-csom-platform-prod` | No |
| `redisCacheName` | Redis Cache name | `redis-csom-platform-prod` | No |
| `functionsAppName` | Functions App name | `func-csom-platform-prod` | No |
| `blobStorageAccountName` | Blob Storage account name | `stcsomarchiveprod` | No |

## Key Vault Integration

For production deployments, use Key Vault references for sensitive parameters:

```json
{
  "postgresAdminPassword": {
    "reference": {
      "keyVault": {
        "id": "/subscriptions/{subscription-id}/resourceGroups/rg-csom-platform-prod/providers/Microsoft.KeyVault/vaults/kv-csom-platform-prod"
      },
      "secretName": "postgres-admin-password"
    }
  }
}
```

## Common Commands

```bash
# Validate template
az deployment group validate \
  --resource-group rg-csom-platform-prod \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json

# Deploy template
az deployment group create \
  --resource-group rg-csom-platform-prod \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json

# Check deployment status
az deployment group list \
  --resource-group rg-csom-platform-prod \
  --query "[?name=='csom-platform-deployment']"

# View deployment outputs
az deployment group show \
  --resource-group rg-csom-platform-prod \
  --name csom-platform-deployment \
  --query properties.outputs

# Delete deployment (does not delete resources)
az deployment group delete \
  --resource-group rg-csom-platform-prod \
  --name csom-platform-deployment
```

## What-If Deployment

Preview changes before deploying:

```bash
# Preview changes
az deployment group what-if \
  --resource-group rg-csom-platform-prod \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json
```

## Incremental vs Complete Deployment

By default, ARM templates use **incremental** deployment mode:

```bash
# Incremental deployment (default)
az deployment group create \
  --resource-group rg-csom-platform-prod \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json \
  --mode Incremental

# Complete deployment (removes resources not in template)
az deployment group create \
  --resource-group rg-csom-platform-prod \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json \
  --mode Complete
```

## Troubleshooting

### Deployment Failures

```bash
# View deployment operations
az deployment operation group list \
  --resource-group rg-csom-platform-prod \
  --name csom-platform-deployment

# View specific operation error
az deployment operation group show \
  --resource-group rg-csom-platform-prod \
  --name csom-platform-deployment \
  --operation-ids {operation-id}
```

### Resource Name Conflicts

Azure resource names must be globally unique. If you get name conflicts:

1. Update parameter values in `azuredeploy.parameters.json`
2. Use different names that are still valid
3. Re-run deployment

### Validation Errors

```bash
# Validate template syntax
az deployment group validate \
  --resource-group rg-csom-platform-prod \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json
```

## CI/CD Integration

### Azure DevOps

```yaml
# azure-pipelines.yml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: AzureResourceManagerTemplateDeployment@3
    inputs:
      deploymentScope: 'Resource Group'
      azureResourceManagerConnection: 'Azure-Service-Connection'
      subscriptionId: '$(AZURE_SUBSCRIPTION_ID)'
      action: 'Create Or Update Resource Group'
      resourceGroupName: 'rg-csom-platform-prod'
      location: 'West Europe'
      templateLocation: 'Linked artifact'
      csmFile: 'infrastructure/arm/azuredeploy.json'
      csmParametersFile: 'infrastructure/arm/azuredeploy.parameters.json'
      deploymentMode: 'Incremental'
```

### GitHub Actions

```yaml
# .github/workflows/arm-deploy.yml
name: ARM Template Deployment
on:
  push:
    branches: [main]
    paths:
      - 'infrastructure/arm/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy ARM Template
        uses: azure/arm-deploy@v1
        with:
          subscriptionId: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          resourceGroupName: rg-csom-platform-prod
          template: infrastructure/arm/azuredeploy.json
          parameters: infrastructure/arm/azuredeploy.parameters.json
```

### GitLab CI/CD

```yaml
# .gitlab-ci.yml
deploy_arm:
  stage: deploy
  image: mcr.microsoft.com/azure-cli:latest
  before_script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
  script:
    - az deployment group create
        --resource-group rg-csom-platform-prod
        --template-file infrastructure/arm/azuredeploy.json
        --parameters @infrastructure/arm/azuredeploy.parameters.json
  only:
    - main
```

## Best Practices

1. **Use Parameters** - Never hardcode values in template
2. **Use Key Vault** - Store secrets in Key Vault and reference them
3. **Validate First** - Always validate template before deploying
4. **Use What-If** - Preview changes before deploying
5. **Version Control** - Commit templates to version control
6. **Tag Resources** - Use consistent tagging strategy
7. **Incremental Mode** - Use incremental deployment mode (default)
8. **Review Outputs** - Review deployment outputs for connection strings and endpoints

## Comparison with Bicep and Terraform

This ARM template is equivalent to:
- **Bicep**: `../bicep/main.bicep`
- **Terraform**: `../terraform/main.tf`

All three create the same Azure resources. Choose based on your team's preferences:

- **ARM Templates**: JSON-based, native Azure, widely supported
- **Bicep**: More readable, compiles to ARM, Azure-native
- **Terraform**: HCL syntax, multi-cloud, extensive ecosystem

See [INFRASTRUCTURE_AS_CODE_COMPARISON.md](../../INFRASTRUCTURE_AS_CODE_COMPARISON.md) for detailed comparison.

## Additional Resources

- [ARM Template Documentation](https://docs.microsoft.com/azure/azure-resource-manager/templates/)
- [ARM Template Functions](https://docs.microsoft.com/azure/azure-resource-manager/templates/template-functions)
- [ARM Template Best Practices](https://docs.microsoft.com/azure/azure-resource-manager/templates/best-practices)
- [Azure Quickstart Templates](https://github.com/Azure/azure-quickstart-templates)

## Support

For issues or questions:
- Review ARM template documentation
- Check Azure deployment logs
- Review error messages
- Contact the DevOps team

---

**Note**: Always validate and preview changes before deploying to production infrastructure.

