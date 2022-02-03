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

kubectl kudo init  --kubeconfig ${CLUSTER_NAME}.conf --wait
kubectl kudo install zookeeper --instance zookeeper -n ${NAMESPACE} --kubeconfig ${CLUSTER_NAME}.conf
kubectl kudo install cassandra --instance cassandra -n ${NAMESPACE} --kubeconfig ${CLUSTER_NAME}.conf
kubectl kudo install kafka --instance kafka -n ${NAMESPACE} --kubeconfig ${CLUSTER_NAME}.conf -p ZOOKEEPER_URI="zookeeper-zookeeper-0.zookeeper-hs:2181,zookeeper-zookeeper-1.zookeeper-hs:2181,zookeeper-zookeeper-2.zookeeper-hs:2181"