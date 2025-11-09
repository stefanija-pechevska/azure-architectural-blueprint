# Step-by-Step Implementation Guide
## Customer Service & Order Management Platform

This guide provides detailed steps to implement the PoC system from scratch.

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
- [Quick Start Commands](#quick-start-commands)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

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

For detailed ARM template setup instructions, see [infrastructure/arm/README.md](../infrastructure/arm/README.md).

**Note:** After deploying with ARM templates, continue with the remaining phases (Database Setup, AKS Setup, etc.) as the infrastructure resources are now created.

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

### Step 6.1: Create Order Service

1. **Initialize Spring Boot Project**
   ```bash
   cd backend/order-service
   # Use Spring Initializr or create manually
   ```

2. **Add Dependencies** (see `backend/order-service/pom.xml`)

3. **Implement Service** (see code examples in `backend/order-service/`)

4. **Build and Push Docker Image**
   ```bash
   docker build -t acrcsomplatform.azurecr.io/order-service:latest .
   docker push acrcsomplatform.azurecr.io/order-service:latest
   ```

5. **Deploy to AKS using Helm** (Recommended)
   ```bash
   # Navigate to Helm chart directory
   cd infrastructure/helm/order-service
   
   # Install/upgrade using Helm
   helm upgrade --install order-service . \
     --namespace production \
     --values values-prod.yaml \
     --set image.tag=latest \
     --wait \
     --timeout 5m
   ```
   
   **Alternative: Deploy using kubectl** (for testing)
   ```bash
   kubectl apply -f infrastructure/kubernetes/order-service/
   ```
   
   For detailed Helm usage, see [HELM_GUIDE.md](./HELM_GUIDE.md).

### Step 6.2: Repeat for Other Services

- Product Service
- Customer Service
- Notification Service
- Payment Service
- Audit Service

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

1. Review architecture and adjust as needed
2. Set up development environment
3. Start with one service (Order Service) as PoC
4. Gradually add other services
5. Implement frontend incrementally
6. Add monitoring and observability
7. Conduct security review
8. Performance testing
9. Production deployment

