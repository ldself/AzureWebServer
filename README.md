# Deploying a Web Server in Azure

## Introduction

The primary purpose of this project is to build an Iaas web server using Terraform.  Other tools are used to build the virtual machine images (Packer) and to create and design a policy (Azure CLI).

## Getting Started

1. [Create](https://portal.azure.com) an Azure account
2. [Install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) the Azure CLI
3. [Install](https://developer.hashicorp.com/packer/docs/install) Packer
4. [Install](https://developer.hashicorp.com/terraform/install) Terraform

## Dependencies

This project assumes that you already have a resource group created in your subscription.  Either create one through the Azure portal or by utilizing the CLI:

```sh
az login
az group create --name <resource-group-name> --location <location>
```  

You will need to know your subscription id and resource group name for the project parameters.  You will also need to create a service principal.  A service peincipal can be created utilizing the CLI:

```sh
az ad sp create-for-rbac --name <service-principal-name> --role Conributor --scopes "/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>"
```

The command outputs the following JSON:

```sh
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": <service-principal-name>,
  "password": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

Make note of the appId and the password.  Going forward, the appId will be used whenever the **client id** is needed, and the password will be used whenever the **client secret** is needed.  This is the only time the password/client secret will be available so do not forget to record it somewhere.

## Instructions

### Set the Azure Policy

The tagging-policy.json file in the Policy folder will force an indexed resources to have at least one tag.  The policy must first be created and then assigned to the appropriate scope.

To create this particular policy using the CLI, first navigate to the Policy folder and enter:

```sh
az policy definition create \
--name "deny-resources-without-tags" \
--display-name "Deny resources without tags" \
--description "Denies the creation of resources without tags." \
--rules "tagging-policy.json" \
--mode "Indexed" \
--metadata category=Tags
```

and to assign this policy to the scope of the resource group, enter:

```sh
az policy assignment create \
--name "deny-resources-without-tags-assignment" \
--policy "deny-resources-without-tags" \
--scope "/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>"
```

It takes a few minutes for the compliance monitoring to begin.

The existence of the policy assignment can be checked by executing the following:

```sh
az policy assignment list --scope "/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>"
```

### Create the virtual machine image

The server.json file in the Packer folder is used to define a virtual machine image.  To create the image, execute the following command:

```sh
packer build \
-var 'client_id=<client_id>' \
-var 'client_secret=<client_secret>' \
-var 'subscription_id=<subscription_id>' \
-var 'resource_group=<resource_group_name>' \
-var 'location=<location>' \
-var 'image_name_prefix=<prefix>' \
-var 'image_version=<image_version>' \
server.json
```

The image_name_prefix will be utilized again in the terraform step and will be specified by the `<prefix>` variable.  The image name will actually be saved as `<prefix>-image`.

## Create the resources utilizing Terraform

After the virtual machine image has been created in the resource group, the rest of the services can be created.  

Variables for the `main.tf` Terraform script are defined in the `terraform.tfvars` file.  Values for the variables are specified in the `vars.tf` file.  Most variables have default values so be sure to check those and modify them via the `vars.tf` file where appropriate.

Values that need to be specfied include:

* subscription_id
* resource_group_name
* prefix (be sure to use the same prefix as the vm image)

To execute the script you must first prepare your directory.  Navigate to the Terraform folder and execute:

```sh
terraform init
```

Then validate the files by executing

```sh
terraform validate
```

and correct any errors where appropriate.

An execution plan, which contains the actual variable-value-defined instructions, can be created by executing:

```sh
terraform plan -out solution.plan
```

Then the infrastructure can be created by executing:

```sh
terraform apply solution.plan
```

If everything executes correctly, then the public IP address of the load balancer (the output is defined in the `outputs.tf` file) is displayed on the screen.
