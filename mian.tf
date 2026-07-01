locals {
  bucket_name = "${data.google_project.project_gc.name}-${terraform.workspace}-multicloud"
  rg_name     = "rg-${terraform.workspace}-empresa"
  vnet_name   = "vnet-empresa"
  location    = "westeurope"
}

terraform {

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }



  backend "gcs" {
    bucket      = "el-plan-iac-principal"
    prefix      = "terraform"
    credentials = "../el-plan-iac.json"
  }
}

provider "azurerm" {
  features {}
}

provider "google" {
  project     = "el-plan-iac"
  credentials = file("../el-plan-iac.json")
}

data "google_project" "project_gc" {}

resource "google_storage_bucket" "static-site" {
  depends_on = [data.google_project.project_gc]
  name       = local.bucket_name
  location   = "EU"
  versioning { enabled = true }
  force_destroy = true
}

resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = local.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "recursos_humanos" {
  name                 = "snet-recursos-humanos"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "almacen" {
  name                 = "snet-almacen"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "produccion" {
  name                 = "snet-produccion"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.10.0/27"]
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "pip-bastion"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-empresa"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

resource "azurerm_network_security_group" "nsg_rh" {
  name                = "nsg-recursos-humanos"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-to-almacen"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.2.0/24"

  }

  security_rule {
    name                       = "allow-to-produccion"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.3.0/24"
  }
  security_rule {
    name                       = "allow-icmp-to-almacen"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.2.0/24"
  }

  security_rule {
    name                       = "allow-internet-out"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    destination_address_prefix = "Internet"
    source_address_prefix      = "10.0.1.0/24"
  }

  security_rule {
    name                       = "deny-from-almacen"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }

  security_rule {
    name                       = "deny-from-produccion"
    priority                   = 310
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.3.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }


}

resource "azurerm_network_security_group" "nsg_almacen" {
  name                = "nsg-almacen"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-to-produccion"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "10.0.3.0/24"
  }

  security_rule {
    name                       = "allow-internet-out"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "deny-to-rh"
    priority                   = 300
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }

  security_rule {
    name                       = "allow-from-rh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.2.0/24"
  }

  security_rule {
    name                       = "allow-icmp-from-rh"
    priority                   = 240
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.2.0/24"
  }
}

resource "azurerm_network_security_group" "nsg_produccion" {
  name                = "nsg-produccion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-to-almacen"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.3.0/24"
    destination_address_prefix = "10.0.2.0/24"
  }

  security_rule {
    name                       = "allow-internet-out"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.3.0/24"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "deny-to-rh"
    priority                   = 300
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.3.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }
}

resource "azurerm_subnet_network_security_group_association" "assoc_rh" {
  subnet_id                 = azurerm_subnet.recursos_humanos.id
  network_security_group_id = azurerm_network_security_group.nsg_rh.id
}

resource "azurerm_subnet_network_security_group_association" "assoc_almacen" {
  subnet_id                 = azurerm_subnet.almacen.id
  network_security_group_id = azurerm_network_security_group.nsg_almacen.id
}

resource "azurerm_subnet_network_security_group_association" "assoc_produccion" {
  subnet_id                 = azurerm_subnet.produccion.id
  network_security_group_id = azurerm_network_security_group.nsg_produccion.id
}

resource "azurerm_network_interface" "nic_linux_prod" {
  name                = "nic-linux-prod"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.produccion.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "nic_win_rh" {
  name                = "nic-win-rh"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.recursos_humanos.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "nic_win_almacen" {
  name                = "nic-win-almacen"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.almacen.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm_linux_prod" {
  name                = "vm-linux-prod"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "adminlinux"
  network_interface_ids = [
    azurerm_network_interface.nic_linux_prod.id
  ]

  admin_password                  = "P@ssword1234!"
  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_disk {
    name                 = "osdisk-linux-prod"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_windows_virtual_machine" "vm_win_rh" {
  name                = "vm-win-rh"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2ms"
  admin_username      = "adminwin"
  admin_password      = "P@ssword1234!"
  network_interface_ids = [
    azurerm_network_interface.nic_win_rh.id
  ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    name                 = "osdisk-win-rh"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_windows_virtual_machine" "vm_win_almacen" {
  name                = "vm-win-almacen"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2ms"
  admin_username      = "adminwin"
  admin_password      = "P@ssword1234!"
  network_interface_ids = [
    azurerm_network_interface.nic_win_almacen.id
  ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    name                 = "osdisk-win-almacen"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-empresa"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "diag_vnet" {
  name                       = "diag-vnet"
  target_resource_id         = azurerm_virtual_network.vnet.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = false
      days    = 0
    }
  }
}





