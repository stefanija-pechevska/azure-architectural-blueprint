# Glossary

This document defines technical terms, acronyms, and Azure service names used throughout the architecture template documentation.

## Table of Contents

- [Azure Services](#azure-services)
- [Architecture Terms](#architecture-terms)
- [Technology Terms](#technology-terms)
- [Acronyms](#acronyms)
- [Deployment Terms](#deployment-terms)
- [Security Terms](#security-terms)

---

## Azure Services

### AKS (Azure Kubernetes Service)
Azure-managed Kubernetes container orchestration service. Used to deploy and manage containerized microservices.

### ACR (Azure Container Registry)
Azure-managed private Docker container registry. Used to store and manage container images.

### Application Insights
Azure monitoring service for application performance monitoring (APM). Provides insights into application performance, availability, and usage.

### Azure API Management
Azure service for API gateway, management, and governance. Provides API versioning, rate limiting, security policies, and analytics.

### Azure Blob Storage
Azure object storage service for unstructured data. Used for file archiving, backups, and long-term storage.

### Azure Database for PostgreSQL
Azure-managed PostgreSQL database service. Provides high availability, automated backups, and scaling capabilities.

### Azure Event Grid
Azure event routing service. Used for event-driven architecture and serverless event processing.

### Azure Functions
Azure serverless compute service. Used for event-driven workloads, housekeeping jobs, and microservices.

### Azure Key Vault
Azure service for secrets management. Stores and manages secrets, keys, certificates, and connection strings.

### Azure Redis Cache
Azure-managed Redis caching service. Used for in-memory caching to improve application performance.

### Azure Service Bus
Azure messaging service for asynchronous communication. Supports queues, topics, and subscriptions for pub/sub messaging.

### Azure Static Web Apps
Azure service for hosting static web applications. Supports serverless APIs and automatic deployments from Git.

### Entra ID (Azure Active Directory)
Microsoft's cloud-based identity and access management service. Used for authentication and authorization.

### Entra External ID (Azure AD B2C)
Microsoft's customer identity and access management service. Used for external user authentication (B2C scenarios).

### Log Analytics
Azure service for collecting and analyzing log data. Part of Azure Monitor for centralized logging.

---

## Architecture Terms

### API Gateway
A service that acts as a single entry point for API requests. Provides routing, security, rate limiting, and monitoring.

### Circuit Breaker
A design pattern that prevents cascading failures by stopping requests to a failing service and providing fallback responses.

### Container
A lightweight, portable unit that packages an application and its dependencies. Used for consistent deployments.

### Microfrontend
An architectural pattern where a frontend application is composed of independently deployable frontend modules.

### Microservices
An architectural approach where an application is built as a collection of loosely coupled, independently deployable services.

### Service Mesh
An infrastructure layer that handles service-to-service communication. Provides service discovery, load balancing, security, and observability.

### Sidecar
A container that runs alongside the main application container in the same pod. Used for cross-cutting concerns like logging and monitoring.

---

## Technology Terms

### Helm
A Kubernetes package manager. Used to define, install, and upgrade Kubernetes applications.

### Istio
An open-source service mesh for Kubernetes. Provides traffic management, security, and observability.

### JWT (JSON Web Token)
A compact, URL-safe token format for securely transmitting information between parties. Used for authentication and authorization.

### Kubernetes
An open-source container orchestration platform. Automates deployment, scaling, and management of containerized applications.

### Module Federation
A webpack feature that allows JavaScript applications to share code at runtime. Used for microfrontend architecture.

### OpenAPI
A specification for defining RESTful APIs. Used for API documentation and code generation.

### Pod
The smallest deployable unit in Kubernetes. Contains one or more containers that share storage and network resources.

### RBAC (Role-Based Access Control)
An access control mechanism based on roles. Users are assigned roles with specific permissions.

### REST (Representational State Transfer)
An architectural style for designing web services. Uses HTTP methods (GET, POST, PUT, DELETE) for operations.

### SOAP (Simple Object Access Protocol)
A protocol for exchanging structured information in web services. Used for legacy system integration.

### Webpack
A JavaScript module bundler. Used to bundle frontend assets and enable Module Federation.

---

## Acronyms

### ADR
Architecture Decision Record. A document that captures an architectural decision, its context, and consequences.

### APM
Application Performance Monitoring. Monitoring and managing application performance and availability.

### B2C
Business-to-Consumer. A scenario where businesses provide services directly to consumers.

### CI/CD
Continuous Integration / Continuous Deployment. Automated processes for building, testing, and deploying software.

### CORS
Cross-Origin Resource Sharing. A mechanism that allows web pages to make requests to a different domain.

### DNS
Domain Name System. A system that translates domain names to IP addresses.

### E2E
End-to-End. Testing that validates the entire application flow from start to finish.

### GDPR
General Data Protection Regulation. European Union regulation for data protection and privacy.

### HPA
Horizontal Pod Autoscaler. Kubernetes feature that automatically scales pods based on metrics.

### IaC
Infrastructure as Code. Managing infrastructure using code and version control.

### JWT
JSON Web Token. A token format for authentication and authorization.

### MFE
Microfrontend. An independently deployable frontend module.

### mTLS
Mutual TLS. A security protocol where both client and server authenticate each other using certificates.

### OAuth
Open Authorization. An authorization framework for delegated access to resources.

### PDB
Pod Disruption Budget. Kubernetes feature that limits the number of pods that can be disrupted during maintenance.

### RBAC
Role-Based Access Control. Access control based on user roles.

### REST
Representational State Transfer. An architectural style for web services.

### SLA
Service Level Agreement. A commitment to service quality and availability.

### SOAP
Simple Object Access Protocol. A protocol for web services.

### SSE
Server-Sent Events. A technology for server-to-client push notifications over HTTP.

### TLS
Transport Layer Security. A cryptographic protocol for secure communication.

### VPC
Virtual Private Cloud. A logically isolated section of a cloud provider's network.

### WebSocket
A communication protocol that provides full-duplex communication over a single TCP connection.

---

## Deployment Terms

### Blue-Green Deployment
A deployment strategy where two identical production environments (blue and green) are maintained. Traffic is switched from one to the other.

### Canary Deployment
A deployment strategy where a new version is deployed to a small subset of users first, then gradually rolled out to all users.

### GitOps
A deployment model where Git is the single source of truth for infrastructure and application configuration.

### Helm Chart
A collection of Kubernetes manifests packaged together. Used for deploying applications to Kubernetes.

### Infrastructure as Code (IaC)
Managing infrastructure using code and version control. Tools include Terraform, Bicep, and ARM templates.

### Rolling Deployment
A deployment strategy where new versions are gradually rolled out, replacing old versions incrementally.

### Service Principal
An identity created for applications, services, and automation tools to access Azure resources.

### Managed Identity
An Azure feature that provides Azure services with an automatically managed identity in Azure AD.

### Publish Profile
An XML file containing deployment credentials for Azure App Service, Functions, or Static Web Apps.

---

## Security Terms

### Authentication
The process of verifying the identity of a user or service.

### Authorization
The process of determining what actions a user or service is allowed to perform.

### Certificate
A digital document that verifies the identity of a party and contains a public key.

### Encryption
The process of converting data into a format that cannot be read without a decryption key.

### Key Vault
A secure storage service for secrets, keys, certificates, and connection strings.

### mTLS (Mutual TLS)
A security protocol where both client and server authenticate each other using certificates.

### OAuth
An authorization framework for delegated access to resources.

### RBAC (Role-Based Access Control)
An access control mechanism based on roles and permissions.

### Secrets
Sensitive information such as passwords, API keys, and connection strings that must be protected.

### TLS (Transport Layer Security)
A cryptographic protocol for secure communication over a network.

---

## Compliance Terms

### GDPR
General Data Protection Regulation. European Union regulation for data protection and privacy.

### Data Minimization
The principle of collecting and processing only the minimum amount of data necessary for a purpose.

### Right to Access
The GDPR right for individuals to access their personal data.

### Right to Erasure
The GDPR right for individuals to have their personal data deleted.

### Right to Rectification
The GDPR right for individuals to have their personal data corrected.

### Consent Management
The process of obtaining, managing, and tracking user consent for data processing.

### Privacy by Design
The principle of building privacy and data protection into systems from the start.

---

## Monitoring Terms

### Application Insights
Azure service for application performance monitoring and diagnostics.

### Distributed Tracing
A method of tracking requests across multiple services in a distributed system.

### Log Analytics
Azure service for collecting and analyzing log data from multiple sources.

### Metrics
Quantitative measurements of system performance and behavior.

### Observability
The ability to understand the internal state of a system based on its external outputs.

### Telemetry
Data collected about the performance and usage of an application.

---

## Additional Resources

For more information about Azure services and technologies, see:
- [Azure Documentation](https://docs.microsoft.com/azure/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Istio Documentation](https://istio.io/docs/)

---

**Last Updated**: November 9, 2025

