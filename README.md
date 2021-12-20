# Overview

Azure based demo environment for Konvoy based on Azure VMs.

Tested with:
- CentOS 7.9
- Ubuntu 20.04

## Requirements
- Azure CLI (for authentication usage)
- Azure credentials
- Terraform 2.88.1+ (tested with 2.88.1)
- jq
- ansible 2.12+
- Ansible collection kubernetes.core
- dpk cli 2.1.0+
- kommander cli 2.1.0+
- make

## Quickstart
````
$ az login

$ cat <<EOF > terraform.tfvars
node_location   = "East US 2"
resource_prefix = "ksahm"
Environment     = "Test"
# master_node_count could be 1 (single) oder 3 (HA)
master_node_count = 1
worker_node_count = 2
master_node_size = "Standard_D4s_v3"
worker_node_size = "Standard_D8s_v3"
admin_username  = "ksahm"
calico_interface = "eth0"
cluster_name = "democluster"
expiration = "3d"
subscription_id = "<Azure subscription ID>"
tenant_id       = "<Azure tenant ID>"
EOF

$ cat <<EOF > license.lic
<license key>
EOF

$ make
````

## The "longer" way
````
$ az login

$ cat <<EOF > terraform.tfvars
node_location   = "East US 2"
resource_prefix = "ksahm"
Environment     = "Test"
# master_node_count could be 1 (single) oder 3 (HA)
master_node_count = 1
worker_node_count = 2
master_node_size = "Standard_D4s_v3"
worker_node_size = "Standard_D8s_v3"
admin_username  = "ksahm"
calico_interface = "eth0"
cluster_name = "democluster"
subscription_id = "<Azure subscription ID>"
tenant_id       = "<Azure tenant ID>"
EOF

$ cat <<EOF > license.lic
<license key>
EOF

$ terraform validate

$ terraform apply

$ make cluster

$ make kommander

$ make metallb

$ make install-license
````

## Test connection via Ansible
````
$ ./create_ansible_inventory.sh

$ ansible master -i inventory -m ping
20.119.198.170 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
20.119.198.126 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
20.119.198.144 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}

$ ansible worker -i inventory -m ping
20.119.198.230 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
20.119.198.227 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
````

## Teardown the environment
````
$ make teardown
````