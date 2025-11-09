# Terraform Infrastructure as Code

This directory contains Terraform configuration files for deploying the Azure infrastructure for the Customer Service & Order Management Platform.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and configured
- Azure subscription with appropriate permissions
- Azure service principal with Contributor role (for CI/CD)

## Quick Start

### 1. Install Terraform

```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Windows
# Download from https://www.terraform.io/downloads
```

### 2. Configure Azure Authentication

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "Your-Subscription-Name"

# Verify
az account show
```

### 3. Configure Variables

```bash
# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# IMPORTANT: Update postgres_admin_password and other sensitive values
```

### 4. Initialize Terraform

```bash
# Initialize Terraform and download providers
terraform init
```

### 5. Plan Deployment

```bash
# Review what will be created
terraform plan
```

### 6. Apply Configuration

```bash
# Deploy infrastructure
terraform apply

# Type 'yes' when prompted, or use -auto-approve flag
terraform apply -auto-approve
```

### 7. View Outputs

```bash
# View all outputs
terraform output

# View specific output
terraform output acr_login_server
terraform output postgres_fqdn
```

## Configuration Files

- **main.tf** - Main Terraform configuration with all resources
- **variables.tf** - Variable definitions with descriptions and validation
- **outputs.tf** - Output values for important resource information
- **terraform.tfvars.example** - Example variable values (copy to terraform.tfvars)
- **.gitignore** - Git ignore rules for Terraform files

## Backend Configuration (Optional)

For team collaboration, configure a remote backend to store Terraform state:

### Azure Storage Backend

```bash
# Create storage account for Terraform state
az storage account create \
  --resource-group rg-terraform-state \
  --name stterraformstate \
  --location westeurope \
  --sku Standard_LRS

# Create container
az storage container create \
  --account-name stterraformstate \
  --name tfstate
```

Create `backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "csom-platform.terraform.tfstate"
  }
}
```

## Resources Created

This Terraform configuration creates the following Azure resources:

- **Resource Group** - Container for all resources
- **Azure Container Registry (ACR)** - Docker image storage
- **Azure Key Vault** - Secrets management
- **PostgreSQL Flexible Server** - Database server
- **Azure Service Bus** - Message broker with topics
- **Application Insights** - Application monitoring
- **Azure Redis Cache** - In-memory cache
- **Azure Functions** - Serverless compute for housekeeping jobs
- **Azure Storage Account** - For Functions and Blob Storage
- **Blob Storage Containers** - Archive, audit-logs, gdpr-data, customer-documents
- **Storage Lifecycle Management** - Automated tiering and deletion policies

## Variable Reference

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `resource_group_name` | Resource group name | `rg-csom-platform-prod` | No |
| `location` | Azure region | `westeurope` | No |
| `postgres_admin_password` | PostgreSQL admin password | - | Yes |
| `acr_name` | ACR name (5-50 chars, lowercase, alphanumeric) | `acrcsomplatform` | No |
| `key_vault_name` | Key Vault name (3-24 chars) | `kv-csom-platform-prod` | No |
| `redis_cache_name` | Redis Cache name (1-63 chars, lowercase) | `redis-csom-platform-prod` | No |
| `functions_app_name` | Functions App name (2-60 chars) | `func-csom-platform-prod` | No |
| `blob_storage_account_name` | Storage account name (3-24 chars, lowercase) | `stcsomarchiveprod` | No |
| `tags` | Tags for all resources | See variables.tf | No |

## Common Commands

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy

# Show current state
terraform show

# List resources
terraform state list

# Refresh state
terraform refresh

# Import existing resource (if needed)
terraform import azurerm_resource_group.example /subscriptions/.../resourceGroups/rg-example
```

## Updating Infrastructure

```bash
# Make changes to .tf files
# Review changes
terraform plan

# Apply changes
terraform apply
```

## Destroying Infrastructure

```bash
# Destroy all resources
terraform destroy

# Destroy specific resource
terraform destroy -target=azurerm_postgresql_flexible_server.main
```

## Troubleshooting

### Authentication Issues

```bash
# Verify Azure login
az account show

# Re-authenticate
az login

# Verify service principal (if using)
az account show --query tenantId
```

### State Lock Issues

If Terraform state is locked:

```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Resource Name Conflicts

Azure resource names must be globally unique. If you get name conflicts:

1. Update variable values in `terraform.tfvars`
2. Use different names that are still valid
3. Re-run `terraform plan` and `terraform apply`

### Importing Existing Resources

If resources already exist in Azure:

```bash
# Import resource into Terraform state
terraform import azurerm_resource_group.main /subscriptions/<subscription-id>/resourceGroups/rg-csom-platform-prod
```

## CI/CD Integration

### GitLab CI/CD

Add to `.gitlab-ci.yml`:

```yaml
terraform:
  stage: deploy
  image: hashicorp/terraform:latest
  before_script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - cd infrastructure/terraform
    - terraform init
  script:
    - terraform plan -out=tfplan
    - terraform apply -auto-approve tfplan
  only:
    - main
```

### GitHub Actions

Create `.github/workflows/terraform.yml`:

```yaml
name: Terraform
on:
  push:
    branches: [main]
    paths:
      - 'infrastructure/terraform/**'

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - name: Terraform Init
        run: terraform init
        working-directory: ./infrastructure/terraform
      - name: Terraform Plan
        run: terraform plan
        working-directory: ./infrastructure/terraform
      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: ./infrastructure/terraform
```

## Best Practices

1. **Use Variables** - Never hardcode values in `.tf` files
2. **Use Remote State** - Store state in Azure Storage for team collaboration
3. **Version Control** - Commit `.tf` files, but not `.tfvars` or `.tfstate`
4. **Use Modules** - Break down complex configurations into modules
5. **Tag Resources** - Use consistent tagging strategy
6. **Validate Early** - Run `terraform validate` and `terraform plan` frequently
7. **Review Changes** - Always review `terraform plan` output before applying
8. **Use Workspaces** - Use Terraform workspaces for environment separation

## Comparison with Bicep

This Terraform configuration is equivalent to the Bicep template in `../bicep/main.bicep`. Both create the same Azure resources.

**When to use Terraform:**
- Multi-cloud deployments
- Team prefers Terraform/HCL syntax
- Need Terraform's extensive provider ecosystem
- Existing Terraform expertise

**When to use Bicep:**
- Azure-only deployments
- Team prefers Bicep/ARM syntax
- Native Azure integration
- Existing Azure/ARM expertise

## Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [Azure Terraform Examples](https://github.com/hashicorp/terraform-provider-azurerm/tree/main/examples)

## Support

For issues or questions:
- Review Terraform documentation
- Check Azure provider documentation
- Review error messages and logs
- Contact the DevOps team

---

**Note**: Always review `terraform plan` output before applying changes to production infrastructure.

