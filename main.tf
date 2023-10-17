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

data "azurerm_subnet" "subnet1" {  //use data blocks when the resource doesn't have a specific azurerm mention, example "subnet1" here doesn't have a variable attached to it to call it from
  name = "subnet1"
  virtual_network_name = "terraform-vnet"
  resource_group_name = azurerm_resource_group.Terraform-RG.name
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

resource "azurerm_network_interface" "nic-name" {
  name                = "terraform-nic"
  location            = local.location
  resource_group_name = azurerm_resource_group.Terraform-RG.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [ azurerm_virtual_network.terraform-vnet ]
}

resource "azurerm_windows_virtual_machine" "vm-name" {
  name                = "terrafomr-vm"
  resource_group_name = azurerm_resource_group.Terraform-RG.name
  location            = local.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.nic-name.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  
  depends_on = [ azurerm_network_interface.nic-name ]
}