#!/bin/bash

if [ ! -e terraform.tfvars ] ; then
    echo "Could not find vars file: terraform.tfvars"
    exit 1
fi

if [ -z ${CLUSTER_NAME} ] ; then
    export CLUSTER_NAME=$(grep ^cluster_name terraform.tfvars|awk '{ print $3 }'|cut -d '"' -f2)
fi
set -x

kubectl create secret generic my-license-secret --from-file=jwt=./license.lic -n kommander --kubeconfig ${CLUSTER_NAME}.conf
kubectl label secret my-license-secret kommanderType=license -n kommander --kubeconfig ${CLUSTER_NAME}.conf
kubectl apply --kubeconfig ${CLUSTER_NAME}.conf -f templates/license.yml