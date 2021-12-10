#!/bin/bash

if [ ! -e terraform.tfvars ] ; then
    echo "Could not find vars file: terraform.tfvars"
    exit 1
fi

if [ -z ${CLUSTER_NAME} ] ; then
    export CLUSTER_NAME=$(grep ^cluster_name terraform.tfvars|awk '{ print $3 }'|cut -d '"' -f2)
fi
set -x

while [ $(kubectl get svc --kubeconfig ${CLUSTER_NAME}.conf -n kommander kommander-traefik -o json| jq '.status.loadBalancer.ingress[].ip'|cut -d'"' -f2) == "pending" ] ; do
    echo "Waiting for Kommander Traefik svc loadbalancer ip"
    sleep 10
done
set +x
PUBLIC_IP=$(kubectl get svc --kubeconfig ${CLUSTER_NAME}.conf -n kommander kommander-traefik -o json| jq '.status.loadBalancer.ingress[].ip'|cut -d'"' -f2)
echo "URL: https://${PUBLIC_IP}/dkp/kommander/dashboard"
kubectl -n kommander get secret --kubeconfig ${CLUSTER_NAME}.conf dkp-credentials -o go-template='Username: {{.data.username|base64decode}}{{ "\n"}}Password: {{.data.password|base64decode}}{{ "\n"}}'