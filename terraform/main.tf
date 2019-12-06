
locals {
  tags = {
    environment = "dev-machine"
    owner = var.user
  }
  user = var.user
}

resource "azurerm_resource_group" "main" {
  name     = "${local.user}-dev-rg"
  location = var.location
  tags = local.tags
}

resource "azurerm_network_security_group" "dev_subnet_security_group" {
  name                = "dev-subnet-sg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "allow_ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.dev_subnet_security_group.name
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.dev_subnet_security_group.id
}

resource "azurerm_virtual_network" "main" {
  name                = "${local.user}-dev-network"
  address_space       = ["10.40.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = local.tags
}

resource "azurerm_subnet" "internal" {
  name                 = "dev-machines"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = "10.40.1.0/24"

}

resource "azurerm_public_ip" "vmpubip" {
  name                = "${local.user}-dev-vm-nic-pub-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  tags = local.tags
}

resource "azurerm_network_interface" "main" {
  name                = "${local.user}-dev-vm-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${local.user}-dev-vm-nic-cfg"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vmpubip.id
  }
  tags = local.tags
  enable_accelerated_networking = true
}



resource "azurerm_virtual_machine" "main" {
  name                  = "${local.user}-ubuntu-dev-vm"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = var.vm_size

  delete_os_disk_on_termination = true


  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${local.user}-ubuntu1804-dev-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.user}-ubuntu1804-dev"
    admin_username = local.user
    
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
        key_data = file("~/.ssh/id_rsa.pub")
        path = "/home/${local.user}/.ssh/authorized_keys"
    }
  }

    storage_data_disk {
        name              = "${local.user}-ubuntu1804-dev-data-disk"
        caching           = "ReadWrite"
        create_option     = "Empty"
        disk_size_gb      = "512"
        lun               = "1"
        write_accelerator_enabled = false
        managed_disk_type = "Premium_LRS"

    }
    tags = local.tags
}

resource "azurerm_virtual_machine_extension" "main" {
  name                 = "install-dev-tools"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  virtual_machine_name = azurerm_virtual_machine.main.name
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
  {
        "fileUris"         : ["https://raw.githubusercontent.com/jlpedrosa/dev-environment/master/config_server.sh"],
        "commandToExecute" : "bash config_server.sh ${local.user}"
  }
SETTINGS

  tags = local.tags
}

resource "local_file" "foo" {
    sensitive_content = <<EOF
{
    user = ${local.user}
}
EOF
    filename = "${path.module}/installsettings.json"
}


resource "azurerm_storage_account" "dev-storage-account" {
  name                     = "${local.user}devsa"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = local.tags
}

resource "azurerm_storage_container" "dev-storage-account-container" {
  name                  = "installsettings"
  storage_account_name  = azurerm_storage_account.dev-storage-account.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "configsettings" {
  name                   = "installsettings.json"
  resource_group_name    = azurerm_resource_group.main.name
  storage_account_name   = azurerm_storage_account.dev-storage-account.name
  storage_container_name = azurerm_storage_container.dev-storage-account-container.name
  type                   = "Block"
  source                 = "installsettings.json"
}