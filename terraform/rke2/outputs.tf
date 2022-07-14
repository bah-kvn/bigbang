output "k3s_cluster_endpoint" {
  description = "The IP address of the deployed instance"
  value       = aws_instance.rke2_cluster.private_ip
}

output "kubeconfig_path" {
  description = "The local location of the kubeconfig file"
  value       = local_sensitive_file.kube_config_server_yaml.filename
}

output "ssh_private_key_pem" {
  description = "SSH private key to allow following modules to ssh to the host"
  value       = tls_private_key.global_key.private_key_pem
  sensitive   = true
}

output "your_cluster_value" {
  description = "cluster value"
  value = local.name_prefix
}
