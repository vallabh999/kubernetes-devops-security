#!/bin/bash

# k8s-deployment.sh

# Print environment variables
echo "KUBECONFIG path: $KUBECONFIG"
echo "Image name: $imageName"
echo "Deployment name: $deploymentName"
echo "Container name: $containerName"

# Replace placeholder in YAML file
sed -i "s#replace#${imageName}#g" k8s_deployment_service.yaml

# Apply the deployment
kubectl -n app apply -f k8s_deployment_service.yaml --kubeconfig=$KUBECONFIG

# Print kubectl version and context for debugging
kubectl version --client
kubectl config current-context
