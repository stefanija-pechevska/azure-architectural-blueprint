#!/bin/bash

# Deploy all services to AKS
# Usage: ./scripts/deploy-all.sh [namespace]

NAMESPACE=${1:-production}
ACR_NAME="acrcsomplatform"

echo "Deploying all services to namespace: $NAMESPACE"

# Get AKS credentials
az aks get-credentials --resource-group rg-csom-platform-prod --name aks-csom-platform-prod

# Deploy Order Service
echo "Deploying Order Service..."
kubectl apply -f infrastructure/kubernetes/order-service/ -n $NAMESPACE

# Deploy Product Service
echo "Deploying Product Service..."
# kubectl apply -f infrastructure/kubernetes/product-service/ -n $NAMESPACE

# Deploy Customer Service
echo "Deploying Customer Service..."
# kubectl apply -f infrastructure/kubernetes/customer-service/ -n $NAMESPACE

# Deploy Payment Service
echo "Deploying Payment Service..."
# kubectl apply -f infrastructure/kubernetes/payment-service/ -n $NAMESPACE

# Deploy Notification Service
echo "Deploying Notification Service..."
# kubectl apply -f infrastructure/kubernetes/notification-service/ -n $NAMESPACE

# Deploy Audit Service
echo "Deploying Audit Service..."
# kubectl apply -f infrastructure/kubernetes/audit-service/ -n $NAMESPACE

echo "Deployment complete. Checking status..."
kubectl get pods -n $NAMESPACE

