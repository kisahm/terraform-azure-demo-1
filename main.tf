terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.88.1"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# Create a resource group
resource "azurerm_resource_group" "demo_rg" {
  name     = "${var.resource_prefix}-RG"
  location = var.node_location
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "demo_vnet" {
  name                = "${var.resource_prefix}-vnet"
  resource_group_name = azurerm_resource_group.demo_rg.name
  location            = var.node_location
  address_space       = var.node_address_space
}

# Create a subnets within the virtual network
resource "azurerm_subnet" "demo_subnet" {
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.demo_rg.name
  virtual_network_name = azurerm_virtual_network.demo_vnet.name
  address_prefixes     = var.node_address_prefixes
}

# Create Linux Public IP for Master
resource "azurerm_public_ip" "demo_master_public_ip" {
  count = var.master_node_count
  name  = "${var.resource_prefix}-master-${format("%02d", count.index)}-PublicIP"
  #name = "${var.resource_prefix}-PublicIP"
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name
  allocation_method   = var.Environment == "Test" ? "Static" : "Dynamic"
  tags = {
    environment = var.resource_prefix
  }
}

# Create Linux Public IP for Worker
resource "azurerm_public_ip" "demo_worker_public_ip" {
  count = var.worker_node_count
  name  = "${var.resource_prefix}-worker-${format("%02d", count.index)}-PublicIP"
  #name = "${var.resource_prefix}-PublicIP"
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name
  allocation_method   = var.Environment == "Test" ? "Static" : "Dynamic"
  tags = {
    environment = var.resource_prefix
  }
}

## Create Linux Public IP for LB if needed
#resource "azurerm_public_ip" "demo_lb_public_ip" {
#  count = var.master_node_count ? 3 : 0
#  name  = "${var.resource_prefix}-lb-PublicIP"
#  location            = azurerm_resource_group.demo_rg.location
#  resource_group_name = azurerm_resource_group.demo_rg.name
#  allocation_method   = var.Environment == "Test" ? "Static" : "Dynamic"
#  tags = {
#    environment = var.resource_prefix
#  }
#}

# Create Network Interface for Master
resource "azurerm_network_interface" "demo_master_nic" {
  count = var.master_node_count
  #name = "${var.resource_prefix}-NIC"
  name                = "${var.resource_prefix}-master-${format("%02d", count.index)}-NIC"
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.demo_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.demo_master_public_ip.*.id, count.index)
    #public_ip_address_id = azurerm_public_ip.demo_public_ip.id
    #public_ip_address_id = azurerm_public_ip.demo_public_ip.id
  }
}

# Create Network Interface for Worker
resource "azurerm_network_interface" "demo_worker_nic" {
  count = var.worker_node_count
  #name = "${var.resource_prefix}-NIC"
  name                = "${var.resource_prefix}-worker-${format("%02d", count.index)}-NIC"
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.demo_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.demo_worker_public_ip.*.id, count.index)
    #public_ip_address_id = azurerm_public_ip.demo_public_ip.id
    #public_ip_address_id = azurerm_public_ip.demo_public_ip.id
  }
}

# Creating resource NSG
resource "azurerm_network_security_group" "demo_nsg" {
  name                = "${var.resource_prefix}-NSG"
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name
  # Security rule can also be defined with resource azurerm_network_security_rule, here just defining it inline.
  security_rule {
    name                       = "Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges     = ["22","80","443","6443","9000","9001"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {
    environment = var.resource_prefix
  }
}

# Subnet and NSG association
resource "azurerm_subnet_network_security_group_association" "demo_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.demo_subnet.id
  network_security_group_id = azurerm_network_security_group.demo_nsg.id
}

# Create virtual machines for Master
resource "azurerm_linux_virtual_machine" "demo_master_linux_vm" {
    count               = var.master_node_count
    name                = "${var.resource_prefix}-master-${format("%02d", count.index)}"
    location            = azurerm_resource_group.demo_rg.location
    resource_group_name = azurerm_resource_group.demo_rg.name
    size                = var.master_node_size
    admin_username      = var.admin_username
    network_interface_ids = [
        element(azurerm_network_interface.demo_master_nic.*.id, count.index)
    ]

    admin_ssh_key {
        username   = var.admin_username
        public_key = file("~/.ssh/id_rsa.pub")
    }

    os_disk {
        name = "myosdisk-master-${count.index}"
        caching = "ReadWrite"
        storage_account_type = "Standard_LRS"
        disk_size_gb = 50

    }

    source_image_reference {
        publisher = "canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts-gen2"
        version   = "latest"
#        publisher = "kinvolk"
#        offer     = "flatcar-container-linux-free"
#        sku       = "stable"
#        version   = "2905.2.1"
#        publisher = "OpenLogic"
#        offer     = "CentOS"
#        sku       = "7_9-gen2"
#        version   = "7.9.2021071901"
        }

# uncomment only if your using flatcar
#    plan {
#        name = "stable"
#        publisher = "kinvolk"
#        product = "flatcar-container-linux-free"
#    }

    tags = {
        environment = var.resource_prefix
        node_type = "master"
    }
}

# Create virtual machines for Worker
resource "azurerm_linux_virtual_machine" "demo_worker_linux_vm" {
    count               = var.worker_node_count
    name                = "${var.resource_prefix}-worker-${format("%02d", count.index)}"
    location            = azurerm_resource_group.demo_rg.location
    resource_group_name = azurerm_resource_group.demo_rg.name
    size                = var.worker_node_size
    admin_username      = var.admin_username
    network_interface_ids = [
        element(azurerm_network_interface.demo_worker_nic.*.id, count.index)
    ]

    admin_ssh_key {
        username   = var.admin_username
        public_key = file("~/.ssh/id_rsa.pub")
    }

    os_disk {
        name = "myosdisk-worker-${count.index}"
        caching = "ReadWrite"
        storage_account_type = "Standard_LRS"
        disk_size_gb = 100
    }

    source_image_reference {
        publisher = "canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts-gen2"
        version   = "latest"
#        publisher = "kinvolk"
#        offer     = "flatcar-container-linux-free"
#        sku       = "stable"
#        version   = "2905.2.1"
#        publisher = "OpenLogic"
#        offer     = "CentOS"
#        sku       = "7_9-gen2"
#        version   = "7.9.2021071901"
        }

# uncomment only if your using flatcar
#    plan {
#        name = "stable"
#        publisher = "kinvolk"
#        product = "flatcar-container-linux-free"
#    }

    tags = {
        environment = var.resource_prefix
        node_type = "worker"
    }
}

#resource "azurerm_lb" "demo-lb" {
#    count = var.master_node_count ? 3 : 0
#    name                = "Loadbalancer"
#    location            = azurerm_resource_group.demo_rg.location
#    resource_group_name = azurerm_resource_group.demo_rg.name
#
#    frontend_ip_configuration {
#        name                 = "PublicIPAddress"
#        public_ip_address_id = azurerm_public_ip.demo_lb_public_ip.id
#    }
#}
#
#resource "azurerm_lb_rule" "demo-lb-rule-6443" {
#    count = var.master_node_count ? 3 : 0
#    resource_group_name            = azurerm_resource_group.demo.name
#    loadbalancer_id                = azurerm_lb.demo.id
#    name                           = "LBRule"
#    protocol                       = "Tcp"
#    frontend_port                  = 6443
#    backend_port                   = 6443
#    frontend_ip_configuration_name = "PublicIPAddress"
#}
#
#resource "azurerm_lb_rule" "demo-lb-rule-80" {
#    count = var.master_node_count ? 3 : 0
#    resource_group_name            = azurerm_resource_group.demo.name
#    loadbalancer_id                = azurerm_lb.demo.id
#    name                           = "LBRule"
#    protocol                       = "Tcp"
#    frontend_port                  = 80
#    backend_port                   = 80
#    frontend_ip_configuration_name = "PublicIPAddress"
#}
#
#resource "azurerm_lb_rule" "demo-lb-rule-443" {
#    count = var.master_node_count ? 3 : 0
#    resource_group_name            = azurerm_resource_group.demo.name
#    loadbalancer_id                = azurerm_lb.demo.id
#    name                           = "LBRule"
#    protocol                       = "Tcp"
#    frontend_port                  = 443
#    backend_port                   = 443
#    frontend_ip_configuration_name = "PublicIPAddress"
#}
#
#output "lb_public_ip" {
#    value = azurerm_public_ip.demo_lb_public_ip.*.ip_address
#}

output "master_node_ips" {
    value = azurerm_public_ip.demo_master_public_ip.*.ip_address
}

output "worker_node_ips" {
    value = azurerm_public_ip.demo_worker_public_ip.*.ip_address
}