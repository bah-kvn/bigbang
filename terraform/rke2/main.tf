
locals {
  admin_username = "ubuntu"
  kube_url       = "kubernetes.${var.terraform_project_name}.${var.dns_domain_tld}"
  kube_port      = 6443
  name_prefix    = "${var.prefix}${var.terraform_project_name}"
  region         = var.aws_region
}

####################################################
# Generate SSH key pair
####################################################
resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Temporary key pair used for SSH accesss
resource "aws_key_pair" "ec2_instance" {
  key_name   = "bsf-${var.terraform_project_name}"
  public_key = tls_private_key.global_key.public_key_openssh
  depends_on = [tls_private_key.global_key]
}

####################################################
# Create EC2 instance and install RKE2
####################################################
provider "aws" {
  region = var.aws_region
}

data "template_file" "master_node" {
  template = file("scripts/install-rke2.sh")

  vars = {
    rke2_version = var.rke2_version
    domain_tld   = var.dns_domain_tld
    kube_url     = local.kube_url
    project_name = var.terraform_project_name
  }
}

resource "aws_instance" "rke2_cluster" {
  ami                         = var.aws_ami
  instance_type               = var.aws_instance_type
  subnet_id                   = var.aws_subnet_id
  key_name                    = aws_key_pair.ec2_instance.key_name
  security_groups             = [aws_security_group.devnodes_sg.id]
  user_data                   = data.template_file.master_node.rendered
  associate_public_ip_address = true
  depends_on                  = [aws_key_pair.ec2_instance, aws_security_group.devnodes_sg]

  root_block_device {
    volume_size = var.aws_root_block_size
  }

  tags = {
    Name                                                               = "${local.name_prefix}-a"
    "kubernetes.io/cluster/${var.prefix}${var.terraform_project_name}" = "owned"
  }

  provisioner "remote-exec" {
    inline = ["cloud-init status --wait > /dev/null"]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = local.admin_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }
}

data "external" "kubeconfig" {
  depends_on = [aws_route53_record.k8s_test]
  program    = ["bash", "scripts/get_kube_config.sh"]

  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    keypath      = "auth/${var.terraform_project_name}/id_rsa"
    hostip       = aws_instance.rke2_cluster.public_ip
    cluster_name = local.name_prefix
    dns_name     = local.kube_url
  }
}

data "external" "node_token" {
  program = ["bash", "scripts/get_node_token.sh"]

  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    keypath = "auth/${var.terraform_project_name}/id_rsa"
    hostip  = aws_instance.rke2_cluster.public_ip
  }
}

####################################################
# Create template file for nodes
####################################################

data "template_file" "extra_nodes" {
  template = file("scripts/install-rke2-node.sh")

  vars = {
    rke2_version = var.rke2_version
    domain_tld   = var.dns_domain_tld
    rke2_master  = aws_instance.rke2_cluster.private_ip
    node_token   = data.external.node_token.result.node_token
    kube_url     = local.kube_url
    project_name = var.terraform_project_name
  }
}

####################################################
# Create additional nodes (node b)
####################################################

resource "aws_instance" "rke2_cluster_node_b" {
  ami                         = var.aws_ami
  instance_type               = var.aws_instance_type
  subnet_id                   = var.aws_subnet_id
  key_name                    = aws_key_pair.ec2_instance.key_name
  security_groups             = [aws_security_group.devnodes_sg.id]
  user_data                   = data.template_file.extra_nodes.rendered
  associate_public_ip_address = true
  depends_on                  = [aws_key_pair.ec2_instance, aws_instance.rke2_cluster]

  root_block_device {
    volume_size = var.aws_root_block_size
  }

  tags = {
    Name                                                               = "${local.name_prefix}-b"
    "kubernetes.io/cluster/${var.prefix}${var.terraform_project_name}" = "owned"
  }

  provisioner "remote-exec" {
    inline = ["cloud-init status --wait > /dev/null"]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = local.admin_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }
}

####################################################
# Create additional nodes (node c)
####################################################

resource "aws_instance" "rke2_cluster_node_c" {
  ami                         = var.aws_ami
  instance_type               = var.aws_instance_type
  subnet_id                   = var.aws_subnet_id
  key_name                    = aws_key_pair.ec2_instance.key_name
  security_groups             = [aws_security_group.devnodes_sg.id]
  user_data                   = data.template_file.extra_nodes.rendered
  associate_public_ip_address = true
  depends_on                  = [aws_key_pair.ec2_instance, aws_instance.rke2_cluster_node_b]

  root_block_device {
    volume_size = var.aws_root_block_size
  }

  tags = {
    Name                                                               = "${local.name_prefix}-c"
    "kubernetes.io/cluster/${var.prefix}${var.terraform_project_name}" = "owned"
  }

  provisioner "remote-exec" {
    inline = ["cloud-init status --wait > /dev/null"]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = local.admin_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }
}

###################################################
# Identify User public IP
###################################################
data "external" "get_public_ip" {
  program = ["bash", "scripts/get_public_ip.sh"]
}

###################################################
# Create Security group for dev nodes
###################################################

resource "aws_security_group" "devnodes_sg" {
  depends_on = [data.external.get_public_ip]

  name        = "allow_devnodes_communication"
  description = "Allow DevNodes communication"
  vpc_id      = var.aws_vpc_id

  ingress {
    description = "var.terraform_project_name"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${data.external.get_public_ip.result.public_ip}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name                                                               = "allow_devnodes_communication"
    "kubernetes.io/cluster/${var.prefix}${var.terraform_project_name}" = "owned"
  }
}

resource "aws_security_group_rule" "cluster_communication" {
  depends_on        = [aws_security_group.devnodes_sg]
  type              = "ingress"
  self              = true
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.devnodes_sg.id
}

###################################################
# Register CNAME for Kubernetes
###################################################
resource "aws_route53_record" "k8s_test" {
  depends_on = [aws_instance.rke2_cluster]
  zone_id    = var.aws_zone_id
  name       = local.kube_url
  type       = "A"
  ttl        = "60"
  records    = [aws_instance.rke2_cluster.public_ip]
}


###################################################
# Tagging resources
###################################################

resource "aws_ec2_tag" "aws_subnet_id" {
  resource_id = var.aws_subnet_id
  key         = "kubernetes.io/cluster/${var.prefix}${var.terraform_project_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "aws_subnet_id_2" {
  resource_id = var.aws_subnet_id_2
  key         = "kubernetes.io/cluster/${var.prefix}${var.terraform_project_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "aws_subnet_id_3" {
  resource_id = var.aws_subnet_id_3
  key         = "kubernetes.io/cluster/${var.prefix}${var.terraform_project_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "aws_vpc_id" {
  resource_id = var.aws_vpc_id
  key         = "kubernetes.io/cluster/${var.prefix}${var.terraform_project_name}"
  value       = "shared"
}

