#!/bin/bash

# Canary Deployment Script
# Usage: ./scripts/deploy-canary.sh [service-name] [namespace] [image-tag]

SERVICE_NAME=${1:-order-service}
NAMESPACE=${2:-production}
IMAGE_TAG=${3:-latest}
CANARY_PERCENTAGE=${4:-10}

echo "Starting canary deployment for $SERVICE_NAME in namespace $NAMESPACE"
echo "Image tag: $IMAGE_TAG"
echo "Initial canary percentage: $CANARY_PERCENTAGE%"

# Deploy canary version
echo "Deploying canary version..."
kubectl set image deployment/${SERVICE_NAME}-canary \
  ${SERVICE_NAME}=acrcsomplatform.azurecr.io/${SERVICE_NAME}:${IMAGE_TAG} \
  -n ${NAMESPACE}

# Wait for canary to be ready
echo "Waiting for canary deployment to be ready..."
kubectl rollout status deployment/${SERVICE_NAME}-canary -n ${NAMESPACE}

# Update Istio VirtualService to route traffic
echo "Updating traffic split: $((100 - CANARY_PERCENTAGE))% stable, ${CANARY_PERCENTAGE}% canary"

# Phase 1: 5% canary
echo "Phase 1: Routing 5% traffic to canary..."
kubectl patch virtualservice ${SERVICE_NAME} -n ${NAMESPACE} --type json -p='
[
  {
    "op": "replace",
    "path": "/spec/http/0/route/0/weight",
    "value": 95
  },
  {
    "op": "replace",
    "path": "/spec/http/0/route/1/weight",
    "value": 5
  }
]'

sleep 300  # Wait 5 minutes

# Phase 2: 25% canary
echo "Phase 2: Routing 25% traffic to canary..."
kubectl patch virtualservice ${SERVICE_NAME} -n ${NAMESPACE} --type json -p='
[
  {
    "op": "replace",
    "path": "/spec/http/0/route/0/weight",
    "value": 75
  },
  {
    "op": "replace",
    "path": "/spec/http/0/route/1/weight",
    "value": 25
  }
]'

sleep 600  # Wait 10 minutes

# Phase 3: 50% canary
echo "Phase 3: Routing 50% traffic to canary..."
kubectl patch virtualservice ${SERVICE_NAME} -n ${NAMESPACE} --type json -p='
[
  {
    "op": "replace",
    "path": "/spec/http/0/route/0/weight",
    "value": 50
  },
  {
    "op": "replace",
    "path": "/spec/http/0/route/1/weight",
    "value": 50
  }
]'

sleep 900  # Wait 15 minutes

# Phase 4: 100% canary (promote to stable)
echo "Phase 4: Promoting canary to stable (100% traffic)..."
kubectl set image deployment/${SERVICE_NAME} \
  ${SERVICE_NAME}=acrcsomplatform.azurecr.io/${SERVICE_NAME}:${IMAGE_TAG} \
  -n ${NAMESPACE}

kubectl patch virtualservice ${SERVICE_NAME} -n ${NAMESPACE} --type json -p='
[
  {
    "op": "replace",
    "path": "/spec/http/0/route/0/weight",
    "value": 100
  },
  {
    "op": "remove",
    "path": "/spec/http/0/route/1"
  }
]'

echo "Canary deployment completed successfully!"

