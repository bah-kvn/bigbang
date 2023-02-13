
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
  source = "git::git@github.com:boozallen/terraform-helm-factory.git"
}

#include {
#  path = find_in_parent_folders()
#}

dependency "server" {
  config_path = "../server"
  mock_outputs = {
    cluster_hosted_zone_id = "mock"
    cluster_name           = "mock"
  }
}

dependency "get_kubeconfig" {
  config_path = "../get_kubeconfig"
  mock_outputs = {
    kubeconfig_local_filename = "mock"
  }
}

dependencies {
  paths = ["../server", "../get_kubeconfig", "../agent"]
}

inputs = merge(local.inputs, {
  bigbang_branch                       = local.inputs.factory.bigbang.branch
  bigbang_enabled                      = local.inputs.factory.bigbang.enabled
  bigbang_path                         = local.inputs.factory.bigbang.path
  bigbang_repo                         = local.inputs.factory.bigbang.repo
  cert_manager_enabled                 = local.inputs.factory.cert_manager.enabled
  cluster_aws_region                   = local.env.region
  cluster_domain                       = "${dependency.server.outputs.cluster_name}.${local.env.domain}"
  cluster_hosted_zone_id               = dependency.server.outputs.cluster_hosted_zone_id
  cluster_name                         = dependency.server.outputs.cluster_name
  external_dns_enabled                 = local.inputs.factory.external_dns.enabled
  factory_chart_repo                   = local.inputs.factory.chart.repo
  factory_chart_repo_password          = local.inputs.data.git.password
  factory_chart_repo_username          = local.inputs.data.git.username
  factory_chart_version                = local.inputs.factory.chart.version
  flux_enabled                         = local.inputs.factory.flux.enabled
  git_password                         = local.inputs.data.git.password
  git_username                         = local.inputs.data.git.username
  kubeconfig_path                      = dependency.get_kubeconfig.outputs.kubeconfig_local_filename
  lets_encrypt_email                   = local.inputs.factory.lets_encrypt.email
  lets_encrypt_issuer                  = local.inputs.factory.lets_encrypt.issuer
  longhorn_enabled                     = local.inputs.factory.longhorn.enabled
  rancher_chart_version                = local.inputs.factory.rancher.chart.version
  rancher_cloud_id                     = local.inputs.data.rancher.cloud.id
  rancher_cloud_secret                 = local.inputs.data.rancher.cloud.secret
  rancher_enabled                      = local.inputs.factory.rancher.enabled
  rancher_password                     = local.inputs.data.rancher.password
  rancher_url                          = "rancher.${dependency.server.outputs.cluster_name}.${local.inputs.domain}"
  registry_email                       = local.inputs.factory.registry.email
  registry_password                    = local.inputs.data.registry.password
  registry_username                    = local.inputs.data.registry.username
})

