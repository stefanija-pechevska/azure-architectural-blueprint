#!/bin/bash

# Build all Docker images and push to ACR
# Usage: ./scripts/build-all.sh

ACR_NAME="acrcsomplatform"
VERSION=${1:-latest}

echo "Building all services..."

# Login to ACR
az acr login --name $ACR_NAME

# Build Order Service
echo "Building Order Service..."
cd backend/order-service
docker build -t $ACR_NAME.azurecr.io/order-service:$VERSION .
docker push $ACR_NAME.azurecr.io/order-service:$VERSION
cd ../..

# Build Product Service
echo "Building Product Service..."
# cd backend/product-service
# docker build -t $ACR_NAME.azurecr.io/product-service:$VERSION .
# docker push $ACR_NAME.azurecr.io/product-service:$VERSION
# cd ../..

# Build Customer Service
echo "Building Customer Service..."
# cd backend/customer-service
# docker build -t $ACR_NAME.azurecr.io/customer-service:$VERSION .
# docker push $ACR_NAME.azurecr.io/customer-service:$VERSION
# cd ../..

echo "Build complete!"

