#!/bin/bash

#k8s-deployment-rollout-status.sh

sleep 60s

if [[ $(kubectl -n default rollout status deploy ${deploymentName} --timeout 5s --kubeconfig=$KUBECONFIG) != *"successfully rolled out"* ]]; 
then     
	echo "Deployment ${deploymentName} Rollout has Failed"
    kubectl -n default rollout undo deploy ${deploymentName} --kubeconfig=$KUBECONFIG
    exit 1;
else
	echo "Deployment ${deploymentName} Rollout is Success"
fi
