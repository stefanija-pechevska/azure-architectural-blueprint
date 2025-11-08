# Technical Architecture Blueprint
## Customer Service & Order Management Platform

### Executive Summary

This document outlines the technical architecture for a cloud-native, microservices-based Customer Service & Order Management Platform deployed on Microsoft Azure. The system supports both internal employees and external clients with separate authentication mechanisms, integrates with legacy systems, and ensures GDPR compliance.

---

## Table of Contents

1. [System Overview](#1-system-overview)
   - [Business Domain](#11-business-domain)
   - [Key Requirements](#12-key-requirements)
2. [Architecture Diagram](#2-architecture-diagram)
   - [Azure Services Architecture Diagram](#21-azure-services-architecture-diagram)
3. [Component Architecture](#3-component-architecture)
   - [Frontend Layer](#31-frontend-layer)
   - [API Gateway Layer](#32-api-gateway-layer)
   - [Microservices Layer](#33-microservices-layer-spring-boot)
   - [Data Layer](#34-data-layer)
   - [Secrets Management Layer](#35-secrets-management-layer)
   - [Serverless Functions Layer](#36-serverless-functions-layer)
   - [Integration Layer](#36-integration-layer)
   - [Messaging & Events](#36-messaging--events)
   - [Authentication & Authorization](#37-authentication--authorization)
   - [Observability](#38-observability)
4. [Security Architecture](#4-security-architecture)
5. [Deployment Architecture](#5-deployment-architecture)
6. [Scalability & Performance](#6-scalability--performance)
7. [Disaster Recovery & Backup](#7-disaster-recovery--backup)
8. [Cost Optimization](#8-cost-optimization)
9. [Technology Stack Summary](#9-technology-stack-summary)
10. [Next Steps](#10-next-steps)

---

## 1. System Overview

### 1.1 Business Domain
**Customer Service & Order Management Platform**
- **Internal Users (Employees)**: Customer service representatives, order managers, administrators
- **External Users (Clients)**: Direct clients placing orders, tracking shipments, managing accounts
- **Core Functionality**: Order processing, customer management, product catalog, notifications, reporting

### 1.2 Key Requirements
- React-based web application with microfrontends architecture
- Spring Boot/Java REST microservices deployed on Azure Kubernetes Service (AKS)
- PostgreSQL database for persistent storage
- Entra ID JWT authentication for employees
- Entra External ID for client authentication
- Apigee API Management for API governance
- Integration with legacy SOAP services (ERP system)
- Integration with external REST services (payment gateway, shipping)
- GDPR compliance for data protection
- Real-time notifications between internal and external applications
- GitLab CI/CD for automated deployments

---

## 2. Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│  EXTERNAL USERS (Clients)                    │              INTERNAL USERS (Employees)        │
│  Entra External ID Authentication            │              Entra ID Authentication          │
└──────────────────┬───────────────────────────┴──────────────────────┬───────────────────────┘
                   │                                                  │
┌──────────────────▼───────────────────────────┐  ┌───────────────────▼───────────────────────┐
│  EXTERNAL REACT WEB APPLICATION             │  │  INTERNAL REACT WEB APPLICATION            │
│  (Microfrontends)                            │  │  (Microfrontends)                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐ │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐│
│  │  Orders  │  │ Products │  │ Account  │ │  │  │  Admin   │  │  Orders  │  │Customers ││
│  │   MFE    │  │   MFE    │  │   MFE    │ │  │  │Dashboard │  │Management│  │Management││
│  └──────────┘  └──────────┘  └──────────┘ │  │  │   MFE    │  │   MFE    │  │   MFE    ││
│  ┌──────────┐                               │  │  └──────────┘  └──────────┘  └──────────┘│
│  │Notifications│                              │  │  ┌──────────┐                            │
│  │    MFE     │                              │  │  │Analytics │                            │
│  └──────────┘                               │  │  │  MFE     │                            │
└──────────────────┬──────────────────────────┘  └──┴──────────┴────────────────────────────┘
                    │                                                  │
┌───────────────────▼──────────────────────────┐  ┌───────────────────▼───────────────────────┐
│  APIGEE API GATEWAY                          │  │  APIGEE API GATEWAY                      │
│  (External Proxy)                             │  │  (Internal Proxy)                        │
│  ┌────────────────────────────────────────┐ │  │  ┌────────────────────────────────────┐ │
│  │ • Entra External ID JWT Validation     │ │  │  │ • Entra ID JWT Validation           │ │
│  │ • Rate Limiting (1000 req/min)         │ │  │  │ • Rate Limiting (5000 req/min)     │ │
│  │ • CORS Policies                        │ │  │  │ • IP Whitelisting                   │ │
│  │ • Request/Response Transform            │ │  │  │ • Request/Response Transform        │ │
│  │ • API Versioning & Analytics           │ │  │  │ • API Versioning & Analytics       │ │
│  └────────────────────────────────────────┘ │  │  └────────────────────────────────────┘ │
└───────────────────┬──────────────────────────┘  └───┬────────────────────────────────────────────┘
                    │                                  │
                    └──────────────┬───────────────────┘
                                   │
                    ┌──────────────▼───────────────────┐
                    │  AZURE KUBERNETES SERVICE (AKS) │
                    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
                    │  │   Order      │  │   Product    │  │   Customer   │ │
                    │  │  Service     │  │   Service    │  │   Service    │ │
                    │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘ │
                    │         │                 │                 │         │
                    │  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐ │
                    │  │ Notification│  │   Payment    │  │   Audit      │ │
                    │  │   Service   │  │   Service    │  │   Service    │ │
                    │  └─────────────┘  └──────┬───────┘  └───────────────┘ │
                    │                          │                           │
                    │  ┌───────────────────────▼────────────────────────┐ │
                    │  │              Service Mesh (Istio)              │ │
                    │  │  • Service Discovery  • Load Balancing         │ │
                    │  │  • Circuit Breakers  • mTLS                   │ │
                    │  │  • Observability                              │ │
                    │  └────────────────────────────────────────────────┘ │
                    └──────────────────────────┬───────────────────────────┘
                                               │
                    ┌──────────────────────────┼──────────────────────────┐
                    │                          │                          │
        ┌───────────▼────────┐   ┌──────────────▼──────────┐   ┌──────────▼────────┐
        │  PostgreSQL        │   │  Azure Service Bus      │   │  Azure Event Grid │
        │  (Primary DB)     │   │  (Messaging)             │   │  (Events)         │
        └────────────────────┘   └──────────────────────────┘   └───────────────────┘
                                               │
                    ┌──────────────────────────┼──────────────────────────┐
                    │                          │                          │
        ┌───────────▼────────┐   ┌──────────────▼──────────┐   ┌──────────▼────────┐
        │  Legacy SOAP        │   │  Payment Gateway        │   │  Shipping Service │
        │  ERP Service         │   │  (REST API)             │   │  (REST API)       │
        └─────────────────────┘   └──────────────────────────┘   └───────────────────┘
```

---

## 2.1 Azure Services Architecture Diagram

This diagram illustrates all Azure services used in the platform and their relationships:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AZURE CLOUD PLATFORM                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
┌───────▼────────┐        ┌─────────▼─────────┐      ┌─────────▼─────────┐
│  Azure Static │        │  Azure App         │      │  Entra ID /        │
│  Web Apps     │        │  Service           │      │  External ID       │
│  (External    │        │  (Internal         │      │                    │
│   Frontend)   │        │   Frontend)         │      │  (Authentication)  │
└───────┬────────┘        └─────────┬─────────┘      └─────────┬─────────┘
        │                            │                           │
        │                            │                           │
┌───────▼────────┐        ┌─────────▼─────────┐                 │
│  External API  │        │  Internal API     │                 │
│  Proxy         │        │  Proxy            │                 │
│  (Apigee)      │        │  (Apigee)         │                 │
└───────┬────────┘        └─────────┬─────────┘                 │
        │                            │                           │
        └────────────────────────────┼───────────────────────────┘
                                     │
┌─────────────────────────────────────▼─────────────────────────────────────┐
│                    APIGEE API MANAGEMENT                                    │
│                    (or Azure API Management)                                 │
│  • External API Proxy (Entra External ID)                                   │
│  • Internal API Proxy (Entra ID)                                           │
└───────────────────────────────────────┬─────────────────────────────────────┘
                                        │
┌───────────────────────────────────────▼─────────────────────────────────────┐
│                    AZURE KUBERNETES SERVICE (AKS)                           │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Microservices Pods:                                                │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐          │   │
│  │  │  Order   │  │ Product  │  │ Customer │  │ Payment  │          │   │
│  │  │ Service  │  │ Service  │  │ Service │  │ Service  │          │   │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘          │   │
│  │       │            │             │             │                  │   │
│  │  ┌────▼─────┐  ┌───▼──────┐  ┌───▼──────┐                        │   │
│  │  │Notification│ │  Audit   │  │  Other   │                        │   │
│  │  │  Service  │ │ Service  │  │ Services │                        │   │
│  │  └──────────┘  └──────────┘  └──────────┘                        │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└───────────────────────────────────────┬─────────────────────────────────────┘
                                        │
        ┌───────────────────────────────┼───────────────────────────────┐
        │                               │                               │
┌───────▼────────┐            ┌─────────▼─────────┐          ┌─────────▼─────────┐
│  Azure         │            │  Azure Database    │          │  Azure Redis      │
│  Key Vault     │            │  for PostgreSQL    │          │  Cache             │
│                │            │  Flexible Server   │          │                    │
│  • Secrets     │            │                    │          │  • Session Cache   │
│  • Certificates│            │  • Primary DB       │          │  • Data Cache      │
│  • Keys        │            │  • Read Replicas    │          │  • Rate Limiting  │
└────────────────┘            └────────────────────┘          └────────────────────┘
                                        │
┌───────────────────────────────────────▼─────────────────────────────────────┐
│                    AZURE SERVICE BUS (Messaging)                             │
│  • order-events topic                                                       │
│  • payment-events topic                                                     │
│  • notification-events topic                                                 │
│  • gdpr-events topic                                                         │
└───────────────────────────────────────┬─────────────────────────────────────┘
                                        │
┌───────────────────────────────────────▼─────────────────────────────────────┐
│                    AZURE EVENT GRID (Event-Driven)                           │
│  • Order lifecycle events                                                   │
│  • Payment events                                                           │
│  • GDPR events                                                              │
└───────────────────────────────────────┬─────────────────────────────────────┘
                                        │
┌───────────────────────────────────────▼─────────────────────────────────────┐
│                    AZURE FUNCTIONS (Serverless)                              │
│  • Housekeeping Jobs:                                                        │
│    - Data retention cleanup                                                  │
│    - Old notification cleanup                                                │
│    - Audit log archival                                                     │
│    - GDPR data anonymization                                                │
│    - Database maintenance                                                    │
│  • Scheduled Tasks (Timer Triggers)                                         │
│  • Event-Driven Tasks (Service Bus Triggers)                                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
┌───────────────────────────────────────▼─────────────────────────────────────┐
│                    AZURE MONITOR & APPLICATION INSIGHTS                      │
│  • Application performance monitoring                                        │
│  • Distributed tracing                                                       │
│  • Custom metrics                                                            │
│  • Alert rules                                                               │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
┌───────────────────────────────────────▼─────────────────────────────────────┐
│                    AZURE LOG ANALYTICS WORKSPACE                             │
│  • Centralized logging                                                       │
│  • Log queries and analytics                                                 │
│  • GDPR-compliant log retention                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
┌───────────────────────────────────────▼─────────────────────────────────────┐
│                    AZURE CONTAINER REGISTRY (ACR)                            │
│  • Docker image storage                                                     │
│  • CI/CD image builds                                                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Azure Services Summary

| Azure Service | Purpose | Usage |
|--------------|---------|-------|
| **Azure Kubernetes Service (AKS)** | Container orchestration | Hosts all Spring Boot microservices |
| **Azure App Service** | Web hosting | Internal frontend application (employee-facing) |
| **Azure Static Web Apps** | Static web hosting | External frontend application (client-facing) |
| **Azure Database for PostgreSQL** | Relational database | Primary data storage for all services |
| **Azure Redis Cache** | In-memory cache | Session storage, data caching, rate limiting |
| **Azure Key Vault** | Secrets management | Stores passwords, connection strings, certificates (or HashiCorp Vault as alternative) |
| **Azure Service Bus** | Message broker | Asynchronous communication between services |
| **Azure Event Grid** | Event routing | Event-driven architecture for real-time processing |
| **Azure Functions** | Serverless compute | Housekeeping jobs, scheduled tasks, event processing |
| **Application Insights** | Application monitoring | Performance monitoring, distributed tracing |
| **Azure Monitor** | Infrastructure monitoring | Metrics, alerts, dashboards |
| **Log Analytics Workspace** | Centralized logging | Log aggregation and analysis |
| **Azure Container Registry (ACR)** | Container registry | Docker image storage for CI/CD |
| **Entra ID** | Identity provider | Employee authentication |
| **Entra External ID** | B2C identity provider | Client authentication |

---

## 3. Component Architecture

### 3.1 Frontend Layer

**Important**: There are **two separate frontend applications** - one for external clients and one for internal employees. They are completely independent and do not call each other.

#### 3.1.1 External Frontend Application (Client-Facing)
**Technology**: React 18+, Module Federation (Webpack 5)
**Deployment**: Azure Static Web Apps
**Authentication**: Entra External ID

**Microfrontends**:
1. **Orders Microfrontend**
   - Order placement, tracking, history
   - Client order management

2. **Products Microfrontend**
   - Product catalog, search, details
   - Product browsing and details

3. **Account Microfrontend**
   - User profile, settings
   - GDPR data management (export, deletion requests)

4. **Notifications Microfrontend**
   - Real-time notifications via WebSocket/SSE
   - Client-facing notifications

**Host Application**:
- Shell application that orchestrates microfrontends
- Handles routing, authentication context (Entra External ID), shared state
- Deployed to Azure Static Web Apps
- Connects to Apigee External API Proxy

#### 3.1.2 Internal Frontend Application (Employee-Facing)
**Technology**: React 18+, Module Federation (Webpack 5)
**Deployment**: Azure App Service
**Authentication**: Entra ID

**Microfrontends**:
1. **Admin Dashboard Microfrontend**
   - System overview, metrics, dashboards
   - Administrative tools

2. **Orders Management Microfrontend**
   - Order management and processing
   - Order status updates, fulfillment

3. **Customers Management Microfrontend**
   - Customer service tools
   - Customer data management
   - GDPR compliance tools

4. **Analytics & Reports Microfrontend**
   - Business analytics
   - Reporting and insights

**Host Application**:
- Shell application that orchestrates microfrontends
- Handles routing, authentication context (Entra ID), shared state
- Deployed to Azure App Service
- Connects to Apigee Internal API Proxy

---

### 3.2 API Gateway Layer

**API Gateway Options**: This architecture supports two API gateway solutions:
1. **Apigee API Management** (Google Cloud) - See `apigee/` directory
2. **Azure API Management** (Azure) - See `azure-api-management/` directory

For a detailed comparison, see [API_GATEWAY_COMPARISON.md](./API_GATEWAY_COMPARISON.md).

**Recommendation**: For this Azure-native architecture, **Azure API Management** is recommended due to native Azure integration, cost-effectiveness, and easier management. However, **Apigee** can be used if advanced analytics, monetization, or multi-cloud support is required.

#### 3.2.1 Apigee API Management
**Purpose**: API governance, security, rate limiting, analytics

**Important**: All REST APIs are **exposed exclusively via the API Gateway** (Apigee or Azure API Management). The backend microservices are not directly accessible from the frontend applications. All API calls go through the API gateway proxies.

**API Specification**: All REST APIs use **OpenAPI 3.0 specification** (Swagger). OpenAPI specs are generated from Spring Boot services using SpringDoc OpenAPI and published to the API gateway Developer Portal.

**API Proxies** (Two Separate Proxies):

1. **External API Proxy** (for External Frontend Application)
   - Routes to client-facing services
   - Entra External ID JWT validation
   - Rate limiting: 1000 req/min per client
   - CORS policies for external domain
   - Routes: `/api/v1/orders`, `/api/v1/products`, `/api/v1/customers/{id}`, `/api/v1/notifications`
   - OpenAPI spec: `https://apigee.example.com/external-api/v1/openapi.json`

2. **Internal API Proxy** (for Internal Frontend Application)
   - Routes to employee-facing services
   - Entra ID JWT validation
   - Higher rate limits for internal users (5000 req/min)
   - IP whitelisting for admin endpoints
   - Routes: `/api/v1/admin/*`, `/api/v1/orders/*`, `/api/v1/customers/*`, `/api/v1/analytics/*`
   - OpenAPI spec: `https://apigee.example.com/internal-api/v1/openapi.json`

**Note**: Both proxies route to the same backend microservices, but with different authentication, rate limits, and access controls. The backend services are not directly exposed - all access is through Apigee.

**Policies**:
- JWT validation (Entra ID for internal, Entra External ID for external)
- Request/response transformation
- Error handling and retry logic
- API versioning (v1, v2)
- Request/response logging (GDPR compliant)
- Separate rate limiting policies per proxy
- OpenAPI spec validation and enforcement

**API Documentation**:
- OpenAPI specifications published to API Gateway Developer Portal
- Interactive API documentation (Swagger UI) available for both proxies
- API versioning and deprecation policies
- SDK generation from OpenAPI specs

#### 3.2.2 Azure API Management (Alternative)
**Purpose**: API governance, security, rate limiting, analytics (Azure-native alternative)

**Configuration**: See `azure-api-management/` directory for configuration files.

**Key Features**:
- Native Azure integration with Entra ID, Key Vault, Application Insights
- OpenAPI import and management
- XML-based policy framework
- Built-in developer portal
- Multiple pricing tiers (Developer, Basic, Standard, Premium, Consumption)

**API Proxies** (Two Separate APIs):

1. **External API** (for External Frontend Application)
   - Base path: `/external-api/v1`
   - Entra External ID JWT validation
   - Rate limiting: 1000 req/min per client
   - CORS policies for external domain
   - OpenAPI spec: Imported from Spring Boot services

2. **Internal API** (for Internal Frontend Application)
   - Base path: `/internal-api/v1`
   - Entra ID JWT validation
   - Higher rate limits for internal users (5000 req/min)
   - IP whitelisting for admin endpoints
   - OpenAPI spec: Imported from Spring Boot services

**Advantages over Apigee**:
- Native Azure integration
- Cost-effective for Azure-based architectures
- Easier setup and management
- Integrated Azure monitoring and security
- Familiar Azure portal and tooling

**See**: [API_GATEWAY_COMPARISON.md](./API_GATEWAY_COMPARISON.md) for detailed comparison.

---

### 3.3 Microservices Layer (Spring Boot)

All services deployed on AKS with:
- Spring Boot 3.x
- Spring Cloud Kubernetes for service discovery
- Spring Security for JWT validation
- PostgreSQL JDBC driver
- Resilience4j for circuit breakers
- **SpringDoc OpenAPI** for OpenAPI 3.0 specification generation
- **OpenAPI annotations** for API documentation

**API Exposure**: All REST endpoints are **exposed via API Gateway only** (Apigee or Azure API Management). Services are not directly accessible from outside the AKS cluster. The API gateway proxies forward requests to the backend services.

**OpenAPI Specification**:
- Each service generates OpenAPI 3.0 spec using SpringDoc OpenAPI
- OpenAPI specs are published to the API Gateway Developer Portal
- Specs include request/response schemas, authentication requirements, and examples
- API documentation is auto-generated from OpenAPI specs
- OpenAPI specs can be imported into either Apigee or Azure API Management

#### 3.3.1 Order Service
**Responsibilities**:
- Order creation, updates, status tracking
- Order history retrieval
- Order validation and business rules

**REST API Endpoints** (exposed via Apigee):
- `POST /api/v1/orders` - Create order
- `GET /api/v1/orders/{id}` - Get order details
- `GET /api/v1/orders` - List orders (with filters)
- `PUT /api/v1/orders/{id}/status` - Update status
- `DELETE /api/v1/orders/{id}` - Cancel order (GDPR compliant)

**OpenAPI Spec**: Available at `/v3/api-docs` endpoint (internal) and published to Apigee

**Database**: `orders` schema in PostgreSQL
- Tables: `orders`, `order_items`, `order_status_history`

**Integrations**:
- Calls Payment Service for payment processing
- Calls Product Service for inventory validation
- Publishes events to Azure Service Bus

---

#### 3.3.2 Product Service
**Responsibilities**:
- Product catalog management
- Inventory tracking
- Product search and filtering

**REST API Endpoints** (exposed via Apigee):
- `GET /api/v1/products` - List products
- `GET /api/v1/products/{id}` - Get product details
- `POST /api/v1/products` - Create product (internal only)
- `PUT /api/v1/products/{id}` - Update product (internal only)
- `GET /api/v1/products/search` - Search products

**OpenAPI Spec**: Available at `/v3/api-docs` endpoint (internal) and published to Apigee

**Database**: `products` schema in PostgreSQL
- Tables: `products`, `product_categories`, `inventory`

**Integrations**:
- Called by Order Service for validation
- Integrates with legacy SOAP ERP for inventory sync

---

#### 3.3.3 Customer Service
**Responsibilities**:
- Customer profile management
- GDPR data management (right to access, deletion)
- Customer segmentation

**REST API Endpoints** (exposed via Apigee):
- `GET /api/v1/customers/{id}` - Get customer profile
- `PUT /api/v1/customers/{id}` - Update profile
- `POST /api/v1/customers/{id}/gdpr/export` - GDPR data export
- `DELETE /api/v1/customers/{id}` - GDPR data deletion
- `GET /api/v1/customers/{id}/orders` - Customer order history

**OpenAPI Spec**: Available at `/v3/api-docs` endpoint (internal) and published to Apigee

**Database**: `customers` schema in PostgreSQL
- Tables: `customers`, `customer_preferences`, `gdpr_audit_log`

**Integrations**:
- Called by Order Service for customer validation
- Publishes GDPR events to Audit Service

---

#### 3.3.4 Notification Service
**Responsibilities**:
- Real-time notifications (WebSocket/SSE)
- Email notifications via Azure Communication Services
- SMS notifications
- Notification preferences management

**REST API Endpoints** (exposed via Apigee):
- `GET /api/v1/notifications/stream` - WebSocket/SSE endpoint
- `GET /api/v1/notifications` - Get notification history
- `POST /api/v1/notifications` - Send notification (internal only)
- `PUT /api/v1/notifications/{id}/read` - Mark as read

**OpenAPI Spec**: Available at `/v3/api-docs` endpoint (internal) and published to Apigee

**Database**: `notifications` schema in PostgreSQL
- Tables: `notifications`, `notification_preferences`

**Integrations**:
- Subscribes to Azure Service Bus events
- Integrates with Azure Communication Services
- Sends notifications to both internal and external users

---

#### 3.3.5 Payment Service
**Responsibilities**:
- Payment processing
- Payment gateway integration
- Payment history and reconciliation

**REST API Endpoints** (exposed via Apigee):
- `POST /api/v1/payments` - Process payment
- `GET /api/v1/payments/{id}` - Get payment status
- `POST /api/v1/payments/{id}/refund` - Process refund

**OpenAPI Spec**: Available at `/v3/api-docs` endpoint (internal) and published to Apigee

**Database**: `payments` schema in PostgreSQL
- Tables: `payments`, `payment_transactions`, `refunds`

**Integrations**:
- Integrates with external REST payment gateway
- Called by Order Service
- Publishes payment events

---

#### 3.3.6 Audit Service
**Responsibilities**:
- GDPR compliance logging
- Security audit trails
- Activity logging

**REST API Endpoints** (exposed via Apigee - Internal only):
- `POST /api/v1/audit/logs` - Create audit log
- `GET /api/v1/audit/logs` - Query audit logs
- `GET /api/v1/audit/gdpr/{customerId}` - GDPR audit trail

**OpenAPI Spec**: Available at `/v3/api-docs` endpoint (internal) and published to Apigee

**Database**: `audit` schema in PostgreSQL
- Tables: `audit_logs`, `gdpr_audit_trail`

**Integrations**:
- Receives events from all services
- Integrates with Azure Log Analytics

---

### 3.4 Data Layer

#### 3.4.1 PostgreSQL Database
**Deployment**: Azure Database for PostgreSQL Flexible Server

**Database Structure**:
- Separate schemas per service (orders, products, customers, notifications, payments, audit)
- Connection pooling via PgBouncer
- Read replicas for scaling
- Automated backups with point-in-time recovery

**GDPR Compliance**:
- Data encryption at rest (Azure managed keys)
- Data encryption in transit (TLS 1.2+)
- Automated data retention policies
- Audit logging for all data access

---

#### 3.4.2 Azure Redis Cache
**Deployment**: Azure Cache for Redis (Standard tier)

**Purpose**:
- Session storage for user sessions
- Data caching for frequently accessed data (products, customer profiles)
- Rate limiting counters
- Distributed locking for concurrent operations

**Configuration**:
- Standard tier (C1 - 1GB cache)
- TLS 1.2+ required
- Non-SSL port disabled
- LRU eviction policy

**Usage Patterns**:
1. **Product Catalog Caching**
   - Cache product details for 1 hour
   - Invalidate on product updates

2. **Session Management**
   - Store user session data
   - 24-hour TTL for sessions

3. **Rate Limiting**
   - Track API request counts per user
   - Sliding window rate limiting

4. **Distributed Locks**
   - Prevent concurrent order processing
   - Ensure idempotency

---

### 3.5 Secrets Management Layer

**Secrets Management Options**: This architecture supports two secrets management solutions:
1. **Azure Key Vault** (Azure) - See `infrastructure/bicep/main.bicep` for Key Vault resource
2. **HashiCorp Vault** (Self-hosted/HCP) - See `hashicorp-vault/` directory

For a detailed comparison, see [SECRETS_MANAGEMENT_COMPARISON.md](./SECRETS_MANAGEMENT_COMPARISON.md).

**Recommendation**: For this Azure-native architecture, **Azure Key Vault** is recommended due to native Azure integration, managed service, and cost-effectiveness. However, **HashiCorp Vault** can be used if dynamic secrets, multi-cloud support, or encryption as a service is required.

#### 3.5.1 Azure Key Vault
**Purpose**: Secure storage and management of secrets, keys, and certificates

**Configuration**: See `infrastructure/bicep/main.bicep` for Key Vault resource definition.

**Key Features**:
- Fully managed Azure service
- Native integration with Managed Identities
- HSM-backed keys (Premium tier)
- Certificate lifecycle management
- Soft delete and recovery protection
- Integration with Azure Monitor and Log Analytics

**Usage**:
- Store database connection strings
- Store API keys and passwords
- Store Service Bus connection strings
- Store JWT secrets
- Store certificates

**Integration with AKS**:
- Secrets Store CSI driver for Kubernetes
- Managed Identities for pod authentication
- Automatic secret injection into pods

#### 3.5.2 HashiCorp Vault (Alternative)
**Purpose**: Advanced secrets management with dynamic secrets and encryption as a service

**Configuration**: See `hashicorp-vault/` directory for deployment and configuration files.

**Key Features**:
- Dynamic secrets generation
- Multiple secrets engines (KV, Azure, Database, etc.)
- Encryption as a service (Transit engine)
- Flexible authentication methods (Kubernetes, AppRole, OIDC, etc.)
- Advanced policy engine (HCL)
- Multi-cloud support

**Deployment Options**:
1. **On AKS**: Deploy Vault as StatefulSet in Kubernetes
2. **On Azure VMs**: Self-hosted Vault deployment
3. **HashiCorp Cloud Platform**: Managed Vault service

**Advantages over Azure Key Vault**:
- Dynamic secrets generation
- Encryption as a service (Transit)
- More flexible authentication
- Multi-cloud support
- Advanced policy engine

**See**: [SECRETS_MANAGEMENT_COMPARISON.md](./SECRETS_MANAGEMENT_COMPARISON.md) for detailed comparison.

---

### 3.6 Serverless Functions Layer

#### 3.6.1 Azure Functions (Housekeeping Jobs)
**Deployment**: Azure Functions (Consumption Plan)

**Functions**:

1. **DataRetentionCleanup** (Timer Trigger - Daily at 2 AM UTC)
   - Clean up old notifications (older than 90 days)
   - Anonymize inactive customer data (older than 7 years)
   - Archive old audit logs (older than 10 years)

2. **DatabaseMaintenance** (Timer Trigger - Weekly on Sundays at 3 AM UTC)
   - Run VACUUM ANALYZE on PostgreSQL
   - Update table statistics
   - Optimize database performance

3. **GDPRDataAnonymization** (Service Bus Trigger)
   - Process GDPR deletion requests
   - Anonymize customer data across all services
   - Archive anonymized data

4. **NotificationCleanup** (Timer Trigger - Daily at 1 AM UTC)
   - Remove read notifications older than 30 days
   - Archive notification history

**Technology**: Java 17, Azure Functions Java Library

**Configuration**:
- Consumption plan for cost efficiency
- Application Insights integration
- Connection to PostgreSQL and Redis Cache
- Service Bus triggers for event-driven processing

---

### 3.6 Integration Layer

#### 3.6.1 Legacy SOAP Service Integration
**Service**: Product Service → Legacy ERP System

**Implementation**:
- Spring WS (Web Services) for SOAP client
- WSDL-based service generation
- Retry logic and circuit breakers
- Async processing for non-critical operations

**Use Cases**:
- Inventory synchronization
- Product master data sync

---

#### 3.6.2 External REST Service Integration
**Services**:
1. **Payment Gateway** (Payment Service)
   - RESTful API integration
   - OAuth 2.0 authentication
   - Idempotency handling

2. **Shipping Service** (Order Service)
   - RESTful API for shipping rates
   - Tracking information retrieval

---

### 3.6 Messaging & Events

#### 3.6.1 Azure Service Bus
**Purpose**: Asynchronous communication between services

**Topics**:
- `order-events` - Order lifecycle events
- `payment-events` - Payment processing events
- `notification-events` - Notification triggers
- `gdpr-events` - GDPR compliance events

**Subscriptions**:
- Per-service subscriptions with filters
- Dead-letter queues for failed messages

---

#### 3.6.2 Azure Event Grid
**Purpose**: Event-driven architecture for real-time processing

**Event Types**:
- Order created/updated
- Payment processed
- GDPR data request
- Notification sent

---

### 3.7 Authentication & Authorization

#### 3.7.1 Entra ID (Azure AD) - Employees
**Configuration**:
- App Registration for internal application
- JWT token validation in Apigee and services
- Role-based access control (RBAC)
- Groups: `admin`, `customer-service`, `order-manager`

**Token Flow**:
1. Employee logs in via Entra ID
2. Receives JWT token
3. Token validated by Apigee
4. Token passed to microservices
5. Services validate token and extract roles

---

#### 3.7.2 Entra External ID - Clients
**Configuration**:
- External ID tenant for B2C
- User flows for registration/login
- Custom policies for advanced scenarios
- JWT token validation

**Token Flow**:
1. Client registers/logs in via Entra External ID
2. Receives JWT token
3. Token validated by Apigee (external proxy)
4. Token passed to microservices
5. Services validate token and extract user ID

---

### 3.8 Observability

#### 3.8.1 Azure Monitor
- Application Insights for all services
- Custom metrics and dashboards
- Alert rules for critical errors

#### 3.8.2 Logging
- Centralized logging via Azure Log Analytics
- Structured logging (JSON format)
- Log retention per GDPR requirements

#### 3.8.3 Distributed Tracing
- Application Insights distributed tracing
- Correlation IDs across services
- Performance monitoring

---

## 4. Security Architecture

### 4.1 Network Security
- AKS private cluster with private endpoints
- Network policies for service-to-service communication
- Azure Firewall for egress traffic control
- VPN/ExpressRoute for on-premises connectivity (if needed)

### 4.2 Application Security
- JWT token validation at API Gateway (Apigee or Azure API Management) and service level
- HTTPS/TLS 1.2+ everywhere
- Secrets management via Azure Key Vault or HashiCorp Vault
- OWASP Top 10 protection

### 4.3 Data Security
- Encryption at rest (Azure managed keys)
- Encryption in transit (TLS)
- Database access via private endpoints
- PII data masking in logs

### 4.4 GDPR Compliance
- Right to access: Data export endpoints
- Right to deletion: Soft delete with audit trail
- Data minimization: Only collect necessary data
- Consent management: Track user consents
- Data breach notification: Automated alerts
- Privacy by design: Built into architecture

---

## 5. Deployment Architecture

### 5.1 Azure Resources
- **AKS Cluster**: Kubernetes 1.28+, 3 node pools (system, user, compute)
- **PostgreSQL**: Flexible Server, zone-redundant high availability
- **Apigee**: Apigee X on Google Cloud (or Azure API Management as alternative)
- **Service Bus**: Premium tier for production
- **Key Vault**: For secrets management (Azure Key Vault or HashiCorp Vault)
- **Container Registry**: Azure Container Registry (ACR)
- **Static Web Apps**: For React frontend (or App Service)

### 5.2 GitLab CI/CD
- **GitLab Runners**: Self-hosted or GitLab.com
- **Pipeline Stages**:
  1. Build (compile, test, build Docker images)
  2. Security scan (SAST, dependency scanning)
  3. Deploy to Dev
  4. Integration tests
  5. Deploy to Staging
  6. E2E tests
  7. Deploy to Production (manual approval)

### 5.3 Kubernetes Deployment
- **Namespaces**: `dev`, `staging`, `production`
- **Deployments**: Each microservice as separate deployment
- **Services**: ClusterIP for internal, LoadBalancer for external
- **Ingress**: NGINX Ingress Controller with TLS
- **ConfigMaps**: Application configuration
- **Secrets**: Retrieved from Azure Key Vault (via CSI driver) or HashiCorp Vault (via Vault Agent)

---

## 6. Scalability & Performance

### 6.1 Horizontal Scaling
- AKS cluster autoscaling
- Pod autoscaling (HPA) based on CPU/memory
- Database read replicas for read-heavy workloads

### 6.2 Caching
- Redis Cache for frequently accessed data
- CDN for static assets (Azure Front Door)

### 6.3 Performance Targets
- API response time: < 200ms (p95)
- Frontend load time: < 2s
- Database query time: < 100ms (p95)
- 99.9% uptime SLA

---

## 7. Disaster Recovery & Backup

### 7.1 Backup Strategy
- PostgreSQL: Automated daily backups, 35-day retention
- AKS: Configuration backup to Git
- Key Vault: Automated backup

### 7.2 Disaster Recovery
- Multi-region deployment (primary + secondary)
- Database geo-replication
- Failover procedures documented

---

## 8. Cost Optimization

### 8.1 Resource Sizing
- Right-sized AKS node pools
- Reserved instances for predictable workloads
- Spot instances for non-critical workloads

### 8.2 Monitoring
- Cost alerts and budgets
- Resource utilization monitoring
- Idle resource cleanup

---

## 9. Technology Stack Summary

| Layer | Technology |
|-------|-----------|
| Frontend | React 18+, Module Federation, TypeScript |
| API Gateway | Apigee API Management |
| API Specification | OpenAPI 3.0 (Swagger), SpringDoc OpenAPI |
| Backend | Spring Boot 3.x, Java 17+ |
| Database | PostgreSQL 15+ (Azure Flexible Server) |
| Container Orchestration | Azure Kubernetes Service (AKS) |
| Messaging | Azure Service Bus, Azure Event Grid |
| Authentication | Entra ID, Entra External ID |
| CI/CD | GitLab CI/CD |
| Monitoring | Azure Monitor, Application Insights |
| Secrets | Azure Key Vault (or HashiCorp Vault) |
| Infrastructure as Code | Bicep/ARM Templates |

---

## 10. Next Steps

1. Review and approve architecture
2. Set up Azure subscription and resource groups
3. Configure Entra ID and External ID tenants
4. Set up GitLab repository and CI/CD pipelines
5. Deploy infrastructure (AKS, PostgreSQL, etc.)
6. Develop and deploy microservices
7. Develop and deploy React microfrontends
8. Configure Apigee API proxies
9. Set up monitoring and alerting
10. Conduct security and GDPR compliance review
11. Performance testing and optimization
12. Production deployment

