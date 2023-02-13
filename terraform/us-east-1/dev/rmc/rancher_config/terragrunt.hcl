
locals {
  env = merge(
    yamldecode(file(find_in_parent_folders("env.yaml"))),
    yamldecode(sops_decrypt_file(find_in_parent_folders("env_secrets.yaml"))),
  )

  # remove nulls from user configuration
  inputs = {
    for field, value in local.env :
    field => value
    if value != null
  }
}

terraform {
  source = "git::git@github.com:boozallen/terraform-rancher-bootstrap.git"
}

dependency "server" {
  config_path = "../server"
  mock_outputs = {
    api_url          = "mock"
    initial_password = "mock"
  }
}

dependencies {
  paths = ["../factory"]
}

inputs = merge(local.inputs, {
  api_url          = "https://rancher.${dependency.server.outputs.cluster_name}.${local.inputs.domain}"
  initial_password = local.inputs.data.rancher.password
})



