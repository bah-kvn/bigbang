
locals {
  env = merge(
    yamldecode(file(find_in_parent_folders("region.yaml"))),
    yamldecode(file(find_in_parent_folders("env.yaml"))),
    yamldecode(file(find_in_parent_folders("cluster.yaml")))
  )
}

terraform {
  source = "git::git@github.com:boozallen/terraform-aws-rke2-nlb.git"
}

#include {
#  path = find_in_parent_folders()
#}

inputs = {
  enable_cross_zone_load_balancing = local.env.controlplane_enable_cross_zone_load_balancing
  enable_deletion_protection       = local.env.controlplane_enable_deletion_protection
  internal                         = local.env.controlplane_internal
  name                             = local.env.cluster.name
  subnets                          = local.env.subnets
  tags                             = local.env.tags
  vpc_id                           = local.env.vpc
}

