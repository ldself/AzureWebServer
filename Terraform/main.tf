data "azurerm_resource_group" "main" {
    name = var.resource_group_name
}

# virtual network definition
resource "azurerm_virtual_network" "main" {
    name                = "${var.prefix}-${var.vnet_name}"
    address_space       = [var.vnet_cidr]
    location            = data.azurerm_resource_group.main.location
    resource_group_name = data.azurerm_resource_group.main.name

    tags = {
      "environment" = var.environment_tag
    }
}

# subnet definition
resource "azurerm_subnet" "main" {
    name                 = "${var.prefix}-${var.subnet_name}"
    resource_group_name  = data.azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = [var.subnet_cidr]
}

# network security group definition
resource "azurerm_network_security_group" "main" {
    name                = "${var.prefix}-${var.nsg_name}"
    location            = data.azurerm_resource_group.main.location
    resource_group_name = data.azurerm_resource_group.main.name

    security_rule {
        name                       = "Allow-http"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "${var.application_port}"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "Allow-Vnet-Access"
        priority                   = 4000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "${var.application_port}"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }

    security_rule {
        name                       = "Allow-LB-Access"
        priority                   = 4001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "AzureLoadBalancer"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "Deny-Internet-Access"
        priority                   = 4090
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "Allow-Vnet-Outbound"
        priority                   = 4000
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }



    tags = {
      "environment" = var.environment_tag
    }
}

# associate network security group with subnet
resource "azurerm_subnet_network_security_group_association" "main" {
    subnet_id                 = azurerm_subnet.main.id
    network_security_group_id = azurerm_network_security_group.main.id
}

# create network interface
resource "azurerm_network_interface" "main" {
    count               = var.vm_count
    name                = "${var.prefix}-nic-${count.index}"
    location            = data.azurerm_resource_group.main.location
    resource_group_name = data.azurerm_resource_group.main.name

    ip_configuration {
        primary                       = true
        name                          = "internal"
        subnet_id                     = azurerm_subnet.main.id
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
      "environment" = var.environment_tag
    }
}


# create public IP definition
resource "azurerm_public_ip" "main" {
    name                = "${var.prefix}-lb-Public-ip"
    location            = data.azurerm_resource_group.main.location
    resource_group_name = data.azurerm_resource_group.main.name
    allocation_method   = "Static"
    sku                 = "Standard"

    tags = {
      "environment" = var.environment_tag
    }
}

# load balancer definition
resource "azurerm_lb" "main" {
    name                = "${var.prefix}-lb"
    location            = data.azurerm_resource_group.main.location
    resource_group_name = data.azurerm_resource_group.main.name

    frontend_ip_configuration {
        name                 = "${var.prefix}-lb-pip"
        public_ip_address_id = azurerm_public_ip.main.id
    }

    
    tags = {
      "environment" = var.environment_tag
    }
}

# backend address pool definition
resource "azurerm_lb_backend_address_pool" "main" {
    loadbalancer_id = azurerm_lb.main.id
    name            = "${var.prefix}-lb-backend-pool"    
}

# health probe definition
resource "azurerm_lb_probe" "main" {
    name                           = "${var.prefix}-lb-probe"
    loadbalancer_id                = azurerm_lb.main.id
    port                           = var.application_port
    protocol                       = "Http"
    request_path                   = "/"
    interval_in_seconds            = 15
    number_of_probes               = 2
}

# associate network interface with backend address pool
resource "azurerm_network_interface_backend_address_pool_association" "main" {
    count                     = var.vm_count
    network_interface_id      = azurerm_network_interface.main[count.index].id
    ip_configuration_name     = "internal"
    backend_address_pool_id   = azurerm_lb_backend_address_pool.main.id
}

# associate network interface with load balancer
resource "azurerm_lb_rule" "main" {
    name                           = "${var.prefix}-lb-rule-http"
    loadbalancer_id                = azurerm_lb.main.id
    protocol                       = "Tcp"
    frontend_port                  = 80
    backend_port                   = var.application_port
    frontend_ip_configuration_name = azurerm_lb.main.frontend_ip_configuration[0].name
    backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
    probe_id                       = azurerm_lb_probe.main.id
}

resource "azurerm_availability_set" "main" {
    name                = "${var.prefix}-availability-set"
    location            = data.azurerm_resource_group.main.location
    resource_group_name = data.azurerm_resource_group.main.name

    tags = {
      "environment" = var.environment_tag
    }
}

resource "azurerm_linux_virtual_machine" "main" {
    count                 = var.vm_count
    name                  = "${var.prefix}-vm${count.index}"
    computer_name         = "${var.prefix}-vm${count.index}"
    resource_group_name   = data.azurerm_resource_group.main.name
    location              = data.azurerm_resource_group.main.location
    size                  = var.vm_size
    admin_username        = var.admin_username
    admin_password        = var.admin_password
    disable_password_authentication = false

    network_interface_ids = [azurerm_network_interface.main[count.index].id]
    availability_set_id = azurerm_availability_set.main.id

    source_image_id     = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Compute/images/${var.prefix}-image"

    os_disk {
        name                 = "${var.prefix}-vm${count.index}-osdisk"
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }
    
    tags = {
      "environment" = var.environment_tag
      "project_name" = "Terraform Lab"
    }    
}

# create managed disk
resource "azurerm_managed_disk" "main" {
    count                = var.vm_count
    name                 = "${var.prefix}-vm${count.index}-datadisk"
    location             = data.azurerm_resource_group.main.location
    resource_group_name  = data.azurerm_resource_group.main.name
    storage_account_type = "Standard_LRS"
    create_option        = "Empty"
    disk_size_gb         = 10

    tags = {
      "environment" = var.environment_tag
    }    
}

resource "azurerm_virtual_machine_data_disk_attachment" "main" {
    count              = var.vm_count
    managed_disk_id    = azurerm_managed_disk.main[count.index].id
    virtual_machine_id = azurerm_linux_virtual_machine.main[count.index].id
    lun                = 10 * count.index
    caching            = "ReadWrite"
}
