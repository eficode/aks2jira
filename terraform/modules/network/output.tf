output "private_endpoint_ip" {
  value = data.azurerm_network_interface.private_endpoint_nic.private_ip_address
  depends_on  = [ data.azurerm_network_interface.private_endpoint_nic ]
}