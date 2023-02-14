
locals {
  env = merge(
    yamldecode(file(find_in_parent_folders("region.yaml"))),
    yamldecode(file(find_in_parent_folders("env.yaml"))),
    yamldecode(file(find_in_parent_folders("cluster.yaml")))
  )
  image_id = run_cmd("sh", "-c", format("aws ec2 describe-images --owners 'aws-marketplace' --filters 'Name=product-code,Values=%s' --query 'sort_by(Images, &CreationDate)[-1].[ImageId]' --output 'text'", local.env.image_product_code))
}

terraform {
  source = "git::git@github.com:boozallen/terraform-aws-rke2-cluster.git"
}

include {
  path = find_in_parent_folders()
}

dependency "ssh" {
  config_path = "../ssh"
  mock_outputs = {
    public_key = "mock_public_key"
  }
}

dependency "elb" {
  config_path = "../elb"
  mock_outputs = {
    dns                   = "mock_dns"
    lb_addresses          = "mock_lb_addresses"
    server_url            = "mock_server_url"
    elb_target_group_arns = "mock_elb_target_group_arns"
  }
}

inputs = {
  ami                    = local.image_id
  agents                 = local.env.cluster.agent.replicas.desired
  agent_instance_type    = local.env.cluster.agent.type
  agent_instance_profile = local.env.cluster.agent.profile
  block_device_mappings = {
    size      = local.env.cluster.server.storage.size
    encrypted = local.env.cluster.server.storage.encrypted
    type      = local.env.cluster.server.storage.type
  }
  cluster_name                                  = local.env.cluster.name
  controlplane_allowed_cidrs                    = local.env.controlplane_allowed_cidrs
  controlplane_enable_cross_zone_load_balancing = local.env.controlplane_enable_cross_zone_load_balancing
  controlplane_internal                         = local.env.controlplane_internal
  domain                                        = local.env.domain
  download                                      = local.env.download
  elb_target_group_arns                         = dependency.elb.outputs.elb_target_group_arns
  enable_ccm                                    = local.env.enable_ccm
  extra_security_group_ids                      = local.env.cluster.extra_security_groups
  iam_instance_profile                          = local.env.cluster.server.profile
  instance_type                                 = local.env.cluster.server.type
  lb_addresses                                  = dependency.elb.outputs.lb_addresses
  nodepool_security_group_id                    = local.env.cluster.nodepool_security_group_id
  pre_userdata                                  = local.env.cluster.init_script
  rke2_config                                   = local.env.cluster.rke2_config
  rke2_version                                  = local.env.cluster.rke2_version
  server_url                                    = dependency.elb.outputs.dns
  servers                                       = local.env.cluster.server.replicas
  ssh_authorized_keys                           = [dependency.ssh.outputs.public_key]
  subnets                                       = local.env.subnets
  tags                                          = merge(local.env.region_tags, local.env.tags, {})
  vpc_id                                        = local.env.vpc
}




