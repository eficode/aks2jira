resource "random_id" "vault_name_suffix" {
  byte_length = 4
}

data "azurerm_client_config" "current" {}

# Create Key Vault
resource "azurerm_key_vault" "vault" {
  name                        = "jira-kv-${random_id.vault_name_suffix.dec}-${terraform.workspace}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 90
  purge_protection_enabled    = false
  sku_name                    = "standard"
  tags                        = var.tags
}

# Create Policy for the Key Vault
resource "azurerm_key_vault_access_policy" "policy" {
  key_vault_id  = azurerm_key_vault.vault.id
  tenant_id     = data.azurerm_client_config.current.tenant_id
  object_id     = data.azurerm_client_config.current.object_id

  key_permissions = [ "Create", "Get", "List", "Recover", "Delete" ]
  secret_permissions = [ "Get", "Set", "Delete", "List", "Recover", "Restore", "Backup", "Purge" ]
  certificate_permissions = [ "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "SetIssuers", "Update" ]

  depends_on = [ azurerm_key_vault.vault ]
}

resource "azurerm_key_vault_access_policy" "vault_access_policy" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.user_managed_identity
  
  key_permissions         = [ "Create", "Get", "List", "Recover", "Delete" ]
  certificate_permissions = [ "Get", "Create", "Import" ]
  secret_permissions      = [ "Get", "List" ] 
}

# Add Cert to Key Vault
resource "azurerm_key_vault_certificate" "vault_cert" {
  name         = var.vault_cert_keyname
  key_vault_id = azurerm_key_vault.vault.id

  certificate {
    contents = filebase64("${path.root}/certs/${terraform.workspace}/${var.cert_filename}")
    password = var.cert_password
  }

  depends_on = [ azurerm_key_vault_access_policy.policy, azurerm_key_vault_access_policy.vault_access_policy ]
}  