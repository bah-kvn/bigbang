# GitHub Terraform

Terraform which will create repos based on the template https://github.boozallencsn.com/Solutions-Center/bsf-deployment-template and add additional configuration.

## Authentication

See https://registry.terraform.io/providers/integrations/github/latest/docs#authentication

tldr; 

```bash
export GITHUB_TOKEN=asdf
```

## Deployment

IMPORTANT: Setup the remote state before running this module.

1. Edit versions.tf and replace NAME-OF-REPO with the name of the repo being created

Create a variables.tfvars file and populate with
> repository_description = "something"  
> repository_name = "something"

2. Ensure you are logged into the AWS account using AWSAML

3. Then run in your terminal:

```bash
terraform init
terraform apply -var-file="variables.tfvars"
```