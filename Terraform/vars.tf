# account variables

variable "subscription_id" {
    description = "The subscription id provided by the lab"
    type        = string
}

variable "resource_group_name" {
    description = "The name of the resource group provided by the lab"
    type        = string
}

# tab variables
variable "environment_tag" {
    description = "Environment tag for resources"
    type        = string
    default     = "dev"
}

# naming variables
variable "prefix" {
    description = "Naming prefix for resources.  Should be 3-8 characters."
    type        = string
    default = "websvr"

    validation {
        condition     = length(var.prefix) >= 3 && length(var.prefix) <= 8
        error_message = "The prefix must be between 3 and 8 characters.  Submitted value was ${length(var.prefix)}."
    }
}

# network variables

variable "vnet_name" {
    description = "The name of the vnet provided by the lab"
    type        = string
    default     = "vnet"
}

variable "vnet_cidr" {
    description = "The CIDR block for the vnet provided to use in the lab.  Defaults to 10.0.0.0/16"
    type        = string
    default     = "10.0.0.0/16"
}

variable "subnet_name" {
    description = "The name of the subnet provided to use in the vnet.  Defaults to web"
    type        = string
    default     = "websubnet"
}

variable "subnet_cidr" {
    description = "The CIDR block for the subnet provided to use in the lab.  Defaults to 10.0.1.0/24"
    type        = string
    default     = "10.0.1.0/24"
}

variable "nsg_name" {
    description = "The name of the network security group provided to use in the vnet.  Defaults to web"
    type        = string
    default     = "webnsg"
}

# application variables

variable "application_port" {
    description = "Port to use for the flask application.  Defaults to 8080."
    type        = number
    default     = 8080
}

variable "vm_size" {
    description = "Size of the VM to deploy.  Defaults to Standard_D2s_v3."
    type        = string
    default     = "Standard_D2s_v3"
}

variable "vm_count" {
    description = "Number of instances in the VM.  Defaults to 2."
    type        = number
    default     = 2

    validation {
        condition     = var.vm_count >= 2 && var.vm_count <= 5
        error_message = "VM count must be between 2 and 5.  Submitted value was ${var.vm_count}."
    }
}

variable "admin_username" {
    description = "Admin username for virtual machine.  Defaults to azureuser"
    type        = string
    default = "azureuser"
}

variable "admin_password" {
    description = "Admin password for virtual machine.  Defaults to Pa$$w0rd1234"
    type        = string
    default = "Pa$$w0rd12345!"
    validation {
        condition     = length(var.admin_password) >= 12 && length(var.admin_password) <= 72
        error_message = "The prefix must be between 12 and 72 characters.  Submitted value was ${length(var.admin_password)}."
    }
}