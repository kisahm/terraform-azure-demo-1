variable "node_location" {
  type = string
}
variable "resource_prefix" {
  type = string
}
variable "node_address_space" {
  default = ["172.16.0.0/16"]
}
#variable for network range
variable "node_address_prefixes" {
  default = ["172.16.1.0/24"]
}
#variable for Environment
variable "Environment" {
  type = string
}
variable "master_node_count" {
  type = number
}
variable "worker_node_count" {
  type = number
}

variable "master_node_size" {
  type = string
}

variable "worker_node_size" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "expiration" {
  type = string
}