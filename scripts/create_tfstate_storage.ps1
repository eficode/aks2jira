###
### This script creates a Resource Group with a storageaccount and a container to store the tfstates.
### When you run terraform init, the flags from TF_CLI_ARGS_init will be appended.
### It takes a few minutes until the Resource Group is created.
###

$RANDOM=Get-Random -Minimum 10000 -Maximum 99999
$RESOURCE_GROUP_NAME="jira-rg-tfstate"
$STORAGE_ACCOUNT_NAME="jiratfstate$RANDOM"
$CONTAINER_NAME="jiratfstate"
$LOCATION="westeurope"

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME

# Store Key of storageaccount as environment variable
$ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)
$Env:TF_VAR_tfstate_storageaccount_key=$ACCOUNT_KEY

# Store name of storageaccount as environment variable
$Env:TF_VAR_tfstate_storageaccount_name=$STORAGE_ACCOUNT_NAME

# create dynamic init arguments as environment variable
$Env:TF_CLI_ARGS_init="-backend-config='storage_account_name=$STORAGE_ACCOUNT_NAME' -backend-config='resource_group_name=$RESOURCE_GROUP_NAME' -backend-config='access_key=$ACCOUNT_KEY' -backend-config='container_name=jiratfstate' -backend-config='key=terraform.tfstate'"