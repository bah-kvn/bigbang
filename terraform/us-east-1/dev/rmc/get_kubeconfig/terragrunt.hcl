
locals {
  env = merge(
    yamldecode(file(find_in_parent_folders("region.yaml"))),
    yamldecode(file(find_in_parent_folders("env.yaml"))),
    yamldecode(file(find_in_parent_folders("cluster.yaml")))
  )
}

terraform {
  source = "git::git@github.com:boozallen/terraform-aws-get-kubeconfig.git"
}

include {
  path = find_in_parent_folders()
}

dependency "server" {
  config_path = "../server"
  mock_outputs = {
    cluster_name        = "mock"
    kubeconfig_bucket   = "mock"
    kubeconfig_filename = "mock"
    kubeconfig_local    = "mock"
  }
}

inputs = {
  cluster_name        = dependency.server.outputs.cluster_name
  kubeconfig_bucket   = dependency.server.outputs.kubeconfig_bucket
  kubeconfig_filename = dependency.server.outputs.kubeconfig_filename
  kubeconfig_local    = "../../../../kubeconfig"
}

