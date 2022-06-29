variable "aws_subnet_id" {
  type        = string
  description = "VCD subnet used for all EC2 instances"
  default     = "subnet-08942469f925d9b66"
}

variable "aws_subnet_id_2" {
  type        = string
  description = "VCD subnet used for all EC2 instances"
  default     = "subnet-04987f9522e27a836"
}

variable "aws_subnet_id_3" {
  type        = string
  description = "VCD subnet used for all EC2 instances"
  default     = "subnet-069fd7685cca4018a"
}

variable "aws_vpc_id" {
  type        = string
  description = "AWS VPC ID"
  default     = "vpc-023a468241eea5b0b"
}

variable "aws_root_block_size" {
  type        = string
  description = "Size (in GB) of the root block device"
  default     = "250"
}

variable "aws_region" {
  type        = string
  description = "AWS region used for all resources"
  default     = "us-east-1"
}

variable "prefix" {
  type        = string
  description = "Prefix added to names of all resources"
  default     = "bsf-"
}

variable "terraform_project_name" {
  type        = string
  description = "Name that identifies the resource"
  default     = "cnn2"
}

variable "terraform_remote_state_name" {
  type        = string
  description = "name of the s3 bucket where the state is stored"
  default     = "bsf-dev-deployments"
}

variable "rke2_version" {
  type        = string
  description = "The version of RKE2 to install"
  default     = "v1.22.9+rke2r2"
}

variable "aws_instance_type" {
  type        = string
  description = "Instance type used for all EC2 instances"
  default     = "m5.2xlarge"
}

variable "aws_ami" {
  type        = string
  description = "AMI used for all EC2 instances"
  default     = "ami-0017560e0ce9d6fbf"
}

variable "aws_instance_profile" {
  type        = string
  description = "Ec2 role used for all EC2 instances"
  default     = "BSF_RKE2_ControlPlane_Role"
}

variable "aws_zone_id" {
  type        = string
  description = "Route53 Zone ID"
  default     = "Z035959739Z0LUKSAJZYX"
}

variable "dns_domain_tld" {
  type        = string
  description = "TLD to use"
  default     = "bahsoftwarefactory.com"
}

