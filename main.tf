terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "92813963-bb62-468f-b6b4-bda395b75676"
  client_id = "f5efa60c-6afa-4094-9378-f61d8683941a"
  client_secret = "pIb8Q~byx_3iBd4OmISpydLZqolqFjfswYlTGbUG"
  tenant_id = "02aa9fc1-18bc-4798-a020-e01c854dd434"
  features { }
}

variable "storage_account_name" {
  type = string
  description = "Please enter a storage account name"
}

locals {
  resource_group = "Terraform-RG"
  location = "West Europe"
}

resource "azurerm_resource_group" "Terraform-RG" {
  name     = local.resource_group
  location = local.location
}

resource "azurerm_storage_account" "terrformsltistorage" {
  name                     = var.storage_account_name
  resource_group_name      = local.resource_group
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "staging"
  }
}

resource "azurerm_storage_container" "testcontianer" {
  name                  = "testcontianer"
  storage_account_name  = var.storage_account_name
  container_access_type = "private"
    depends_on = [ 
    azurerm_storage_account.terrformsltistorage
   ]
}

resource "azurerm_storage_blob" "testblob" {
  name                   = "some-local-file.txt"
  storage_account_name   = var.storage_account_name
  storage_container_name = azurerm_storage_container.testcontianer.name
  type                   = "Block"
  source                 = "some-local-file.txt"
  depends_on = [ 
    azurerm_storage_account.terrformsltistorage
   ]
}