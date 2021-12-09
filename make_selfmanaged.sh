#!/bin/bash

if [ ! -e terraform.tfvars ] ; then
    echo "Could not find vars file: terraform.tfvars"
    exit 1
fi

set -x
if [ -z ${CLUSTER_NAME} ] ; then
    export CLUSTER_NAME=$(grep ^cluster_name terraform.tfvars|awk '{ print $3 }'|cut -d '"' -f2)
fi

dkp get kubeconfig -c ${CLUSTER_NAME} > ${CLUSTER_NAME}.conf

dkp create bootstrap controllers --kubeconfig ${CLUSTER_NAME}.conf
dkp move --to-kubeconfig ${CLUSTER_NAME}.conf
kubectl --kubeconfig ${CLUSTER_NAME}.conf wait --for=condition=ControlPlaneReady "clusters/${CLUSTER_NAME}" --timeout=20m
dkp describe cluster --kubeconfig ${CLUSTER_NAME}.conf -c ${CLUSTER_NAME}

dkp delete bootstrap
