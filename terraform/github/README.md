# GitHub Terraform

Terraform which will create repos based on the template https://github.boozallencsn.com/Solutions-Center/bsf-deployment-template and add additional configuration.

## Authentication

See https://registry.terraform.io/providers/integrations/github/latest/docs#authentication

tldr; 

```bash
export GITHUB_TOKEN=asdf
```

## Requirements

1. AWSAML - For remote state on S3
2. GitHub PAT for Deployment
    1. Repo Admin
    2. admin:pre_receive_hook
    3. [optional] delete_repo
3. GitHub PAT for Actions
    1. repo:status
    2. read:org
4. GitHub Repo template
    1. template repo must have default branch 'main'

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