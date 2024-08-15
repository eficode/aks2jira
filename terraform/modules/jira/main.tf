provider "helm" {
  kubernetes {
    host                    = var.kube_config.0.host
    client_certificate      = "${base64decode(var.kube_config.0.client_certificate)}"
    client_key              = "${base64decode(var.kube_config.0.client_key)}"
    cluster_ca_certificate  = "${base64decode(var.kube_config.0.cluster_ca_certificate)}" 
  }
}

# Install Prometheus/Grafana (helm install jira atlassian-data-center/jira --values ..\jira\values.yaml --namespace jira)
resource "helm_release" "monitoring" {
  count = "${terraform.workspace == "dev" ? 1 : 0}" # only on test
  
  name          = "prometheus"
  repository    = "https://prometheus-community.github.io/helm-charts"
  chart         = "kube-prometheus-stack"
  namespace     = "monitoring"
  values        = [ file("${path.module}/values-monitoring.yaml") ]
}

# Install Jira (helm install jira atlassian-data-center/jira --values ..\jira\values.yaml --namespace jira)
resource "helm_release" "jira" {
  count = "${terraform.workspace == "dev" ? 1 : 0}" # only on test
  
  name          = "jira"
  repository    = "https://atlassian.github.io/data-center-helm-charts" 
  chart         = "jira"
  namespace     = "jira"
  values        = [ file("${path.module}/values-jira.yaml") ]

  depends_on = [ helm_release.monitoring ]
}