# Local resources

# Save SSH key pair locally for development purposes
resource "local_sensitive_file" "ssh_private_key_pem" {
  filename        = "auth/${var.terraform_project_name}/id_rsa"
  content         = tls_private_key.global_key.private_key_pem
  file_permission = "0600"
  depends_on      = [tls_private_key.global_key]
}

resource "null_resource" "upload_ssh_private_key_pem" {
  depends_on = [local_sensitive_file.ssh_private_key_pem]
  provisioner "local-exec" {
    command = "aws s3 cp auth/${var.terraform_project_name}/id_rsa s3://${var.terraform_remote_state_name}/${var.terraform_project_name}/auth/id_rsa"
  }
}

resource "local_file" "ssh_public_key_openssh" {
  filename   = "auth/${var.terraform_project_name}/id_rsa.pub"
  content    = tls_private_key.global_key.public_key_openssh
  depends_on = [tls_private_key.global_key]
}

resource "null_resource" "upload_ssh_private_key_openssh" {
  depends_on = [local_file.ssh_public_key_openssh]
  provisioner "local-exec" {
    command = "aws s3 cp auth/${var.terraform_project_name}/id_rsa.pub s3://${var.terraform_remote_state_name}/${var.terraform_project_name}/auth/id_rsa.pub"
  }
}

# Save kubeconfig file for interacting with the RKE cluster on your local machine
resource "local_sensitive_file" "kube_config_server_yaml" {
  filename   = "auth/${var.terraform_project_name}/kubeconfig.yaml"
  content    = data.external.kubeconfig.result["kubeconfig"]
  depends_on = [data.external.kubeconfig]
}

resource "null_resource" "upload_kube_config_server_yaml" {
  depends_on = [local_sensitive_file.kube_config_server_yaml]
  provisioner "local-exec" {
    command = "aws s3 cp auth/${var.terraform_project_name}/kubeconfig.yaml s3://${var.terraform_remote_state_name}/${var.terraform_project_name}/auth/kubeconfig.yaml"
  }
}
