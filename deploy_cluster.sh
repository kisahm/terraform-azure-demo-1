#!/bin/bash

set -x
dkp create bootstrap

export CLUSTER_NAME=democluster
kubectl create secret generic ${CLUSTER_NAME}-ssh-key --from-file=ssh-privatekey=${HOME}/.ssh/id_rsa
kubectl label secret ${CLUSTER_NAME}-ssh-key clusterctl.cluster.x-k8s.io/move=

./create_ansible_inventory.sh
ansible-playbook -i ./inventory -e sshSecretName="${CLUSTER_NAME}-ssh-key" -e sshUsername="$(grep ^admin_username terraform.tfvars|awk '{ print $3 }')" -e clusterName="${CLUSTER_NAME}" playbook-generate-inventory.yml || exit 1
kubectl apply -f PreprovisionedInventory.yml

if [ $(grep ^master_node_count terraform.tfvars |awk '{ print $3 }') -gt 1 ] ; then
    CONTROLPLANE_ENDPOINT=$(terraform output -json lb_public_ip|jq '.'|egrep -v "(\[|\])"|cut -d'"' -f2)
else
    CONTROLPLANE_ENDPOINT="$(terraform output -json master_node_ips|jq '.'|egrep -v "(\[|\])"|cut -d'"' -f2) --control-plane-replicas 1"
fi
export EXTRAVARS=""
grep offer main.tf |grep -v "#"|grep flatcar > /dev/null
if [ $? -eq 0 ] ; then
    EXTRAVARS="$EXTRAVARS --os-hint flatcar"
fi

dkp create cluster preprovisioned --cluster-name ${CLUSTER_NAME} --control-plane-endpoint-host ${CONTROLPLANE_ENDPOINT} --worker-replicas $(grep ^worker_node_count terraform.tfvars|awk '{ print $3 }') --control-plane-endpoint-port 6443 ${EXTRAVARS} --dry-run -o yaml > cluster.yml
kubectl apply -f cluster.yml

kubectl get kubeadmcontrolplane,cluster,preprovisionedcluster,preprovisionedmachinetemplate,clusterresourceset,machinedeployment,preprovisionedmachinetemplate,kubeadmconfigtemplate