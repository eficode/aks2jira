variable "resource_group" {
  description = "Resource group object where this cluster needs to be created"
}

variable "tags" {
  description = "A set of tags for all the resources created in this module"
}

variable "db_jira_name" {
  description = "A name for the Jira DB."
}

variable "db_eazybi_name" {
  description = "A name for the EazyBI DB."
}

variable "dbserver_name" {
  description = "A name for the DB Server."
}

variable "user_managed_identity" {
  description = "User managed identity for the cluster"
}
