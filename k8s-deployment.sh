#!/bin/bash

# k8s-deployment.sh

# Print environment variables
export KUBECONFIG=$KUBECONFIG
echo "KUBECONFIG path: $KUBECONFIG"
echo "Image name: $imageName"
echo "Deployment name: $deploymentName"
echo "Container name: $containerName"

kubectl auth can-i get deployments --as=system:serviceaccount:jenkins:jenkins-deployer --namespace=app
kubectl auth can-i create services --as=system:serviceaccount:jenkins:jenkins-deployer --namespace=app

# Replace placeholder in YAML file
sed -i "s#replace#${imageName}#g" k8s_deployment_service.yaml

# Apply the deployment
kubectl -n app apply -f k8s_deployment_service.yaml --kubeconfig=$KUBECONFIG

# Print kubectl version and context for debugging
kubectl version --client
kubectl config current-context
