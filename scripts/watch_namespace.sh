#!/bin/bash

if [ ! -e terraform.tfvars ] ; then
    echo "Could not find vars file: terraform.tfvars"
    exit 1
fi

if [ -z ${CLUSTER_NAME} ] ; then
    export CLUSTER_NAME=$(grep ^cluster_name terraform.tfvars|awk '{ print $3 }'|cut -d '"' -f2)
fi

watch kubectl get po,svc -n $1 --kubeconfig $(grep ^cluster_name terraform.tfvars|awk '{ print $3 }'|cut -d '"' -f2).conf

