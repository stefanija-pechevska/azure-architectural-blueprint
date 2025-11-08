# HashiCorp Vault Configuration

This directory contains configuration files for HashiCorp Vault as an alternative to Azure Key Vault.

## Structure

```
hashicorp-vault/
├── kubernetes/
│   ├── vault-deployment.yaml      # Vault deployment on AKS
│   ├── vault-service.yaml         # Vault service
│   └── vault-configmap.yaml       # Vault configuration
├── policies/
│   ├── order-service-policy.hcl   # Policy for Order Service
│   └── product-service-policy.hcl # Policy for Product Service
└── README.md
```

## Deployment Options

### Option 1: Deploy on AKS

```bash
# Deploy Vault to AKS
kubectl apply -f kubernetes/vault-deployment.yaml
kubectl apply -f kubernetes/vault-service.yaml
kubectl apply -f kubernetes/vault-configmap.yaml

# Initialize Vault
kubectl exec -it vault-0 -- vault operator init

# Unseal Vault (repeat for each key)
kubectl exec -it vault-0 -- vault operator unseal <unseal-key>
```

### Option 2: Deploy on Azure VMs

```bash
# Create VM for Vault
az vm create \
  --resource-group rg-csom-platform-prod \
  --name vm-vault \
  --image UbuntuLTS \
  --size Standard_D2s_v3 \
  --admin-username vaultadmin

# Install Vault (via script or manual)
# Configure Vault
# Set up auto-unseal with Azure Key Vault
```

### Option 3: Use HashiCorp Cloud Platform (HCP)

- Managed Vault service
- No infrastructure management
- Pay-per-use pricing

## Configuration

### Enable Secrets Engines

```bash
# Enable KV secrets engine
vault secrets enable -path=secret kv-v2

# Enable Azure secrets engine
vault secrets enable azure

# Enable Database secrets engine for PostgreSQL
vault secrets enable database
```

### Configure Authentication

#### Kubernetes Authentication

```bash
# Enable Kubernetes auth
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
  token_reviewer_jwt="<service-account-token>" \
  kubernetes_host="https://aks-cluster:443" \
  kubernetes_ca_cert=@ca.crt
```

#### AppRole Authentication

```bash
# Enable AppRole
vault auth enable approle

# Create AppRole for Order Service
vault write auth/approle/role/order-service \
  token_policies="order-service-policy" \
  token_ttl=1h \
  token_max_ttl=4h
```

### Configure Policies

```bash
# Create policy for Order Service
vault policy write order-service-policy policies/order-service-policy.hcl

# Create policy for Product Service
vault policy write product-service-policy policies/product-service-policy.hcl
```

## Integration with Spring Boot

### Add Vault Dependencies

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-vault-config</artifactId>
</dependency>
```

### Configure application.yml

```yaml
spring:
  cloud:
    vault:
      uri: http://vault:8200
      authentication: KUBERNETES
      kubernetes:
        role: order-service
        service-account-token-file: /var/run/secrets/kubernetes.io/serviceaccount/token
      kv:
        enabled: true
        backend: secret
        default-context: order-service
```

## Dynamic Secrets

### PostgreSQL Dynamic Credentials

```bash
# Configure database connection
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  allowed_roles="order-service" \
  connection_url="postgresql://{{username}}:{{password}}@postgres:5432/ordersdb" \
  username="vault" \
  password="vault-password"

# Create role for dynamic credentials
vault write database/roles/order-service \
  db_name=postgresql \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" \
  default_ttl="1h" \
  max_ttl="24h"
```

## Vault Agent for Kubernetes

Use Vault Agent Sidecar Injector for automatic secret injection:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "order-service"
    vault.hashicorp.com/agent-inject-secret-db: "database/creds/order-service"
spec:
  # ... deployment spec
```

## Monitoring

### Enable Audit Logging

```bash
# Enable file audit device
vault audit enable file file_path=/var/log/vault_audit.log

# Enable syslog audit device
vault audit enable syslog tag="vault" facility="AUTH"
```

### Metrics

Vault exposes Prometheus metrics at `/v1/sys/metrics`.

## Security Best Practices

1. **Auto-Unseal**: Configure auto-unseal with Azure Key Vault
2. **Network Policies**: Restrict Vault access to authorized pods
3. **TLS**: Enable TLS for all Vault communication
4. **Policies**: Use least-privilege access policies
5. **Audit Logging**: Enable comprehensive audit logging
6. **Seal Protection**: Use auto-unseal to prevent manual unsealing

## Migration from Azure Key Vault

1. Export secrets from Azure Key Vault
2. Import to HashiCorp Vault
3. Update application configurations
4. Configure authentication methods
5. Update CI/CD pipelines
6. Test and validate

## References

- [HashiCorp Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [Vault on Kubernetes](https://developer.hashicorp.com/vault/docs/platform/k8s)
- [Vault Agent Injector](https://developer.hashicorp.com/vault/docs/platform/k8s/injector)

