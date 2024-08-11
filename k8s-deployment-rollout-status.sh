#!/bin/bash

#k8s-deployment-rollout-status.sh

sleep 60s

export KUBECONFIG=$KUBECONFIG
echo "KUBECONFIG path: $KUBECONFIG"
echo "Image name: $imageName"
echo "Deployment name: $deploymentName"
echo "Container name: $containerName"

kubectl auth can-i get deployments --as=system:serviceaccount:jenkins:jenkins-deployer --namespace=app
kubectl auth can-i create services --as=system:serviceaccount:jenkins:jenkins-deployer --namespace=app

if [[ $(kubectl -n app rollout status deploy ${deploymentName} --timeout 5s --kubeconfig=$KUBECONFIG) != *"successfully rolled out"* ]]; 
then     
	echo "Deployment ${deploymentName} Rollout has Failed"
    kubectl -n app rollout undo deploy ${deploymentName} --kubeconfig=$KUBECONFIG
    exit 1;
else
	echo "Deployment ${deploymentName} Rollout is Success"
fi
