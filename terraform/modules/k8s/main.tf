provider "kubernetes" {
  host                    = var.kube_config.0.host
  client_certificate      = "${base64decode(var.kube_config.0.client_certificate)}"
  client_key              = "${base64decode(var.kube_config.0.client_key)}"
  cluster_ca_certificate  = "${base64decode(var.kube_config.0.cluster_ca_certificate)}"
}

# Create namespace jira
resource "kubernetes_namespace" "namespace_jira" {
  metadata {
    name = "jira"
    labels = {
      "app" = "jira"
    }
  }
}

# Create namespace monitoring
resource "kubernetes_namespace" "namespace_monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "app" = "monitoring"
    }
  }
}

# Create a Secret for DB credentials
resource "kubernetes_secret" "k8s_secret_db" {
  metadata {
    name      = "jiradb-secret"
    namespace = kubernetes_namespace.namespace_jira.metadata[0].name
    labels    = {
      "sensitive" = "true"
      "app"       = "jira"
    }
  }

  data = {
    username = var.dbadmin_name
    password = var.dbadmin_password
  }

  type = "Opaque"
}

# Create storage type
resource "kubernetes_storage_class" "azurefile_csi_premium_retain" {
  metadata {
    name = "azurefile-csi-premium-retain"
  }
  storage_provisioner = "file.csi.azure.com"
  
  parameters = {
    skuName = "Premium_LRS"
  }

  allow_volume_expansion  = true
  mount_options           = ["mfsymlinks", "actimeo=30", "nosharesock"]
  reclaim_policy          = "Retain"
  volume_binding_mode     = "Immediate"
}

# Create Network Policy to block outgoing traffic on DEV
resource "kubernetes_network_policy" "k8s_np" {
  
  metadata {
    name      = "block-egress"
    namespace = "jira"
  }

  spec {
    pod_selector {
      match_expressions {
        key       = "app.kubernetes.io/instance"
        operator  = "In"
        values    =  ["jira"]
      }
    }

    policy_types = ["Egress"]  

    # Allow DNS and Nameserver
    egress {
      ports {
        port = "1433"
        protocol = "TCP"
      }

      ports {
        port = "53"
        protocol = "UDP"
      }

      to {
        ip_block {
          cidr = "0.0.0.0/0"
        } 
      }
    }      

    # Allow https to AppGW
    egress {
      ports {
        port = "443"
        protocol = "TCP"
      }
      to {
        ip_block {
          cidr = "${var.appgw_pip_ip}/32"
        } 
      }
    }  

    # Allow connection to vNet
    egress {
      to {
        ip_block {
          cidr = "${var.aks_pod_cidr}"
        } 
      }
    }      

    # Allow Ubuntu Updates
    egress {
      ports {
        port = "80"
        protocol = "TCP"
      }      
      to {
        ip_block {
          cidr = "185.125.190.36/30"
        } 
      }
    }     

    # Allow Atlassian Marketplace
    egress {
      ports {
        port = "443"
        protocol = "TCP"
      }      
      to {
        ip_block {
          cidr = "16.63.53.148/30"
        } 
      }
    }   

    # Allow Atlassian Marketplace
    egress {
      ports {
        port = "443"
        protocol = "TCP"
      }      
      to {
        ip_block {
          cidr = "185.166.143.32/30"
        } 
      }
    }                 
  } 
}

# Create a Secret for JVM trusted certs
resource "kubernetes_secret" "k8s_secret_cert_jvm" {
  metadata {
    name      = "jvm-trusted-certs"
    namespace = kubernetes_namespace.namespace_jira.metadata[0].name
    labels    = {
      "sensitive" = "true"
      "app"       = "jira"
    }
  }

  data = {
    "IssuingCA01.crt" = file("${path.root}/certs/all/IssuingCA01.crt")
    "RootCA.crt" = file("${path.root}/certs/all/RootCA.crt")
  }

  type = "Opaque"
}

# Create ConfigMap for Log4j
resource "kubernetes_config_map" "k8s_log4j" {
  metadata {
    name      = "log4j2-settings"
    namespace = "jira"
  }

  data = {
    "log4j2.xml" = "${file("${path.module}/log4j2.xml")}"
  }
}
