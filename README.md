# Azure Cloud-Native Architecture Template

A ready-to-use architecture template for bootstrapping cloud-native applications on Microsoft Azure. This template provides a comprehensive foundation with React microfrontends, Spring Boot microservices, and full CI/CD automation, complete with examples for each Azure service and component.

---

## 📋 Overview

This template provides a **production-ready cloud-native architecture** with the following components:

- **React-based web application** with microfrontends architecture (Module Federation)
- **Spring Boot/Java REST microservices** deployed on Azure Kubernetes Service (AKS)
- **PostgreSQL database** for persistent storage (Azure Database for PostgreSQL)
- **Azure Blob Storage** for file archiving and long-term storage
- **Entra ID** for authentication (internal and external users)
- **API Management** (Apigee or Azure API Management) for API governance
- **Service Bus** for asynchronous messaging
- **Redis Cache** for caching and session management
- **Azure Functions** for serverless workloads
- **Key Vault** for secrets management
- **Application Insights** for monitoring and observability
- **GitLab CI/CD** for automated deployments

---

## 🏗️ Architecture

### System Components

```
┌─────────────────┐
│  React Shell    │  (Microfrontends Host)
│  + MFE Apps     │
└────────┬────────┘
         │
┌────────▼────────┐
│  API Gateway    │  (Apigee / Azure API Management)
└────────┬────────┘
         │
┌────────▼────────┐
│  AKS Cluster    │  (Kubernetes)
│  ┌──────────┐   │
│  │ Service 1│   │  Spring Boot Microservices
│  │ Service 2│   │
│  │ Service N│   │
│  └──────────┘   │
└────────┬────────┘
         │
┌────────▼────────┐
│  PostgreSQL     │  (Azure Database for PostgreSQL)
└─────────────────┘

┌─────────────────┐
│  Azure Services │
│  • Blob Storage │  (Archiving & Storage)
│  • Service Bus  │  (Messaging)
│  • Redis Cache  │  (Caching)
│  • Key Vault    │  (Secrets)
│  • Functions    │  (Serverless)
└─────────────────┘
```

### Key Components

1. **Microservices** - Spring Boot services deployed on AKS
2. **Frontend** - React application with microfrontends architecture
3. **API Gateway** - API management and governance
4. **Database** - PostgreSQL for persistent storage
5. **Storage** - Azure Blob Storage for files and archiving
6. **Messaging** - Azure Service Bus for asynchronous communication
7. **Caching** - Redis Cache for performance optimization
8. **Secrets** - Azure Key Vault or HashiCorp Vault
9. **Monitoring** - Application Insights and Azure Monitor
10. **CI/CD** - GitLab CI/CD for automated deployments

---

## 📚 Documentation

### Core Documentation
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Comprehensive technical architecture blueprint
- **[IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)** - Step-by-step implementation guide
- **[OPERATIONS_GUIDE.md](./OPERATIONS_GUIDE.md)** - Day-to-day operations, runbooks, and maintenance procedures
- **[TESTING_STRATEGY.md](./TESTING_STRATEGY.md)** - Comprehensive testing guidelines and strategies
- **[GLOSSARY.md](./GLOSSARY.md)** - Technical terms, acronyms, and Azure service definitions

### Infrastructure & Deployment
- **[INFRASTRUCTURE_AS_CODE_COMPARISON.md](./INFRASTRUCTURE_AS_CODE_COMPARISON.md)** - Bicep vs Terraform vs ARM Templates comparison
- **[INFRASTRUCTURE_DEPLOYMENT_GUIDE.md](./INFRASTRUCTURE_DEPLOYMENT_GUIDE.md)** - Infrastructure deployment guide with CI/CD examples and best practices
- **[HELM_GUIDE.md](./HELM_GUIDE.md)** - Helm charts guide for Kubernetes deployments

### Comparisons & Alternatives
- **[API_GATEWAY_COMPARISON.md](./API_GATEWAY_COMPARISON.md)** - Apigee vs Azure API Management comparison
- **[SECRETS_MANAGEMENT_COMPARISON.md](./SECRETS_MANAGEMENT_COMPARISON.md)** - HashiCorp Vault vs Azure Key Vault comparison

### Compliance & Validation
- **[GDPR_COMPLIANCE.md](./GDPR_COMPLIANCE.md)** - GDPR compliance implementation guide
- **[DOCUMENTATION_VALIDATION_REPORT.md](./DOCUMENTATION_VALIDATION_REPORT.md)** - Documentation structure validation and recommendations

---

## 🚀 Quick Start

### Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI installed and configured
- Docker installed
- kubectl installed
- **Helm 3.x** (for Kubernetes deployments)
- Maven 3.9+ and Java 17+ (for backend services)
- Node.js 20+ and npm (for frontend)
- GitLab account (or GitLab CI/CD runner)
- **Terraform >= 1.5.0** (optional, for Terraform deployment)
- **Bicep CLI** (optional, for Bicep deployment)

### 1. Clone Repository

```bash
git clone <repository-url>
cd azure-architectural-blueprint
```

### 2. Configure Variables

Update the following files with your values:

- `infrastructure/terraform/terraform.tfvars.example` (copy to `terraform.tfvars`)
- `infrastructure/bicep/main.bicep` (update parameters)
- `infrastructure/arm/azuredeploy.parameters.json` (update parameters)

**Important**: Replace placeholder values like:
- Resource group names (`rg-your-project-name`)
- Storage account names (`styourprojectname`)
- Key Vault names (`kv-your-project-name`)
- AKS cluster names (`aks-your-project-name`)
- PostgreSQL server names (`psql-your-project-name`)

### 3. Set Up Azure Resources

#### Option A: Using ARM Templates (Azure Native JSON)

```bash
# Login to Azure
az login

# Create resource group
az group create --name rg-your-project-name --location westeurope

# Deploy infrastructure using ARM templates
az deployment group create \
  --resource-group rg-your-project-name \
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
  --resource-group rg-your-project-name \
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

**For comprehensive infrastructure deployment examples, CI/CD integration, and best practices, see [INFRASTRUCTURE_DEPLOYMENT_GUIDE.md](./INFRASTRUCTURE_DEPLOYMENT_GUIDE.md).**

### 4. Configure Entra ID

1. **Create App Registration for Internal Users**
   - Navigate to Azure Portal → Azure Active Directory → App registrations
   - Create new registration
   - Note: Client ID and Tenant ID

2. **Configure Entra External ID for External Users** (optional)
   - Navigate to Azure Portal → Azure AD External Identities
   - Create user flow for sign-up/sign-in
   - Create app registration
   - Note: Client ID and Tenant ID

### 5. Set Up GitLab CI/CD Variables

In GitLab → Settings → CI/CD → Variables, add:

- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CLIENT_ID` (service principal)
- `AZURE_CLIENT_SECRET` (service principal)
- `AZURE_TENANT_ID`
- `ACR_NAME`: Your Azure Container Registry name
- `AKS_RESOURCE_GROUP`: Your resource group name
- `AKS_CLUSTER_NAME`: Your AKS cluster name
- `POSTGRES_HOST`: Your PostgreSQL server host
- `ENTRA_INTERNAL_CLIENT_ID` (if using internal authentication)
- `ENTRA_EXTERNAL_CLIENT_ID` (if using external authentication)

### 6. Build and Deploy Services

#### Backend Services

```bash
# Build example service
cd backend/example-service
mvn clean package
docker build -t your-acr.azurecr.io/example-service:latest .
docker push your-acr.azurecr.io/example-service:latest

# Deploy to AKS using Helm
cd infrastructure/helm/example-service
helm upgrade --install example-service . \
  --namespace production \
  --values values-prod.yaml \
  --set image.tag=latest
```

#### Frontend

```bash
# Build Shell Application
cd frontend/shell
npm install
npm run build

# Deploy to Azure Static Web Apps
az staticwebapp create \
  --name your-project-frontend \
  --resource-group rg-your-project-name
```

### 7. Configure API Management

1. Import API definitions from `azure-api-management/apis/`
2. Configure JWT validation policies
3. Set up rate limiting
4. Deploy APIs

---

## 🧪 Testing

### Local Development

```bash
# Start PostgreSQL locally
docker run --name postgres-local \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 -d postgres:15

# Run example service locally
cd backend/example-service
mvn spring-boot:run

# Run Frontend locally
cd frontend/shell
npm run dev
```

### API Testing

```bash
# Get authentication token (example)
TOKEN=$(az account get-access-token --resource api://your-client-id --query accessToken -o tsv)

# Test API
curl -X GET https://api.example.com/api/v1/example \
  -H "Authorization: Bearer $TOKEN"
```

---

## 📁 Project Structure

```
azure-architectural-blueprint/
├── frontend/
│   ├── shell/                 # React shell application
│   └── example-mfe/           # Example microfrontend
├── backend/
│   └── example-service/       # Example Spring Boot microservice
├── infrastructure/
│   ├── arm/                   # ARM templates (JSON)
│   ├── bicep/                 # Azure Bicep templates
│   ├── terraform/             # Terraform configuration files
│   ├── kubernetes/            # Kubernetes manifests
│   ├── helm/                  # Helm charts for microservices
│   └── database/              # Database migrations
├── azure-api-management/      # Azure API Management configs
│   ├── apis/                  # API definitions (OpenAPI)
│   └── policies/              # API Management policies
├── hashicorp-vault/           # HashiCorp Vault configs
│   ├── kubernetes/            # Vault deployment on AKS
│   └── policies/              # Vault access policies
├── azure-functions/           # Azure Functions examples
│   └── example-function/      # Example serverless function
├── ARCHITECTURE.md            # Architecture documentation
├── IMPLEMENTATION_GUIDE.md    # Implementation guide
├── OPERATIONS_GUIDE.md        # Operations guide and runbooks
├── TESTING_STRATEGY.md        # Testing strategy and guidelines
├── GLOSSARY.md                # Technical terms and acronyms
├── INFRASTRUCTURE_AS_CODE_COMPARISON.md  # IaC comparison
├── API_GATEWAY_COMPARISON.md  # API Gateway comparison
├── SECRETS_MANAGEMENT_COMPARISON.md  # Secrets management comparison
├── HELM_GUIDE.md              # Helm guide
├── INFRASTRUCTURE_DEPLOYMENT_GUIDE.md  # Infrastructure deployment guide
├── GDPR_COMPLIANCE.md         # GDPR compliance guide
├── DOCUMENTATION_VALIDATION_REPORT.md  # Documentation validation report
├── .gitlab-ci.yml             # GitLab CI/CD pipeline
└── README.md                  # This file
```

---

## 🔐 Security

- **Authentication**: Entra ID (internal and external users)
- **Authorization**: JWT-based with role-based access control (RBAC)
- **API Security**: API Management with rate limiting and policies
- **Data Encryption**: Encryption at rest and in transit
- **Secrets Management**: Azure Key Vault or HashiCorp Vault
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

## 🔌 Integrations

### Legacy SOAP Service Integration
- Example: Integration with external SOAP-based services
- Technology: Spring WS (Web Services)
- Use Case: External system integration

### External REST Services
- Example: Integration with external REST APIs
- Technology: Spring RestTemplate or WebClient
- Use Case: Third-party service integration

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

## 📝 Customization

This template is designed to be customized for your specific needs:

1. **Update Resource Names**: Replace placeholder names with your project names
2. **Configure Services**: Update service configurations in Helm charts
3. **Add Microservices**: Add new services following the example service structure
4. **Customize Frontend**: Modify the React application and microfrontends
5. **Adjust Infrastructure**: Modify infrastructure templates for your requirements
6. **Configure CI/CD**: Update GitLab CI/CD pipeline for your workflow

---

## 📖 Examples

This template includes examples for:

- **Azure Services**: AKS, PostgreSQL, Blob Storage, Service Bus, Redis Cache, Key Vault, Functions, Application Insights
- **Infrastructure as Code**: Terraform, Bicep, ARM Templates
- **Kubernetes**: Helm charts, deployments, services, ingress, HPA
- **CI/CD**: GitLab CI/CD pipeline with Helm integration
- **API Management**: Apigee and Azure API Management configurations
- **Secrets Management**: Azure Key Vault and HashiCorp Vault examples
- **Monitoring**: Application Insights and Azure Monitor setup

---

## 📄 License

[Add your license information here]

---

## 🙏 Acknowledgments

This template demonstrates modern cloud-native architecture patterns using:
- Microsoft Azure services
- Spring Boot microservices
- React microfrontends
- Kubernetes orchestration
- GitLab CI/CD

---

**Last Updated**: November 9, 2024
