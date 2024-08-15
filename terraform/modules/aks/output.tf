output "id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config
}

output "node_resource_group_name" {
  value = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "appgw_name" {
  value = var.appgw_name
}

output "appgw_id" {
  value = azurerm_application_gateway.appgw.id
}

output "appgw" {
  value = azurerm_application_gateway.appgw
}

output "appgw_pip_name" {
  value = azurerm_public_ip.appgw-pip.name
}

output "appgw_pip_ip" {
  value = azurerm_public_ip.appgw-pip.ip_address
}