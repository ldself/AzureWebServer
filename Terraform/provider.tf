provider "azurerm" {
  features {}
  environment = "public"
  resource_provider_registrations = "none"
  subscription_id = var.subscription_id
}