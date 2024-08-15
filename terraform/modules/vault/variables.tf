variable "resource_group_name" {
  description = "Resource group name where key vault should be created"
  type        = string
}

variable "tags" {
  description = "Tags to set on the resource"
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "The location of the Vault"
}

variable "vault_cert_keyname" {
  description   = "The key name of the cert entry in the Key Vault."
}

variable "cert_filename" {
  description = "The filename for the SSL Cert."
  type        = string
  sensitive   = true
}

variable "cert_password" {
  description = "The password for the SSL Cert."
  type        = string
  sensitive   = true
}

variable "user_managed_identity" {
  description = "User managed identity"
}
