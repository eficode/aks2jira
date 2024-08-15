output "aks_subnet_id" {
    description = "ID of the subnet where the AKS is in."
    value       = data.azurerm_subnet.aks_subnet.id
}

output "appgw_subnet_id" {
    description = "ID of the subnet where the Application Gateway is in."
    value       = data.azurerm_subnet.appgw_subnet.id
}

output "aks_subnet_cidr" {
    description = "CIDR of the subnet where the AKS is in."
    value       = data.azurerm_subnet.aks_subnet.address_prefixes
}

