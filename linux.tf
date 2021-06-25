provider "azurerm" {
 features {}
  subscription_id = "2ec54521-cad5-4427-8676-e48e94ba0724"
  client_id = "5e9c700e-13f1-40a0-ab32-7a4ad26d5faf"
  client_secret = "mkYUhutx7~06cL_~pA9aMIamOIsAksiTov"
  tenant_id = "b50952ac-7887-4047-a495-00b98722e7ed"
}
 
resource "azurerm_resource_group" "main" {
 name = "${var.prefix}-resources"
 location = var.location
}


 
resource "azurerm_virtual_network" "main" {
 name = "${var.prefix}-network"
 address_space = ["10.0.0.0/16"]
 location = azurerm_resource_group.main.location
 resource_group_name = azurerm_resource_group.main.name
}
 
resource "azurerm_subnet" "internal" {
 name = "internal"
 resource_group_name = azurerm_resource_group.main.name
 virtual_network_name = azurerm_virtual_network.main.name
 address_prefixes = ["10.0.2.0/24"]
}
 
resource "azurerm_public_ip" "main" {
 name = "${var.prefix}-pip"
 resource_group_name = azurerm_resource_group.main.name
 location = azurerm_resource_group.main.location
 allocation_method = "Static"
}
 
resource "azurerm_resource_group" "example" {
 name = "example-resources"
 location = "West Europe"
}
 
resource "azurerm_network_security_group" "example" {
 name = "acceptanceTestSecurityGroup1"
 location = azurerm_resource_group.main.location
 resource_group_name = azurerm_resource_group.main.name
 
 security_rule {
 name = "test123"
 priority = 100
 direction = "Inbound"
 access = "Allow"
 protocol = "Tcp"
 source_port_range = "*"
 destination_port_range = "80"
 source_address_prefix = "*"
 destination_address_prefix = "*"
 }
 security_rule {
 name = "test124"
 priority = 200
 direction = "Inbound"
 access = "Allow"
 protocol = "Tcp"
 source_port_range = "*"
 destination_port_range = "22"
 source_address_prefix = "*"
 destination_address_prefix = "*"
 }
 
 tags = {
 environment = "Production"
 }
}
resource "azurerm_network_interface" "main" {
 name = "${var.prefix}-nic"
 resource_group_name = azurerm_resource_group.main.name
 location = azurerm_resource_group.main.location
 
 ip_configuration {
 name = "internal"
 subnet_id = azurerm_subnet.internal.id
 private_ip_address_allocation = "Dynamic"
 public_ip_address_id = azurerm_public_ip.main.id
 }
}
 
resource "azurerm_network_interface_security_group_association" "example" {
network_interface_id = azurerm_network_interface.main.id
network_security_group_id = azurerm_network_security_group.example.id
}
 
resource "azurerm_linux_virtual_machine" "main" {
 name = "${var.prefix}-vm"
 resource_group_name = azurerm_resource_group.main.name
 location = azurerm_resource_group.main.location
 size = "Standard_F2"
 admin_username = "adminuser"
 admin_password = "P@ssw0rd1234!"
 disable_password_authentication = false
 network_interface_ids = [
 azurerm_network_interface.main.id,
 ]
 
 source_image_reference {
 publisher = "Canonical"
 offer = "UbuntuServer"
 sku = "16.04-LTS"
 version = "latest"
 }
 
 os_disk {
 storage_account_type = "Standard_LRS"
 caching = "ReadWrite"
 }
 
 provisioner "remote-exec" {
 inline = [
 "sudo apt-get install apache2 -y",
 "sudo chown adminuser: /var/www/html",
 "sudo rm /var/www/html/index.html"
 
 
 ]
 
 connection {
 host = self.public_ip_address
 user = self.admin_username
 password = self.admin_password
 }
 }
 
 provisioner "file" {
 source = "index.html"
 destination = "/var/www/html/"
 
 connection {
 host = self.public_ip_address
 user = self.admin_username
 password = self.admin_password
 }
 
 }
}
