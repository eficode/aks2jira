variable "resource_group" {
  description = "Resource group object where this cluster needs to be created"
}

variable "rg_cust_name" {
  description = "Name of the custom RG"
}

variable "rg_cust_id" {
  description = "ID of the custom RG"
}

variable "cluster_name" {
  description = "A unique name for the AKS cluster. This will be also used as a DNS prefix for the cluster"
}

variable "vnet_name" {
  description = "A unique name for the Virtual Network"
  default     = "jira-vnet"
}

variable "user_managed_identity" {
  description = "User managed identity"
}

variable "user_managed_identity_id" {
  description = "ID of managed identity"
}

variable "loganalytics_retention_days" {
  description = "Number of days to keep logs in Log Analytics"
  default = "30"
}

variable "loganalytics_sku" {
  description = "Pricing tier for Log Analytics: Pay per GB"
  default = "PerGB2018"
}

variable "cluster_node_count" {
  description = "Number of nodes in the AKS cluster"
  default = "2"
}

variable "tags" {
  description = "A set of tags for all the resources created in this module"
}

variable "cluster_default_node_pool_vm_size" {
  description = "The VM size of the default node pool"
  default = "Standard_B2pls_v2"
}

variable "k8s_version" {
  description = "Version of Kubernetes" 
}

variable "aks_dns_prefix" {
  description = "DNS prefix to use with hosted Kubernetes API server FQDN."
}

variable "aks_dns_service_ip" {
  description = "Containers DNS server IP address."
  default     = "10.0.0.10"
}

variable "appgw_name" {
  description = "The name of the Application Gateway that is created automatically by the AKS Cluster."
}

variable "aks_subnet_id" {
  description   = "ID of the subnet where the AKS is in."
}

variable "appgw_subnet_id" {
  description   = "ID of the subnet where the Application Gateway is in."
}

variable "jira_domain" {
  description   = "Domain of the Jira Application."
}

variable "jira_sslcert_name" {
  description   = "Name of the SSL Certificate."
}

variable "ssl_kv_cert_id" {
  description   = "KV ID of the SSL Certificate."
}
