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

# data "azurerm_subnet" "subnet1" {  //use data blocks when the resource doesn't have a specific azurerm mention, example "subnet1" here doesn't have a variable attached to it to call it from
#   name = "subnet1"
#   virtual_network_name = "terraform-vnet"
#   resource_group_name = azurerm_resource_group.Terraform-RG.name
# }

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "Terraform-RG" {
  name     = local.resource_group
  location = local.location
}

resource "azurerm_virtual_network" "terraform-vnet" {
  name                = "terraform-vnet"
  location            = local.location
  resource_group_name = azurerm_resource_group.Terraform-RG.name
  address_space       = ["10.0.0.0/16"]

  # subnet {
  #   name           = "subnet1"
  #   address_prefix = "10.0.1.0/24"
  # }
}

resource "azurerm_subnet" "subnet-name" {
  name                 = "subnet1"
  resource_group_name  = local.resource_group
  virtual_network_name = azurerm_virtual_network.terraform-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on = [ 
    azurerm_virtual_network.terraform-vnet
   ]
}

resource "azurerm_network_interface" "nic-name" {
  name                = "terraform-nic"
  location            = local.location
  resource_group_name = azurerm_resource_group.Terraform-RG.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet-name.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pub-name.id
  }

  depends_on = [ 
    azurerm_virtual_network.terraform-vnet, 
    azurerm_public_ip.pub-name,
    azurerm_subnet.subnet-name
  ]
}

resource "azurerm_windows_virtual_machine" "vm-name" {
  name                = "terraform-vm"
  resource_group_name = azurerm_resource_group.Terraform-RG.name
  location            = local.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = azurerm_key_vault_secret.key-secrect-name.value
  #availability_set_id = azurerm_availability_set.availability-set-name.id

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
  
  depends_on = [ 
    azurerm_network_interface.nic-name, 
    #azurerm_availability_set.availability-set-name,
    azurerm_key_vault_secret.key-secrect-name
  ]
}

resource "azurerm_public_ip" "pub-name" {
  name                = "terraform-pub"
  resource_group_name = azurerm_resource_group.Terraform-RG.name
  location            = local.location
  allocation_method   = "Static"
}

resource "azurerm_managed_disk" "disk_name" {
  name                 = "terraform_disk"
  location             = local.location
  resource_group_name  = azurerm_resource_group.Terraform-RG.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"
}

# resource "azurerm_virtual_machine_data_disk_attachment" "data-disk-attachment-name" {
#   managed_disk_id    = azurerm_managed_disk.disk_name.id
#   virtual_machine_id = azurerm_windows_virtual_machine.vm-name.id
#   lun                = "0"
#   caching            = "ReadWrite"
#   depends_on = [ 
#     azurerm_managed_disk.disk_name, azurerm_windows_virtual_machine.vm-name
#    ]
# }

# resource "azurerm_availability_set" "availability-set-name" {
#   name                = "terraform-aset"
#   location            = local.location
#   resource_group_name = azurerm_resource_group.Terraform-RG.name
#   platform_fault_domain_count = 3
#   platform_update_domain_count = 3
# }

# resource "azurerm_storage_account" "storage_name" {
#   name                     = "terraformstorage90004568"
#   resource_group_name      = azurerm_resource_group.Terraform-RG.name
#   location                 = azurerm_resource_group.Terraform-RG.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
  
# }

# resource "azurerm_storage_container" "container-name" {
#   name                  = "terraformcontainer"
#   storage_account_name  = azurerm_storage_account.storage_name.name
#   container_access_type = "blob"
# }

# resource "azurerm_storage_blob" "blob-name" {
#   name                   = "IIS_Config.ps1"
#   storage_account_name   = azurerm_storage_account.storage_name.name
#   storage_container_name = azurerm_storage_container.container-name.name
#   type                   = "Block"
#   source                 = "IIS_Config.ps1"
# }

# resource "azurerm_virtual_machine_extension" "extension-name" {
#   name                 = "hostname1"
#   virtual_machine_id   = azurerm_windows_virtual_machine.vm-name.id
#   publisher            = "Microsoft.Compute"
#   type                 = "CustomScriptExtension"
#   type_handler_version = "1.10"

#   depends_on = [ 
#     azurerm_storage_blob.blob-name
#    ]

# settings = <<SETTINGS
#     {
#         "fileUris": ["https://${azurerm_storage_account.storage_name.name}.blob.core.windows.net/terraformcontainer/IIS_Config.ps1"],
#           "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file IIS_Config.ps1"     
#     }
# SETTINGS


#NSG
resource "azurerm_network_security_group" "nsg-name" {
  name                = "terrafom-NSG"
  location            = local.location
  resource_group_name = azurerm_resource_group.Terraform-RG.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-association" {
  subnet_id                 = azurerm_subnet.subnet-name.id
  network_security_group_id = azurerm_network_security_group.nsg-name.id

  depends_on = [ 
    azurerm_network_security_group.nsg-name
   ]
}

#Key Vault
resource "azurerm_key_vault" "keyvault-name" {
  name                        = "terraformkeyvault0000654"
  location                    = local.location
  resource_group_name         = azurerm_resource_group.Terraform-RG.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

        key_permissions = [
      "Get",
    ]
    secret_permissions = [
      "Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore", "Set",
    ]
    storage_permissions = [
      "Get",
    ]
  }

  depends_on = [ 
    azurerm_resource_group.Terraform-RG
   ]
}

resource "azurerm_key_vault_secret" "key-secrect-name" {
  name         = "adminuser"
  value        = "P@$$w0rd1234!"
  key_vault_id = azurerm_key_vault.keyvault-name.id
  depends_on = [ 
    azurerm_key_vault.keyvault-name
   ]
}