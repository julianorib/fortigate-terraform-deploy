resource "azurerm_subnet" "subnet009" {
  name                 = "subnet009"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = azurerm_virtual_network.fgtvnetwork.name
  address_prefixes     = [var.subnet009]
}

resource "azurerm_subnet_route_table_association" "subnet2009" {
  depends_on     = [azurerm_route_table.internal]
  subnet_id      = azurerm_subnet.subnet009.id
  route_table_id = azurerm_route_table.internal.id
}

variable "subnet009" {
  default = "10.208.9.0/24"
}

variable "nome" {
  type        = string
  description = "Nome do projeto"
  default     = "vmLinux"
}

variable "user-vm1" {
  type        = string
  description = "Usuario da Maquina Virtual 01"
  default     = "usuario"
}

variable "tag-dono" {
  type        = string
  description = "Dono do projeto"
  default     = "juliano"
}

variable "tag-ambiente" {
  type        = string
  description = "Ambiente do projeto"
  default     = "Testes"
}

variable "tag-ccusto" {
  type        = string
  description = "Centro de Custo do projeto"
  default     = "2009"
}


variable "sizevm" {
  type        = string
  description = "Tipo de Maquina Virtual"
  default     = "Standard_B1s"
}


locals {
  common_tags = {
    projeto  = var.nome
    ambiente = var.tag-ambiente
    dono     = var.tag-dono
    ccusto   = var.tag-ccusto
  }
}


resource "azurerm_network_interface" "nic-vm1" {
  name                = "${var.nome}-nic-vm1"
  location            = azurerm_resource_group.myterraformgroup.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  ip_configuration {
    name                          = "${var.nome}-ipconfig"
    subnet_id                     = azurerm_subnet.subnet009.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.common_tags
}

resource "azurerm_network_security_group" "nsg-vm1" {
  name                = "${var.nome}-nsg-vm1"
  location            = azurerm_resource_group.myterraformgroup.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}


resource "azurerm_network_interface_security_group_association" "nic_to_nsg" {
  network_interface_id      = azurerm_network_interface.nic-vm1.id
  network_security_group_id = azurerm_network_security_group.nsg-vm1.id
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "${var.nome}-vm1"
  location              = azurerm_resource_group.myterraformgroup.location
  resource_group_name   = azurerm_resource_group.myterraformgroup.name
  network_interface_ids = [azurerm_network_interface.nic-vm1.id]
  size                  = var.sizevm
  admin_username        = var.user-vm1

  admin_ssh_key {
    username   = var.user-vm1
    public_key = file("teste.pub")
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

  tags = local.common_tags
}