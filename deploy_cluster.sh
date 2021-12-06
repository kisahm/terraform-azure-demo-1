#!/bin/bash

set -x

export CLUSTER_NAME=democluster
kubectl create secret generic ${CLUSTER_NAME}-ssh-key --from-file=ssh-privatekey=${HOME}/.ssh/id_rsa
kubectl label secret ${CLUSTER_NAME}-ssh-key clusterctl.cluster.x-k8s.io/move=

./create_ansible_inventory.sh
ansible-playbook -i ./inventory -e sshSecretName="${CLUSTER_NAME}-ssh-key" -e sshUsername="$(grep ^admin_username terraform.tfvars|awk '{ print $3 }')" -e clusterName="${CLUSTER_NAME}" playbook-generate-inventory.yml
kubectl apply -f PreprovisionedInventory.yml

if [ $(grep ^master_node_count terraform.tfvars |awk '{ print $3 }') -gt 1 ] ; then
    CONTROLPLANE_ENDPOINT=$(terraform output -json lb_public_ip|jq '.'|egrep -v "(\[|\])"|cut -d'"' -f2)
else
    CONTROLPLANE_ENDPOINT=$(terraform output -json master_node_ips|jq '.'|egrep -v "(\[|\])"|cut -d'"' -f2)
fi
dkp create cluster preprovisioned --cluster-name ${CLUSTER_NAME} --control-plane-endpoint-host ${CONTROLPLANE_ENDPOINT} --control-plane-endpoint-port 6443
dkp get kubeconfig -c ${CLUSTER_NAME} > ${CLUSTER_NAME}.conf
kubectl get po