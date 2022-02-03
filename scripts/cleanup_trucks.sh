#!/bin/bash

if [ ! -e terraform.tfvars ] ; then
    echo "Could not find vars file: terraform.tfvars"
    exit 1
fi
set -x

if [ $1 == "eks" ] ; then
    export CLUSTER_NAME=$(grep ^cluster_name_eks terraform.tfvars|awk '{ print $3 }'|cut -d '"' -f2)
elif [ $1 == "aws" ] ; then
    export CLUSTER_NAME=$(grep ^cluster_name_aws terraform.tfvars|awk '{ print $3 }'|cut -d '"' -f2)
else
    echo "ERR: no cluster found"
    exit 1
fi

NAMESPACE="truck-demo"

for i in zookeeper cassandra kafka; do
    kubectl kudo uninstall --instance $i -n ${NAMESPACE} --kubeconfig ${CLUSTER_NAME}.conf
done

for i in $(kubectl get pvc -n ${NAMESPACE} --kubeconfig ${CLUSTER_NAME}.conf --no-headers|cut -d" " -f1); do
    kubectl delete pvc $i -n ${NAMESPACE} --kubeconfig ${CLUSTER_NAME}.conf
done
