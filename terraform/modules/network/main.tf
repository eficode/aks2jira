# Fetch all resources in the vnet
data "azurerm_virtual_network" "appgw_vnet" {
  name                = "vnet-tjira"
  resource_group_name = "rg-tjira-fw01"
}

# Create Private DNS Zone
resource "azurerm_private_dns_zone" "aks_private_dns" {
  name                = "privatelink.database.windows.net" # fixed name
  resource_group_name = "${var.resource_group.name}-appgw"
  tags                = var.tags
}

# Create vnet link in Private DNS Zone
resource "azurerm_private_dns_zone_virtual_network_link" "aks_vnet_link" {
  name                  = "jiravnetlink${terraform.workspace}"
  resource_group_name   = "${var.resource_group.name}-appgw"
  private_dns_zone_name = azurerm_private_dns_zone.aks_private_dns.name
  virtual_network_id    = data.azurerm_virtual_network.appgw_vnet.id
}

# Create a Private Endpoint for the DB
resource "azurerm_private_endpoint" "aks_db_endpoint" {
  name                          = var.db_endpoint_name
  resource_group_name           = var.resource_group.name
  location                      = var.resource_group.location
  subnet_id                     = var.subnet_id
  custom_network_interface_name = "${var.db_endpoint_name}-nic"
  tags                          = var.tags

  private_service_connection {
    name                            = "jira-db-conn-${terraform.workspace}"
    private_connection_resource_id  = var.dbserver_id
    is_manual_connection            = false
    subresource_names               = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.aks_private_dns.id]    
  }  
}

# Create NIC for Endpoint
data "azurerm_network_interface" "private_endpoint_nic" {
  name                = azurerm_private_endpoint.aks_db_endpoint.custom_network_interface_name
  resource_group_name = var.resource_group.name

  depends_on = [ azurerm_private_endpoint.aks_db_endpoint ]
}

# Create ASG
resource "azurerm_application_security_group" "aks_asg" {
  name                = "aks-asg"
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
}

# Create association between Private Endpoint and ASG
resource "azurerm_private_endpoint_application_security_group_association" "asg_endpoint" {
  private_endpoint_id           = azurerm_private_endpoint.aks_db_endpoint.id
  application_security_group_id = azurerm_application_security_group.aks_asg.id

  depends_on = [ azurerm_private_endpoint.aks_db_endpoint ]
}
