output "vault_name" {
  description = "The name of the key vault resource created"
  value       = azurerm_key_vault.vault.name
}

output "vault_id" {
  description = "The ID of the key vault resource created"
  value       = azurerm_key_vault.vault.id
}

output "cert_secret_id" {
  description = "The secret ID of the cert in the Key Vault"
  value       = azurerm_key_vault_certificate.vault_cert.secret_id
}
