terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.1"
    }
  }

  backend "s3" {
    bucket = "bah-bsf-terraform-state"
    #key    = "github-repos/NAME-OF-REPO" # Replace NAME-OF-REPO to match the name of the repo
    key            = "github-repos/bsf-deployment-scott-final" # Replace NAME-OF-REPO to match the name of the repo
    dynamodb_table = "bah-bsf-terraform-state"
    region         = "us-east-1"
  }
}

provider "github" {
  base_url = var.github_base_url
  owner    = var.github_owner
}

provider "null" {
  # Configuration options
}