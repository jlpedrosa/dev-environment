

resource "azurerm_resource_group" "main" {
  name     = "${var.user}-dev-rg"
  location = var.location

  tags = {
    environment = "dev-machine"
  }

}

resource "azurerm_virtual_network" "main" {
  name                = "${var.user}-dev-network"
  address_space       = ["10.40.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "dev-machines"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = "10.40.1.0/24"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.user}-dev-vm-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.user}-dev-vm-nic-cfg"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.user}-ubuntu-dev-vm"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = var.vm_size

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.user}-ubuntu1804-dev-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.user}-ubuntu1804-dev"
    admin_username = var.user
    
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
        key_data = file("~/.ssh/id_rsa.pub")
        path = "/home/${var.user}/.ssh/authorized_keys"
    }
  }

    storage_data_disk {
        name              = "${var.user}-ubuntu1804-dev-data-disk"
        caching           = "ReadWrite"
        create_option     = "Empty"
        disk_size_gb      = "512"
        lun               = "1"
        write_accelerator_enabled = true
        managed_disk_type = "Premium_LRS"

    }
  

  tags = {
    environment = "dev-machine"
  }
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
        "fileUris"         : "https://raw.githubusercontent.com/jlpedrosa/dev-environment/master/config_server.sh",
        "commandToExecute" : "sh config_server.sh"
  }
SETTINGS

  tags = {
    environment = "dev-machine"
  }
}