# This file creates a new SSH key pair for accessing the bastion and cluster nodes

locals {
  env = merge(
    yamldecode(file(find_in_parent_folders("env.yaml"))),
    yamldecode(file(find_in_parent_folders("cluster.yaml")))
  )
}

terraform {
  source = "git::https://repo1.dso.mil/big-bang/customers/template//terraform/modules/ssh?ref=1.13.1"
}

#include {
#  path = find_in_parent_folders()
#}

inputs = {
  name = local.env.cluster.name
}
