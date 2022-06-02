terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.63.0"
    }
    acme = {
      source  = "vancluever/acme"
      version = "2.8.0"
    }
  }
  required_version = ">= 0.13"
}
  