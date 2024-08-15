# Create the resource group to provision AKS
resource "azurerm_resource_group" "aks_rg" {
  name      = local.rg_name
  location  = local.location
  tags      = local.tags
}


# Create the resource group to provision AKS
resource "azurerm_resource_group" "rg_cust" {
  name      = "${local.rg_name}-cust"
  location  = local.location
  tags      = local.tags
}

# Fetch Ayure Subscription
data "azurerm_subscription" "current" {
}

# Fetch pre-created User Managed Identity
data "azurerm_user_assigned_identity" "aks_identity" {
  resource_group_name = "rg-tjira-fw01"
  name = local.user_managed_identity
}

# Create the Key Vault with cert
module "vault" {
  source                = "./terraform/modules/vault"
  resource_group_name   = azurerm_resource_group.aks_rg.name
  location              = azurerm_resource_group.aks_rg.location
  tags                  = local.tags
  vault_cert_keyname    = "ssl-cert"
  cert_filename         = var.cert_filename
  cert_password         = var.cert_password
  user_managed_identity = data.azurerm_user_assigned_identity.aks_identity.principal_id
}

# Get existing Subnets for AKS
module "network_aks" {
  source                = "./terraform/modules/network_aks"
  user_managed_identity = data.azurerm_user_assigned_identity.aks_identity.id
}

# Create the AKS cluster
module "aks" {
  source                            = "./terraform/modules/aks"
  resource_group                    = azurerm_resource_group.aks_rg
  cluster_name                      = local.cluster_name
  user_managed_identity             = data.azurerm_user_assigned_identity.aks_identity.id
  tags                              = local.tags
  k8s_version                       = local.k8s_version
  aks_dns_prefix                    = local.aks_dns_prefix
  appgw_name                        = local.appgw_name
  cluster_default_node_pool_vm_size = local.aks_vmsize[terraform.workspace]
  aks_subnet_id                     = module.network_aks.aks_subnet_id
  appgw_subnet_id                   = module.network_aks.appgw_subnet_id
  jira_domain                       = local.jira_domains[terraform.workspace]
  jira_sslcert_name                 = local.jira_sslcert_name
  ssl_kv_cert_id                    = module.vault.cert_secret_id
  user_managed_identity_id          = data.azurerm_user_assigned_identity.aks_identity.principal_id
  rg_cust_name                      = azurerm_resource_group.rg_cust.name
  rg_cust_id                        = azurerm_resource_group.rg_cust.id

  depends_on                        = [ module.network_aks ]
}

# Create Database
module "db" {
  source                = "./terraform/modules/db"
  resource_group        = azurerm_resource_group.aks_rg
  user_managed_identity = data.azurerm_user_assigned_identity.aks_identity
  tags                  = local.tags
  dbserver_name         = "jira-dbserver-${terraform.workspace}"
  db_jira_name          = "jira-db-jira-${terraform.workspace}"
  db_eazybi_name        = "jira-db-eazybi-${terraform.workspace}"

  depends_on = [ module.aks ]
}

# Create vLink and Endpoint
module "network" {
  source            = "./terraform/modules/network"
  resource_group    = azurerm_resource_group.aks_rg
  tags              = local.tags
  dbserver_id       = module.db.dbserver_id
  db_endpoint_name  = "jira-db-ep-${terraform.workspace}"
  subnet_id         = module.network_aks.aks_subnet_id

  depends_on        = [ module.db ]
}

# Create the Kubernetes Components
module "k8s" {
  source                      = "./terraform/modules/k8s"
  kube_config                 = module.aks.kube_config
  resource_group              = azurerm_resource_group.aks_rg.name
  dbadmin_name                = module.db.dbadmin_name
  dbadmin_password            = module.db.dbadmin_password
  cert_filename               = var.cert_filename
  aks_pod_cidr                = local.aks_pod_cidr
  appgw_name                  = local.appgw_name
  appgw_pip_name              = module.aks.appgw_pip_name
  appgw_pip_ip                = module.aks.appgw_pip_ip
  node_resource_group_name    = module.aks.node_resource_group_name
}

# Install JIRA via Helm
module "jira" {
  source      = "./terraform/modules/jira"
  kube_config = module.aks.kube_config
}
