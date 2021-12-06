# Overview

Azure based demo environment for Konvoy based on Azure VMs.

## Requirements
- Azure CLI (for authentication usage)
- Azure credentials
- Terraform 2.88.1+ (tested with 2.88.1)
- jq
- ansible 

## Quickstart
````
$ cat <EOF > terraform.tfvars
node_location   = "East US 2"
resource_prefix = "ksahm"
Environment     = "Test"
master_node_count = 3
worker_node_count = 2
master_node_size = "Standard_DS1_v2"
worker_node_size = "Standard_D2s_v3"
admin_username  = "ksahm"
subscription_id = "<Azure subscription ID>"
tenant_id       = "<Azure tenant ID>"
EOF

$ terraform validate
$ terraform apply
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