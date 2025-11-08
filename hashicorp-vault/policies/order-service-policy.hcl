# Policy for Order Service
# Allows read access to order-service secrets

path "secret/data/order-service/*" {
  capabilities = ["read", "list"]
}

# Allow access to dynamic database credentials
path "database/creds/order-service" {
  capabilities = ["read"]
}

# Allow access to Service Bus connection string
path "secret/data/service-bus" {
  capabilities = ["read"]
}

# Allow access to PostgreSQL connection details
path "secret/data/postgresql" {
  capabilities = ["read"]
}

# Deny access to other services' secrets
path "secret/data/*" {
  capabilities = ["deny"]
}

