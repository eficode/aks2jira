variable "resource_group" {
  description   = "Resource group object where this cluster needs to be created"
  type          = string
}

variable "kube_config" {
  description = "The kube config of the AKS cluster"
  sensitive   = true
}

variable "dbadmin_name" {
  description = "A name for the DB Admin."
  type        = string
  sensitive   = true
}

variable "dbadmin_password" {
  description = "A password for the DB Admin."
  type        = string
  sensitive   = true
}

variable "cert_filename" {
  description = "The PFX filename for the SSL Cert."
  type        = string
  sensitive   = true
}

variable "appgw_name" {
  description = "The name of the Application Gateway."
  type        = string
}

variable "appgw_pip_name" {
  description = "The name of the Application Gateway Frontend IP."
  type        = string
}

variable "appgw_pip_ip" {
  description = "The IP of the Application Gateway Frontend IP."
  type        = string
}

variable "aks_pod_cidr" {
  description = "A CIDR notation IP range from which to assign service pod IPs."
}

variable "node_resource_group_name" {
  description = "Node Resource Group of the Application Gateway."
}