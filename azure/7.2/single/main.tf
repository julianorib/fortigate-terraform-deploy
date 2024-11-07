// Resource Group

resource "azurerm_resource_group" "myterraformgroup" {
  name     = var.resourcegroup
  location = var.location

  tags = {
    environment = "Terraform Single FortiGate"
  }
}
