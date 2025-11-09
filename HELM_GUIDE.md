# Helm Guide
## Kubernetes Package Management for Microservices

This guide explains how to use Helm for deploying and managing microservices in the Azure Kubernetes Service (AKS) cluster.

---

## Table of Contents

1. [What is Helm?](#1-what-is-helm)
2. [Why Use Helm?](#2-why-use-helm)
3. [Helm Chart Structure](#3-helm-chart-structure)
4. [Available Helm Charts](#4-available-helm-charts)
5. [Installation and Setup](#5-installation-and-setup)
6. [Deploying Services](#6-deploying-services)
7. [Environment-Specific Deployments](#7-environment-specific-deployments)
8. [Upgrading and Rolling Back](#8-upgrading-and-rolling-back)
9. [CI/CD Integration](#9-cicd-integration)
10. [Best Practices](#10-best-practices)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. What is Helm?

**Helm** is the package manager for Kubernetes. It simplifies the deployment and management of Kubernetes applications by:

- **Packaging**: Bundling Kubernetes manifests into reusable charts
- **Templating**: Using Go templates to parameterize configurations
- **Versioning**: Managing different versions of application deployments
- **Dependencies**: Managing chart dependencies
- **Release Management**: Tracking and managing deployed releases

### Key Concepts

- **Chart**: A package of pre-configured Kubernetes resources (deployments, services, configmaps, etc.)
- **Release**: An instance of a chart deployed to a Kubernetes cluster
- **Repository**: A collection of charts that can be shared and versioned
- **Values**: Configuration parameters that customize chart deployments

---

## 2. Why Use Helm?

### Benefits for This Architecture

1. **Consistency**: Standardized deployment structure across all microservices
2. **Environment Management**: Easy switching between dev, staging, and production configurations
3. **Version Control**: Track and rollback to previous versions
4. **Reusability**: Share common configurations across services
5. **CI/CD Integration**: Seamless integration with GitLab CI/CD pipelines
6. **Complex Deployments**: Manage multi-resource deployments (deployments, services, HPA, PDB, ingress) as a single unit

### Current Usage

- **Third-party Components**: NGINX Ingress Controller, Secrets Store CSI Driver
- **Microservices**: Order Service, Product Service, Customer Service, Payment Service, Notification Service, Audit Service

---

## 3. Helm Chart Structure

Each microservice has its own Helm chart with the following structure:

```
order-service/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default values
├── values-dev.yaml         # Development environment values
├── values-staging.yaml     # Staging environment values
├── values-prod.yaml        # Production environment values
└── templates/
    ├── _helpers.tpl        # Template helpers
    ├── deployment.yaml     # Kubernetes Deployment
    ├── service.yaml        # Kubernetes Service
    ├── configmap.yaml      # ConfigMap for configuration
    ├── serviceaccount.yaml # ServiceAccount
    ├── hpa.yaml            # HorizontalPodAutoscaler
    ├── pdb.yaml            # PodDisruptionBudget
    └── ingress.yaml        # Ingress (optional)
```

### Key Files Explained

#### Chart.yaml
Defines chart metadata:
```yaml
apiVersion: v2
name: order-service
description: A Helm chart for Order Service microservice
type: application
version: 1.0.0
appVersion: "1.0.0"
```

#### values.yaml
Default configuration values:
```yaml
replicaCount: 3
image:
  repository: acrcsomplatform.azurecr.io/order-service
  tag: "latest"
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
```

#### templates/
Kubernetes manifest templates with Go templating:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "order-service.fullname" . }}
spec:
  replicas: {{ .Values.replicaCount }}
```

---

## 4. Available Helm Charts

The following Helm charts are available in `infrastructure/helm/`:

1. **order-service**: Order management microservice
2. **product-service**: Product catalog microservice
3. **customer-service**: Customer management microservice
4. **payment-service**: Payment processing microservice
5. **notification-service**: Notification microservice
6. **audit-service**: Audit logging microservice

Each chart follows the same structure and can be customized via values files.

---

## 5. Installation and Setup

### Prerequisites

1. **Helm CLI** (v3.x):
   ```bash
   # macOS
   brew install helm
   
   # Linux
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   
   # Verify installation
   helm version
   ```

2. **kubectl** configured to access your AKS cluster:
   ```bash
   az aks get-credentials --resource-group rg-csom-platform-prod --name aks-csom-platform-prod
   ```

3. **Azure Container Registry (ACR)** access configured:
   ```bash
   az acr login --name acrcsomplatform
   ```

### Setup Namespaces

```bash
# Create namespaces for different environments
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace production
```

---

## 6. Deploying Services

### Basic Deployment

Deploy a service using default values:

```bash
# Navigate to the chart directory
cd infrastructure/helm/order-service

# Install the chart
helm install order-service . \
  --namespace production \
  --create-namespace
```

### Deployment with Custom Values

```bash
# Deploy with custom values file
helm install order-service . \
  --namespace production \
  --values values-prod.yaml \
  --set image.tag=v1.2.3
```

### Verify Deployment

```bash
# Check release status
helm list -n production

# Check pods
kubectl get pods -n production -l app.kubernetes.io/name=order-service

# Check services
kubectl get svc -n production -l app.kubernetes.io/name=order-service

# View release details
helm get values order-service -n production
```

---

## 7. Environment-Specific Deployments

### Development Environment

```bash
helm install order-service . \
  --namespace dev \
  --values values-dev.yaml \
  --set env.postgresHost=postgres-dev.example.com \
  --set env.keyVaultName=kv-csom-platform-dev
```

### Staging Environment

```bash
helm install order-service . \
  --namespace staging \
  --values values-staging.yaml \
  --set env.postgresHost=postgres-staging.example.com \
  --set env.keyVaultName=kv-csom-platform-staging
```

### Production Environment

```bash
helm install order-service . \
  --namespace production \
  --values values-prod.yaml \
  --set env.postgresHost=postgres-prod.example.com \
  --set env.keyVaultName=kv-csom-platform-prod \
  --set image.tag=v1.2.3
```

### Using Secrets

Secrets should be created separately and referenced in values:

```bash
# Create secret
kubectl create secret generic postgres-secrets \
  --from-literal=username=admin \
  --from-literal=password=secure-password \
  -n production

# Deploy with secret reference
helm install order-service . \
  --namespace production \
  --values values-prod.yaml \
  --set secrets.postgresSecret=postgres-secrets
```

---

## 8. Upgrading and Rolling Back

### Upgrade a Release

```bash
# Upgrade to new version
helm upgrade order-service . \
  --namespace production \
  --values values-prod.yaml \
  --set image.tag=v1.3.0

# Check upgrade status
helm status order-service -n production
```

### Rollback to Previous Version

```bash
# List release history
helm history order-service -n production

# Rollback to previous version
helm rollback order-service -n production

# Rollback to specific revision
helm rollback order-service 3 -n production
```

### Dry Run

Test changes before applying:

```bash
helm upgrade order-service . \
  --namespace production \
  --values values-prod.yaml \
  --set image.tag=v1.3.0 \
  --dry-run \
  --debug
```

---

## 9. CI/CD Integration

### GitLab CI/CD Pipeline Integration

Helm is fully integrated into the GitLab CI/CD pipeline. See `.gitlab-ci.yml` for the complete implementation.

**Key Features**:
- **Helm Chart Validation**: Validates Helm charts before deployment
- **Environment-Specific Deployments**: Uses different values files for dev, staging, and production
- **Automatic Namespace Creation**: Creates namespaces if they don't exist
- **Image Tag Management**: Uses commit SHA or Git tags for image versions
- **Manual Approval**: Production deployments require manual approval

**Pipeline Stages**:
1. **validate-helm**: Validates Helm charts using `helm lint` and `helm template`
2. **deploy-dev**: Deploys to dev environment using `values-dev.yaml`
3. **deploy-staging**: Deploys to staging environment using `values-staging.yaml`
4. **deploy-production**: Deploys to production using `values-prod.yaml` (manual approval)

**Example Deployment Job** (from `.gitlab-ci.yml`):

```yaml
deploy-production:
  stage: deploy-production
  image: alpine/helm:latest
  before_script:
    - apk add --no-cache curl azure-cli kubectl
    - az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
    - az aks get-credentials --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME
    - kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
  script:
    - cd infrastructure/helm/$SERVICE_NAME
    - |
      IMAGE_TAG=${CI_COMMIT_TAG:-$CI_COMMIT_SHORT_SHA}
      helm upgrade --install $SERVICE_NAME . \
        --namespace production \
        --values values-prod.yaml \
        --set image.repository=$ACR_NAME.azurecr.io/$SERVICE_NAME \
        --set image.tag=$IMAGE_TAG \
        --wait \
        --timeout 10m
  when: manual
  only:
    - main
    - tags
```

**To Deploy a Different Service**:
- Set the `SERVICE_NAME` CI/CD variable in GitLab (e.g., `product-service`, `customer-service`)
- Or override it in the job definition

### Automated Deployment Workflow

1. **Build**: Docker image is built and pushed to ACR
2. **Test**: Helm chart is validated (`helm lint`)
3. **Deploy**: Helm upgrade is executed
4. **Verify**: Health checks confirm successful deployment

---

## 10. Best Practices

### 1. Version Management

- Use semantic versioning for chart versions
- Tag Docker images with version numbers
- Keep chart version and app version in sync

### 2. Values Organization

- Use separate values files for each environment
- Keep sensitive data in Kubernetes Secrets, not values files
- Use `--set` for one-off overrides

### 3. Resource Limits

- Always set resource requests and limits
- Use HPA for automatic scaling
- Monitor resource usage and adjust accordingly

### 4. Health Checks

- Configure liveness, readiness, and startup probes
- Use appropriate delays and timeouts
- Test health endpoints before deployment

### 5. Security

- Use ServiceAccounts with minimal permissions
- Enable Pod Security Policies
- Scan images for vulnerabilities
- Use Secrets Store CSI Driver for secrets

### 6. Testing

- Use `helm lint` to validate charts
- Use `helm template` to render manifests
- Test in dev/staging before production
- Use `--dry-run` before actual deployments

### 7. Documentation

- Document all configurable values
- Include examples in values files
- Maintain changelog for chart versions

---

## 11. Troubleshooting

### Common Issues

#### 1. Chart Installation Fails

```bash
# Check chart syntax
helm lint infrastructure/helm/order-service

# Validate templates
helm template order-service infrastructure/helm/order-service --debug

# Check Kubernetes cluster connectivity
kubectl cluster-info
```

#### 2. Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n production

# Check logs
kubectl logs <pod-name> -n production

# Check events
kubectl get events -n production --sort-by='.lastTimestamp'
```

#### 3. Image Pull Errors

```bash
# Verify ACR access
az acr login --name acrcsomplatform

# Check image exists
az acr repository show-tags --name acrcsomplatform --repository order-service

# Verify image pull secrets
kubectl get secret -n production
```

#### 4. Configuration Issues

```bash
# View current values
helm get values order-service -n production

# Compare with expected values
helm get values order-service -n production > current-values.yaml
diff current-values.yaml values-prod.yaml
```

#### 5. Rollback Issues

```bash
# Check release history
helm history order-service -n production

# View previous revision
helm get values order-service -n production --revision 2

# Force rollback
helm rollback order-service -n production --force
```

### Debug Commands

```bash
# Render templates locally
helm template order-service infrastructure/helm/order-service \
  --values values-prod.yaml \
  --debug

# Validate against cluster
helm install order-service infrastructure/helm/order-service \
  --namespace production \
  --values values-prod.yaml \
  --dry-run \
  --debug

# Check resource status
kubectl get all -n production -l app.kubernetes.io/name=order-service
```

---

## Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Azure Kubernetes Service](https://docs.microsoft.com/azure/aks/)

---

## Summary

Helm simplifies Kubernetes deployments by:

- **Standardizing** microservice deployments
- **Enabling** environment-specific configurations
- **Facilitating** version management and rollbacks
- **Integrating** with CI/CD pipelines
- **Reducing** deployment complexity

Use Helm charts for all microservices to ensure consistency, maintainability, and ease of deployment across environments.

