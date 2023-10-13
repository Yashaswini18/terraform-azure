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

resource "azurerm_resource_group" "Terraform-RG" {
  name     = "Terraform-RG"
  location = "West Europe"
}

resource "azurerm_storage_account" "terrformsltistorage" {
  name                     = "terrformsltistorage"
  resource_group_name      = azurerm_resource_group.Terraform-RG.name
  location                 = azurerm_resource_group.Terraform-RG.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "staging"
  }
}

resource "azurerm_storage_container" "testcontianer" {
  name                  = "testcontianer"
  storage_account_name  = azurerm_storage_account.terrformsltistorage.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "testblob" {
  name                   = "some-local-file.txt"
  storage_account_name   = azurerm_storage_account.terrformsltistorage.name
  storage_container_name = azurerm_storage_container.testcontianer.name
  type                   = "Block"
  source                 = "some-local-file.txt"
  depends_on = [ 
    azurerm_storage_account.terrformsltistorage
   ]
}