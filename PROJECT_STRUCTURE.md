# Project Structure

This document provides an overview of the project structure and key files.

## Table of Contents

- [Directory Structure](#directory-structure)
- [Key Files Explained](#key-files-explained)
- [Service Communication](#service-communication)
- [Authentication Flow](#authentication-flow)
- [Data Flow](#data-flow)
- [Environment Variables](#environment-variables)
- [Next Steps](#next-steps)

---

## Directory Structure

```
azure-architectural-blueprint/
│
├── 📄 README.md                          # Main project overview and quick start
├── 📄 ARCHITECTURE.md                    # Comprehensive architecture blueprint
├── 📄 IMPLEMENTATION_GUIDE.md            # Step-by-step implementation guide
├── 📄 GDPR_COMPLIANCE.md                 # GDPR compliance documentation
├── 📄 PROJECT_STRUCTURE.md               # This file
├── 📄 .gitlab-ci.yml                     # GitLab CI/CD pipeline configuration
│
├── 📁 frontend/                          # React Microfrontends
│   ├── shell/                            # Shell application (host)
│   │   ├── package.json
│   │   ├── vite.config.ts                # Module Federation config
│   │   └── src/
│   │       ├── App.tsx                   # Main app component
│   │       ├── auth/
│   │       │   └── msalConfig.ts         # Entra ID/External ID config
│   │       ├── components/
│   │       ├── context/
│   │       └── pages/                     # Route pages that load MFEs
│   │
│   ├── orders-mfe/                       # Orders microfrontend
│   │   ├── webpack.config.js             # Module Federation remote config
│   │   └── src/
│   │       └── App.tsx                   # Orders app component
│   │
│   ├── products-mfe/                     # Products microfrontend
│   ├── account-mfe/                      # Account microfrontend
│   └── notifications-mfe/                # Notifications microfrontend
│
├── 📁 backend/                           # Spring Boot Microservices
│   ├── order-service/                    # Order Management Service
│   │   ├── pom.xml                       # Maven dependencies
│   │   ├── Dockerfile                    # Container image definition
│   │   └── src/main/java/
│   │       └── com/csom/platform/orderservice/
│   │           ├── OrderServiceApplication.java
│   │           ├── controller/
│   │           │   └── OrderController.java
│   │           ├── service/
│   │           │   └── OrderService.java
│   │           ├── repository/
│   │           │   └── OrderRepository.java
│   │           ├── entity/
│   │           │   ├── Order.java
│   │           │   └── OrderStatus.java
│   │           ├── dto/
│   │           │   ├── OrderCreateRequest.java
│   │           │   └── OrderResponse.java
│   │           ├── client/
│   │           │   ├── PaymentServiceClient.java
│   │           │   └── ProductServiceClient.java
│   │           ├── config/
│   │           │   └── SecurityConfig.java
│   │           └── messaging/
│   │               └── OrderEventPublisher.java
│   │       └── resources/
│   │           └── application.yml       # Service configuration
│   │
│   ├── product-service/                  # Product Catalog Service
│   │   └── src/main/java/.../productservice/
│   │       └── integration/soap/
│   │           └── LegacyERPSoapClient.java
│   │
│   ├── customer-service/                 # Customer & GDPR Service
│   │   └── src/main/java/.../customerservice/
│   │       └── controller/
│   │           └── GDPRController.java
│   │
│   ├── payment-service/                  # Payment Processing Service
│   ├── notification-service/             # Notification Service
│   └── audit-service/                    # Audit & Logging Service
│
├── 📁 infrastructure/                    # Infrastructure as Code
│   ├── bicep/                            # Azure Bicep templates
│   │   └── main.bicep                    # Main infrastructure template
│   │
│   ├── kubernetes/                       # Kubernetes manifests
│   │   └── order-service/
│   │       └── deployment.yaml           # K8s deployment config
│   │
│   └── database/                         # Database migrations
│       └── migrations/
│           └── 001_create_orders_schema.sql
│
├── 📁 apigee/                            # Apigee API Management
│   └── proxies/
│       └── external-api-proxy/
│           └── apiproxy/
│               ├── proxies/
│               │   └── default.xml        # Proxy endpoint config
│               └── policies/
│                   └── ValidateJWT-External.xml
│
└── 📁 scripts/                           # Utility scripts
    ├── build-all.sh                      # Build all Docker images
    └── deploy-all.sh                     # Deploy all services to AKS
```

## Key Files Explained

### Frontend

- **`frontend/shell/vite.config.ts`**: Configures Module Federation to load remote microfrontends
- **`frontend/shell/src/auth/msalConfig.ts`**: Configures Entra ID (internal) and Entra External ID (external) authentication
- **`frontend/orders-mfe/webpack.config.js`**: Exposes Orders microfrontend as a remote module

### Backend

- **`backend/order-service/pom.xml`**: Maven dependencies including Spring Boot, Azure SDK, PostgreSQL, JWT, etc.
- **`backend/order-service/src/main/resources/application.yml`**: Service configuration (database, Azure services, JWT issuers)
- **`backend/order-service/src/main/java/.../config/SecurityConfig.java`**: JWT validation configuration for Entra ID tokens
- **`backend/order-service/src/main/java/.../messaging/OrderEventPublisher.java`**: Publishes events to Azure Service Bus

### Infrastructure

- **`infrastructure/bicep/main.bicep`**: Defines all Azure resources (AKS, PostgreSQL, Service Bus, Key Vault, etc.)
- **`infrastructure/kubernetes/order-service/deployment.yaml`**: Kubernetes deployment manifest with health checks, resource limits, etc.
- **`infrastructure/database/migrations/001_create_orders_schema.sql`**: Database schema with GDPR support (soft delete, audit trails)

### CI/CD

- **`.gitlab-ci.yml`**: Complete CI/CD pipeline with stages: build, test, security scan, build images, deploy to dev/staging/production

### API Management

- **`apigee/proxies/external-api-proxy/apiproxy/proxies/default.xml`**: Apigee proxy endpoint configuration
- **`apigee/proxies/external-api-proxy/apiproxy/policies/ValidateJWT-External.xml`**: JWT validation policy for Entra External ID

## Service Communication

```
Frontend (React)
    ↓ (HTTPS + JWT)
Apigee API Gateway
    ↓ (HTTPS + JWT)
AKS Services
    ├── Order Service → Payment Service (Feign/REST)
    ├── Order Service → Product Service (Feign/REST)
    ├── Product Service → Legacy ERP (SOAP)
    └── All Services → Azure Service Bus (Events)
    ↓
PostgreSQL Database
```

## Authentication Flow

1. **Internal Users (Employees)**:
   - Login via Entra ID
   - Receive JWT token
   - Token validated by Apigee (internal proxy)
   - Token passed to services

2. **External Users (Clients)**:
   - Login via Entra External ID
   - Receive JWT token
   - Token validated by Apigee (external proxy)
   - Token passed to services

## Data Flow

1. **Order Creation**:
   - Client → Apigee → Order Service
   - Order Service → Product Service (validate inventory)
   - Order Service → Payment Service (process payment)
   - Order Service → Service Bus (publish event)
   - Notification Service (subscribes to event) → Sends notification

2. **GDPR Data Export**:
   - Client → Apigee → Customer Service
   - Customer Service aggregates data from all services
   - Returns JSON export

3. **GDPR Data Deletion**:
   - Client → Apigee → Customer Service
   - Customer Service soft-deletes customer
   - Publishes GDPR deletion event
   - Other services anonymize related data

## Environment Variables

Key environment variables needed:

- `POSTGRES_HOST`, `POSTGRES_USER`, `POSTGRES_PASSWORD`
- `KEY_VAULT_NAME`
- `SERVICE_BUS_CONNECTION_STRING`
- `ENTRA_INTERNAL_TENANT_ID`, `ENTRA_INTERNAL_CLIENT_ID`
- `ENTRA_EXTERNAL_TENANT_ID`, `ENTRA_EXTERNAL_CLIENT_ID`
- `ENTRA_EXTERNAL_TENANT_NAME`

## Next Steps

1. Review the architecture in `ARCHITECTURE.md`
2. Follow the implementation guide in `IMPLEMENTATION_GUIDE.md`
3. Start with Order Service as a PoC
4. Gradually add other services
5. Implement frontend incrementally

