locals {
  tags = {
    owner     = "me@mydomain.com"
    project   = "jira"
    env       = "${terraform.workspace}"
  }

  aks_vmsize = {
    test  = "Standard_B4as_v2" #4 Core, 16 GB RAM, intel, Burstable
    dev   = "Standard_D4ads_v5" #4 Core, 16 GB RAM, intel
    int   = "Standard_D4ads_v5" #4 Core, 16 GB RAM, intel
    prod  = "Standard_D4ads_v5" #4 Core, 16 GB RAM, intel
  }

  jira_domains = {
    test  = "test.jira.mydomain.com"
    dev   = "dev.jira.mydomain.com"
  }

  rg_name                 = "rg-jira-${terraform.workspace}"
  location                = "West Europe"
  user_managed_identity   = "Jira-uid-${terraform.workspace}"
  jira_sslcert_name       = "SSLCert"

  # AKS
  cluster_name            = "jira-aks-${terraform.workspace}"
  k8s_version             = "1.29.4"
  aks_dns_prefix          = "aks${terraform.workspace}"
  appgw_name              = "jira-appgw-${terraform.workspace}"
  aks_pod_cidr            = "10.210.2.0/24"
}

