locals {
  env = merge(
    yamldecode(file(find_in_parent_folders("region.yaml"))),
    yamldecode(file(find_in_parent_folders("env.yaml"))),
    yamldecode(sops_decrypt_file(find_in_parent_folders("env_secrets.yaml"))),
    yamldecode(file(find_in_parent_folders("cluster.yaml")))
  )

  # remove nulls from user configuration
  inputs = {
    for field, value in local.env :
    field => value
    if value != null
  }
}

terraform {
  #source = "git::git@github.com:boozallen/terraform-rancher-registration.git"
  source = "/usr/local/git/terraform-rancher-registration"
}

dependency "get_kubeconfig" {
  config_path = "../get_kubeconfig"
  mock_outputs = {
    kubeconfig_local_filename = "mock"
  }
}

dependency "rancher_config" {
  config_path = "../../rmc/rancher_config"
  mock_outputs = {
    rancher_url = "mock"
    token       = "mock"
  }
}

dependency "rmc_server" {
  config_path = "../../rmc/server"
  mock_outputs = {
    cluster_sg = "mock"
  }
}

inputs = merge(local.inputs, {
  api_url                = dependency.rancher_config.outputs.rancher_url
  kubeconfig_path        = dependency.get_kubeconfig.outputs.kubeconfig_local_filename
  cluster_name           = local.inputs.cluster.name
  kubernetes_version     = local.inputs.cluster.rke2_version
  token                  = dependency.rancher_config.outputs.rancher_token
  rancher_security_group = dependency.rmc_server.outputs.cluster_sg
})

