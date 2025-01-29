output "lb_ip" {
  value = "Load balance public IP: ${azurerm_public_ip.main.ip_address}"
}

