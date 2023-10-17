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

locals {
  resource_group = "Terraform-RG"
  location = "West Europe"
}

resource "azurerm_resource_group" "Terraform-RG" {
  name     = local.resource_group
  location = local.location
}

resource "azurerm_virtual_network" "terraform-vnet" {
  name                = "terraform-vnet"
  location            = local.location
  resource_group_name = azurerm_resource_group.Terraform-RG.name
  address_space       = ["10.0.0.0/16"]

  subnet {
    name           = "subnet1"
    address_prefix = "10.0.1.0/24"
  }

  tags = {
    environment = "Production"
  }
}