# Infrastructure Deployment Guide
## Best Practices and CI/CD Integration

This guide provides comprehensive examples and best practices for deploying Azure infrastructure using Terraform, Bicep, or ARM Templates, including CI/CD integration.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Deployment Strategies](#2-deployment-strategies)
3. [CI/CD Integration](#3-cicd-integration)
4. [Terraform Deployment](#4-terraform-deployment)
5. [Bicep Deployment](#5-bicep-deployment)
6. [ARM Templates Deployment](#6-arm-templates-deployment)
7. [Best Practices](#7-best-practices)
8. [Security Considerations](#8-security-considerations)
9. [State Management](#9-state-management)
10. [Environment Separation](#10-environment-separation)
11. [Rollback Strategies](#11-rollback-strategies)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Overview

### Infrastructure as Code (IaC) Tools

This project supports three Infrastructure as Code tools:

1. **Terraform** - Multi-cloud, HCL syntax, state management
2. **Bicep** - Azure-native DSL, no state files, compiles to ARM
3. **ARM Templates** - Azure-native JSON, universal Azure support

All three tools create the same Azure resources and are functionally equivalent.

### Deployment Approaches

**Option 1: CI/CD Pipeline (Recommended)**
- Automated, repeatable deployments
- Version controlled
- Audit trail
- Approval gates for production
- Best for team collaboration

**Option 2: Manual Deployment**
- Quick testing and development
- One-off deployments
- Learning and experimentation
- Best for initial setup or emergencies

---

## 2. Deployment Strategies

### 2.1 CI/CD Deployment (Recommended)

**Benefits**:
- ✅ Automated and repeatable
- ✅ Version controlled infrastructure changes
- ✅ Audit trail of all changes
- ✅ Approval gates for production
- ✅ Integration with pull request reviews
- ✅ Automated testing and validation
- ✅ Rollback capabilities

**When to Use**:
- Production deployments
- Team environments
- Infrastructure changes that need review
- Compliance and audit requirements

### 2.2 Manual Deployment

**Benefits**:
- ✅ Quick for testing
- ✅ Full control over deployment process
- ✅ Useful for learning and experimentation

**When to Use**:
- Initial setup
- Development and testing
- Emergency fixes (with post-deployment CI/CD update)
- One-off changes

**Best Practice**: Always commit infrastructure changes to version control, even if deployed manually.

---

## 3. CI/CD Integration

### 3.1 GitLab CI/CD Pipeline

The infrastructure deployment is integrated into the GitLab CI/CD pipeline with the following stages:

1. **Validate Infrastructure** - Validate Terraform/Bicep/ARM templates
2. **Plan Infrastructure** - Generate deployment plan (Terraform)
3. **Deploy Infrastructure** - Deploy to environments (dev, staging, production)
4. **Verify Deployment** - Verify infrastructure deployment

### 3.2 Pipeline Stages

```yaml
stages:
  - validate-infrastructure
  - plan-infrastructure
  - deploy-infrastructure-dev
  - deploy-infrastructure-staging
  - deploy-infrastructure-production
```

### 3.3 Environment Separation

- **Development**: Automatic deployment on merge to `develop` branch
- **Staging**: Automatic deployment on merge to `main` branch
- **Production**: Manual approval required, deploys on tags or manual trigger

---

## 4. Terraform Deployment

### 4.1 Manual Deployment

#### Prerequisites

```bash
# Install Terraform
brew install terraform  # macOS
# or download from https://www.terraform.io/downloads

# Verify installation
terraform version

# Install Azure CLI
az --version
```

#### Step 1: Configure Azure Authentication

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "Your-Subscription-Name"

# Verify
az account show
```

#### Step 2: Configure Terraform Backend (Remote State)

```bash
# Create storage account for Terraform state (one-time setup)
az group create --name rg-terraform-state --location westeurope
az storage account create \
  --name stterraformstate \
  --resource-group rg-terraform-state \
  --location westeurope \
  --sku Standard_LRS

# Create container
az storage container create \
  --name terraform-state \
  --account-name stterraformstate
```

#### Step 3: Configure Terraform

```bash
# Navigate to Terraform directory
cd infrastructure/terraform

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# Important: Never commit terraform.tfvars to version control
```

#### Step 4: Initialize Terraform

```bash
# Initialize Terraform (downloads providers, configures backend)
terraform init

# Verify backend configuration
terraform init -backend-config=backend.hcl
```

#### Step 5: Plan Deployment

```bash
# Generate deployment plan
terraform plan -out=tfplan

# Review the plan carefully
# Check for:
# - Resources to be created
# - Resources to be modified
# - Resources to be destroyed
```

#### Step 6: Apply Configuration

```bash
# Apply the plan
terraform apply tfplan

# Or apply directly (interactive)
terraform apply

# Apply with auto-approve (non-interactive)
terraform apply -auto-approve
```

#### Step 7: Verify Deployment

```bash
# View outputs
terraform output

# List resources
terraform state list

# Show specific resource
terraform state show azurerm_resource_group.main
```

### 4.2 CI/CD Deployment (GitLab)

#### GitLab CI/CD Configuration

```yaml
# Terraform Infrastructure Deployment
variables:
  TF_ROOT: infrastructure/terraform
  TF_ADDRESS: https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/terraform/state/${CI_COMMIT_REF_NAME}
  TF_USERNAME: gitlab-ci-token
  TF_PASSWORD: ${CI_JOB_TOKEN}
  TF_HTTP_LOCK_ADDRESS: ${TF_ADDRESS}/lock
  TF_HTTP_LOCK_METHOD: POST
  TF_HTTP_UNLOCK_ADDRESS: ${TF_ADDRESS}/lock
  TF_HTTP_UNLOCK_METHOD: DELETE
  TF_HTTP_RETRY_WAIT_MIN: 5

# Validate Terraform
validate-terraform:
  stage: validate-infrastructure
  image: hashicorp/terraform:latest
  before_script:
    - cd ${TF_ROOT}
  script:
    - terraform init -backend=false
    - terraform validate
    - terraform fmt -check
  only:
    - merge_requests
    - main
    - develop

# Plan Terraform (Development)
plan-terraform-dev:
  stage: plan-infrastructure
  image: hashicorp/terraform:latest
  before_script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - cd ${TF_ROOT}
    - terraform init
      -backend-config="storage_account_name=$TF_STATE_STORAGE_ACCOUNT"
      -backend-config="container_name=$TF_STATE_CONTAINER"
      -backend-config="key=dev/terraform.tfstate"
      -backend-config="resource_group_name=$TF_STATE_RESOURCE_GROUP"
  script:
    - terraform workspace select dev || terraform workspace new dev
    - terraform plan -out=tfplan-dev -var-file=terraform.tfvars.dev
  artifacts:
    paths:
      - ${TF_ROOT}/tfplan-dev
    expire_in: 1 week
  only:
    - develop

# Deploy Terraform (Development)
deploy-terraform-dev:
  stage: deploy-infrastructure-dev
  image: hashicorp/terraform:latest
  before_script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - cd ${TF_ROOT}
    - terraform init
      -backend-config="storage_account_name=$TF_STATE_STORAGE_ACCOUNT"
      -backend-config="container_name=$TF_STATE_CONTAINER"
      -backend-config="key=dev/terraform.tfstate"
      -backend-config="resource_group_name=$TF_STATE_RESOURCE_GROUP"
  script:
    - terraform workspace select dev
    - terraform apply -auto-approve tfplan-dev
  dependencies:
    - plan-terraform-dev
  environment:
    name: dev
  only:
    - develop

# Plan Terraform (Staging)
plan-terraform-staging:
  stage: plan-infrastructure
  image: hashicorp/terraform:latest
  before_script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - cd ${TF_ROOT}
    - terraform init
      -backend-config="storage_account_name=$TF_STATE_STORAGE_ACCOUNT"
      -backend-config="container_name=$TF_STATE_CONTAINER"
      -backend-config="key=staging/terraform.tfstate"
      -backend-config="resource_group_name=$TF_STATE_RESOURCE_GROUP"
  script:
    - terraform workspace select staging || terraform workspace new staging
    - terraform plan -out=tfplan-staging -var-file=terraform.tfvars.staging
  artifacts:
    paths:
      - ${TF_ROOT}/tfplan-staging
    expire_in: 1 week
  only:
    - main

# Deploy Terraform (Staging)
deploy-terraform-staging:
  stage: deploy-infrastructure-staging
  image: hashicorp/terraform:latest
  before_script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - cd ${TF_ROOT}
    - terraform init
      -backend-config="storage_account_name=$TF_STATE_STORAGE_ACCOUNT"
      -backend-config="container_name=$TF_STATE_CONTAINER"
      -backend-config="key=staging/terraform.tfstate"
      -backend-config="resource_group_name=$TF_STATE_RESOURCE_GROUP"
  script:
    - terraform workspace select staging
    - terraform apply -auto-approve tfplan-staging
  dependencies:
    - plan-terraform-staging
  environment:
    name: staging
  only:
    - main

# Plan Terraform (Production)
plan-terraform-production:
  stage: plan-infrastructure
  image: hashicorp/terraform:latest
  before_script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - cd ${TF_ROOT}
    - terraform init
      -backend-config="storage_account_name=$TF_STATE_STORAGE_ACCOUNT"
      -backend-config="container_name=$TF_STATE_CONTAINER"
      -backend-config="key=production/terraform.tfstate"
      -backend-config="resource_group_name=$TF_STATE_RESOURCE_GROUP"
  script:
    - terraform workspace select production || terraform workspace new production
    - terraform plan -out=tfplan-production -var-file=terraform.tfvars.production
  artifacts:
    paths:
      - ${TF_ROOT}/tfplan-production
    expire_in: 1 month
  only:
    - main
    - tags

# Deploy Terraform (Production) - Manual Approval
deploy-terraform-production:
  stage: deploy-infrastructure-production
  image: hashicorp/terraform:latest
  before_script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - cd ${TF_ROOT}
    - terraform init
      -backend-config="storage_account_name=$TF_STATE_STORAGE_ACCOUNT"
      -backend-config="container_name=$TF_STATE_CONTAINER"
      -backend-config="key=production/terraform.tfstate"
      -backend-config="resource_group_name=$TF_STATE_RESOURCE_GROUP"
  script:
    - terraform workspace select production
    - terraform apply -auto-approve tfplan-production
  dependencies:
    - plan-terraform-production
  environment:
    name: production
  when: manual
  only:
    - main
    - tags
```

#### Required GitLab CI/CD Variables

Set these in GitLab CI/CD settings:

- `AZURE_CLIENT_ID` - Azure service principal client ID
- `AZURE_CLIENT_SECRET` - Azure service principal client secret
- `AZURE_TENANT_ID` - Azure tenant ID
- `TF_STATE_STORAGE_ACCOUNT` - Storage account for Terraform state
- `TF_STATE_CONTAINER` - Container name for Terraform state
- `TF_STATE_RESOURCE_GROUP` - Resource group for Terraform state storage

### 4.3 Best Practices for Terraform

1. **Use Remote State**: Store state in Azure Storage Account
2. **Use Workspaces**: Separate state for dev, staging, production
3. **Use Variables Files**: `terraform.tfvars.dev`, `terraform.tfvars.staging`, `terraform.tfvars.production`
4. **Never Commit Secrets**: Use Azure Key Vault or GitLab CI/CD variables
5. **Use Modules**: Break down complex configurations
6. **Validate and Format**: Run `terraform validate` and `terraform fmt` before committing
7. **Review Plans**: Always review `terraform plan` output before applying
8. **Version Pinning**: Pin provider versions in `versions.tf`

---

## 5. Bicep Deployment

### 5.1 Manual Deployment

#### Prerequisites

```bash
# Install Azure CLI (includes Bicep)
az --version

# Install Bicep CLI (if not included)
az bicep install

# Verify installation
az bicep version
```

#### Step 1: Configure Azure Authentication

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "Your-Subscription-Name"
```

#### Step 2: Validate Bicep Template

```bash
# Navigate to Bicep directory
cd infrastructure/bicep

# Validate Bicep template
az deployment group validate \
  --resource-group rg-csom-platform-prod \
  --template-file main.bicep \
  --parameters @main.parameters.json
```

#### Step 3: Preview Changes (What-If)

```bash
# Preview changes before deploying
az deployment group what-if \
  --resource-group rg-csom-platform-prod \
  --template-file main.bicep \
  --parameters @main.parameters.json
```

#### Step 4: Deploy Bicep Template

```bash
# Deploy Bicep template
az deployment group create \
  --resource-group rg-csom-platform-prod \
  --template-file main.bicep \
  --parameters @main.parameters.json \
  --name csom-platform-deployment-$(date +%Y%m%d-%H%M%S)
```

#### Step 5: Verify Deployment

```bash
# View deployment outputs
az deployment group show \
  --resource-group rg-csom-platform-prod \
  --name csom-platform-deployment-* \
  --query properties.outputs

# List resources
az resource list --resource-group rg-csom-platform-prod --output table
```

### 5.2 CI/CD Deployment (GitLab)

```yaml
# Validate Bicep
validate-bicep:
  stage: validate-infrastructure
  image: mcr.microsoft.com/azure-cli:latest
  before_script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
  script:
    - cd infrastructure/bicep
    - az bicep build --file main.bicep
    - az deployment group validate \
        --resource-group $RESOURCE_GROUP \
        --template-file main.bicep \
        --parameters @main.parameters.json
  only:
    - merge_requests
    - main
    - develop

# Deploy Bicep (Development)
deploy-bicep-dev:
  stage: deploy-infrastructure-dev
  image: mcr.microsoft.com/azure-cli:latest
  before_script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - az group create --name rg-csom-platform-dev --location westeurope || true
  script:
    - cd infrastructure/bicep
    - |
      az deployment group create \
        --resource-group rg-csom-platform-dev \
        --template-file main.bicep \
        --parameters @main.parameters.dev.json \
        --name csom-platform-dev-${CI_COMMIT_SHORT_SHA} \
        --mode Incremental
  environment:
    name: dev
  only:
    - develop

# Deploy Bicep (Staging)
deploy-bicep-staging:
  stage: deploy-infrastructure-staging
  image: mcr.microsoft.com/azure-cli:latest
  before_script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - az group create --name rg-csom-platform-staging --location westeurope || true
  script:
    - cd infrastructure/bicep
    - |
      az deployment group create \
        --resource-group rg-csom-platform-staging \
        --template-file main.bicep \
        --parameters @main.parameters.staging.json \
        --name csom-platform-staging-${CI_COMMIT_SHORT_SHA} \
        --mode Incremental
  environment:
    name: staging
  only:
    - main

# Deploy Bicep (Production) - Manual Approval
deploy-bicep-production:
  stage: deploy-infrastructure-production
  image: mcr.microsoft.com/azure-cli:latest
  before_script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - az group create --name rg-csom-platform-prod --location westeurope || true
  script:
    - cd infrastructure/bicep
    - |
      az deployment group create \
        --resource-group rg-csom-platform-prod \
        --template-file main.bicep \
        --parameters @main.parameters.prod.json \
        --name csom-platform-prod-${CI_COMMIT_TAG:-${CI_COMMIT_SHORT_SHA}} \
        --mode Incremental
  environment:
    name: production
  when: manual
  only:
    - main
    - tags
```

### 5.3 Best Practices for Bicep

1. **Use Parameters Files**: Separate parameter files for each environment
2. **Use What-If**: Always preview changes before deploying
3. **Use Modules**: Break down complex templates into modules
4. **Validate First**: Always validate templates before deploying
5. **Use Key Vault References**: Reference secrets from Key Vault
6. **Version Control**: Commit all Bicep files to version control
7. **Incremental Mode**: Use incremental deployment mode (default)
8. **Tag Resources**: Use consistent tagging strategy

---

## 6. ARM Templates Deployment

### 6.1 Manual Deployment

#### Prerequisites

```bash
# Install Azure CLI
az --version
```

#### Step 1: Configure Azure Authentication

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "Your-Subscription-Name"
```

#### Step 2: Validate ARM Template

```bash
# Navigate to ARM directory
cd infrastructure/arm

# Validate ARM template
az deployment group validate \
  --resource-group rg-csom-platform-prod \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json
```

#### Step 3: Preview Changes (What-If)

```bash
# Preview changes before deploying
az deployment group what-if \
  --resource-group rg-csom-platform-prod \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json
```

#### Step 4: Deploy ARM Template

```bash
# Deploy ARM template
az deployment group create \
  --resource-group rg-csom-platform-prod \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json \
  --name csom-platform-deployment-$(date +%Y%m%d-%H%M%S)
```

#### Step 5: Verify Deployment

```bash
# View deployment outputs
az deployment group show \
  --resource-group rg-csom-platform-prod \
  --name csom-platform-deployment-* \
  --query properties.outputs
```

### 6.2 CI/CD Deployment (GitLab)

```yaml
# Validate ARM Template
validate-arm:
  stage: validate-infrastructure
  image: mcr.microsoft.com/azure-cli:latest
  before_script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
  script:
    - cd infrastructure/arm
    - |
      az deployment group validate \
        --resource-group $RESOURCE_GROUP \
        --template-file azuredeploy.json \
        --parameters @azuredeploy.parameters.json
  only:
    - merge_requests
    - main
    - develop

# Deploy ARM Template (Development)
deploy-arm-dev:
  stage: deploy-infrastructure-dev
  image: mcr.microsoft.com/azure-cli:latest
  before_script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - az group create --name rg-csom-platform-dev --location westeurope || true
  script:
    - cd infrastructure/arm
    - |
      az deployment group create \
        --resource-group rg-csom-platform-dev \
        --template-file azuredeploy.json \
        --parameters @azuredeploy.parameters.dev.json \
        --name csom-platform-dev-${CI_COMMIT_SHORT_SHA} \
        --mode Incremental
  environment:
    name: dev
  only:
    - develop

# Deploy ARM Template (Staging)
deploy-arm-staging:
  stage: deploy-infrastructure-staging
  image: mcr.microsoft.com/azure-cli:latest
  before_script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - az group create --name rg-csom-platform-staging --location westeurope || true
  script:
    - cd infrastructure/arm
    - |
      az deployment group create \
        --resource-group rg-csom-platform-staging \
        --template-file azuredeploy.json \
        --parameters @azuredeploy.parameters.staging.json \
        --name csom-platform-staging-${CI_COMMIT_SHORT_SHA} \
        --mode Incremental
  environment:
    name: staging
  only:
    - main

# Deploy ARM Template (Production) - Manual Approval
deploy-arm-production:
  stage: deploy-infrastructure-production
  image: mcr.microsoft.com/azure-cli:latest
  before_script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - az group create --name rg-csom-platform-prod --location westeurope || true
  script:
    - cd infrastructure/arm
    - |
      az deployment group create \
        --resource-group rg-csom-platform-prod \
        --template-file azuredeploy.json \
        --parameters @azuredeploy.parameters.prod.json \
        --name csom-platform-prod-${CI_COMMIT_TAG:-${CI_COMMIT_SHORT_SHA}} \
        --mode Incremental
  environment:
    name: production
  when: manual
  only:
    - main
    - tags
```

### 6.3 Best Practices for ARM Templates

1. **Use Parameters**: Never hardcode values in templates
2. **Use Key Vault References**: Reference secrets from Key Vault
3. **Validate First**: Always validate templates before deploying
4. **Use What-If**: Preview changes before deploying
5. **Use Linked Templates**: Break down complex templates
6. **Version Control**: Commit all templates to version control
7. **Incremental Mode**: Use incremental deployment mode (default)
8. **Tag Resources**: Use consistent tagging strategy

---

## 7. Best Practices

### 7.1 General Best Practices

1. **Version Control**: Always commit infrastructure code to version control
2. **Code Review**: Require code review for all infrastructure changes
3. **Testing**: Test infrastructure changes in dev/staging before production
4. **Documentation**: Document infrastructure changes and decisions
5. **Monitoring**: Monitor infrastructure deployments and resources
6. **Backup**: Backup critical infrastructure state and configurations
7. **Tagging**: Use consistent resource tagging for cost tracking and management
8. **Naming Conventions**: Use consistent naming conventions for resources

### 7.2 Security Best Practices

1. **Secrets Management**: Never commit secrets to version control
2. **Key Vault**: Use Azure Key Vault for secrets storage
3. **Service Principals**: Use service principals with least privilege
4. **RBAC**: Implement Role-Based Access Control (RBAC)
5. **Network Security**: Use private endpoints and network security groups
6. **Encryption**: Enable encryption at rest and in transit
7. **Audit Logging**: Enable Azure audit logging
8. **Regular Updates**: Keep infrastructure tools and dependencies updated

### 7.3 CI/CD Best Practices

1. **Validation**: Validate infrastructure code before deployment
2. **Approval Gates**: Require manual approval for production deployments
3. **Artifact Storage**: Store deployment plans and artifacts
4. **Rollback Plan**: Have a rollback plan for failed deployments
5. **Notification**: Notify teams of infrastructure changes
6. **Testing**: Run infrastructure tests in CI/CD pipeline
7. **Environment Separation**: Separate pipelines for each environment
8. **State Management**: Properly manage infrastructure state

---

## 8. Security Considerations

### 8.1 Authentication and Authorization

**Service Principals**:
- Use service principals for CI/CD pipelines
- Grant least privilege permissions
- Rotate credentials regularly
- Use managed identities when possible

**Key Vault Integration**:
- Store secrets in Azure Key Vault
- Reference secrets from Key Vault in templates
- Use Key Vault access policies
- Enable soft delete and purge protection

### 8.2 Network Security

**Private Endpoints**:
- Use private endpoints for Azure services
- Restrict network access
- Use network security groups
- Implement firewall rules

### 8.3 Data Protection

**Encryption**:
- Enable encryption at rest
- Use TLS/SSL for data in transit
- Use Azure Disk Encryption
- Enable SQL transparent data encryption

---

## 9. State Management

### 9.1 Terraform State

**Remote State**:
- Store state in Azure Storage Account
- Enable state locking
- Use state encryption
- Backup state regularly

**State Backend Configuration**:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "terraform-state"
    key                  = "production/terraform.tfstate"
  }
}
```

### 9.2 Bicep State

**No State Files**:
- Bicep doesn't require state files
- State is managed by Azure Resource Manager
- Deployment history is stored in Azure
- Use deployment names for tracking

### 9.3 ARM Template State

**No State Files**:
- ARM templates don't require state files
- State is managed by Azure Resource Manager
- Deployment history is stored in Azure
- Use deployment names for tracking

---

## 10. Environment Separation

### 10.1 Resource Groups

**Separate Resource Groups**:
- `rg-csom-platform-dev` - Development environment
- `rg-csom-platform-staging` - Staging environment
- `rg-csom-platform-prod` - Production environment

### 10.2 Terraform Workspaces

**Workspace Configuration**:
```bash
# Create workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new production

# Select workspace
terraform workspace select dev

# List workspaces
terraform workspace list
```

### 10.3 Parameter Files

**Environment-Specific Parameters**:
- `terraform.tfvars.dev` - Development parameters
- `terraform.tfvars.staging` - Staging parameters
- `terraform.tfvars.production` - Production parameters

**Bicep Parameters**:
- `main.parameters.dev.json` - Development parameters
- `main.parameters.staging.json` - Staging parameters
- `main.parameters.prod.json` - Production parameters

**ARM Parameters**:
- `azuredeploy.parameters.dev.json` - Development parameters
- `azuredeploy.parameters.staging.json` - Staging parameters
- `azuredeploy.parameters.prod.json` - Production parameters

---

## 11. Rollback Strategies

### 11.1 Terraform Rollback

**Rollback Options**:
1. **Revert Code**: Revert to previous version in version control
2. **State Rollback**: Restore previous state file from backup
3. **Destroy and Recreate**: Destroy and recreate from previous version
4. **Targeted Destroy**: Destroy specific resources

```bash
# Restore previous state
terraform state pull > terraform.tfstate.backup
terraform state push terraform.tfstate.previous

# Rollback to previous version
git revert <commit-hash>
terraform apply
```

### 11.2 Bicep Rollback

**Rollback Options**:
1. **Revert Code**: Revert to previous version in version control
2. **Redeploy Previous**: Redeploy previous version of template
3. **Delete Resources**: Delete resources and redeploy previous version

```bash
# Redeploy previous version
az deployment group create \
  --resource-group rg-csom-platform-prod \
  --template-file main.bicep \
  --parameters @main.parameters.prod.json \
  --name csom-platform-rollback-$(date +%Y%m%d-%H%M%S)
```

### 11.3 ARM Template Rollback

**Rollback Options**:
1. **Revert Code**: Revert to previous version in version control
2. **Redeploy Previous**: Redeploy previous version of template
3. **Delete Resources**: Delete resources and redeploy previous version

```bash
# Redeploy previous version
az deployment group create \
  --resource-group rg-csom-platform-prod \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.prod.json \
  --name csom-platform-rollback-$(date +%Y%m%d-%H%M%S)
```

---

## 12. Troubleshooting

### 12.1 Common Issues

**Terraform Issues**:
- **State Lock**: Unlock state if locked
  ```bash
  terraform force-unlock <lock-id>
  ```
- **State Drift**: Refresh state to detect drift
  ```bash
  terraform refresh
  ```
- **Provider Errors**: Update provider versions
  ```bash
  terraform init -upgrade
  ```

**Bicep Issues**:
- **Validation Errors**: Check template syntax
  ```bash
  az bicep build --file main.bicep
  ```
- **Deployment Errors**: Check deployment operations
  ```bash
  az deployment operation group list \
    --resource-group rg-csom-platform-prod \
    --name <deployment-name>
  ```

**ARM Template Issues**:
- **Validation Errors**: Validate template syntax
  ```bash
  az deployment group validate \
    --resource-group rg-csom-platform-prod \
    --template-file azuredeploy.json
  ```
- **Deployment Errors**: Check deployment operations
  ```bash
  az deployment operation group list \
    --resource-group rg-csom-platform-prod \
    --name <deployment-name>
  ```

### 12.2 Debugging

**Enable Debug Logging**:
```bash
# Terraform
export TF_LOG=DEBUG
terraform apply

# Azure CLI
az deployment group create --debug ...
```

**View Logs**:
```bash
# Terraform
terraform plan -out=tfplan
terraform show tfplan

# Azure CLI
az deployment group show \
  --resource-group rg-csom-platform-prod \
  --name <deployment-name>
```

---

## Summary

### Key Takeaways

1. **Use CI/CD**: Deploy infrastructure via CI/CD for production environments
2. **Manual for Development**: Manual deployment is acceptable for development and testing
3. **Version Control**: Always commit infrastructure code to version control
4. **Security**: Use Key Vault for secrets, service principals for authentication
5. **State Management**: Properly manage infrastructure state (Terraform) or rely on Azure (Bicep/ARM)
6. **Environment Separation**: Separate infrastructure for dev, staging, and production
7. **Testing**: Test infrastructure changes in dev/staging before production
8. **Rollback Plan**: Have a rollback plan for failed deployments

### Recommended Approach

**For Production**:
- ✅ Use CI/CD pipeline with manual approval
- ✅ Require code review
- ✅ Test in dev/staging first
- ✅ Use version control
- ✅ Monitor deployments

**For Development**:
- ✅ Manual deployment is acceptable
- ✅ Commit changes to version control
- ✅ Use CI/CD for consistency
- ✅ Test before committing

---

## Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [ARM Templates Documentation](https://docs.microsoft.com/azure/azure-resource-manager/templates/)
- [Azure CLI Documentation](https://docs.microsoft.com/cli/azure/)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)

---

**Note**: Always review infrastructure changes carefully before deploying to production. Use validation and preview features to understand the impact of changes.

