variable "resourcename" {
  default = "gitlab-resource-group"
}

#subscription_id = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#client_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#client_secret   = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#tenant_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Configure the Microsoft Azure Provider
provider "azurerm" {
    
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "gitlabgroup" {
    name     = "gitlab-resource-group"
    location = "eastus"

    tags {
        environment = "Gitlab Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "gitlabnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.gitlabgroup.name}"

    tags {
        environment = "Gitlab Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "gitlabsubnet" {
    name                 = "mySubnet"
    resource_group_name  = "${azurerm_resource_group.gitlabgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.gitlabnetwork.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "gitlabpublicip" {
    name                         = "myPublicIP"
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.gitlabgroup.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "Gitlab Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "gitlabnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.gitlabgroup.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTP"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTPS"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "Gitlab Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "gitlabnic" {
    name                      = "myNIC"
    location                  = "eastus"
    resource_group_name       = "${azurerm_resource_group.gitlabgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.gitlabnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.gitlabsubnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.gitlabpublicip.id}"
    }

    tags {
        environment = "Gitlab Demo"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.gitlabgroup.name}"
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.gitlabgroup.name}"
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "Gitlab Demo"
    }
}

resource "azurerm_managed_disk" "gitlabdata" {
  name                 = "gitlabdata_existing"
  location             = "${azurerm_resource_group.gitlabgroup.location}"
  resource_group_name  = "${azurerm_resource_group.gitlabgroup.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "512"
}

# Create virtual machine
resource "azurerm_virtual_machine" "gitlabvm" {
    name                  = "gitlabhostvm"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.gitlabgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.gitlabnic.id}"]
    vm_size               = "Standard_B2s"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_data_disk {
        name            = "${azurerm_managed_disk.gitlabdata.name}"
        managed_disk_id = "${azurerm_managed_disk.gitlabdata.id}"
        create_option   = "Attach"
        lun             = 0
        disk_size_gb    = "${azurerm_managed_disk.gitlabdata.disk_size_gb}"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "gitlabhostvm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFbsGEDOs83SnJ6TeTDSZEBTqMTEt8q/aD4eiGAV6ms2L0sBNwGJR0EsQHzHA7bQ+rS1vAL8Ce69j6CyyqC21cdeepOjP+1Dt15qJU7AK3FZcQWxApqdbCMV373oyK7HqZGLa8TuCmaScsQpdzX2xh1yzPfSHHPeaE+OfZbvu5bET78yALnEUrKn1ClFQE5Z39McW2AViTOnoOY4a3kPZp8AXbZPUERy+GM6KglltalHmLEToy82dN3LQnzdS6o83MF0OTW705Nc/en4eHl3WSJ+pKos4ckB7Jpaaxemu7X8aKC5eKKgJ1wf5FXXTDzeOJVlI/YbTSfMBGxKE6VJx/ michael@DESKTOP-2OFI6F3"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Gitlab Demo"
    }
}

resource "azurerm_virtual_machine_extension" "rungitlab" {
  name                 = "gitlabhostvm"
  location             = "eastus"
  resource_group_name  = "${azurerm_resource_group.gitlabgroup.name}"
  virtual_machine_name = "${azurerm_virtual_machine.gitlabvm.name}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "fileUris": ["https://raw.githubusercontent.com/MichaelSL/az-powershell/master/gitlab/gitlab.sh"],
        "commandToExecute": "sudo ./gitlab.sh"
    }
SETTINGS

  tags {
    environment = "Gitlab Demo"
  }
}