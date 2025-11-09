# Helm Charts

This directory contains Helm charts for deploying microservices to Azure Kubernetes Service (AKS).

## Structure

```
helm/
├── order-service/          # Order Service Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-dev.yaml
│   ├── values-staging.yaml
│   ├── values-prod.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── configmap.yaml
│       ├── serviceaccount.yaml
│       ├── hpa.yaml
│       ├── pdb.yaml
│       └── ingress.yaml
├── product-service/        # Product Service Helm chart (same structure)
├── customer-service/       # Customer Service Helm chart (same structure)
├── payment-service/        # Payment Service Helm chart (same structure)
├── notification-service/  # Notification Service Helm chart (same structure)
└── audit-service/          # Audit Service Helm chart (same structure)
```

## Quick Start

### Prerequisites

1. **Helm CLI** (v3.x):
   ```bash
   brew install helm  # macOS
   # or
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

2. **kubectl** configured for AKS:
   ```bash
   az aks get-credentials --resource-group rg-csom-platform-prod --name aks-csom-platform-prod
   ```

### Deploy a Service

```bash
# Navigate to service chart directory
cd infrastructure/helm/order-service

# Deploy to production
helm upgrade --install order-service . \
  --namespace production \
  --values values-prod.yaml \
  --set image.tag=v1.0.0 \
  --wait \
  --timeout 5m
```

### Deploy All Services

```bash
# Deploy all services to production
for service in order-service product-service customer-service payment-service notification-service audit-service; do
  helm upgrade --install $service ./$service \
    --namespace production \
    --values ./$service/values-prod.yaml \
    --wait \
    --timeout 5m
done
```

## Chart Structure

All service charts follow the same structure:

- **Chart.yaml**: Chart metadata and version
- **values.yaml**: Default configuration values
- **values-{env}.yaml**: Environment-specific overrides
- **templates/**: Kubernetes manifest templates

## Environment-Specific Values

Each service has three environment-specific values files:

- **values-dev.yaml**: Development environment (1 replica, minimal resources)
- **values-staging.yaml**: Staging environment (2 replicas, moderate resources)
- **values-prod.yaml**: Production environment (5+ replicas, full resources, HPA enabled)

## Customization

### Override Values

```bash
# Override specific values
helm upgrade --install order-service . \
  --namespace production \
  --values values-prod.yaml \
  --set replicaCount=10 \
  --set image.tag=v1.2.3
```

### Create Custom Values File

```bash
# Create custom values file
cat > my-custom-values.yaml <<EOF
replicaCount: 5
image:
  tag: "custom-tag"
resources:
  limits:
    cpu: 2000m
    memory: 2Gi
EOF

# Deploy with custom values
helm upgrade --install order-service . \
  --namespace production \
  --values values-prod.yaml \
  --values my-custom-values.yaml
```

## Common Operations

### List Releases

```bash
helm list -n production
```

### View Release Values

```bash
helm get values order-service -n production
```

### Upgrade Release

```bash
helm upgrade order-service . \
  --namespace production \
  --values values-prod.yaml \
  --set image.tag=v1.3.0
```

### Rollback Release

```bash
# Rollback to previous version
helm rollback order-service -n production

# Rollback to specific revision
helm rollback order-service 3 -n production
```

### Uninstall Release

```bash
helm uninstall order-service -n production
```

## CI/CD Integration

Helm charts are designed to integrate with GitLab CI/CD pipelines. See [HELM_GUIDE.md](../../HELM_GUIDE.md) for detailed CI/CD examples.

## Documentation

For comprehensive Helm usage documentation, see:
- **[HELM_GUIDE.md](../../HELM_GUIDE.md)** - Complete Helm guide with examples and best practices

## Notes

- All charts use the same template structure for consistency
- Environment-specific values files should be customized per environment
- Secrets should be created separately and referenced in values files
- Use `--dry-run` flag to test deployments before applying

