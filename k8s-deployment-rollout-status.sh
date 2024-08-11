#!/bin/bash

#k8s-deployment-rollout-status.sh

sleep 60s
echo $KUBECONFIG

if [[ $(kubectl -n app rollout status deploy ${deploymentName} --timeout 5s --kubeconfig=$KUBECONFIG) != *"successfully rolled out"* ]]; 
then     
	echo "Deployment ${deploymentName} Rollout has Failed"
    kubectl -n app rollout undo deploy ${deploymentName} --kubeconfig=$KUBECONFIG
    exit 1;
else
	echo "Deployment ${deploymentName} Rollout is Success"
fi
