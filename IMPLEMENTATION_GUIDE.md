# Step-by-Step Implementation Guide
## Cloud-Native Architecture Template

This guide provides detailed steps to implement the cloud-native architecture template from scratch. This template serves as a ready-to-use foundation for bootstrapping cloud-native applications on Azure.

---

## Table of Contents

- [Phase 1: Prerequisites and Azure Setup](#phase-1-prerequisites-and-azure-setup)
- [Phase 2: Database Setup](#phase-2-database-setup)
- [Phase 3: AKS Cluster Setup](#phase-3-aks-cluster-setup)
- [Phase 4: Azure Service Bus Setup](#phase-4-azure-service-bus-setup)
- [Phase 4.5: Azure Redis Cache Setup](#phase-45-azure-redis-cache-setup)
- [Phase 4.6: Azure Functions Setup](#phase-46-azure-functions-setup)
- [Phase 4.7: Azure Blob Storage Setup](#phase-47-azure-blob-storage-setup)
- [Phase 5: GitLab Repository Setup](#phase-5-gitlab-repository-setup)
- [Phase 6: Backend Services Development](#phase-6-backend-services-development)
- [Phase 7: Frontend Development](#phase-7-frontend-development)
- [Phase 8: Apigee Configuration](#phase-8-apigee-configuration)
- [Phase 9: Integration Setup](#phase-9-integration-setup)
- [Phase 10: Monitoring and Observability](#phase-10-monitoring-and-observability)
- [Phase 11: GDPR Compliance Implementation](#phase-11-gdpr-compliance-implementation)
- [Phase 12: Testing](#phase-12-testing)
- [Phase 13: Production Deployment](#phase-13-production-deployment)
- [Phase 14: Documentation](#phase-14-documentation)
- [Deployment Authentication Options](#deployment-authentication-options)
- [Quick Start Commands](#quick-start-commands)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)
- [Related Documents](#related-documents)

---

## Phase 1: Prerequisites and Azure Setup

### Step 1.1: Azure Subscription Setup

1. **Create Azure Subscription** (if not exists)
   ```bash
   # Login to Azure
   az login
   
   # Set subscription
   az account set --subscription "Your-Subscription-Name"
   
   # Verify
   az account show
   ```

2. **Create Resource Group**
   ```bash
   az group create \
     --name rg-csom-platform-prod \
     --location westeurope
   ```

3. **Create Service Principal for CI/CD**
   ```bash
   az ad sp create-for-rbac \
     --name sp-gitlab-cicd \
     --role contributor \
     --scopes /subscriptions/{subscription-id}/resourceGroups/rg-csom-platform-prod
   ```
   Save the output (appId, password, tenant) for GitLab CI/CD configuration.

   **Note**: For comprehensive information about deployment authentication options (Service Principal, Publish Profile, Managed Identity), see the [Deployment Authentication Options](#deployment-authentication-options) section below.

---

### Step 1.2: Entra ID Configuration

#### 1.2.1: Entra ID App Registration (Employees)

1. **Navigate to Azure Portal** → Azure Active Directory → App registrations

2. **Create New Registration**
   - Name: `csom-platform-internal`
   - Supported account types: Single tenant
   - Redirect URI: `https://your-app.azurestaticapps.net/auth/callback`

3. **Configure API Permissions**
   - Add Microsoft Graph permissions:
     - `User.Read`
     - `GroupMember.Read.All`

4. **Create Client Secret**
   - Certificates & secrets → New client secret
   - Save the secret value (shown only once)

5. **Note Application (Client) ID and Directory (Tenant) ID**

#### 1.2.2: Entra External ID Configuration (Clients)

1. **Navigate to Azure Portal** → Azure AD External Identities

2. **Create New Tenant** (if needed) or use existing

3. **Create User Flow**
   - Sign up and sign in
   - Profile editing
   - Password reset

4. **Configure App Registration for External ID**
   - Create app registration in External ID tenant
   - Name: `csom-platform-external`
   - Redirect URI: `https://your-app.azurestaticapps.net/auth/callback`

5. **Note Application (Client) ID and Tenant ID**

---

### Step 1.3: Infrastructure Deployment

Choose one of the following options for deploying infrastructure:

#### Option A: Using ARM Templates (Azure Native JSON)

**Prerequisites:**
- Azure CLI configured
- Resource group created

**Steps:**

1. **Navigate to ARM templates directory**
   ```bash
   cd infrastructure/arm
   ```

2. **Edit parameters file**
   ```bash
   # Edit azuredeploy.parameters.json
   # Update postgresAdminPassword and other parameter values
   ```

3. **Validate template**
   ```bash
   az deployment group validate \
     --resource-group rg-csom-platform-prod \
     --template-file azuredeploy.json \
     --parameters @azuredeploy.parameters.json
   ```

4. **Deploy template**
   ```bash
   az deployment group create \
     --resource-group rg-csom-platform-prod \
     --template-file azuredeploy.json \
     --parameters @azuredeploy.parameters.json \
     --name csom-platform-deployment
   ```

5. **View outputs**
   ```bash
   az deployment group show \
     --resource-group rg-csom-platform-prod \
     --name csom-platform-deployment \
     --query properties.outputs
   ```

For detailed ARM template setup instructions, see [infrastructure/arm/README.md](./infrastructure/arm/README.md).

**Note:** After deploying with ARM templates, continue with the remaining phases (Database Setup, AKS Setup, etc.) as the infrastructure resources are now created.

**For comprehensive infrastructure deployment examples, CI/CD integration, and best practices, see [INFRASTRUCTURE_DEPLOYMENT_GUIDE.md](./INFRASTRUCTURE_DEPLOYMENT_GUIDE.md).**

#### Option B: Using Bicep (Azure Native DSL)

See Phase 1.4 and subsequent phases for Bicep-based deployment steps.

#### Option C: Using Terraform (Multi-Cloud)

**Prerequisites:**
- Terraform >= 1.5.0 installed
- Azure CLI configured

**Steps:**

1. **Navigate to Terraform directory**
   ```bash
   cd infrastructure/terraform
   ```

2. **Copy and configure variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   # Update postgres_admin_password and other sensitive values
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Plan deployment**
   ```bash
   terraform plan
   ```

5. **Apply configuration**
   ```bash
   terraform apply
   # Type 'yes' when prompted, or use -auto-approve flag
   ```

6. **View outputs**
   ```bash
   terraform output
   ```

7. **Store connection strings in Key Vault**
   ```bash
   # Get outputs
   ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
   POSTGRES_FQDN=$(terraform output -raw postgres_fqdn)
   REDIS_HOST=$(terraform output -raw redis_cache_hostname)
   REDIS_KEY=$(terraform output -raw redis_cache_primary_key)
   BLOB_STORAGE_CONN=$(terraform output -raw blob_storage_connection_string)
   
   # Store in Key Vault
   az keyvault secret set --vault-name kv-csom-platform-prod --name acr-login-server --value "$ACR_LOGIN_SERVER"
   az keyvault secret set --vault-name kv-csom-platform-prod --name postgres-fqdn --value "$POSTGRES_FQDN"
   az keyvault secret set --vault-name kv-csom-platform-prod --name redis-host --value "$REDIS_HOST"
   az keyvault secret set --vault-name kv-csom-platform-prod --name redis-primary-key --value "$REDIS_KEY"
   az keyvault secret set --vault-name kv-csom-platform-prod --name blob-storage-connection-string --value "$BLOB_STORAGE_CONN"
   ```

For detailed Terraform setup instructions, see [infrastructure/terraform/README.md](../infrastructure/terraform/README.md).

**Note:** After deploying with Terraform, continue with the remaining phases (Database Setup, AKS Setup, etc.) as the infrastructure resources are now created.

---

### Step 1.4: Azure Key Vault

```bash
# Create Key Vault
az keyvault create \
  --name kv-csom-platform-prod \
  --resource-group rg-csom-platform-prod \
  --location westeurope

# Store database password
az keyvault secret set \
  --vault-name kv-csom-platform-prod \
  --name postgres-admin-password \
  --value "YourSecurePassword123!"

# Store JWT secrets
az keyvault secret set \
  --vault-name kv-csom-platform-prod \
  --name entra-internal-client-secret \
  --value "your-internal-client-secret"

az keyvault secret set \
  --vault-name kv-csom-platform-prod \
  --name entra-external-client-secret \
  --value "your-external-client-secret"
```

---

## Phase 2: Database Setup

### Step 2.1: PostgreSQL Database

```bash
# Create PostgreSQL Flexible Server
az postgres flexible-server create \
  --resource-group rg-csom-platform-prod \
  --name psql-csom-platform-prod \
  --location westeurope \
  --admin-user csomadmin \
  --admin-password "YourSecurePassword123!" \
  --sku-name Standard_B2s \
  --tier Burstable \
  --version 15 \
  --storage-size 32 \
  --public-access 0.0.0.0

# Create firewall rule for AKS (update with AKS subnet)
az postgres flexible-server firewall-rule create \
  --resource-group rg-csom-platform-prod \
  --name psql-csom-platform-prod \
  --rule-name AllowAKS \
  --start-ip-address 10.0.0.0 \
  --end-ip-address 10.0.255.255

# Create databases
az postgres flexible-server db create \
  --resource-group rg-csom-platform-prod \
  --server-name psql-csom-platform-prod \
  --database-name ordersdb

az postgres flexible-server db create \
  --resource-group rg-csom-platform-prod \
  --server-name psql-csom-platform-prod \
  --database-name productsdb

az postgres flexible-server db create \
  --resource-group rg-csom-platform-prod \
  --server-name psql-csom-platform-prod \
  --database-name customersdb

az postgres flexible-server db create \
  --resource-group rg-csom-platform-prod \
  --server-name psql-csom-platform-prod \
  --database-name notificationsdb

az postgres flexible-server db create \
  --resource-group rg-csom-platform-prod \
  --server-name psql-csom-platform-prod \
  --database-name paymentsdb

az postgres flexible-server db create \
  --resource-group rg-csom-platform-prod \
  --server-name psql-csom-platform-prod \
  --database-name auditdb
```

### Step 2.2: Database Schema Initialization

See `infrastructure/database/migrations/` for SQL migration scripts. Run them in order:

```bash
# Connect to database
psql -h psql-csom-platform-prod.postgres.database.azure.com \
     -U csomadmin \
     -d ordersdb

# Run migrations (see infrastructure/database/migrations/)
```

---

## Phase 3: AKS Cluster Setup

### Step 3.1: Create AKS Cluster

```bash
# Create AKS cluster
az aks create \
  --resource-group rg-csom-platform-prod \
  --name aks-csom-platform-prod \
  --node-count 3 \
  --node-vm-size Standard_D4s_v3 \
  --enable-managed-identity \
  --network-plugin azure \
  --enable-addons monitoring \
  --enable-msi-auth-for-monitoring \
  --attach-acr acrcsomplatform

# Get credentials
az aks get-credentials \
  --resource-group rg-csom-platform-prod \
  --name aks-csom-platform-prod
```

### Step 3.2: Configure Namespaces

```bash
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace production
```

### Step 3.3: Install NGINX Ingress Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
```

### Step 3.4: Install Secrets Store CSI Driver (for Key Vault)

```bash
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace kube-system

# Install Azure Key Vault provider
kubectl apply -f https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/deployment/provider-azure-installer.yaml
```

---

## Phase 4: Azure Service Bus Setup

### Step 4.1: Create Service Bus Namespace

```bash
# Create Service Bus namespace
az servicebus namespace create \
  --resource-group rg-csom-platform-prod \
  --name sb-csom-platform-prod \
  --location westeurope \
  --sku Premium

# Create topics
az servicebus topic create \
  --resource-group rg-csom-platform-prod \
  --namespace-name sb-csom-platform-prod \
  --name order-events

az servicebus topic create \
  --resource-group rg-csom-platform-prod \
  --namespace-name sb-csom-platform-prod \
  --name payment-events

az servicebus topic create \
  --resource-group rg-csom-platform-prod \
  --namespace-name sb-csom-platform-prod \
  --name notification-events

az servicebus topic create \
  --resource-group rg-csom-platform-prod \
  --namespace-name sb-csom-platform-prod \
  --name gdpr-events
```

---

## Phase 4.5: Azure Redis Cache Setup

### Step 4.5.1: Create Redis Cache

```bash
# Create Redis Cache
az redis create \
  --resource-group rg-csom-platform-prod \
  --name redis-csom-platform-prod \
  --location westeurope \
  --sku Standard \
  --vm-size c1 \
  --enable-non-ssl-port false \
  --minimum-tls-version 1.2

# Get Redis access keys
az redis list-keys \
  --resource-group rg-csom-platform-prod \
  --name redis-csom-platform-prod

# Store Redis primary key in Key Vault
az keyvault secret set \
  --vault-name kv-csom-platform-prod \
  --name redis-primary-key \
  --value "<redis-primary-key>"
```

### Step 4.5.2: Configure Redis Firewall (Optional)

```bash
# Allow access from AKS subnet (if needed)
az redis firewall-rule create \
  --resource-group rg-csom-platform-prod \
  --name redis-csom-platform-prod \
  --rule-name AllowAKS \
  --start-ip-address 10.0.0.0 \
  --end-ip-address 10.0.255.255
```

---

## Phase 4.6: Azure Functions Setup

### Step 4.6.1: Create Azure Functions App

The Azure Functions app is created via the Bicep template, but you can also create it manually:

```bash
# Create Storage Account for Functions
az storage account create \
  --resource-group rg-csom-platform-prod \
  --name funccsomplatformstor \
  --location westeurope \
  --sku Standard_LRS

# Create Function App
az functionapp create \
  --resource-group rg-csom-platform-prod \
  --name func-csom-platform-prod \
  --storage-account funccsomplatformstor \
  --consumption-plan-location westeurope \
  --runtime java \
  --runtime-version 17 \
  --functions-version 4

# Configure Function App settings
az functionapp config appsettings set \
  --resource-group rg-csom-platform-prod \
  --name func-csom-platform-prod \
  --settings \
    POSTGRES_HOST="psql-csom-platform-prod.postgres.database.azure.com" \
    POSTGRES_USER="csomadmin" \
    REDIS_CACHE_HOST="redis-csom-platform-prod.redis.cache.windows.net" \
    REDIS_CACHE_PORT="6380" \
    BLOB_STORAGE_CONNECTION_STRING="@Microsoft.KeyVault(SecretUri=https://kv-csom-platform-prod.vault.azure.net/secrets/blob-storage-connection-string/)"
```

### Step 4.6.2: Deploy Housekeeping Functions

```bash
# Build and deploy Functions
cd azure-functions/housekeeping-jobs
mvn clean package
mvn azure-functions:deploy

# Or use Azure CLI
func azure functionapp publish func-csom-platform-prod
```

### Step 4.6.3: Verify Functions

```bash
# List functions
az functionapp function list \
  --resource-group rg-csom-platform-prod \
  --name func-csom-platform-prod

# Test timer trigger (manually trigger for testing)
az functionapp function show \
  --resource-group rg-csom-platform-prod \
  --name func-csom-platform-prod \
  --function-name DataRetentionCleanup
```

---

## Phase 4.7: Azure Blob Storage Setup

### Step 4.7.1: Create Blob Storage Account

The Blob Storage account is created via the Bicep template, but you can also create it manually:

```bash
# Create Storage Account for Archiving
az storage account create \
  --resource-group rg-csom-platform-prod \
  --name stcsomarchiveprod \
  --location westeurope \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2

# Enable soft delete for blobs
az storage blob service-properties update \
  --account-name stcsomarchiveprod \
  --enable-delete-retention true \
  --delete-retention-days 7

# Enable container delete retention
az storage blob service-properties update \
  --account-name stcsomarchiveprod \
  --enable-container-delete-retention true \
  --container-delete-retention-days 7
```

### Step 4.7.2: Create Blob Containers

```bash
# Create archive containers
az storage container create \
  --account-name stcsomarchiveprod \
  --name archive \
  --public-access off

az storage container create \
  --account-name stcsomarchiveprod \
  --name audit-logs \
  --public-access off

az storage container create \
  --account-name stcsomarchiveprod \
  --name gdpr-data \
  --public-access off

az storage container create \
  --account-name stcsomarchiveprod \
  --name customer-documents \
  --public-access off
```

### Step 4.7.3: Configure Lifecycle Management Policy

```bash
# Get storage account key
STORAGE_ACCOUNT_KEY=$(az storage account keys list \
  --resource-group rg-csom-platform-prod \
  --account-name stcsomarchiveprod \
  --query '[0].value' -o tsv)

# Create lifecycle management policy JSON
cat > lifecycle-policy.json << 'EOF'
{
  "rules": [
    {
      "name": "ArchiveToCoolAfter30Days",
      "enabled": true,
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["archive/"]
        },
        "actions": {
          "baseBlob": {
            "tierToCool": {
              "daysAfterModificationGreaterThan": 30
            },
            "tierToArchive": {
              "daysAfterModificationGreaterThan": 90
            },
            "delete": {
              "daysAfterModificationGreaterThan": 2555
            }
          }
        }
      }
    },
    {
      "name": "DeleteOldAuditLogs",
      "enabled": true,
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["audit-logs/"]
        },
        "actions": {
          "baseBlob": {
            "delete": {
              "daysAfterModificationGreaterThan": 2555
            }
          }
        }
      }
    }
  ]
}
EOF

# Apply lifecycle management policy
az storage account blob-service-properties update \
  --account-name stcsomarchiveprod \
  --resource-group rg-csom-platform-prod \
  --set "deleteRetentionPolicy.enabled=true" \
         "deleteRetentionPolicy.days=7" \
         "containerDeleteRetentionPolicy.enabled=true" \
         "containerDeleteRetentionPolicy.days=7"

# Apply lifecycle management rules (requires Azure CLI extension)
az storage account management-policy create \
  --account-name stcsomarchiveprod \
  --resource-group rg-csom-platform-prod \
  --policy @lifecycle-policy.json
```

### Step 4.7.4: Store Connection String in Key Vault

```bash
# Get Blob Storage connection string
BLOB_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
  --resource-group rg-csom-platform-prod \
  --name stcsomarchiveprod \
  --query connectionString -o tsv)

# Store in Key Vault
az keyvault secret set \
  --vault-name kv-csom-platform-prod \
  --name blob-storage-connection-string \
  --value "$BLOB_STORAGE_CONNECTION_STRING"
```

### Step 4.7.5: Configure Access Control (Optional)

```bash
# Grant Function App Managed Identity access to Blob Storage
FUNCTION_APP_PRINCIPAL_ID=$(az functionapp identity show \
  --resource-group rg-csom-platform-prod \
  --name func-csom-platform-prod \
  --query principalId -o tsv)

# Assign Storage Blob Data Contributor role
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $FUNCTION_APP_PRINCIPAL_ID \
  --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/rg-csom-platform-prod/providers/Microsoft.Storage/storageAccounts/stcsomarchiveprod"
```

### Step 4.7.6: Verify Blob Storage Setup

```bash
# List containers
az storage container list \
  --account-name stcsomarchiveprod \
  --account-key $STORAGE_ACCOUNT_KEY

# Test upload (optional)
echo "Test file" > test-archive.txt
az storage blob upload \
  --account-name stcsomarchiveprod \
  --container-name archive \
  --name test/test-archive.txt \
  --file test-archive.txt \
  --account-key $STORAGE_ACCOUNT_KEY

# Verify upload
az storage blob list \
  --account-name stcsomarchiveprod \
  --container-name archive \
  --account-key $STORAGE_ACCOUNT_KEY

# Clean up test file
az storage blob delete \
  --account-name stcsomarchiveprod \
  --container-name archive \
  --name test/test-archive.txt \
  --account-key $STORAGE_ACCOUNT_KEY
rm test-archive.txt
```

### Step 4.7.7: Update Database Schema for Archiving

Add an `archived` column to the `audit_logs` table to track which logs have been archived:

```sql
-- Connect to PostgreSQL
psql -h psql-csom-platform-prod.postgres.database.azure.com \
     -U csomadmin \
     -d auditdb

-- Add archived flag and timestamp
ALTER TABLE audit.audit_logs 
ADD COLUMN IF NOT EXISTS archived BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS archived_at TIMESTAMP;

-- Create index for archival queries
CREATE INDEX IF NOT EXISTS idx_audit_logs_archived_created_at 
ON audit.audit_logs(archived, created_at);
```

---

## Phase 5: GitLab Repository Setup

### Step 5.1: Create GitLab Project Structure

```
csom-platform/
├── frontend/
│   ├── shell/
│   ├── orders-mfe/
│   ├── products-mfe/
│   ├── account-mfe/
│   └── notifications-mfe/
├── backend/
│   ├── order-service/
│   ├── product-service/
│   ├── customer-service/
│   ├── notification-service/
│   ├── payment-service/
│   └── audit-service/
├── infrastructure/
│   ├── bicep/
│   ├── kubernetes/
│   └── database/
├── apigee/
│   └── proxies/
└── .gitlab-ci.yml
```

### Step 5.2: Configure GitLab CI/CD Variables

In GitLab → Settings → CI/CD → Variables, add:

- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CLIENT_ID` (from service principal)
- `AZURE_CLIENT_SECRET` (from service principal)
- `AZURE_TENANT_ID`
- `ACR_NAME`: `acrcsomplatform`
- `AKS_RESOURCE_GROUP`: `rg-csom-platform-prod`
- `AKS_CLUSTER_NAME`: `aks-csom-platform-prod`
- `POSTGRES_HOST`: `psql-csom-platform-prod.postgres.database.azure.com`
- `ENTRA_INTERNAL_CLIENT_ID`
- `ENTRA_EXTERNAL_CLIENT_ID`
- `ENTRA_INTERNAL_TENANT_ID`
- `ENTRA_EXTERNAL_TENANT_ID`

---

## Phase 6: Backend Services Development

### Step 6.1: Create Example Service

1. **Initialize Spring Boot Project**
   ```bash
   cd backend/example-service
   # Use Spring Initializr or create manually
   # See example-service/ for reference implementation
   ```

2. **Add Dependencies** (see `backend/example-service/pom.xml`)
   - Spring Boot Starter Web
   - Spring Boot Starter Data JPA
   - Spring Boot Starter Security
   - PostgreSQL Driver
   - Azure Service Bus
   - Redis Cache
   - Application Insights

3. **Implement Service** (see code examples in `backend/example-service/`)
   - REST API controllers
   - Service layer with business logic
   - Repository layer for data access
   - Configuration for Azure services
   - Security configuration

4. **Build and Push Docker Image**
   ```bash
   # Replace with your ACR name
   docker build -t your-acr.azurecr.io/example-service:latest .
   docker push your-acr.azurecr.io/example-service:latest
   ```

5. **Deploy to AKS using Helm** (Recommended)
   ```bash
   # Navigate to Helm chart directory
   cd infrastructure/helm/example-service
   
   # Install/upgrade using Helm
   helm upgrade --install example-service . \
     --namespace production \
     --values values-prod.yaml \
     --set image.tag=latest \
     --wait \
     --timeout 5m
   ```
   
   **Alternative: Deploy using kubectl** (for testing)
   ```bash
   kubectl apply -f infrastructure/kubernetes/example-service/
   ```
   
   For detailed Helm usage, see [HELM_GUIDE.md](./HELM_GUIDE.md).

### Step 6.2: Create Additional Services

Repeat the process for additional services:
- Create new service directories following the example-service structure
- Update Helm charts for each service
- Configure service-to-service communication
- Set up monitoring and observability

---

## Phase 7: Frontend Development

### Step 7.1: Create Shell Application

```bash
cd frontend/shell
npm create vite@latest . -- --template react-ts
npm install
# Configure Module Federation (see code examples)
```

### Step 7.2: Create Microfrontends

For each microfrontend:
```bash
cd frontend/orders-mfe
npm create vite@latest . -- --template react-ts
# Configure as remote module (see code examples)
```

### Step 7.3: Configure Authentication

- Install `@azure/msal-react` for Entra ID integration
- Configure MSAL for both internal and external tenants
- Implement token refresh logic

### Step 7.4: Build and Deploy

```bash
# Build all microfrontends
npm run build

# Deploy to Azure Static Web Apps or App Service
az staticwebapp create --name csom-platform-frontend --resource-group rg-csom-platform-prod
```

---

## Phase 8: Apigee Configuration

### Step 8.1: Set Up Apigee Organization

1. **Create Apigee Organization** (if using Apigee X)
   - Or use Azure API Management as alternative

2. **Create API Proxies**
   - External API Proxy
   - Internal API Proxy
   - Notification API Proxy

3. **Configure Policies**
   - JWT validation policies
   - Rate limiting policies
   - CORS policies
   - Request/response transformation

See `apigee/proxies/` for configuration examples.

---

## Phase 9: Integration Setup

### Step 9.1: SOAP Service Integration

1. **Generate SOAP Client** (in Product Service)
   ```bash
   # Use wsimport or Spring WS
   wsimport -keep -s src/main/java https://legacy-erp.example.com/wsdl
   ```

2. **Implement SOAP Client Service**
   - See `backend/product-service/src/main/java/.../soap/` for example

### Step 9.2: REST Service Integration

1. **Payment Gateway Integration** (in Payment Service)
   - Configure REST client with Feign or WebClient
   - Implement retry logic and circuit breakers

2. **Shipping Service Integration** (in Order Service)
   - Similar REST client setup

---

## Phase 10: Monitoring and Observability

### Step 10.1: Application Insights

1. **Create Application Insights**
   ```bash
   az monitor app-insights component create \
     --app csom-platform-insights \
     --location westeurope \
     --resource-group rg-csom-platform-prod
   ```

2. **Configure in Services**
   - Add Application Insights SDK
   - Configure connection string in Key Vault

### Step 10.2: Log Analytics

1. **Create Log Analytics Workspace**
   ```bash
   az monitor log-analytics workspace create \
     --resource-group rg-csom-platform-prod \
     --workspace-name law-csom-platform-prod
   ```

2. **Configure Log Collection**
   - Enable container insights on AKS
   - Configure log forwarding from services

---

## Phase 11: GDPR Compliance Implementation

### Step 11.1: Data Export Endpoint

Implement in Customer Service:
- `GET /api/v1/customers/{id}/gdpr/export`
- Returns all customer data in JSON format

### Step 11.2: Data Deletion Endpoint

Implement in Customer Service:
- `DELETE /api/v1/customers/{id}`
- Soft delete with audit trail
- Cascade to related services

### Step 11.3: Consent Management

- Track user consents in database
- Implement consent withdrawal endpoint
- Audit all consent changes

### Step 11.4: Data Retention Policies

- Configure automated data retention in PostgreSQL
- Implement data anonymization for old records

---

## Phase 12: Testing

### Step 12.1: Unit Tests

```bash
# Run tests for each service
cd backend/order-service
mvn test
```

### Step 12.2: Integration Tests

- Test service-to-service communication
- Test database operations
- Test external integrations (mocked)

### Step 12.3: End-to-End Tests

- Test complete user flows
- Test authentication flows
- Test GDPR operations

---

## Phase 13: Production Deployment

### Step 13.1: Pre-Deployment Checklist

- [ ] All tests passing
- [ ] Security scan completed
- [ ] Performance testing completed
- [ ] GDPR compliance verified
- [ ] Monitoring and alerting configured
- [ ] Backup and DR procedures documented
- [ ] Runbook created

### Step 13.2: Deploy to Production

```bash
# Update GitLab CI/CD to deploy to production namespace
# Manual approval gate in pipeline
```

### Step 13.3: Post-Deployment Verification

- Verify all services are running
- Test API endpoints
- Verify authentication flows
- Check monitoring dashboards
- Verify database connectivity

---

## Phase 14: Documentation

### Step 14.1: API Documentation

- Generate OpenAPI/Swagger docs for all services
- Publish to API documentation portal

### Step 14.2: Runbooks

- Create runbooks for common operations
- Document troubleshooting procedures
- Document rollback procedures

### Step 14.3: User Guides

- Create user guides for internal employees
- Create user guides for external clients

---

## Quick Start Commands

### Local Development

```bash
# Start PostgreSQL locally (Docker)
docker run --name postgres-local -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:15

# Run Order Service locally
cd backend/order-service
mvn spring-boot:run

# Run Frontend locally
cd frontend/shell
npm run dev
```

### Deployment

```bash
# Build and push all services
./scripts/build-all.sh

# Deploy to AKS
./scripts/deploy-all.sh production
```

### Monitoring

```bash
# View logs
kubectl logs -f deployment/order-service -n production

# View service status
kubectl get pods -n production

# Access Application Insights
az monitor app-insights component show --app csom-platform-insights
```

---

## Deployment Authentication Options

This section provides a comprehensive guide to Azure deployment authentication methods: Service Principal, Publish Profile, and Managed Identity. Understanding these options is crucial for secure and efficient deployments.

### Table of Contents

- [Overview](#overview)
- [Service Principal](#service-principal)
- [Publish Profile](#publish-profile)
- [Managed Identity](#managed-identity)
- [Comparison and When to Use Each](#comparison-and-when-to-use-each)
- [Security Best Practices](#security-best-practices)
- [Service-Specific Examples](#service-specific-examples)

---

### Overview

Azure provides three main authentication methods for deployments:

1. **Service Principal** - Non-interactive authentication for CI/CD pipelines and automation
2. **Publish Profile** - Simplified authentication for manual deployments and IDE integration
3. **Managed Identity** - Azure-managed identity for resources accessing other Azure services

Each method has specific use cases, advantages, and security considerations.

---

### Service Principal

#### What is a Service Principal?

A Service Principal is an identity created for use with applications, services, and automation tools to access Azure resources. It's similar to a user account but intended for non-human access.

**Key Characteristics:**
- Non-interactive authentication
- Credentials-based (client ID and secret)
- Scoped permissions via Azure RBAC
- Ideal for CI/CD pipelines and automation
- Supports certificate-based authentication (more secure)

#### When to Use Service Principal

✅ **Use Service Principal for:**
- CI/CD pipelines (GitLab CI/CD, GitHub Actions, Azure DevOps)
- Infrastructure as Code deployments (Terraform, Bicep, ARM templates)
- Automated scripts and tooling
- Service-to-service authentication
- AKS cluster authentication
- ACR (Azure Container Registry) access
- Production deployments requiring audit trails

❌ **Don't use Service Principal for:**
- Manual, one-off deployments from local machines
- Developer workstations (use Azure CLI with user login)
- Interactive scenarios

#### Creating a Service Principal

**Option 1: Using Azure CLI (Recommended)**

```bash
# Create service principal with Contributor role for a resource group
az ad sp create-for-rbac \
  --name sp-gitlab-cicd \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/rg-your-project-name

# Output will include:
# {
#   "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",  # Client ID
#   "password": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",  # Client Secret
#   "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"   # Tenant ID
# }
```

**Option 2: Using Azure Portal**

1. Navigate to **Azure Active Directory** → **App registrations**
2. Click **New registration**
3. Enter a name (e.g., `sp-gitlab-cicd`)
4. Select **Accounts in this organizational directory only**
5. Click **Register**
6. Note the **Application (client) ID** and **Directory (tenant) ID**
7. Go to **Certificates & secrets** → **New client secret**
8. Add description and expiration
9. **Copy the secret value immediately** (shown only once)

#### Assigning Permissions

**Least Privilege Principle:**

```bash
# Assign specific role to resource group (most restrictive)
az role assignment create \
  --assignee <app-id> \
  --role "Contributor" \
  --scope /subscriptions/{subscription-id}/resourceGroups/rg-your-project-name

# Assign role to subscription (broader scope)
az role assignment create \
  --assignee <app-id> \
  --role "Contributor" \
  --scope /subscriptions/{subscription-id}

# Common roles:
# - Contributor: Full access to resources
# - Reader: Read-only access
# - AcrPush: Push images to ACR
# - Kubernetes Cluster Admin: Manage AKS clusters
```

#### Using Service Principal in CI/CD

**GitLab CI/CD Example:**

```yaml
deploy:
  stage: deploy
  image: mcr.microsoft.com/azure-cli:latest
  before_script:
    - az login --service-principal \
        -u $AZURE_CLIENT_ID \
        -p $AZURE_CLIENT_SECRET \
        --tenant $AZURE_TENANT_ID
  script:
    - az aks get-credentials \
        --resource-group $AKS_RESOURCE_GROUP \
        --name $AKS_CLUSTER_NAME
    - kubectl apply -f deployment.yaml
```

**GitLab CI/CD Variables:**
- `AZURE_CLIENT_ID` - Service principal client ID (appId)
- `AZURE_CLIENT_SECRET` - Service principal secret (password)
- `AZURE_TENANT_ID` - Azure tenant ID
- `AZURE_SUBSCRIPTION_ID` - Azure subscription ID

**Terraform Example:**

```hcl
# Configure Azure Provider
provider "azurerm" {
  features {}
  
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}
```

**Bicep/ARM Example:**

```bash
# Login with service principal
az login --service-principal \
  -u $AZURE_CLIENT_ID \
  -p $AZURE_CLIENT_SECRET \
  --tenant $AZURE_TENANT_ID

# Deploy infrastructure
az deployment group create \
  --resource-group rg-your-project \
  --template-file main.bicep
```

#### Service Principal Security Best Practices

1. **Use Certificate Authentication (More Secure)**
   ```bash
   # Create service principal with certificate
   az ad sp create-for-rbac \
     --name sp-gitlab-cicd \
     --cert @cert.pem \
     --create-cert
   ```

2. **Implement Least Privilege**
   - Assign minimum required permissions
   - Scope to specific resource groups, not entire subscription
   - Use role-based access control (RBAC)

3. **Rotate Credentials Regularly**
   ```bash
   # Create new secret
   az ad sp credential reset \
     --name sp-gitlab-cicd \
     --append
   
   # Update CI/CD variables with new secret
   # Remove old secret after verification
   ```

4. **Store Secrets Securely**
   - Use GitLab CI/CD protected variables
   - Use Azure Key Vault for secret storage
   - Never commit secrets to version control

5. **Monitor and Audit**
   - Enable Azure AD audit logs
   - Review service principal activity regularly
   - Set up alerts for unusual activity

---

### Publish Profile

#### What is a Publish Profile?

A Publish Profile is an XML file containing deployment credentials for Azure App Service, Azure Functions, or Azure Static Web Apps. It simplifies deployment from IDEs like Visual Studio, Visual Studio Code, or deployment tools.

**Key Characteristics:**
- XML file format (`.PublishSettings`)
- Contains deployment endpoint and credentials
- One profile per Azure resource
- Simplified deployment workflow
- Ideal for manual deployments and IDE integration

#### When to Use Publish Profile

✅ **Use Publish Profile for:**
- Manual deployments from local machines
- Visual Studio / Visual Studio Code deployments
- Quick testing and development
- One-off deployments
- Azure Functions deployment from IDE
- Static Web Apps deployment
- App Service deployment from local machine

❌ **Don't use Publish Profile for:**
- CI/CD pipelines (use Service Principal)
- Production automated deployments
- Infrastructure as Code (use Service Principal)
- Service-to-service authentication

#### Downloading Publish Profile

**Option 1: Azure Portal**

1. Navigate to your **App Service** or **Function App**
2. Click **Get publish profile** (top menu)
3. Save the `.PublishSettings` file
4. **Keep it secure** - contains deployment credentials

**Option 2: Azure CLI**

```bash
# Download publish profile for App Service
az webapp deployment list-publishing-profiles \
  --name your-app-service \
  --resource-group rg-your-project \
  --xml > publish-profile.xml

# Download publish profile for Function App
az functionapp deployment list-publishing-profiles \
  --name your-function-app \
  --resource-group rg-your-project \
  --xml > publish-profile.xml
```

#### Using Publish Profile

**Visual Studio:**

1. Right-click project → **Publish**
2. Select **Azure** → **Azure App Service**
3. Import publish profile
4. Select the `.PublishSettings` file
5. Click **Publish**

**Visual Studio Code:**

1. Install **Azure App Service** extension
2. Sign in to Azure
3. Right-click project → **Deploy to Web App**
4. Or use publish profile file directly

**Azure CLI:**

```bash
# Deploy using publish profile
az webapp deploy \
  --name your-app-service \
  --resource-group rg-your-project \
  --src-path ./app.zip \
  --type zip
```

**MSBuild:**

```bash
# Publish and deploy using publish profile
msbuild /p:PublishProfile=publish-profile.pubxml \
  /p:WebPublishMethod=FileSystem \
  /p:PublishUrl=./publish
```

#### Publish Profile Structure

```xml
<?xml version="1.0" encoding="utf-8"?>
<publishData>
  <publishProfile
    profileName="your-app-service - Web Deploy"
    publishMethod="MSDeploy"
    publishUrl="your-app-service.scm.azurewebsites.net:443"
    userName="$your-app-service"
    userPWD="deployment-password"
    destinationAppUrl="https://your-app-service.azurewebsites.net"
    SQLServerDBConnectionString=""
    mySQLDBConnectionString=""
    hostingProviderForumLink=""
    controlPanelLink="https://portal.azure.com"
    webSystem="WebSites">
    <databases />
  </publishProfile>
</publishData>
```

#### Publish Profile Security Best Practices

1. **Protect the File**
   - Store in secure location
   - Never commit to version control
   - Add to `.gitignore`
   - Share only with authorized personnel

2. **Rotate Credentials**
   ```bash
   # Reset deployment credentials
   az webapp deployment user set \
     --user-name <username> \
     --password <new-password>
   ```

3. **Use Scoped Access**
   - Download profile only when needed
   - Delete after use if possible
   - Use Service Principal for automation instead

4. **Monitor Usage**
   - Review deployment logs
   - Set up alerts for deployments
   - Audit who has access to publish profiles

---

### Managed Identity

#### What is Managed Identity?

Managed Identity is an Azure feature that provides Azure services with an automatically managed identity in Azure AD. It eliminates the need for credentials in code or configuration files.

**Key Characteristics:**
- No credentials to manage
- Automatically rotated by Azure
- Integrated with Azure AD
- Two types: System-assigned and User-assigned
- Most secure option for Azure-to-Azure authentication

#### Types of Managed Identity

**1. System-Assigned Managed Identity**
- Created and tied to a specific Azure resource
- Lifecycle tied to the resource (deleted with resource)
- Unique to each resource
- Cannot be shared

**2. User-Assigned Managed Identity**
- Created as standalone Azure resource
- Can be assigned to multiple resources
- Independent lifecycle
- Reusable across resources

#### When to Use Managed Identity

✅ **Use Managed Identity for:**
- Azure services accessing other Azure services
- Applications running on Azure (App Service, Functions, AKS)
- Accessing Azure Key Vault from Azure services
- Accessing Azure Storage from Azure services
- Accessing Azure SQL Database from Azure services
- Eliminating secrets from code and configuration

❌ **Don't use Managed Identity for:**
- CI/CD pipelines (use Service Principal)
- Local development (use Azure CLI with user login)
- Non-Azure resources
- Cross-tenant scenarios (use Service Principal)

#### Enabling Managed Identity

**System-Assigned (Azure Portal):**

1. Navigate to your Azure resource (App Service, Function App, etc.)
2. Go to **Identity** settings
3. Select **System assigned** tab
4. Turn **Status** to **On**
5. Click **Save**
6. Note the **Object (principal) ID**

**System-Assigned (Azure CLI):**

```bash
# Enable system-assigned managed identity for App Service
az webapp identity assign \
  --name your-app-service \
  --resource-group rg-your-project

# Enable for Function App
az functionapp identity assign \
  --name your-function-app \
  --resource-group rg-your-project

# Enable for AKS (requires addon)
az aks update \
  --name your-aks-cluster \
  --resource-group rg-your-project \
  --enable-managed-identity
```

**User-Assigned (Azure CLI):**

```bash
# Create user-assigned managed identity
az identity create \
  --name mi-your-identity \
  --resource-group rg-your-project

# Assign to App Service
az webapp identity assign \
  --name your-app-service \
  --resource-group rg-your-project \
  --identities mi-your-identity

# Get identity client ID
az identity show \
  --name mi-your-identity \
  --resource-group rg-your-project \
  --query clientId -o tsv
```

#### Granting Permissions to Managed Identity

**Access Azure Key Vault:**

```bash
# Grant Key Vault access to managed identity
az keyvault set-policy \
  --name your-key-vault \
  --object-id <managed-identity-object-id> \
  --secret-permissions get list
```

**Access Azure Storage:**

```bash
# Assign Storage Blob Data Reader role
az role assignment create \
  --assignee <managed-identity-object-id> \
  --role "Storage Blob Data Reader" \
  --scope /subscriptions/{subscription-id}/resourceGroups/rg-your-project/providers/Microsoft.Storage/storageAccounts/your-storage-account
```

**Access Azure SQL Database:**

```sql
-- Create user for managed identity in SQL Database
CREATE USER [your-app-service] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [your-app-service];
ALTER ROLE db_datawriter ADD MEMBER [your-app-service];
```

#### Using Managed Identity in Code

**C# / .NET Example:**

```csharp
// Using Azure.Identity
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var credential = new DefaultAzureCredential();
var client = new SecretClient(
    new Uri("https://your-key-vault.vault.azure.net/"),
    credential
);

var secret = await client.GetSecretAsync("my-secret");
```

**Java / Spring Boot Example:**

```java
// Using Azure Identity
import com.azure.identity.DefaultAzureCredentialBuilder;
import com.azure.security.keyvault.secrets.SecretClient;
import com.azure.security.keyvault.secrets.SecretClientBuilder;

SecretClient secretClient = new SecretClientBuilder()
    .vaultUrl("https://your-key-vault.vault.azure.net/")
    .credential(new DefaultAzureCredentialBuilder().build())
    .buildClient();

String secret = secretClient.getSecret("my-secret").getValue();
```

**Python Example:**

```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

credential = DefaultAzureCredential()
client = SecretClient(
    vault_url="https://your-key-vault.vault.azure.net/",
    credential=credential
)

secret = client.get_secret("my-secret")
```

#### Managed Identity Security Best Practices

1. **Use System-Assigned When Possible**
   - Simpler to manage
   - Automatic lifecycle management
   - No risk of orphaned identities

2. **Use User-Assigned for Multiple Resources**
   - When same identity needed across resources
   - Easier to manage permissions centrally

3. **Implement Least Privilege**
   - Grant minimum required permissions
   - Use RBAC roles appropriately
   - Regular permission audits

4. **Monitor Usage**
   - Review managed identity usage
   - Set up alerts for access failures
   - Audit identity assignments

---

### Comparison and When to Use Each

| Feature | Service Principal | Publish Profile | Managed Identity |
|---------|------------------|-----------------|------------------|
| **Use Case** | CI/CD, Automation | Manual, IDE | Azure-to-Azure |
| **Credentials** | Client ID + Secret | XML file | None (managed) |
| **Security** | High (with rotation) | Medium | Highest |
| **Scope** | Subscription/Resource Group | Single Resource | Azure Resources |
| **Lifecycle** | Manual management | Manual management | Automatic |
| **CI/CD** | ✅ Yes | ❌ No | ❌ No |
| **Local Dev** | ✅ Yes | ✅ Yes | ❌ No |
| **Azure Services** | ✅ Yes | ❌ No | ✅ Yes |
| **Audit Trail** | ✅ Yes | Limited | ✅ Yes |

**Decision Tree:**

```
Are you deploying from CI/CD pipeline?
├─ Yes → Use Service Principal
└─ No
   ├─ Is it an Azure service accessing another Azure service?
   │  ├─ Yes → Use Managed Identity
   │  └─ No
   │     ├─ Manual deployment from local machine?
   │     │  ├─ Yes → Use Publish Profile (for quick deployment)
   │     │  └─ No → Use Service Principal
   │     └─ Automated script?
   │        └─ Yes → Use Service Principal
```

---

### Security Best Practices

#### General Security Practices

1. **Never Commit Credentials**
   - Use `.gitignore` for publish profiles
   - Store secrets in CI/CD variables
   - Use Azure Key Vault for secrets

2. **Implement Least Privilege**
   - Grant minimum required permissions
   - Scope to specific resource groups
   - Use role-based access control

3. **Rotate Credentials Regularly**
   - Service Principal secrets: Every 90 days
   - Publish Profile credentials: Every 90 days
   - Managed Identity: Automatic (no action needed)

4. **Monitor and Audit**
   - Enable Azure AD audit logs
   - Review access logs regularly
   - Set up alerts for unusual activity

5. **Use Secure Storage**
   - Azure Key Vault for secrets
   - GitLab CI/CD protected variables
   - Encrypted secret management

#### Service Principal Security

- Use certificate authentication when possible
- Implement credential rotation policy
- Monitor service principal activity
- Use separate service principals per environment

#### Publish Profile Security

- Store in secure location
- Delete after use if possible
- Rotate deployment credentials regularly
- Limit access to authorized personnel only

#### Managed Identity Security

- Prefer system-assigned when possible
- Grant minimum required permissions
- Monitor identity usage
- Regular permission audits

---

### Service-Specific Examples

#### Azure App Service

**Service Principal (CI/CD):**
```yaml
# GitLab CI/CD
deploy-app-service:
  script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - az webapp deployment source config-zip \
        --name your-app-service \
        --resource-group rg-your-project \
        --src app.zip
```

**Publish Profile (Manual):**
```bash
# Download publish profile
az webapp deployment list-publishing-profiles \
  --name your-app-service \
  --resource-group rg-your-project \
  --xml > publish-profile.xml

# Deploy using Visual Studio or VS Code with publish profile
```

**Managed Identity (Access Key Vault):**
```bash
# Enable managed identity
az webapp identity assign \
  --name your-app-service \
  --resource-group rg-your-project

# Grant Key Vault access
az keyvault set-policy \
  --name your-key-vault \
  --object-id <managed-identity-object-id> \
  --secret-permissions get list
```

#### Azure Functions

**Service Principal (CI/CD):**
```yaml
# GitLab CI/CD
deploy-function:
  script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - az functionapp deployment source config-zip \
        --name your-function-app \
        --resource-group rg-your-project \
        --src function.zip
```

**Publish Profile (Manual):**
```bash
# Download publish profile
az functionapp deployment list-publishing-profiles \
  --name your-function-app \
  --resource-group rg-your-project \
  --xml > publish-profile.xml
```

**Managed Identity (Access Storage):**
```bash
# Enable managed identity
az functionapp identity assign \
  --name your-function-app \
  --resource-group rg-your-project

# Grant Storage access
az role assignment create \
  --assignee <managed-identity-object-id> \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/{subscription-id}/resourceGroups/rg-your-project/providers/Microsoft.Storage/storageAccounts/your-storage-account
```

#### Azure Static Web Apps

**Service Principal (CI/CD):**
```yaml
# GitLab CI/CD
deploy-static-web-app:
  script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - az staticwebapp deploy \
        --name your-static-web-app \
        --resource-group rg-your-project \
        --source-location ./dist
```

**Publish Profile (Manual):**
- Static Web Apps use deployment tokens
- Get token from Azure Portal → Static Web App → Manage deployment token
- Use in deployment tools or VS Code extension

#### Azure Kubernetes Service (AKS)

**Service Principal (CI/CD):**
```yaml
# GitLab CI/CD
deploy-aks:
  script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - az aks get-credentials --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME
    - kubectl apply -f deployment.yaml
```

**Managed Identity (Pod Identity):**
```bash
# Enable managed identity for AKS
az aks update \
  --name your-aks-cluster \
  --resource-group rg-your-project \
  --enable-managed-identity

# Use Azure Key Vault Provider for Secrets Store CSI Driver
# Pods can use managed identity to access Key Vault
```

#### Azure Container Registry (ACR)

**Service Principal (CI/CD):**
```yaml
# GitLab CI/CD
push-to-acr:
  script:
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - az acr login --name your-acr
    - docker push your-acr.azurecr.io/your-image:latest
```

**Managed Identity (ACR Pull from AKS):**
```bash
# Attach ACR to AKS using managed identity
az aks update \
  --name your-aks-cluster \
  --resource-group rg-your-project \
  --attach-acr your-acr
```

---

## Troubleshooting

### Common Issues

1. **Service can't connect to database**
   - Check firewall rules
   - Verify connection string
   - Check network policies

2. **Authentication failures**
   - Verify JWT token format
   - Check Entra ID configuration
   - Verify token expiration

3. **Service Bus connection issues**
   - Check connection string
   - Verify topic/subscription exists
   - Check network connectivity

4. **CI/CD pipeline failures**
   - Check service principal permissions
   - Verify ACR access
   - Check AKS credentials

---

## Next Steps

1. Review [ARCHITECTURE.md](./ARCHITECTURE.md) for architecture details
2. Set up development environment (see Phase 1)
3. Start with one example service as PoC (see Phase 6)
4. Gradually add other services
5. Implement frontend incrementally (see Phase 7)
6. Set up monitoring and observability (see Phase 10 and [OPERATIONS_GUIDE.md](./OPERATIONS_GUIDE.md))
7. Implement testing strategy (see Phase 12 and [TESTING_STRATEGY.md](./TESTING_STRATEGY.md))
8. Conduct security review (see [ARCHITECTURE.md](./ARCHITECTURE.md) Section 5)
9. Performance testing (see [TESTING_STRATEGY.md](./TESTING_STRATEGY.md) Section 6)
10. Production deployment (see Phase 13)

---

## Related Documents

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Comprehensive architecture blueprint
- [OPERATIONS_GUIDE.md](./OPERATIONS_GUIDE.md) - Operations procedures and runbooks
- [TESTING_STRATEGY.md](./TESTING_STRATEGY.md) - Testing guidelines and strategies
- [GLOSSARY.md](./GLOSSARY.md) - Technical terms and acronyms
- [INFRASTRUCTURE_DEPLOYMENT_GUIDE.md](./INFRASTRUCTURE_DEPLOYMENT_GUIDE.md) - Infrastructure deployment guide
- [HELM_GUIDE.md](./HELM_GUIDE.md) - Helm charts guide
- [GDPR_COMPLIANCE.md](./GDPR_COMPLIANCE.md) - GDPR compliance implementation
- [API_GATEWAY_COMPARISON.md](./API_GATEWAY_COMPARISON.md) - API Gateway comparison
- [SECRETS_MANAGEMENT_COMPARISON.md](./SECRETS_MANAGEMENT_COMPARISON.md) - Secrets management comparison

