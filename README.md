# Azure Architectural Blueprint
## Customer Service & Order Management Platform

A comprehensive Proof of Concept (PoC) system demonstrating a modern, cloud-native microservices architecture on Microsoft Azure with React microfrontends, Spring Boot services, and full CI/CD automation.

---

## 📋 Overview

This PoC implements a **Customer Service & Order Management Platform** with the following key features:

- **React-based web application** with microfrontends architecture
- **Spring Boot/Java REST microservices** deployed on Azure Kubernetes Service (AKS)
- **PostgreSQL database** for persistent storage
- **Azure Blob Storage** for file archiving and long-term storage
- **Entra ID JWT authentication** for employees
- **Entra External ID** for client authentication
- **Apigee API Management** or **Azure API Management** for API governance
- **Integration with legacy SOAP services** (ERP system)
- **Integration with external REST services** (payment gateway, shipping)
- **GDPR compliance** with data export, deletion, and audit capabilities
- **Real-time notifications** between internal and external applications
- **GitLab CI/CD** for automated deployments on Azure

---

## 🏗️ Architecture

### System Components

```
┌─────────────────┐
│  React Shell    │  (Microfrontends Host)
│  + 5 MFE Apps   │
└────────┬────────┘
         │
┌────────▼────────┐
│  Apigee Gateway │  (API Management)
└────────┬────────┘
         │
┌────────▼────────┐
│  AKS Cluster    │  (Kubernetes)
│  ┌──────────┐   │
│  │ Order    │   │  Spring Boot Services
│  │ Product  │   │
│  │ Customer │   │
│  │ Payment  │   │
│  │ Notify   │   │
│  │ Audit    │   │
│  └──────────┘   │
└────────┬────────┘
         │
┌────────▼────────┐
│  PostgreSQL     │  (Azure Flexible Server)
└─────────────────┘

┌─────────────────┐
│  Azure Blob     │  (Archiving & Storage)
│  Storage        │
│  • Archive      │
│  • Audit Logs   │
│  • GDPR Data    │
└─────────────────┘
```

### Key Services

1. **Order Service** - Order creation, tracking, and management
2. **Product Service** - Product catalog and inventory (integrates with legacy SOAP ERP)
3. **Customer Service** - Customer profiles and GDPR compliance
4. **Payment Service** - Payment processing (integrates with REST payment gateway)
5. **Notification Service** - Real-time notifications via WebSocket/SSE
6. **Audit Service** - GDPR audit trails and security logging

### Frontend Microfrontends

1. **Orders MFE** - Order placement and tracking
2. **Products MFE** - Product catalog and search
3. **Account MFE** - User profile and GDPR data management
4. **Notifications MFE** - Real-time notification center
5. **Admin Dashboard MFE** - Internal employee dashboard

---

## 📚 Documentation

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Comprehensive technical architecture blueprint
- **[IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)** - Step-by-step implementation guide
- **[GDPR_COMPLIANCE.md](./GDPR_COMPLIANCE.md)** - GDPR compliance implementation details
- **[INFRASTRUCTURE_AS_CODE_COMPARISON.md](./INFRASTRUCTURE_AS_CODE_COMPARISON.md)** - Bicep vs Terraform vs ARM Templates comparison
- **[API_GATEWAY_COMPARISON.md](./API_GATEWAY_COMPARISON.md)** - Apigee vs Azure API Management comparison
- **[SECRETS_MANAGEMENT_COMPARISON.md](./SECRETS_MANAGEMENT_COMPARISON.md)** - HashiCorp Vault vs Azure Key Vault comparison
- **[HELM_GUIDE.md](./HELM_GUIDE.md)** - Helm charts guide for Kubernetes deployments
- **[INFRASTRUCTURE_DEPLOYMENT_GUIDE.md](./INFRASTRUCTURE_DEPLOYMENT_GUIDE.md)** - Infrastructure deployment guide with CI/CD examples and best practices

---

## 🚀 Quick Start

### Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI installed and configured
- Docker installed
- kubectl installed
- **Helm 3.x** (for Kubernetes deployments)
- Maven 3.9+ and Java 17+
- Node.js 20+ and npm
- GitLab account (or GitLab CI/CD runner)
- **Terraform >= 1.5.0** (optional, for Terraform deployment)
- **Azure CLI** (for ARM templates and Bicep)

### 1. Clone Repository

```bash
git clone <repository-url>
cd azure-architectural-blueprint
```

### 2. Set Up Azure Resources

#### Option A: Using ARM Templates (Azure Native JSON)

```bash
# Login to Azure
az login

# Create resource group
az group create --name rg-csom-platform-prod --location westeurope

# Deploy infrastructure using ARM templates
az deployment group create \
  --resource-group rg-csom-platform-prod \
  --template-file infrastructure/arm/azuredeploy.json \
  --parameters @infrastructure/arm/azuredeploy.parameters.json
```

See [infrastructure/arm/README.md](./infrastructure/arm/README.md) for detailed ARM template setup instructions.

#### Option B: Using Bicep (Azure Native DSL)

```bash
# Login to Azure
az login

# Deploy infrastructure using Bicep
az deployment group create \
  --resource-group rg-csom-platform-prod \
  --template-file infrastructure/bicep/main.bicep \
  --parameters postgresAdminPassword='YourSecurePassword123!'
```

#### Option C: Using Terraform (Multi-Cloud)

```bash
# Login to Azure
az login

# Navigate to Terraform directory
cd infrastructure/terraform

# Initialize Terraform
terraform init

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

See [infrastructure/terraform/README.md](./infrastructure/terraform/README.md) for detailed Terraform setup instructions.

### 3. Configure Entra ID

1. **Create App Registration for Internal Users (Employees)**
   - Navigate to Azure Portal → Azure Active Directory → App registrations
   - Create new registration: `csom-platform-internal`
   - Note: Client ID and Tenant ID

2. **Configure Entra External ID for External Users (Clients)**
   - Navigate to Azure Portal → Azure AD External Identities
   - Create user flow for sign-up/sign-in
   - Create app registration: `csom-platform-external`
   - Note: Client ID and Tenant ID

### 4. Set Up GitLab CI/CD Variables

In GitLab → Settings → CI/CD → Variables, add:

- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CLIENT_ID` (service principal)
- `AZURE_CLIENT_SECRET` (service principal)
- `AZURE_TENANT_ID`
- `ACR_NAME`: `acrcsomplatform`
- `AKS_RESOURCE_GROUP`: `rg-csom-platform-prod`
- `AKS_CLUSTER_NAME`: `aks-csom-platform-prod`
- `POSTGRES_HOST`: `psql-csom-platform-prod.postgres.database.azure.com`
- `ENTRA_INTERNAL_CLIENT_ID`
- `ENTRA_EXTERNAL_CLIENT_ID`
- `ENTRA_INTERNAL_TENANT_ID`
- `ENTRA_EXTERNAL_TENANT_ID`

### 5. Build and Deploy Services

#### Backend Services

```bash
# Build Order Service
cd backend/order-service
mvn clean package
docker build -t acrcsomplatform.azurecr.io/order-service:latest .
docker push acrcsomplatform.azurecr.io/order-service:latest

# Deploy to AKS
kubectl apply -f infrastructure/kubernetes/order-service/
```

#### Frontend

```bash
# Build Shell Application
cd frontend/shell
npm install
npm run build

# Deploy to Azure Static Web Apps
az staticwebapp create \
  --name csom-platform-frontend \
  --resource-group rg-csom-platform-prod
```

### 6. Configure Apigee API Proxies

1. Import API proxies from `apigee/proxies/`
2. Configure JWT validation policies
3. Set up rate limiting
4. Deploy proxies

---

## 🧪 Testing

### Local Development

```bash
# Start PostgreSQL locally
docker run --name postgres-local \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 -d postgres:15

# Run Order Service locally
cd backend/order-service
mvn spring-boot:run

# Run Frontend locally
cd frontend/shell
npm run dev
```

### API Testing

```bash
# Get authentication token (example)
TOKEN=$(az account get-access-token --resource api://your-client-id --query accessToken -o tsv)

# Test Order Service
curl -X GET https://api.example.com/api/v1/orders \
  -H "Authorization: Bearer $TOKEN"
```

---

## 📁 Project Structure

```
azure-architectural-blueprint/
├── frontend/
│   ├── shell/                 # React shell application
│   ├── orders-mfe/            # Orders microfrontend
│   ├── products-mfe/          # Products microfrontend
│   ├── account-mfe/           # Account microfrontend
│   └── notifications-mfe/     # Notifications microfrontend
├── backend/
│   ├── order-service/         # Order management service
│   ├── product-service/       # Product catalog service
│   ├── customer-service/      # Customer & GDPR service
│   ├── payment-service/       # Payment processing service
│   ├── notification-service/  # Notification service
│   └── audit-service/         # Audit & logging service
├── infrastructure/
│   ├── arm/                   # ARM templates (JSON)
│   ├── bicep/                 # Azure Bicep templates
│   ├── terraform/             # Terraform configuration files
│   ├── kubernetes/            # Kubernetes manifests
│   ├── helm/                  # Helm charts for microservices
│   └── database/              # Database migrations
├── apigee/
│   └── proxies/               # Apigee API proxy configs
├── azure-api-management/      # Azure API Management configs
│   ├── apis/                  # API definitions (OpenAPI)
│   └── policies/              # API Management policies
├── hashicorp-vault/           # HashiCorp Vault configs
│   ├── kubernetes/            # Vault deployment on AKS
│   └── policies/              # Vault access policies
├── API_GATEWAY_COMPARISON.md  # Apigee vs Azure API Management comparison
├── SECRETS_MANAGEMENT_COMPARISON.md  # HashiCorp Vault vs Azure Key Vault comparison
├── INFRASTRUCTURE_AS_CODE_COMPARISON.md  # Bicep vs Terraform comparison
├── ARCHITECTURE.md            # Architecture documentation
├── IMPLEMENTATION_GUIDE.md    # Implementation guide
├── GDPR_COMPLIANCE.md         # GDPR compliance guide
├── .gitlab-ci.yml             # GitLab CI/CD pipeline
└── README.md                  # This file
```

---

## 🔐 Security

- **Authentication**: Entra ID (employees) and Entra External ID (clients)
- **Authorization**: JWT-based with role-based access control (RBAC)
- **API Security**: Apigee API Management with rate limiting and policies
- **Data Encryption**: Encryption at rest and in transit
- **Secrets Management**: Azure Key Vault
- **Network Security**: Private AKS cluster, network policies
- **File Archiving**: Azure Blob Storage with lifecycle management

---

## 📊 Monitoring & Observability

- **Application Insights**: Application performance monitoring
- **Azure Monitor**: Infrastructure and application metrics
- **Log Analytics**: Centralized logging
- **Distributed Tracing**: Request correlation across services

---

## 🔄 CI/CD Pipeline

The GitLab CI/CD pipeline uses **Helm** for Kubernetes deployments and includes:

1. **Build** - Compile and test code
2. **Security Scan** - Vulnerability scanning
3. **Validate Helm** - Validate Helm charts before deployment
4. **Build Images** - Docker image creation and push to ACR
5. **Deploy Dev** - Automatic deployment to dev environment using Helm
6. **Integration Tests** - Service integration testing
7. **Deploy Staging** - Deployment to staging using Helm
8. **E2E Tests** - End-to-end testing
9. **Deploy Production** - Manual approval for production deployment using Helm

**Helm Integration**: All Kubernetes deployments use Helm charts located in `infrastructure/helm/`. The pipeline validates charts, uses environment-specific values files, and supports easy rollbacks. See [HELM_GUIDE.md](./HELM_GUIDE.md) for details.

---

## 🛡️ GDPR Compliance

The platform implements comprehensive GDPR compliance:

- ✅ **Right to Access**: Data export endpoints
- ✅ **Right to Erasure**: Soft delete with audit trail
- ✅ **Right to Rectification**: Data update capabilities
- ✅ **Consent Management**: Consent tracking and withdrawal
- ✅ **Data Minimization**: Only collect necessary data
- ✅ **Breach Notification**: Automated alerting
- ✅ **Privacy by Design**: Built into architecture

See [GDPR_COMPLIANCE.md](./GDPR_COMPLIANCE.md) for detailed implementation.

---

## 🔌 Integrations

### Legacy SOAP Service
- **Service**: Product Service → Legacy ERP System
- **Technology**: Spring WS (Web Services)
- **Use Case**: Inventory synchronization

### External REST Services
- **Payment Gateway**: Payment processing
- **Shipping Service**: Shipping rates and tracking

---

## 📈 Scalability

- **Horizontal Scaling**: AKS cluster and pod autoscaling
- **Database Scaling**: Read replicas for read-heavy workloads
- **Caching**: Redis Cache for frequently accessed data
- **CDN**: Azure Front Door for static assets
- **Archiving**: Azure Blob Storage with automated lifecycle management for cost optimization

---

## 🚨 Troubleshooting

### Common Issues

1. **Service can't connect to database**
   - Check firewall rules in PostgreSQL
   - Verify connection string in Key Vault
   - Check network policies in AKS

2. **Authentication failures**
   - Verify JWT token format
   - Check Entra ID configuration
   - Verify token expiration

3. **CI/CD pipeline failures**
   - Check service principal permissions
   - Verify ACR access
   - Check AKS credentials

See [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) for detailed troubleshooting.

---

## 📝 Next Steps

1. Review architecture and adjust as needed
2. Set up development environment
3. Start with one service (Order Service) as PoC
4. Gradually add other services
5. Implement frontend incrementally
6. Add monitoring and observability
7. Conduct security review
8. Performance testing
9. Production deployment

---

## 📞 Support

For questions or issues:
- Review documentation in `ARCHITECTURE.md` and `IMPLEMENTATION_GUIDE.md`
- Check GitLab issues
- Contact the development team

---

## 📄 License

[Add your license information here]

---

## 🙏 Acknowledgments

This PoC demonstrates modern cloud-native architecture patterns using:
- Microsoft Azure services
- Spring Boot microservices
- React microfrontends
- Kubernetes orchestration
- GitLab CI/CD

---

**Last Updated**: January 2024
