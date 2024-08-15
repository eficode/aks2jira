variable "resource_group" {
  description = "Resource group object where this cluster needs to be created"
}

variable "tags" {
  description = "A set of tags for all the resources created in this module"
}

variable "vnet_name" {
  description   = "A set of tags for all the resources created in this module"
  default       = "aks-vnet"
}

variable "subnet_name" {
  description   = "A set of tags for all the resources created in this module"
  default       = "aks-subnet"
}

variable "gateway_name" {
  description   = "A unique name for the Application Gateway Ingress Controller"
}

variable "gateway_sku" {
  description = "SKU of the Ingress Controller"
  default = "Standard_v2"
}

variable "subnet_gateway_name" {
  description = "A unique name for the Gateway Subnet"
}

variable "frontend_port_name" {
  description = "A unique name for the Frontend Port Name"
}

variable "frontend_ip_configuration_name" {
  description = "A name for the Frontend IP Config"
}

variable "backend_address_pool_name" {
  description = "A name for the Backend Address Pool"
}

variable "backend_http_setting_name" {
  description = "A unique name for the Backend HTTP Setting"
}

variable "http_listener_name" {
  description = "A name for the HTTP Listener"
}

variable "request_routing_rule_name" {
  description = "A name for the Request Routing Rule"
}

variable "db_endpoint_name" {
  description = "The name private Endpoint of the DB."
}

variable "dbserver_id" {
  description = "The ID of the DBServer."
}

variable "subnet_id" {
  description   = "ID of the subnet where the Endpoint is in."
}