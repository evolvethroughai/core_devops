variable "resource_group_name" { type = string }
variable "location" { type = string }

# 1. Hub Virtual Network
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-eastus"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "hub_firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 2. Spoke Virtual Network (UAT)
resource "azurerm_virtual_network" "spoke_uat" {
  name                = "vnet-spoke-uat-eastus"
  address_space       = ["10.1.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "spoke_app" {
  name                 = "snet-uat-app"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke_uat.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "spoke_pe" {
  name                 = "snet-uat-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke_uat.name
  address_prefixes     = ["10.1.2.0/24"]
}

# 3. Bi-Directional VNet Peering (Hub <-> Spoke)
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-spoke-uat"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_uat.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-spoke-uat-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.spoke_uat.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
}

# 4. Network Security Group (NSG) for Spoke App Subnet
resource "azurerm_network_security_group" "app_nsg" {
  name                = "nsg-uat-app"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "app_nsg_assoc" {
  subnet_id                 = azurerm_subnet.spoke_app.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

# 5. User-Defined Route (UDR) forcing outbound traffic through Hub
resource "azurerm_route_table" "spoke_udr" {
  name                = "rt-uat-spoke"
  location            = var.location
  resource_group_name = var.resource_group_name

  route {
    name                   = "DefaultRouteToHub"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.4" # Simulated Hub Firewall IP
  }
}

resource "azurerm_subnet_route_table_association" "spoke_udr_assoc" {
  subnet_id      = azurerm_subnet.spoke_app.id
  route_table_id = azurerm_route_table.spoke_udr.id
}

# 6. Private DNS Zone for Blob Storage Private Link
resource "azurerm_private_dns_zone" "blob_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub_dns_link" {
  name                  = "link-hub-blob-dns"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob_dns.name
  virtual_network_id    = azurerm_virtual_network.hub.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_dns_link" {
  name                  = "link-spoke-uat-blob-dns"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob_dns.name
  virtual_network_id    = azurerm_virtual_network.spoke_uat.id
}

output "pe_subnet_id" { value = azurerm_subnet.spoke_pe.id }
output "blob_dns_zone_id" { value = azurerm_private_dns_zone.blob_dns.id }
