
output "public_ip" {
    value = azurerm_public_ip.vmpubip.ip_address
}