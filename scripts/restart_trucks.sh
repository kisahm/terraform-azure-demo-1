#!/bin/bash
if [ ! -e terraform.tfvars ] ; then
    echo "Could not find vars file: terraform.tfvars"
    exit 1
fi

if [ -z ${CLUSTER_NAME} ] ; then
    export CLUSTER_NAME=$(grep ^cluster_name terraform.tfvars|awk '{ print $3 }'|cut -d '"' -f2)
fi
set -x
NAMESPACE="truck-demo"

for i in 1 2 3; do
    kubectl delete jobs truck-${i} -n truck-demo --kubeconfig ${CLUSTER_NAME}.conf
done

for i in 1 2 3; do
    kubectl apply -f https://raw.githubusercontent.com/mesosphere/dkp-demo/main/truck-data-generator-${i}.yaml -n truck-demo --kubeconfig ${CLUSTER_NAME}.conf
done