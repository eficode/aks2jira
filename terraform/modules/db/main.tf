# Create DB-Server
resource "azurerm_mssql_server" "aks_dbserver" {
  name                         = var.dbserver_name
  resource_group_name          = var.resource_group.name
  location                     = var.resource_group.location
  version                      = "12.0"
  administrator_login          = var.dbadmin_name
  administrator_login_password = var.dbadmin_password
  minimum_tls_version          = "1.2"
  tags                         = var.tags

  azuread_administrator {
    login_username = var.user_managed_identity.name
    object_id      = var.user_managed_identity.principal_id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_managed_identity.id]
  }

  primary_user_assigned_identity_id = var.user_managed_identity.id
}

# Create DB
resource "azurerm_mssql_database" "db_jira" {
  name      = var.db_jira_name
  server_id = azurerm_mssql_server.aks_dbserver.id
  collation = "SQL_Latin1_General_CP437_CI_AI"
  tags      = var.tags
}

# Create DB EazyBI
resource "azurerm_mssql_database" "db-eazybi" {
  name      = var.db_eazybi_name
  server_id = azurerm_mssql_server.aks_dbserver.id
  collation = "SQL_Latin1_General_CP437_CI_AI"
  tags      = var.tags
}
