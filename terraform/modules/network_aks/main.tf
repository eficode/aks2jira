# Fetch pre-existing Subnet for AKS
data "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  virtual_network_name = "vnet-jira"
  resource_group_name  = "rg-jira-fw01"
}

# Fetch pre-existing Subnet for AppGW
data "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw-subnet"
  virtual_network_name = "vnet-jira"
  resource_group_name  = "rg-jira-fw01"
}
