resource "random_id" "log_analytics_workspace_name_suffix" {
  byte_length = 8
}

# Create Workspace for LogAnalyzer
resource "azurerm_log_analytics_workspace" "aks_loganalytics" {
  name                = "jira-log-${terraform.workspace}-${random_id.log_analytics_workspace_name_suffix.dec}"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  retention_in_days   = var.loganalytics_retention_days
  sku                 = var.loganalytics_sku
  tags                = var.tags
}

# Create AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                      = var.cluster_name
  location                  = var.resource_group.location
  resource_group_name       = var.resource_group.name
  dns_prefix                = var.aks_dns_prefix
  tags                      = var.tags
  kubernetes_version        = var.k8s_version

  lifecycle {
    # With autoscaling on, the node count cannot be always known.
    ignore_changes = [default_node_pool[0].node_count]
  }

  # Changing some params here might recreate the cluster
  default_node_pool {
    name                        = "jiranodepool"
    node_count                  = var.cluster_node_count
    vm_size                     = var.cluster_default_node_pool_vm_size
    enable_auto_scaling         = true
    max_count                   = var.cluster_node_count
    min_count                   = var.cluster_node_count
    tags                        = var.tags
    orchestrator_version        = var.k8s_version
    temporary_name_for_rotation = "jiraupgrade"
    vnet_subnet_id              = var.aks_subnet_id

    upgrade_settings {
      max_surge = "33%" #during upgrade % of nodes are added
    }        
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.appgw.id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_managed_identity]
  }  

  network_profile {
    network_plugin  = "azure"
    network_policy  = "azure"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_loganalytics.id
  }

  node_resource_group = "${var.resource_group.name}-appgw"
}

# Set Permissions
resource "azurerm_role_assignment" "ingressuser_appgw" {
  scope = azurerm_application_gateway.appgw.id
  role_definition_name = "Contributor"
  principal_id = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}

resource "azurerm_role_assignment" "ingressuser_rg-cust" {
  scope = var.rg_cust_id
  role_definition_name = "Contributor"
  principal_id = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}

resource "azurerm_role_assignment" "ingressuser_subnet-aks" {
  scope = var.aks_subnet_id
  role_definition_name = "Network Contributor"
  principal_id = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}

resource "azurerm_role_assignment" "ingressuser_jirauser_mido" {
  scope = var.user_managed_identity
  role_definition_name = "Managed Identity Operator"
  principal_id = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}

resource "azurerm_role_assignment" "ingressuser_jirauser_nwc" {
  scope = var.user_managed_identity
  role_definition_name = "Network Contributor"
  principal_id = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}

resource "azurerm_role_assignment" "inressuser_appgw" {
  scope = var.appgw_subnet_id
  role_definition_name = "Network Contributor"
  principal_id = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}

# Create Public IP for AppGW
resource "azurerm_public_ip" "appgw-pip" {
  name = "jira-appgw-${terraform.workspace}-pip"
  resource_group_name = var.rg_cust_name
  location = var.resource_group.location
  allocation_method = "Static"
  sku = "Standard"
}

# Create Application Gateway
resource "azurerm_application_gateway" "appgw" {
  name                = var.appgw_name
  resource_group_name = var.rg_cust_name
  location            = var.resource_group.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_managed_identity]
  }  

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = var.appgw_subnet_id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_port {
    name = "https"
    port = 443
  }  

  frontend_ip_configuration {
    name                 = azurerm_public_ip.appgw-pip.name
    public_ip_address_id = azurerm_public_ip.appgw-pip.id
  }

  backend_address_pool {
    name = "jira-appgw-${terraform.workspace}-bepool"
  }

  backend_http_settings {
    name                  = "${var.appgw_name}-httpsetting"
    cookie_based_affinity = "Enabled"
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 210
    probe_name            = "jira-probe-${terraform.workspace}"
  }

  ssl_certificate {
    name = var.jira_sslcert_name
    key_vault_secret_id = var.ssl_kv_cert_id
  }

  http_listener {
    name                           = "${var.appgw_name}-listener-http"
    frontend_ip_configuration_name = azurerm_public_ip.appgw-pip.name
    frontend_port_name             = "http"
    protocol                       = "Http"
    host_names                     = [var.jira_domain]
  }

  http_listener {
    name                           = "${var.appgw_name}-listener-https"
    frontend_ip_configuration_name = azurerm_public_ip.appgw-pip.name
    frontend_port_name             = "https"
    protocol                       = "Https"
    host_name                      = var.jira_domain
    ssl_certificate_name           = var.jira_sslcert_name
  }  

  request_routing_rule {
    name                       = "${var.appgw_name}-routingrule-https"
    priority                   = 19000
    rule_type                  = "Basic"
    http_listener_name         = "${var.appgw_name}-listener-https"
    backend_address_pool_name  = "${var.appgw_name}-bepool"
    backend_http_settings_name = "${var.appgw_name}-httpsetting"
  }

  request_routing_rule {
    name                       = "${var.appgw_name}-routingrule-http"
    priority                   = 19005
    rule_type                  = "Basic"
    http_listener_name         = "${var.appgw_name}-listener-http"
    redirect_configuration_name = "${var.appgw_name}-redirect-http"
  }  

  redirect_configuration {
    name = "${var.appgw_name}-redirect-http"
    redirect_type = "Permanent"
    target_listener_name = "${var.appgw_name}-listener-https"
    include_query_string = true
    include_path = true
  }

  probe {
    name = "jira-probe-${terraform.workspace}"
    protocol = "Http"
    host = var.jira_domain
    interval = 30
    path = "/"
    timeout = 30
    unhealthy_threshold = 3
  }

  lifecycle {
    ignore_changes = [
      tags, backend_address_pool, backend_http_settings, frontend_port, http_listener, probe, redirect_configuration, request_routing_rule, ssl_certificate, url_path_map
    ]
  }

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }

  depends_on = [ azurerm_public_ip.appgw-pip ]
}

# Updating the kubeconfig after setting up AKS cluster
resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    when = create
    command = <<EOT
      az aks get-credentials --resource-group ${azurerm_kubernetes_cluster.aks.resource_group_name} --name ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing
    EOT
  }

  depends_on = [ azurerm_kubernetes_cluster.aks ]
}
