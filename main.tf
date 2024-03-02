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
  features { }
}

locals {
  resource_group = "Terraform-RG-2"
  location = "West Europe"
}

data "template_cloudinit_config" "linuxconfig" {
  gzip = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content = "packages: ['nginx']"
  }
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

resource "azurerm_linux_virtual_machine" "linux-vm-name" {
  name                = "terraform-linux-vm"
  resource_group_name = azurerm_resource_group.Terraform-RG.name
  location            = local.location
  size                = "Standard_F2"
  admin_username      = "linuxuser"
  # admin_password      = azurerm_key_vault_secret.key-secrect-name.value
  # availability_set_id = azurerm_availability_set.availability-set-name.id
  # disable_password_authentication = false
  custom_data = data.template_cloudinit_config.linuxconfig.rendered

  network_interface_ids = [
    azurerm_network_interface.nic-name.id
  ]

    admin_ssh_key {
    username   = "linuxuser"
    public_key = tls_private_key.ssh-private-key-name.public_key_openssh #private key will be stored in the
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  } 
  
  depends_on = [ 
    azurerm_network_interface.nic-name, 
    #azurerm_availability_set.availability-set-name,
    azurerm_key_vault_secret.key-secrect-name,
    tls_private_key.ssh-private-key-name
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

resource "azurerm_virtual_machine_data_disk_attachment" "data-disk-attachment-name" {
  managed_disk_id    = azurerm_managed_disk.disk_name.id
  virtual_machine_id = azurerm_linux_virtual_machine.linux-vm-name.id
  lun                = "0"
  caching            = "ReadWrite"
  depends_on = [ 
    azurerm_managed_disk.disk_name, 
    azurerm_linux_virtual_machine.linux-vm-name
   ]
}

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
    azurerm_key_vault.keyvault-name,
    azurerm_resource_group.Terraform-RG
   ]
}

#ssh-key
resource "tls_private_key" "ssh-private-key-name" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "local-file-name" {
  filename = "linuxkey.pem"
  content = tls_private_key.ssh-private-key-name.private_key_pem
}

resource "azurerm_app_service_plan" "plan-name" {
  name                = "terraform-plan-name"
  location            = local.location
  resource_group_name = azurerm_resource_group.Terraform-RG.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "app-service-name" {
  name                = "terraformapp00009274823"
  location            = local.location
  resource_group_name = azurerm_resource_group.Terraform-RG.name
  app_service_plan_id = azurerm_app_service_plan.plan-name.id

  site_config {
    dotnet_framework_version = "v6.0"
   # scm_type                 = "LocalGit"
  }

  # app_settings = {
  #   "SOME_KEY" = "some-value"
  # }

  # connection_string {
  #   name  = "Database"
  #   type  = "SQLServer"
  #   value = "Server=some-server.mydomain.com;Integrated Security=SSPI"
  # }

  source_control {
    repo_url = "https://github.com/alashro/webapp"
    branch = "master"
    manual_integration = true
    use_mercurial = false
  }
}
