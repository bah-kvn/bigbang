
#locals {
#  env = merge(
#    yamldecode(file(find_in_parent_folders("region.yaml"))),
#    yamldecode(file(find_in_parent_folders("env.yaml"))),
#    yamldecode(file(find_in_parent_folders("cluster.yaml")))
#  )
#}

terraform {
  source = "git::git@github.com:boozallen/terraform-flux.git"
}

#include {
#  path = find_in_parent_folders()
#}

dependency "get_kubeconfig" {
  config_path = "../get_kubeconfig"
  mock_outputs = {
    kubeconfig_local_filename = "mock"
  }
}

inputs = {
  kubeconfig_path = dependency.get_kubeconfig.outputs.kubeconfig_local_filename
}

