output "dbserver_id" {
  value = azurerm_mssql_server.aks_dbserver.id
}

output "dbserver_fqdn" {
  value = azurerm_mssql_server.aks_dbserver.fully_qualified_domain_name 
}

output "dbadmin_name" {
  value = var.dbadmin_name
}

output "dbadmin_password" {
  value = var.dbadmin_password
  sensitive = true
}