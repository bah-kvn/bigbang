
terraform {
  source = "git::git@github.com:boozallen/terraform-aws-instances.git"
}

#include {
#  path = find_in_parent_folders()
#}

dependency "server" {
  config_path = "../server"
  mock_outputs = {
    cluster_name = "mock"
    pool         = "mock"
  }
}

inputs = {
  key  = dependency.server.outputs.cluster_name
  pool = dependency.server.outputs.server_nodepool_name
}

