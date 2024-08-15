# aks-terraform-setup

There are two ways setting up an environment. We describe both the scripted and the manual alternative.

Goal of both alternatives is to create a managed ecosystem on Azure that includes an AKS Cluster, an MSSQL Database-Server with two Databases, one shared and one local Filesystem and network components like public ip. 

In this setup, the managed user and the vnet including the subnets and are already existing. 

The overall architecture looks like following (does not include all comonents and services)

[AKS Architecture](./doc/aks-architecture.png)

## Tools

You will need bash|powershell, terraform, azurecli and helm.

1) Terraform - [install](https://www.terraform.io/downloads.html) (Remarks: Download and add to PATH)
2) Azure CLI - [install](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3) Helm - [install](https://helm.sh/docs/intro/install/)

## Initial setup (very first run)

### Prepare projects

1) Create a Storage Account in Azure to store the tfstate by executing (.ps1 on windows, .sh on linux):
```bash
./scripts/create_tfstate_storage.ps1|sh
```

This script will store necessary information like the access token as an environment variable. These environment variables are needed to run terraform commands like `terraform init`. 

2) Create a file `./terraform/modules/db/secrets.tf` by replacing the respective values with following content:
```bash
variable "dbadmin_name" {
  description = "A name for the DB Admin."
  type        = string
  sensitive   = true
  default     = "<db_username>"
}

variable "dbadmin_password" {
  description = "A password for the DB Admin."
  type        = string
  sensitive   = true
  default     = "<db_password>"
}
```

Make sure that username and password fulfills to your internal policies.

Important: Make sure ths file is included in .gitignore

3) Create folder and add CA certificates (IssuingCA01 and RootCA)
```bash
`./certs/all`
```

## Add new environment

### Prepare new environment
1) Create A Managed User in Resource Group rg-jira-fw01
```bash
Jira-uid-<env>
```

2) Add permissions to this user by adding Contributor on Resource Group Scope rg-tjira-fw01

3) Terraform is executed with the current user. In order to avoid different permission behaviour with different users, it is highly recommended to use a Sevice Principal user. Therefore:

3.1) Create a Service Principal (done by IT)
```bash
Jira-sp-terraform
```

This step needs to be done once only since it is not specific for a single environment.

This user and its information can be found in the Portal > Entra ID > App registrations > All applications
3.2) Set environment variables
3.2.1) Linux
```bash
export ARM_TENANT_ID="<tenantID>"
export ARM_SUBSCRIPTION_ID="<subscriptionID>"
export ARM_CLIENT_SECRET="<passwordNotSecretID>"
export ARM_CLIENT_ID="<appID>"
```
3.2.2) Windows
```bash
$env:ARM_TENANT_ID = "<tenantID>"
$env:ARM_SUBSCRIPTION_ID = "<subscriptionID>"
$env:ARM_CLIENT_SECRET = "<passwordNotSecretID>"
$env:ARM_CLIENT_ID = "<appID>"
```

4) Create Terraform Workspace, e.g. dev, prod
```bash
terraform workspace new <env>
```

You can list all the workspaces. The * indicates the workspace you're in.
```bash
terraform workspace list
```

5) Create folder and add TLS certificate
```bash
`./certs/<env>`
```

6) In file `./variables.tf`, extend `aks_vmsize` and `jira_domains` by adding values for the new environment

7) Create a file `./secrets.tf` with following content:
```bash
variable "cert_filename" {
  description = "The name for the SSL Cert."
  type        = string
  sensitive   = true
  default     = "<cert_filename>"
}

variable "cert_password_dev" {
  description = "The password for the SSL Cert."
  type        = string
  sensitive   = true
  default     = "<cert_password>"
}
```

Important: Make sure ths file is included in `.gitignore`

### Deploy new environment
(all commands from within the `./aks2jira` folder)

1) Install Azure Components with Terraform
```bash
terraform init
terraform plan
terraform apply
```

### Connect to AKS and Install Jira

1) Connect to newly created AKS cluster
```bash
az aks get-credentials --resource-group rg-jira-<env> --name jira-aks-<env>
```

2) If you are setting up JIRA with an unresolvable DNS name you need to update the helm values file: `./terraform/modules/jira/values-jira.yaml`
```bash
additionalHosts:
  - ip: "<ApplicationGatewayExternalIP>" 
    hostnames:
    - "<Hostname>"
```

3) Install JIRA with Helm
```bash
helm repo add atlassian-data-center https://atlassian.github.io/data-center-helm-charts
helm upgrade --install jira atlassian-data-center/jira --values ./terraform/modules/jira/values-jira.yaml --namespace jira
```

4) Install Prometheus/Grafana with Helm

> WIP: needs to be configured once there is application data @Anders

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts

helm upgrade --install prometheus prometheus-community/prometheus --values ./terraform/modules/jira/values-monitoring.yaml --namespace monitoring
```

### Network Policy
There is a Kubernetes Network Policy that is deployed on the environments per Default. It is blocking the egress traffic and only allows a few IPs for the ingress traffic since it should be avoided to send emails etc. to consumers and customers before the real GoLive.

It is important to delete this network policy once your environment is really live and you want the traffic explicitely.

In order to do so, run following command:
```bash
kubectl get netpol -n jira
kubectl delete netpol block-egress -n jira
kubectl get netpol -n jira
```

### Backup

1) DB Backup
A backup strategy is enabled during the creation of the Database. The default retention time is 7 days. The retention policy can be changed by an additional Terraform Block on the DB-Server. 

2) Enable Filesystem Backup in Azure
Jira creates a Storage Account in the Node Resource Group but comes without a Backup strategy. Therefore, the Backup needs to be manually enabled if needed.

In Azure Portal:
- go to `Resource Group` rg-jira-\<env\>-appgw
- click on `StorageAccount` (e.g. f420041aa669446b69c93df)
- on the left, click on `File shares` (under Data storage)
- click on the respective `PVC` (e.g. pvc-495b3e65-a7e3-4dce-9e1e-9438886ccd0f)
- on the left, click on `Backup`
- edit the chosen policy if you want to have a more than a daily backup
- enable Backup with default values

## Logging

Azure Loganalytics is a central workspace to store all types of logs. The rentenion time of the logs is 90 days per Default but can be set as you require. The amount of Logs need to be observed and components might be disabled. 

You can see the settings of the log on the `AKS-Cluster > Monitoring > Diagnostic Setting`. In our case following AKS Logs are enabled via the Diagnostic Setting `aks_diag` and should be observed in terms of storage usage:

<ul>
  <li>Kubernetes API Server</li>
  <li>Kubernetes Audit</li>
  <li>Kubernetes Audit Admin Logs</li>
  <li>Kubernetes Controller Manager</li>
  <li>Kubernetes Scheduler</li>
  <li>Kubernetes Cluster Autoscaler</li>
  <li>Kubernetes Cloud Controller Manager</li>
  <li>guard</li>
  <li>csi-azuredisk-controller</li>
  <li>csi-azurefile-controller</li>
  <li>csi-snapshot-controller</li>
  <li>AllMetrics</li>
 </ul> 

 The logs are visible at `AKS-Cluster > Monitoring > Logs` or in the specific Table in the Loganalytics Workspace.

 The usage can be checked at `Loganalytics > Settings > Usage and estimated costs`. 


## HowTo

### Update AKS

After the announced deprecation date, you have 30 days to upgrade your minor AKS version. It is not allowed to migrate two minor versions in a single upgrade process. (You can not update from version 1.11.x to 1.13.x, you must update to 1.12.x first). 

During the upgrade AKS will temporarily create a given number of new nodes with the new version. That's where the attribute `max_surge` is important. Microsoft recommends the value to be `33%`, so a third of orginal number of nodes will be created during the update process. Once the pods are switched to the new nodes, the old nodes are destroyed.

1) Check available AKS versions for your location for your cluster
```bash
az aks get-upgrades --resource-group rg-jira-<env> --name jira-aks-<env> --output table
```

2) Update version in file `./variables.tf` accordingly
```bash
k8s_version = "<version>"
```

This variable defines the version of the Cluster (`aks/kubernetes_version`) and the Nodes (`aks/default_node_pool/orchestrator_version`). If you ever want to run different versions between the Cluster and the Node you have to define a second variable.

3) Execute Terraform to do an upgrade:
```bash
terraform plan
terraform apply
```

Important: Cross check the output of plan to make sure that Terraform will not destroy your Cluster/Nodes.

## Needful Information

### References

> [Running Jira on an Azure cluster](https://confluence.atlassian.com/enterprise/running-jira-on-an-azure-cluster-969535564.html)<br/>
> [Running Jira Data Center on a Kubernetes cluster](https://confluence.atlassian.com/adminjiraserver/running-jira-data-center-on-a-kubernetes-cluster-1085180502.html)<br/>
> [Upgrading Jira Data Center with zero downtime](https://confluence.atlassian.com/adminjiraserver/upgrading-jira-data-center-with-zero-downtime-938846953.html)<br/>
> [Atlassian Data Center Helm Charts](https://atlassian.github.io/data-center-helm-charts/)<br/>
> [Quickstart: Create an Azure Kubernetes Service (AKS) cluster by using Terraform](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-terraform?tabs=azure-cli)<br/>
> [azurerm_mssql_server: Example Usage for Transparent Data Encryption(TDE) with a Customer Managed Key(CMK) during Create](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/)

### Remarks
> Show Terraform State: ```terraform state list```<br/>
> Remove all modules from the Terraform State: ```terraform state rm $(terraform state list)```<br/>
> AKS supports latest version minus two minor versions (if latest: 1.25.x so least: 1.23.x)<br/>
> Every quarter, a new minor version is released. So you should perform 4 upgrades a year<br/>
> Major version of Cluster and Nodes must be the same<br/>
> Nodes can not be higher versioned than the Cluster<br/>
> Minor version of Nodes must be within two minor versions of Cluster

### Important
> Never commit .tfstate files into version control as they contain sensitive information about your infrastructure!<br/>


### Azure Commands
```bash
# Show sku for database server in West Europe
az sql db list-editions -l westeurope -o table

# Show sku for VMs in West Europe
az vm list-skus -l westeurope -o table

# Show available AKS versions in West Europe 
az aks get-versions --location westeurope --output table

# Show available AKS versions for your AKS
az aks get-upgrades --resource-group <rg> --name <aks-cluster> -o table
```