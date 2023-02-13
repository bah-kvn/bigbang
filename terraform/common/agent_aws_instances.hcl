locals {
  env = merge(
    yamldecode(file(find_in_parent_folders("cluster.yaml")))
  )
}

terraform {
  source = "git::git@github.com:boozallen/terraform-aws-instances.git"
}

#include {
#  path = find_in_parent_folders()
#}

dependency "agent" {
  config_path = "../agent"
  mock_outputs = {
    cluster_name = "mock"
    pool         = "mock"
  }
}

inputs = {
  key  = local.env.cluster.name
  pool = dependency.agent.outputs.nodepool_name
}

