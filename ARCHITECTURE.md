# Cloud-Native Architecture Blueprint
## Azure Architecture Template

### Executive Summary

This document outlines a production-ready, cloud-native microservices architecture template deployed on Microsoft Azure. This template provides a comprehensive foundation for building scalable, secure, and maintainable cloud-native applications with examples for each Azure service and component.

---

## Table of Contents

1. [System Overview](#1-system-overview)
   - [Architecture Purpose](#11-architecture-purpose)
   - [Key Features](#12-key-features)
2. [Architecture Diagram](#2-architecture-diagram)
   - [Azure Services Architecture Diagram](#21-azure-services-architecture-diagram)
3. [Non-Functional Requirements](#3-non-functional-requirements)
   - [High Availability](#31-high-availability)
   - [Scalability](#32-scalability)
   - [Performance](#33-performance)
   - [Reliability](#34-reliability)
   - [Security](#35-security)
   - [Maintainability](#36-maintainability)
   - [Usability](#37-usability)
   - [Compliance](#38-compliance)
   - [Disaster Recovery](#39-disaster-recovery)
4. [Component Architecture](#4-component-architecture)
   - [Frontend Layer](#41-frontend-layer)
   - [API Gateway Layer](#42-api-gateway-layer)
   - [Microservices Layer](#43-microservices-layer-spring-boot)
   - [Data Layer](#44-data-layer)
   - [Secrets Management Layer](#45-secrets-management-layer)
   - [Serverless Functions Layer](#46-serverless-functions-layer)
   - [Integration Layer](#47-integration-layer)
   - [Messaging & Events](#48-messaging--events)
   - [Authentication & Authorization](#49-authentication--authorization)
   - [Observability](#410-observability)
5. [Security Architecture](#5-security-architecture)
6. [Deployment Architecture](#6-deployment-architecture)
   - [Azure Resources](#61-azure-resources)
   - [GitLab CI/CD](#62-gitlab-cicd)
   - [Kubernetes Deployment](#63-kubernetes-deployment)
   - [Deployment Strategies](#64-deployment-strategies)
7. [Scalability & Performance](#7-scalability--performance)
8. [Disaster Recovery & Backup](#8-disaster-recovery--backup)
9. [Cost Optimization](#9-cost-optimization)
10. [Technology Stack Summary](#10-technology-stack-summary)
11. [Next Steps](#11-next-steps)

---

## 1. System Overview

### 1.1 Architecture Purpose
**Cloud-Native Application Template**
- **Purpose**: Ready-to-use architecture template for bootstrapping cloud-native applications on Azure
- **Target Users**: Development teams building cloud-native applications
- **Use Cases**: Microservices applications, web applications, API platforms, enterprise applications

### 1.2 Key Features
- React-based web application with microfrontends architecture (Module Federation)
- Spring Boot/Java REST microservices deployed on Azure Kubernetes Service (AKS)
- PostgreSQL database for persistent storage (Azure Database for PostgreSQL)
- Entra ID authentication (internal and external users)
- API Management (Apigee or Azure API Management) for API governance
- Integration examples for legacy SOAP services
- Integration examples for external REST services
- Data protection and compliance capabilities
- Real-time notifications and event-driven architecture
- GitLab CI/CD for automated deployments
- Comprehensive examples for each Azure service and component

---

## 2. Architecture Diagram

This section provides visual representations of the system architecture, including the overall system design and Azure services used.

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│  EXTERNAL USERS                           │              INTERNAL USERS                      │
│  Entra External ID Authentication         │              Entra ID Authentication             │
└──────────────────┬────────────────────────┴──────────────────────┬──────────────────────────┘
                   │                                               │
┌──────────────────▼────────────────────────┐  ┌───────────────────▼──────────────────────────┐
│  EXTERNAL REACT WEB APPLICATION          │  │  INTERNAL REACT WEB APPLICATION               │
│  (Microfrontends)                        │  │  (Microfrontends)                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   MFE 1  │  │   MFE 2  │  │   MFE 3  ││  │  │   MFE 1  │  │   MFE 2  │  │   MFE 3  │   │
│  │ (Public) │  │ (Public) │  │ (Public) ││  │  │ (Admin)  │  │ (Admin)  │  │ (Admin)  │   │
│  └──────────┘  └──────────┘  └──────────┘│  │  └──────────┘  └──────────┘  └──────────┘   │
│  ┌──────────┐                            │  │  ┌──────────┐                                │
│  │   MFE 4  │                            │  │  │   MFE 4  │                                │
│  │(Notifications)                        │  │  │(Analytics)                                │
│  └──────────┘                            │  │  └──────────┘                                │
└──────────────────┬────────────────────────┘  └──┴──────────────────────────────────────────┘
                   │                                               │
┌───────────────────▼──────────────────────────┐  ┌───────────────────▼──────────────────────────┐
│  API GATEWAY (External)                     │  │  API GATEWAY (Internal)                      │
│  Apigee / Azure API Management              │  │  Apigee / Azure API Management               │
│  ┌────────────────────────────────────────┐ │  │  ┌────────────────────────────────────┐     │
│  │ • Entra External ID JWT Validation     │ │  │  │ • Entra ID JWT Validation           │     │
│  │ • Rate Limiting                        │ │  │  │ • Rate Limiting                     │     │
│  │ • CORS Policies                        │ │  │  │ • IP Whitelisting                   │     │
│  │ • Request/Response Transform            │ │  │  │ • Request/Response Transform        │     │
│  │ • API Versioning & Analytics           │ │  │  │ • API Versioning & Analytics       │     │
│  └────────────────────────────────────────┘ │  │  └────────────────────────────────────┘     │
└───────────────────┬──────────────────────────┘  └───┬────────────────────────────────────────────┘
                    │                                  │
                    └──────────────┬───────────────────┘
                                   │
                    ┌──────────────▼───────────────────┐
                    │  AZURE KUBERNETES SERVICE (AKS) │
                    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
                    │  │  Service 1   │  │  Service 2   │  │  Service 3   │ │
                    │  │(Example)     │  │(Example)     │  │(Example)     │ │
                    │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘ │
                    │         │                 │                 │         │
                    │  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐ │
                    │  │  Service 4   │  │  Service 5   │  │  Service 6   │ │
                    │  │(Example)     │  │(Example)     │  │(Example)     │ │
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
        │  Legacy SOAP        │   │  External API 1         │   │  External API 2   │
        │  Service            │   │  (REST API)             │   │  (REST API)       │
        └─────────────────────┘   └──────────────────────────┘   └───────────────────┘
```

---

### 2.1 Azure Services Architecture Diagram

This diagram illustrates all Azure services used in the template and their relationships:

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
└─────────────────────────────────────┬─────────────────────────────────────┘
                                     │
┌─────────────────────────────────────▼─────────────────────────────────────┐
│                    AZURE KUBERNETES SERVICE (AKS)                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  Service 1   │  │  Service 2   │  │  Service 3   │  │  Service 4   │ │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────┬─────────────────────────────────────┘
                                     │
        ┌────────────────────────────┼────────────────────────────┐
        │                            │                            │
┌───────▼────────┐        ┌──────────▼──────────┐    ┌──────────▼──────────┐
│  PostgreSQL    │        │  Azure Service Bus  │    │  Azure Redis Cache  │
│  (Database)    │        │  (Messaging)        │    │  (Caching)          │
└───────┬────────┘        └──────────────────────┘    └──────────────────────┘
        │
┌───────▼────────┐
│  Azure Key     │
│  Vault         │
│  (Secrets)     │
└───────┬────────┘
        │
┌───────▼────────┐        ┌──────────▼──────────┐    ┌──────────▼──────────┐
│  Azure Blob    │        │  Azure Functions    │    │  Application        │
│  Storage       │        │  (Serverless)       │    │  Insights           │
│  (Archiving)   │        │                     │    │  (Monitoring)       │
└────────────────┘        └──────────────────────┘    └──────────────────────┘
```

**Key Azure Services**:
- **Azure Kubernetes Service (AKS)**: Container orchestration for microservices
- **Azure Database for PostgreSQL**: Primary database for persistent storage
- **Azure Service Bus**: Asynchronous messaging and event-driven architecture
- **Azure Redis Cache**: In-memory caching for performance optimization
- **Azure Key Vault**: Secrets management and certificate storage
- **Azure Blob Storage**: File storage and archiving
- **Azure Functions**: Serverless compute for housekeeping jobs
- **Application Insights**: Application performance monitoring and observability
- **Entra ID / External ID**: Authentication and authorization
- **Azure API Management / Apigee**: API gateway and management
- **Azure Static Web Apps / App Service**: Frontend hosting

---

## 3. Non-Functional Requirements

This section defines the non-functional requirements (NFRs) that the system must meet. These requirements focus on system qualities such as availability, scalability, performance, and reliability rather than specific functional features.

### 3.1 High Availability

**Requirement**: The system must maintain high availability with minimal downtime.

**Target Metrics**:
- **Uptime SLA**: 99.9% (maximum 43.8 minutes downtime per month)
- **Planned Maintenance Window**: Maximum 4 hours per month (scheduled during low-traffic periods)
- **Unplanned Downtime**: Maximum 0.1% (43.8 minutes per month)

**Note**: These metrics are examples and should be adjusted based on your specific requirements.

**Implementation Strategy**:

1. **Multi-Region Deployment**
   - Primary region: West Europe
   - Secondary region: North Europe (for disaster recovery)
   - Active-passive configuration with automatic failover

2. **AKS High Availability**
   - Multiple node pools across availability zones
   - Pod anti-affinity rules to distribute replicas
   - Minimum 3 replicas per service
   - Health checks and automatic pod restart

3. **Database High Availability**
   - PostgreSQL Flexible Server with zone-redundant high availability
   - Automated failover (RTO < 60 seconds)
   - Read replicas for read-heavy workloads
   - Automated backups with point-in-time recovery

4. **API Gateway High Availability**
   - Apigee: Multi-region deployment (if using Apigee X)
   - Azure API Management: Premium tier with multi-region support
   - Load balancing across gateway instances

5. **Frontend High Availability**
   - Azure Static Web Apps: Global CDN distribution
   - Azure App Service: Multiple instances with auto-scaling
   - Health monitoring and automatic instance replacement

6. **Service Bus High Availability**
   - Premium tier with zone-redundant configuration
   - Message replication across availability zones

**Monitoring**:
- Azure Monitor alerts for service unavailability
- Application Insights availability tests
- Automated incident response procedures

---

### 3.2 Scalability

**Requirement**: The system must scale horizontally and vertically to handle varying loads.

**Target Metrics**:
- **Concurrent Users**: Support 10,000 concurrent external users and 1,000 concurrent internal users
- **API Requests**: Handle 100,000 requests per minute (peak)
- **Database Connections**: Support 1,000 concurrent database connections
- **Message Throughput**: Process 50,000 messages per minute

**Implementation Strategy**:

1. **Horizontal Scaling (AKS)**
   - **Cluster Autoscaling**: Automatically scale node pools based on demand
   - **Pod Autoscaling (HPA)**: Scale pods based on CPU (70% threshold) and memory (80% threshold)
   - **Custom Metrics**: Scale based on queue depth, request rate, or custom business metrics
   - **Target Replicas**: Minimum 3, maximum 20 per service

2. **Database Scaling**
   - **Read Replicas**: Up to 5 read replicas for read-heavy workloads
   - **Vertical Scaling**: Scale compute and storage independently
   - **Connection Pooling**: PgBouncer for efficient connection management
   - **Partitioning**: Table partitioning for large datasets (example: business entities, audit logs)

3. **Caching Strategy**
   - **Redis Cache**: Cache frequently accessed data (example: business entities, user profiles)
   - **CDN**: Azure Front Door for static assets and API responses
   - **Application-Level Caching**: In-memory caching in Spring Boot services

4. **API Gateway Scaling**
   - **Apigee**: Auto-scaling based on traffic
   - **Azure API Management**: Scale units based on capacity (Standard: 1-4 units, Premium: 1-12 units)

5. **Message Queue Scaling**
   - **Service Bus**: Premium tier with auto-scaling
   - **Partitioning**: Partition topics for parallel processing
   - **Consumer Scaling**: Multiple consumers per subscription

6. **Frontend Scaling**
   - **Static Web Apps**: Automatic global CDN scaling
   - **App Service**: Auto-scaling based on CPU, memory, or HTTP queue length

**Scaling Triggers**:
- CPU utilization > 70% for 5 minutes
- Memory utilization > 80% for 5 minutes
- Request queue length > 100
- Response time > 500ms (p95)
- Custom business metrics (e.g., queue depth, request rate)

---

### 3.3 Performance

**Requirement**: The system must meet specified performance targets for response times and throughput.

**Target Metrics**:

| Component | Metric | Target | Measurement |
|-----------|--------|--------|-------------|
| **API Response Time** | P50 (median) | < 100ms | 95% of requests |
| | P95 | < 200ms | 95% of requests |
| | P99 | < 500ms | 99% of requests |
| **Frontend Load Time** | Initial page load | < 2 seconds | Time to First Byte (TTFB) |
| | Time to Interactive | < 3 seconds | Full page interactive |
| **Database Query Time** | P95 | < 100ms | Query execution time |
| **Message Processing** | End-to-end latency | < 1 second | Event publish to processing |
| **Authentication** | Token validation | < 50ms | JWT validation time |
| **Throughput** | API requests/sec | 1,000+ | Sustained throughput |

**Implementation Strategy**:

1. **API Performance**
   - Response caching for read-heavy endpoints
   - Database query optimization (indexes, query tuning)
   - Connection pooling (HikariCP for Spring Boot)
   - Async processing for non-critical operations

2. **Frontend Performance**
   - Code splitting and lazy loading
   - Image optimization and CDN delivery
   - Service Worker for offline support
   - Bundle size optimization (< 500KB initial load)

3. **Database Performance**
   - Index optimization on frequently queried columns
   - Query plan analysis and optimization
   - Read replicas for read-heavy queries
   - Connection pooling (PgBouncer)

4. **Caching Strategy**
   - Redis cache for hot data (TTL: 1 hour)
   - Application-level caching (Caffeine cache)
   - HTTP response caching (Cache-Control headers)

5. **Monitoring**
   - Application Insights for performance monitoring
   - Custom metrics and dashboards
   - Performance regression detection
   - Load testing in staging environment

---

### 3.4 Reliability

**Requirement**: The system must operate reliably with minimal errors and automatic recovery.

**Target Metrics**:
- **Error Rate**: < 0.1% (99.9% success rate)
- **MTBF (Mean Time Between Failures)**: > 720 hours (30 days)
- **MTTR (Mean Time To Recovery)**: < 15 minutes
- **Data Consistency**: 100% (no data loss)

**Implementation Strategy**:

1. **Error Handling**
   - Comprehensive error handling in all services
   - Graceful degradation for non-critical features
   - Circuit breakers (Resilience4j) for external service calls
   - Retry logic with exponential backoff

2. **Data Reliability**
   - Database transactions for data consistency
   - Idempotency keys for critical operations
   - Event sourcing for audit trails
   - Automated backups (daily) with 35-day retention

3. **Service Reliability**
   - Health checks and automatic restart
   - Liveness and readiness probes in Kubernetes
   - Dead letter queues for failed messages
   - Transactional outbox pattern for reliable messaging

4. **Monitoring and Alerting**
   - Real-time error monitoring (Application Insights)
   - Automated alerts for error rate thresholds
   - Error tracking and analysis
   - Incident response procedures

---

### 3.5 Security

**Requirement**: The system must implement comprehensive security measures to protect data and services.

**Target Metrics**:
- **Security Incidents**: Zero critical security incidents
- **Vulnerability Remediation**: Critical vulnerabilities patched within 24 hours
- **Access Control**: 100% authenticated and authorized access
- **Data Encryption**: 100% encryption at rest and in transit

**Implementation Strategy**:

1. **Authentication & Authorization**
   - JWT-based authentication (Entra ID / External ID)
   - Role-based access control (RBAC)
   - API key management for service-to-service communication
   - Multi-factor authentication (MFA) for internal users

2. **Data Protection**
   - Encryption at rest (Azure managed keys)
   - Encryption in transit (TLS 1.2+)
   - PII data masking in logs
   - Secrets management (Azure Key Vault or HashiCorp Vault)

3. **Network Security**
   - Private AKS cluster with private endpoints
   - Network policies for pod-to-pod communication
   - Azure Firewall for egress traffic control
   - DDoS protection (Azure DDoS Protection Standard)

4. **Application Security**
   - OWASP Top 10 protection
   - Input validation and sanitization
   - SQL injection prevention (parameterized queries)
   - XSS and CSRF protection

5. **Compliance**
   - GDPR compliance (data export, deletion, audit)
   - Security audit logging
   - Regular security assessments
   - Penetration testing (annual)

---

### 3.6 Maintainability

**Requirement**: The system must be maintainable with clear documentation, monitoring, and operational procedures.

**Target Metrics**:
- **Deployment Time**: < 30 minutes for full deployment
- **Incident Resolution**: 80% of incidents resolved within SLA
- **Documentation Coverage**: 100% of APIs and services documented
- **Code Coverage**: > 80% unit test coverage

**Implementation Strategy**:

1. **Code Quality**
   - Code reviews for all changes
   - Automated testing (unit, integration, E2E)
   - Static code analysis (SonarQube)
   - Consistent coding standards

2. **Documentation**
   - API documentation (OpenAPI/Swagger)
   - Architecture documentation
   - Runbooks for operations
   - Deployment guides

3. **Monitoring & Observability**
   - Centralized logging (Azure Log Analytics)
   - Distributed tracing (Application Insights)
   - Custom dashboards
   - Alert rules and notifications

4. **CI/CD**
   - Automated builds and tests
   - Automated deployments
   - Rollback procedures
   - Blue-green deployments

---

### 3.7 Usability

**Requirement**: The system must provide an intuitive and responsive user experience.

**Target Metrics**:
- **User Satisfaction**: > 4.0/5.0 rating
- **Task Completion Rate**: > 95%
- **Error Recovery**: Users can recover from errors without support
- **Accessibility**: WCAG 2.1 AA compliance

**Implementation Strategy**:

1. **User Interface**
   - Responsive design (mobile, tablet, desktop)
   - Intuitive navigation
   - Consistent design system
   - Loading states and progress indicators

2. **Error Handling**
   - Clear error messages
   - Helpful error recovery suggestions
   - Validation feedback
   - Graceful error handling

3. **Performance**
   - Fast page loads (< 2 seconds)
   - Smooth interactions (60 FPS)
   - Optimistic UI updates
   - Progressive loading

4. **Accessibility**
   - Keyboard navigation
   - Screen reader support
   - Color contrast compliance
   - ARIA labels

---

### 3.8 Compliance

**Requirement**: The system must comply with relevant regulations and standards.

**Target Metrics**:
- **GDPR Compliance**: 100% compliance with GDPR requirements
- **Audit Trail**: 100% of critical operations logged
- **Data Retention**: Compliance with data retention policies
- **Privacy**: User consent management

**Implementation Strategy**:

1. **GDPR Compliance**
   - Right to access (data export)
   - Right to erasure (data deletion)
   - Right to rectification (data updates)
   - Consent management
   - Data breach notification procedures

2. **Audit Logging**
   - Comprehensive audit trails
   - Immutable audit logs
   - 10-year retention for audit logs
   - Secure storage and access control

3. **Data Protection**
   - Data minimization
   - Privacy by design
   - Encryption of sensitive data
   - Access controls and monitoring

---

### 3.9 Disaster Recovery

**Requirement**: The system must have robust disaster recovery procedures to minimize data loss and downtime.

**Target Metrics**:
- **RPO (Recovery Point Objective)**: < 1 hour (maximum data loss)
- **RTO (Recovery Time Objective)**: < 4 hours (maximum downtime)
- **Backup Frequency**: Daily automated backups
- **Backup Retention**: 35 days (point-in-time recovery)

**Implementation Strategy**:

1. **Backup Strategy**
   - Daily automated database backups
   - Geo-redundant backup storage
   - Point-in-time recovery capability
   - Configuration backup (Infrastructure as Code)

2. **Disaster Recovery Plan**
   - Documented DR procedures
   - Regular DR drills (quarterly)
   - Multi-region deployment
   - Automated failover procedures

3. **Data Replication**
   - Database geo-replication
   - Service Bus message replication
   - Key Vault backup and restore

4. **Recovery Procedures**
   - Step-by-step recovery runbooks
   - Recovery testing procedures
   - Communication plan
   - Post-incident review process

---

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
│  │  │ Service 1│  │ Service 2│  │ Service 3│  │ Service 4│          │   │
│  │  │(Example) │  │(Example) │  │(Example) │  │(Example) │          │   │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘          │   │
│  │       │            │             │             │                  │   │
│  │  ┌────▼─────┐  ┌───▼──────┐  ┌───▼──────┐                        │   │
│  │  │ Service 5│  │ Service 6│  │  Other   │                        │   │
│  │  │(Example) │  │(Example) │  │ Services │                        │   │
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
│  • service-events topic (example)                                           │
│  • business-events topic (example)                                          │
│  • notification-events topic (example)                                       │
│  • audit-events topic (example)                                              │
└───────────────────────────────────────┬─────────────────────────────────────┘
                                        │
┌───────────────────────────────────────▼─────────────────────────────────────┐
│                    AZURE EVENT GRID (Event-Driven)                           │
│  • Service lifecycle events (example)                                        │
│  • Business events (example)                                                 │
│  • Compliance events (example)                                               │
└───────────────────────────────────────┬─────────────────────────────────────┘
                                        │
┌───────────────────────────────────────▼─────────────────────────────────────┐
│                    AZURE FUNCTIONS (Serverless)                              │
│  • Housekeeping Jobs:                                                        │
│    - Data retention cleanup                                                  │
│    - Old notification cleanup                                                │
│    - Audit log archival to Blob Storage                                     │
│    - GDPR data anonymization                                                │
│    - Database maintenance                                                    │
│    - File archiving to Blob Storage                                         │
│  • Scheduled Tasks (Timer Triggers)                                         │
│  • Event-Driven Tasks (Service Bus Triggers)                                 │
└───────────────────────────────────────┬─────────────────────────────────────┘
                                        │
┌───────────────────────────────────────▼─────────────────────────────────────┐
│                    AZURE BLOB STORAGE (Archiving)                            │
│  • archive container - Archived files and documents                         │
│  • audit-logs container - Archived audit logs for compliance                │
│  • compliance-data container - Compliance export and anonymized data        │
│  • documents container - User documents and attachments                     │
│  • Lifecycle management - Auto-tiering (Hot → Cool → Archive)               │
│  • Automated deletion after retention period (7 years)                      │
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
| **Azure Blob Storage** | Object storage | File archiving, audit logs, GDPR data, customer documents |
| **Azure Key Vault** | Secrets management | Stores passwords, connection strings, certificates (or HashiCorp Vault as alternative) |
| **Azure Service Bus** | Message broker | Asynchronous communication between services |
| **Azure Event Grid** | Event routing | Event-driven architecture for real-time processing |
| **Azure Functions** | Serverless compute | Housekeeping jobs, scheduled tasks, event processing, file archiving |
| **Application Insights** | Application monitoring | Performance monitoring, distributed tracing |
| **Azure Monitor** | Infrastructure monitoring | Metrics, alerts, dashboards |
| **Log Analytics Workspace** | Centralized logging | Log aggregation and analysis |
| **Azure Container Registry (ACR)** | Container registry | Docker image storage for CI/CD |
| **Entra ID** | Identity provider | Employee authentication |
| **Entra External ID** | B2C identity provider | Client authentication |

---

## 4. Component Architecture

### 4.1 Frontend Layer

**Important**: There are **two separate frontend applications** - one for external clients and one for internal employees. They are completely independent and do not call each other.

#### 4.1.1 External Frontend Application (Client-Facing)
**Technology**: React 18+, Module Federation (Webpack 5)
**Deployment**: Azure Static Web Apps
**Authentication**: Entra External ID

**Microfrontends**:
1. **Example MFE 1** (Public)
   - Example functionality for external users
   - User-facing features

2. **Example MFE 2** (Public)
   - Example functionality for external users
   - User-facing features

3. **Example MFE 3** (Public)
   - User profile, settings
   - Data management (export, deletion requests)

4. **Example MFE 4** (Notifications)
   - Real-time notifications via WebSocket/SSE
   - Client-facing notifications

**Host Application**:
- Shell application that orchestrates microfrontends
- Handles routing, authentication context (Entra External ID), shared state
- Deployed to Azure Static Web Apps
- Connects to Apigee External API Proxy

#### 4.1.2 Internal Frontend Application (Employee-Facing)
**Technology**: React 18+, Module Federation (Webpack 5)
**Deployment**: Azure App Service
**Authentication**: Entra ID

**Microfrontends**:
1. **Example MFE 1** (Admin Dashboard)
   - System overview, metrics, dashboards
   - Administrative tools

2. **Example MFE 2** (Management)
   - Management and processing features
   - Status updates and fulfillment

3. **Example MFE 3** (Data Management)
   - Data management tools
   - User data management
   - Compliance tools

4. **Example MFE 4** (Analytics)
   - Business analytics
   - Reporting and insights

**Host Application**:
- Shell application that orchestrates microfrontends
- Handles routing, authentication context (Entra ID), shared state
- Deployed to Azure App Service
- Connects to Apigee Internal API Proxy

---

### 4.2 API Gateway Layer

**API Gateway Options**: This architecture supports two API gateway solutions:
1. **Apigee API Management** (Google Cloud) - See `apigee/` directory
2. **Azure API Management** (Azure) - See `azure-api-management/` directory

For a detailed comparison, see [API_GATEWAY_COMPARISON.md](./API_GATEWAY_COMPARISON.md).

**Recommendation**: For this Azure-native architecture, **Azure API Management** is recommended due to native Azure integration, cost-effectiveness, and easier management. However, **Apigee** can be used if advanced analytics, monetization, or multi-cloud support is required.

#### 4.2.1 Apigee API Management
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

#### 4.2.2 Azure API Management (Alternative)
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

### 4.3 Microservices Layer (Spring Boot)

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

#### 4.3.1 Example Service 1
**Responsibilities**:
- Example entity creation, updates, status tracking
- Example history retrieval
- Example validation and business rules

**REST API Endpoints** (exposed via Apigee):
- `POST /api/v1/examples` - Create example entity
- `GET /api/v1/examples/{id}` - Get example details
- `GET /api/v1/examples` - List examples (with filters)
- `PUT /api/v1/examples/{id}/status` - Update status
- `DELETE /api/v1/examples/{id}` - Delete example (compliance compliant)

**OpenAPI Spec**: Available at `/v3/api-docs` endpoint (internal) and published to Apigee

**Database**: `service1` schema in PostgreSQL
- Tables: `examples`, `example_items`, `example_status_history`

**Integrations**:
- Calls Example Service 5 for processing
- Calls Example Service 2 for validation
- Publishes events to Azure Service Bus

---

#### 4.3.2 Example Service 2
**Responsibilities**:
- Example catalog management
- Example tracking
- Example search and filtering

**REST API Endpoints** (exposed via Apigee):
- `GET /api/v1/examples` - List examples
- `GET /api/v1/examples/{id}` - Get example details
- `POST /api/v1/examples` - Create example (internal only)
- `PUT /api/v1/examples/{id}` - Update example (internal only)
- `GET /api/v1/examples/search` - Search examples

**OpenAPI Spec**: Available at `/v3/api-docs` endpoint (internal) and published to Apigee

**Database**: `service2` schema in PostgreSQL
- Tables: `examples`, `example_categories`, `inventory`

**Integrations**:
- Called by Example Service 1 for validation
- Integrates with external SOAP API (example)

---

#### 4.3.3 Example Service 3
**Responsibilities**:
- User profile management
- Data management (right to access, deletion)
- User segmentation

**REST API Endpoints** (exposed via Apigee):
- `GET /api/v1/users/{id}` - Get user profile
- `PUT /api/v1/users/{id}` - Update profile
- `POST /api/v1/users/{id}/data/export` - Data export
- `DELETE /api/v1/users/{id}` - Data deletion
- `GET /api/v1/users/{id}/history` - User history

**OpenAPI Spec**: Available at `/v3/api-docs` endpoint (internal) and published to Apigee

**Database**: `service3` schema in PostgreSQL
- Tables: `users`, `user_preferences`, `compliance_audit_log`

**Integrations**:
- Called by Example Service 1 for user validation
- Publishes compliance events to Example Service 6

---

#### 4.3.4 Example Service 4 (Notification Service)
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

**Database**: `service4` schema in PostgreSQL
- Tables: `notifications`, `notification_preferences`

**Integrations**:
- Subscribes to Azure Service Bus events
- Integrates with Azure Communication Services
- Sends notifications to both internal and external users

---

#### 4.3.5 Example Service 5
**Responsibilities**:
- Example processing functionality
- External API integration
- Example history and reconciliation

**REST API Endpoints** (exposed via Apigee):
- `POST /api/v1/examples` - Process example
- `GET /api/v1/examples/{id}` - Get example status
- `POST /api/v1/examples/{id}/reverse` - Reverse example

**OpenAPI Spec**: Available at `/v3/api-docs` endpoint (internal) and published to Apigee

**Database**: `service5` schema in PostgreSQL
- Tables: `examples`, `example_transactions`, `reversals`

**Integrations**:
- Integrates with external REST API (example)
- Called by Example Service 1
- Publishes business events (example)

---

#### 4.3.6 Example Service 6 (Audit Service)
**Responsibilities**:
- Compliance logging
- Security audit trails
- Activity logging

**REST API Endpoints** (exposed via Apigee - Internal only):
- `POST /api/v1/audit/logs` - Create audit log
- `GET /api/v1/audit/logs` - Query audit logs
- `GET /api/v1/audit/compliance/{userId}` - Compliance audit trail

**OpenAPI Spec**: Available at `/v3/api-docs` endpoint (internal) and published to Apigee

**Database**: `service6` schema in PostgreSQL
- Tables: `audit_logs`, `compliance_audit_trail`

**Integrations**:
- Receives events from all services
- Integrates with Azure Log Analytics

---

### 4.4 Data Layer

#### 4.4.1 PostgreSQL Database
**Deployment**: Azure Database for PostgreSQL Flexible Server

**Database Structure**:
- Separate schemas per service (service1, service2, service3, service4, service5, service6)
- Connection pooling via PgBouncer
- Read replicas for scaling
- Automated backups with point-in-time recovery

**GDPR Compliance**:
- Data encryption at rest (Azure managed keys)
- Data encryption in transit (TLS 1.2+)
- Automated data retention policies
- Audit logging for all data access

---

#### 4.4.2 Azure Redis Cache
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

#### 4.4.3 Azure Blob Storage
**Deployment**: Azure Storage Account (StorageV2) with Blob Storage

**Purpose**:
- Long-term file archiving for compliance and retention
- Storage of audit logs and audit trails
- GDPR data export and anonymized data storage
- Customer documents and attachments
- Automated lifecycle management with cost optimization

**Configuration**:
- Storage Account: Standard LRS (Locally Redundant Storage)
- Access Tier: Hot (frequently accessed), Cool (infrequently accessed), Archive (rarely accessed)
- TLS 1.2+ required
- Public access disabled
- Soft delete enabled (7 days retention)
- Container delete retention enabled (7 days)

**Containers**:
1. **archive** - General archived files and documents
   - Lifecycle: Hot → Cool (30 days) → Archive (90 days) → Delete (7 years)
   
2. **audit-logs** - Archived audit logs for compliance
   - Lifecycle: Hot → Delete after 7 years (GDPR compliance)
   
3. **gdpr-data** - GDPR export and anonymized data
   - Lifecycle: Hot → Cool (30 days) → Archive (90 days) → Delete (7 years)
   
4. **customer-documents** - Customer documents and attachments
   - Lifecycle: Hot → Cool (30 days) → Archive (90 days) → Delete (7 years)

**Lifecycle Management Policies**:
- **Automatic Tiering**: Files automatically move from Hot to Cool tier after 30 days, then to Archive tier after 90 days
- **Automatic Deletion**: Files are automatically deleted after 7 years (2555 days) for GDPR compliance
- **Cost Optimization**: Reduces storage costs by moving infrequently accessed data to cheaper tiers

**Usage Patterns**:
1. **Audit Log Archival**
   - Archive old audit logs from PostgreSQL to Blob Storage
   - Maintain 7-year retention for compliance
   - Automated archival via Azure Functions

2. **GDPR Data Export**
   - Export customer data to Blob Storage on request
   - Store anonymized data for analytics
   - Secure access with SAS tokens

3. **Customer Documents**
   - Store customer-uploaded documents
   - Archive order-related documents (invoices, receipts)
   - Lifecycle management for cost optimization

4. **File Archiving**
   - Archive old files from application storage
   - Move files to archive tier after inactivity
   - Automated cleanup after retention period

**Integration**:
- **Azure Functions**: Automated archival jobs move data from PostgreSQL/application storage to Blob Storage
- **Spring Boot Services**: Direct integration using Azure Storage SDK for Java
- **Key Vault**: Store connection strings and SAS tokens securely
- **Managed Identity**: Authenticate to Blob Storage using Azure Managed Identity (recommended)

**Security**:
- Private endpoints for secure access (optional)
- Role-Based Access Control (RBAC) for container access
- Shared Access Signatures (SAS) for temporary access
- Encryption at rest (Azure managed keys)
- Encryption in transit (TLS 1.2+)

**Cost Optimization**:
- Hot tier: $0.0184 per GB/month (frequently accessed)
- Cool tier: $0.01 per GB/month (infrequently accessed)
- Archive tier: $0.00099 per GB/month (rarely accessed)
- Lifecycle policies automatically optimize costs by tiering data

---

### 4.5 Secrets Management Layer

**Secrets Management Options**: This architecture supports two secrets management solutions:
1. **Azure Key Vault** (Azure) - See `infrastructure/bicep/main.bicep` for Key Vault resource
2. **HashiCorp Vault** (Self-hosted/HCP) - See `hashicorp-vault/` directory

For a detailed comparison, see [SECRETS_MANAGEMENT_COMPARISON.md](./SECRETS_MANAGEMENT_COMPARISON.md).

**Recommendation**: For this Azure-native architecture, **Azure Key Vault** is recommended due to native Azure integration, managed service, and cost-effectiveness. However, **HashiCorp Vault** can be used if dynamic secrets, multi-cloud support, or encryption as a service is required.

#### 4.5.1 Azure Key Vault
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

#### 4.5.2 HashiCorp Vault (Alternative)
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

### 4.6 Serverless Functions Layer

#### 4.6.1 Azure Functions (Housekeeping Jobs)
**Deployment**: Azure Functions (Consumption Plan)

**Functions**:

1. **DataRetentionCleanup** (Timer Trigger - Daily at 2 AM UTC)
   - Clean up old notifications (older than 90 days)
   - Anonymize inactive user data (older than 7 years)
   - Delete archived audit logs older than 7 years (after archival to Blob Storage)

2. **AuditLogArchival** (Timer Trigger - Daily at 3 AM UTC)
   - Archive audit logs older than 1 year to Azure Blob Storage
   - Group logs by date for efficient storage
   - Mark logs as archived in database
   - Store in `audit-logs` container with lifecycle management

3. **DatabaseMaintenance** (Timer Trigger - Weekly on Sundays at 3 AM UTC)
   - Run VACUUM ANALYZE on PostgreSQL
   - Update table statistics
   - Optimize database performance

4. **ComplianceDataAnonymization** (Service Bus Trigger)
   - Process data deletion requests (e.g., GDPR)
   - Anonymize user data across all services
   - Archive anonymized data to Blob Storage (`compliance-data` container)
   - Export user data to Blob Storage on request

5. **NotificationCleanup** (Timer Trigger - Daily at 1 AM UTC)
   - Remove read notifications older than 30 days
   - Archive notification history to Blob Storage if needed

**Technology**: Java 17, Azure Functions Java Library

**Configuration**:
- Consumption plan for cost efficiency
- Application Insights integration
- Connection to PostgreSQL and Redis Cache
- Connection to Azure Blob Storage for archiving
- Service Bus triggers for event-driven processing

**Blob Storage Integration**:
- Automated archival of audit logs to Blob Storage
- GDPR data export and anonymization storage
- Customer document archiving
- Lifecycle management policies for cost optimization

---

### 4.7 Integration Layer

#### 4.7.1 Legacy SOAP Service Integration
**Service**: Example Service → Legacy SOAP System

**Implementation**:
- Spring WS (Web Services) for SOAP client
- WSDL-based service generation
- Retry logic and circuit breakers
- Async processing for non-critical operations

**Use Cases**:
- Inventory synchronization
- Product master data sync

---

#### 4.7.2 External REST Service Integration
**Services**:
1. **External API 1** (Example Service)
   - RESTful API integration
   - OAuth 2.0 authentication
   - Idempotency handling
   - Example: Payment gateway, shipping service, or third-party API

2. **External API 2** (Example Service)
   - RESTful API integration
   - Authentication as required
   - Error handling and retries
   - Example: External service integration

---

### 4.8 Messaging & Events

#### 4.8.1 Azure Service Bus
**Purpose**: Asynchronous communication between services

**Topics**:
- `service-events` - Service lifecycle events (example)
- `business-events` - Business processing events (example)
- `notification-events` - Notification triggers (example)
- `compliance-events` - Compliance events (example)

**Subscriptions**:
- Per-service subscriptions with filters
- Dead-letter queues for failed messages

---

#### 4.8.2 Azure Event Grid
**Purpose**: Event-driven architecture for real-time processing

**Event Types**:
- Order created/updated
- Payment processed
- GDPR data request
- Notification sent

---

### 4.9 Authentication & Authorization

#### 4.9.1 Entra ID (Azure AD) - Employees
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

#### 4.9.2 Entra External ID - Clients
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

### 4.10 Observability

#### 4.10.1 Azure Monitor
- Application Insights for all services
- Custom metrics and dashboards
- Alert rules for critical errors

#### 4.10.2 Logging
- Centralized logging via Azure Log Analytics
- Structured logging (JSON format)
- Log retention per GDPR requirements

#### 4.10.3 Distributed Tracing
- Application Insights distributed tracing
- Correlation IDs across services
- Performance monitoring

---

## 5. Security Architecture

### 5.1 Network Security
- AKS private cluster with private endpoints
- Network policies for service-to-service communication
- Azure Firewall for egress traffic control
- VPN/ExpressRoute for on-premises connectivity (if needed)

### 5.2 Application Security
- JWT token validation at API Gateway (Apigee or Azure API Management) and service level
- HTTPS/TLS 1.2+ everywhere
- Secrets management via Azure Key Vault or HashiCorp Vault
- OWASP Top 10 protection

### 5.3 Data Security
- Encryption at rest (Azure managed keys)
- Encryption in transit (TLS)
- Database access via private endpoints
- PII data masking in logs

### 5.4 GDPR Compliance
- Right to access: Data export endpoints
- Right to deletion: Soft delete with audit trail
- Data minimization: Only collect necessary data
- Consent management: Track user consents
- Data breach notification: Automated alerts
- Privacy by design: Built into architecture

---

## 6. Deployment Architecture

### 6.1 Azure Resources
- **AKS Cluster**: Kubernetes 1.28+, 3 node pools (system, user, compute)
- **PostgreSQL**: Flexible Server, zone-redundant high availability
- **Apigee**: Apigee X on Google Cloud (or Azure API Management as alternative)
- **Service Bus**: Premium tier for production
- **Key Vault**: For secrets management (Azure Key Vault or HashiCorp Vault)
- **Container Registry**: Azure Container Registry (ACR)
- **Static Web Apps**: For React frontend (or App Service)

### 6.2 GitLab CI/CD
- **GitLab Runners**: Self-hosted or GitLab.com
- **Pipeline Stages**:
  1. Build (compile, test, build Docker images)
  2. Security scan (SAST, dependency scanning)
  3. Deploy to Dev
  4. Integration tests
  5. Deploy to Staging
  6. E2E tests
  7. Deploy to Production (manual approval)

### 6.3 Kubernetes Deployment
- **Namespaces**: `dev`, `staging`, `production`
- **Package Management**: Helm charts for microservices deployment
- **Deployments**: Each microservice as separate deployment (managed via Helm)
- **Services**: ClusterIP for internal, LoadBalancer for external
- **Ingress**: NGINX Ingress Controller with TLS
- **ConfigMaps**: Application configuration (via Helm values)
- **Secrets**: Retrieved from Azure Key Vault (via CSI driver) or HashiCorp Vault (via Vault Agent)
- **Helm Charts**: Standardized Helm charts for all microservices with environment-specific values files

**Helm Benefits**:
- Consistent deployment structure across all services
- Environment-specific configurations (dev, staging, prod)
- Version management and rollback capabilities
- CI/CD integration for automated deployments
- Template-based configuration management

For detailed Helm usage, see [HELM_GUIDE.md](./HELM_GUIDE.md).

---

### 6.4 Deployment Strategies

This section outlines the deployment strategies used for safe, zero-downtime deployments of microservices and frontend applications.

#### 6.4.1 Deployment Strategy Overview

**Principles**:
- Zero-downtime deployments
- Gradual rollout with automatic rollback
- Feature flags for controlled feature releases
- Health checks and automated validation
- Canary and blue-green deployments

**Deployment Environments**:
- **Development**: Immediate deployment, no approval required
- **Staging**: Automatic deployment after successful tests
- **Production**: Manual approval with gradual rollout

---

#### 6.4.2 Blue-Green Deployment

**Description**: Deploy new version alongside existing version, then switch traffic.

**Use Cases**:
- Production deployments requiring zero downtime
- Major version upgrades
- Database schema migrations
- High-risk deployments

**Implementation**:

1. **Kubernetes Blue-Green Deployment**
   ```yaml
   # Blue deployment (current version)
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: order-service-blue
     labels:
       version: blue
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: order-service
         version: blue
   
   # Green deployment (new version)
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: order-service-green
     labels:
       version: green
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: order-service
         version: green
   ```

2. **Traffic Switching**
   - Use Kubernetes Service selector to switch between blue/green
   - Switch all traffic at once or gradually
   - Keep blue deployment running for quick rollback

3. **Validation Steps**:
   - Health checks on green deployment
   - Smoke tests
   - Monitor metrics for 15 minutes
   - Validate business metrics

4. **Rollback Procedure**:
   - Switch Service selector back to blue
   - Keep green deployment for analysis
   - Investigate issues before cleanup

**Advantages**:
- ✅ Zero downtime
- ✅ Instant rollback
- ✅ Full validation before traffic switch
- ✅ Isolated testing environment

**Disadvantages**:
- ❌ Requires double resources during deployment
- ❌ Database migration complexity
- ❌ More complex setup

---

#### 6.4.3 Canary Deployment

**Description**: Gradually roll out new version to a small percentage of users, then increase.

**Use Cases**:
- Low-risk deployments
- Performance validation
- A/B testing
- Gradual feature rollouts

**Implementation**:

1. **Kubernetes Canary Deployment with Istio**
   ```yaml
   # Canary traffic splitting
   apiVersion: networking.istio.io/v1beta1
   kind: VirtualService
   metadata:
     name: order-service
   spec:
     hosts:
     - order-service
     http:
     - match:
       - headers:
           canary:
             exact: "true"
       route:
       - destination:
           host: order-service
           subset: canary
         weight: 100
     - route:
       - destination:
           host: order-service
           subset: stable
         weight: 90
       - destination:
           host: order-service
           subset: canary
         weight: 10
   ```

2. **Canary Phases**:
   - **Phase 1**: 5% traffic to canary (5 minutes)
   - **Phase 2**: 25% traffic to canary (10 minutes)
   - **Phase 3**: 50% traffic to canary (15 minutes)
   - **Phase 4**: 100% traffic to canary (promote to stable)

3. **Automated Promotion Criteria**:
   - Error rate < 0.1%
   - Response time within 10% of baseline
   - No critical errors
   - Business metrics within acceptable range

4. **Automated Rollback Criteria**:
   - Error rate > 1%
   - Response time degradation > 50%
   - Critical errors detected
   - Business metrics degradation

**Advantages**:
- ✅ Minimal risk exposure
- ✅ Real-user validation
- ✅ Gradual rollout
- ✅ Automatic rollback

**Disadvantages**:
- ❌ Requires service mesh (Istio)
- ❌ More complex monitoring
- ❌ Slower full rollout

---

#### 6.4.4 Rolling Deployment

**Description**: Gradually replace old pods with new pods.

**Use Cases**:
- Standard deployments
- Development and staging environments
- Low-risk production deployments

**Implementation**:

1. **Kubernetes Rolling Update** (default strategy)
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   spec:
     strategy:
       type: RollingUpdate
       rollingUpdate:
         maxSurge: 1
         maxUnavailable: 0
     replicas: 3
   ```

2. **Rolling Update Parameters**:
   - **maxSurge**: Maximum number of pods that can be created above desired replicas
   - **maxUnavailable**: Maximum number of pods that can be unavailable during update
   - **minReadySeconds**: Minimum seconds a pod must be ready before considered available

3. **Health Checks**:
   - Liveness probe: Restart unhealthy pods
   - Readiness probe: Remove pods from service during updates
   - Startup probe: Wait for slow-starting applications

**Advantages**:
- ✅ No downtime (if configured correctly)
- ✅ Resource efficient
- ✅ Simple implementation
- ✅ Automatic rollback on failure

**Disadvantages**-:
- ❌ Mixed versions during rollout
- ❌ Slower than blue-green
- ❌ Potential compatibility issues

---

#### 6.4.5 Feature Flags

**Description**: Control feature availability without code deployment.

**Use Cases**:
- Gradual feature rollouts
- A/B testing
- Emergency feature disable
- Regional feature availability

**Implementation**:

1. **Feature Flag Service** (Azure App Configuration or custom service)
   - Centralized feature flag management
   - Real-time flag updates
   - User segmentation
   - Percentage-based rollouts

2. **Integration with Services**:
   ```java
   @FeatureFlag(name = "new-payment-flow", enabled = true)
   public PaymentResponse processPayment(PaymentRequest request) {
       // New implementation
   }
   ```

3. **Feature Flag Types**:
   - **Boolean flags**: Simple on/off
   - **Percentage flags**: Gradual rollout (10%, 25%, 50%, 100%)
   - **User-based flags**: Specific user groups
   - **Time-based flags**: Scheduled activation

4. **Feature Flag Management**:
   - Azure App Configuration for feature flags
   - Real-time updates without deployment
   - Audit trail of flag changes
   - Emergency kill switch

**Advantages**:
- ✅ Instant feature control
- ✅ A/B testing capability
- ✅ Reduced deployment risk
- ✅ Gradual rollouts

**Disadvantages**:
- ❌ Code complexity
- ❌ Technical debt if flags not cleaned up
- ❌ Requires feature flag infrastructure

---

#### 6.4.6 Database Migration Strategy

**Description**: Safe database schema and data migrations during deployments.

**Strategies**:

1. **Backward-Compatible Migrations**
   - Add new columns as nullable
   - Add new tables without breaking changes
   - Deploy application code that works with old and new schema
   - Migrate data in background
   - Remove old columns in separate deployment

2. **Blue-Green Database Migration**
   - Create new database version
   - Run migrations on new database
   - Deploy application with dual-write (write to both databases)
   - Sync data from old to new database
   - Switch reads to new database
   - Switch writes to new database
   - Decommission old database

3. **Liquibase/Flyway for Version Control**
   - Version-controlled database migrations
   - Automated migration execution
   - Rollback capability
   - Migration testing in CI/CD

---

#### 6.4.7 Frontend Deployment Strategy

**Description**: Deployment strategies for React microfrontends.

**Strategies**:

1. **Static Web Apps Deployment**
   - **External Frontend**: Azure Static Web Apps with CDN
   - Automatic deployment from Git
   - Preview deployments for PRs
   - Production deployments with approval

2. **Microfrontend Deployment**
   - Independent deployment of each microfrontend
   - Version pinning in shell application
   - Gradual rollout of microfrontend updates
   - Feature flags for microfrontend features

3. **Versioning Strategy**:
   - Semantic versioning (major.minor.patch)
   - Backward-compatible updates (minor/patch)
   - Breaking changes (major version)
   - Multiple versions running simultaneously

---

#### 6.4.8 Deployment Pipeline Integration

**GitLab CI/CD Pipeline with Deployment Strategies**:

1. **Development Environment**
   - Strategy: Rolling deployment
   - Approval: Automatic
   - Rollback: Automatic on failure

2. **Staging Environment**
   - Strategy: Blue-green deployment
   - Approval: Automatic after tests
   - Validation: Automated smoke tests
   - Rollback: Manual or automated on failure

3. **Production Environment**
   - Strategy: Canary deployment (default) or Blue-green (major releases)
   - Approval: Manual approval required
   - Phases:
     - Phase 1: Deploy to 5% canary
     - Phase 2: Monitor for 15 minutes
     - Phase 3: Increase to 25% if healthy
     - Phase 4: Increase to 50% if healthy
     - Phase 5: Increase to 100% if healthy
   - Rollback: Automatic on error threshold breach

**Deployment Automation**:
- Automated health checks
- Automated smoke tests
- Automated performance validation
- Automated rollback on failure
- Deployment notifications

---

#### 6.4.9 Monitoring and Validation

**Pre-Deployment Validation**:
- Unit tests
- Integration tests
- Security scans
- Performance tests
- Load tests

**Post-Deployment Validation**:
- Health checks
- Smoke tests
- Performance metrics
- Error rate monitoring
- Business metrics validation

**Monitoring During Deployment**:
- Real-time error rate
- Response time metrics
- Resource utilization
- Database performance
- Business metrics (orders, payments, etc.)

**Automated Rollback Triggers**:
- Error rate > 1% for 2 minutes
- Response time degradation > 50%
- Critical errors detected
- Database connection failures
- Business metrics degradation

---

#### 6.4.10 Deployment Best Practices

1. **Always Use Health Checks**
   - Liveness probes
   - Readiness probes
   - Startup probes for slow-starting apps

2. **Implement Gradual Rollouts**
   - Start with small percentage
   - Monitor metrics
   - Gradually increase traffic
   - Automatic rollback on issues

3. **Database Migrations**
   - Backward-compatible migrations
   - Test migrations in staging
   - Run migrations before application deployment
   - Have rollback plan

4. **Feature Flags**
   - Use for new features
   - Enable gradual rollout
   - Monitor feature usage
   - Clean up old flags

5. **Monitoring and Alerting**
   - Monitor during deployment
   - Set up alerts for critical metrics
   - Have rollback procedures ready
   - Document deployment runbooks

6. **Testing**
   - Test in staging environment
   - Load test before production
   - Validate database migrations
   - Test rollback procedures

---

#### 6.4.11 Deployment Tools

**Kubernetes Native**:
- `kubectl rollout` commands
- Deployment strategies (RollingUpdate, Recreate)
- Health checks and probes

**Service Mesh (Istio)**:
- Traffic splitting for canary deployments
- Circuit breakers
- Request routing and load balancing

**GitLab CI/CD**:
- Automated deployment pipelines
- Environment-specific configurations
- Manual approval gates
- Rollback automation

**Azure DevOps** (Alternative):
- Release pipelines
- Deployment groups
- Approval gates
- Automated testing

**ArgoCD** (GitOps):
- Git-based deployments
- Automated sync
- Rollback capabilities
- Multi-environment management

---

## 7. Scalability & Performance

### 7.1 Horizontal Scaling
- AKS cluster autoscaling
- Pod autoscaling (HPA) based on CPU/memory
- Database read replicas for read-heavy workloads

### 7.2 Caching
- Redis Cache for frequently accessed data
- CDN for static assets (Azure Front Door)

### 7.3 Performance Targets
- API response time: < 200ms (p95)
- Frontend load time: < 2s
- Database query time: < 100ms (p95)
- 99.9% uptime SLA

---

## 8. Disaster Recovery & Backup

### 8.1 Backup Strategy
- PostgreSQL: Automated daily backups, 35-day retention
- AKS: Configuration backup to Git
- Key Vault: Automated backup

### 8.2 Disaster Recovery
- Multi-region deployment (primary + secondary)
- Database geo-replication
- Failover procedures documented

---

## 9. Cost Optimization

### 9.1 Resource Sizing
- Right-sized AKS node pools
- Reserved instances for predictable workloads
- Spot instances for non-critical workloads

### 9.2 Monitoring
- Cost alerts and budgets
- Resource utilization monitoring
- Idle resource cleanup

---

## 10. Technology Stack Summary

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
| Infrastructure as Code | ARM Templates, Bicep, or Terraform |

---

## 11. Next Steps

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

