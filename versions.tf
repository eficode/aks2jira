terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.77.0"
    }
  }

  backend "azurerm" {
      #resource_group_name  = "" #set by script
      #storage_account_name = "" #set by script
      #container_name       = "" #set by script
      #key                  = "" #set by script
  }

  required_version = "~>1.6.1"
}

provider "azurerm" {
  features {
    key_vault {
      recover_soft_deleted_key_vaults = true
      purge_soft_delete_on_destroy    = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
