# This file sets up the RKE2 cluster generic agents in AWS using an autoscale group

locals {
  env = merge(
    yamldecode(file(find_in_parent_folders("region.yaml"))),
    yamldecode(file(find_in_parent_folders("env.yaml"))),
    yamldecode(file(find_in_parent_folders("cluster.yaml")))
  )
  image_id = run_cmd("sh", "-c", format("aws ec2 describe-images --owners 'aws-marketplace' --filters 'Name=product-code,Values=%s' --query 'sort_by(Images, &CreationDate)[-1].[ImageId]' --output 'text'", local.env.image_product_code))
}

terraform {
  source = "git::https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform.git//modules/agent-nodepool?ref=v2.1.0"
}

#include {
#  path = find_in_parent_folders()
#}

dependency "server" {
  config_path = "../server"
  mock_outputs = {
    cluster_data = {
      name       = "mock"
      cluster_sg = "mock"
      server_url = "mock"
      token      = { bucket = "mock", bucket_arn = "mock", object = "", policy_document = "{}" }
    }
  }
}

dependency "elb" {
  config_path = "../elb"
  mock_outputs = {
    lb_addresses      = "mock_lb_addresses"
    server_url        = "mock_server_url"
    target_group_arns = "mock_target_group_arns"
  }
}

dependency "ssh" {
  config_path = "../ssh"
  mock_outputs = {
    public_key = "mock_public_key"
  }
}

inputs = {
  ami = local.image_id
  asg = {
    min : local.env.cluster.agent.replicas.min,
    max : local.env.cluster.agent.replicas.max,
    desired : local.env.cluster.agent.replicas.desired
  }
  block_device_mappings = {
    size      = local.env.cluster.agent.storage.size
    encrypted = local.env.cluster.agent.storage.encrypted
    type      = local.env.cluster.agent.storage.type
  }
  cluster_data             = dependency.server.outputs.cluster_data
  download                 = local.env.download
  enable_autoscaler        = local.env.enable_autoscaler
  enable_ccm               = local.env.enable_ccm
  extra_security_group_ids = [dependency.server.outputs.cluster_data.cluster_sg]
  iam_instance_profile     = local.env.cluster.agent.profile
  instance_type            = local.env.cluster.agent.type
  name                     = "generic"
  pre_userdata             = local.env.cluster.init_script
  rke2_config              = local.env.cluster.rke2_config
  rke2_version             = local.env.cluster.rke2_version
  spot                     = local.env.spot
  ssh_authorized_keys      = [dependency.ssh.outputs.public_key]
  subnets                  = local.env.subnets
  tags                     = merge(local.env.region_tags, local.env.tags, {})
  vpc_id                   = local.env.vpc
}

