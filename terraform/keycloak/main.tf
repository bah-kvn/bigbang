terraform {
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "3.9.1"
    }
  }
}

provider "keycloak" {
  client_id = "terraform"
  url = "https://keycloak.address.com"
}