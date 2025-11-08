#!/bin/bash

# Blue-Green Deployment Script
# Usage: ./scripts/deploy-blue-green.sh [service-name] [namespace] [image-tag]

SERVICE_NAME=${1:-order-service}
NAMESPACE=${2:-production}
IMAGE_TAG=${3:-latest}

echo "Starting blue-green deployment for $SERVICE_NAME in namespace $NAMESPACE"
echo "Image tag: $IMAGE_TAG"

# Get current active version (blue or green)
CURRENT_VERSION=$(kubectl get service ${SERVICE_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.selector.version}')

if [ "$CURRENT_VERSION" == "blue" ]; then
  NEW_VERSION="green"
  OLD_VERSION="blue"
elif [ "$CURRENT_VERSION" == "green" ]; then
  NEW_VERSION="blue"
  OLD_VERSION="green"
else
  echo "Error: Current version is not blue or green"
  exit 1
fi

echo "Current active version: $CURRENT_VERSION"
echo "Deploying new version: $NEW_VERSION"

# Deploy new version (green)
echo "Deploying $NEW_VERSION version..."
kubectl set image deployment/${SERVICE_NAME}-${NEW_VERSION} \
  ${SERVICE_NAME}=acrcsomplatform.azurecr.io/${SERVICE_NAME}:${IMAGE_TAG} \
  -n ${NAMESPACE}

# Wait for new version to be ready
echo "Waiting for $NEW_VERSION deployment to be ready..."
kubectl rollout status deployment/${SERVICE_NAME}-${NEW_VERSION} -n ${NAMESPACE}

# Run smoke tests on new version
echo "Running smoke tests on $NEW_VERSION version..."
# Add your smoke test commands here
# Example: kubectl run smoke-test --image=curlimages/curl --rm -i --restart=Never -- curl http://${SERVICE_NAME}-${NEW_VERSION}:8080/actuator/health

# Monitor metrics for 15 minutes
echo "Monitoring $NEW_VERSION version for 15 minutes..."
sleep 900

# Switch traffic to new version
echo "Switching traffic to $NEW_VERSION version..."
kubectl patch service ${SERVICE_NAME} -n ${NAMESPACE} --type json -p="[
  {
    \"op\": \"replace\",
    \"path\": \"/spec/selector/version\",
    \"value\": \"${NEW_VERSION}\"
  }
]"

echo "Traffic switched to $NEW_VERSION version"
echo "Keeping $OLD_VERSION version running for quick rollback if needed"
echo "To rollback, run: kubectl patch service ${SERVICE_NAME} -n ${NAMESPACE} --type json -p='[{\"op\": \"replace\", \"path\": \"/spec/selector/version\", \"value\": \"${OLD_VERSION}\"}]'"

