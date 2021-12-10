#!/bin/bash

if [ ! -e terraform.tfvars ] ; then
    echo "Could not find vars file: terraform.tfvars"
    exit 1
fi

if [ -z ${CLUSTER_NAME} ] ; then
    export CLUSTER_NAME=$(grep ^cluster_name terraform.tfvars|awk '{ print $3 }'|cut -d '"' -f2)
fi
set -x

kubectl get svc --kubeconfig ${CLUSTER_NAME}.conf -n kommander kommander-traefik 2>&1 > /dev/null
while [ $? -ne 0 ] ; do
    echo "Waiting for Kommander Traefik svc"
    sleep 10
    kubectl get svc --kubeconfig ${CLUSTER_NAME}.conf -n kommander kommander-traefik > /dev/null
done

HTTP_PORT=$(kubectl get svc --kubeconfig ${CLUSTER_NAME}.conf -n kommander kommander-traefik -o json | jq '.spec.ports[]  | select(.name == "web").nodePort')
HTTPS_PORT=$(kubectl get svc --kubeconfig ${CLUSTER_NAME}.conf -n kommander kommander-traefik -o json | jq '.spec.ports[]  | select(.name == "websecure").nodePort')
MINIO_PORT=$(kubectl get svc --kubeconfig ${CLUSTER_NAME}.conf -n kommander kommander-traefik -o json | jq '.spec.ports[]  | select(.name == "velero-minio").nodePort')
ansible-playbook -i inventory -e HTTP_PORT=${HTTP_PORT} -e HTTPS_PORT=${HTTPS_PORT} -e MINIO_PORT=${MINIO_PORT} playbooks/metallb.yml