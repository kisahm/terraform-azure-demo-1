#!/bin/bash

if [ ! -e terraform.tfvars ] ; then
    echo "Could not find vars file: terraform.tfvars"
    exit 1
fi

set -x
dkp create bootstrap

if [ "$(grep offer main.tf|grep -v '#'|uniq |awk '{print $3}'|cut -d '"' -f2)" == "CentOS" ] && [ "$(grep sku main.tf|grep -v '#'|uniq |awk '{print $3}'|cut -d '"' -f2)" == "7_9-gen2" ]; then
    sed 's/<PYTHONVERSION>/python/g' templates/ansible.cfg.tmpl > ./ansible.cfg
else
    sed 's/<PYTHONVERSION>/python3/g' templates/ansible.cfg.tmpl > ./ansible.cfg
fi

if [ -z ${CLUSTER_NAME} ] ; then
    export CLUSTER_NAME=$(grep ^cluster_name terraform.tfvars|awk '{ print $3 }'|cut -d '"' -f2)
fi

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

dkp create cluster preprovisioned --cluster-name ${CLUSTER_NAME} --control-plane-endpoint-host ${CONTROLPLANE_ENDPOINT} --worker-replicas $(grep ^worker_node_count terraform.tfvars|awk '{ print $3 }') --control-plane-endpoint-port 6443 ${EXTRAVARS} --dry-run -o yaml > /tmp/cluster.yml
CALICO_INTERFACE="$(grep ^calico_interface terraform.tfvars|awk '{ print $3 }')"
if [ -z ${CALICO_INTERFACE} ] ; then
    CALICO_INTERFACE="eth0"
fi
sed "s/      calicoNetwork:/      calicoNetwork:\n        nodeAddressAutodetectionV4:\n          interface: ${CALICO_INTERFACE}/g" /tmp/cluster.yml > /tmp/cluster2.yml
sed "s/encapsulation: IPIP/encapsulation: VXLAN/g" /tmp/cluster2.yml > cluster.yml
rm /tmp/cluster*.yml
kubectl apply -f cluster.yml

kubectl get kubeadmcontrolplane,cluster,preprovisionedcluster,preprovisionedmachinetemplate,clusterresourceset,machinedeployment,preprovisionedmachinetemplate,kubeadmconfigtemplate

echo "Waiting for platform cluster ready state..."

while [ $(kubectl get kubeadmcontrolplane.controlplane.cluster.x-k8s.io/${CLUSTER_NAME}-control-plane -o json |jq '.status.readyReplicas // 0') -ne $(grep ^master_node_count terraform.tfvars |awk '{ print $3 }') ] ; do 
    echo "Waiting for Control Plane"
    sleep 10
done
echo "\o/ Control Plane is ready... \o/"
while [ $(kubectl get machinedeployment.cluster.x-k8s.io/${CLUSTER_NAME}-md-0 -o json |jq '.status.readyReplicas // 0') -ne $(grep ^worker_node_count terraform.tfvars |awk '{ print $3 }') ] ; do 
    echo "Waiting for Worker Nodes"
    sleep 10
done
echo "\o/ Cluster is ready... \o/"

./make_selfmanaged.sh