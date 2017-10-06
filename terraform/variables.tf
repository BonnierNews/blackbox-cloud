# AWS
variable "region" {
  description = "The AWS region to deploy the probe to"
}

# VPC
variable "vpc_cidr" {
  description = "IPv4 CIDR to use in the VPC"
  default = "172.16.0.0/24"
}

# Blackbox
variable "blackbox_version" {
  description = "The AMI is found by searching for blackbox-cloud/<version>/*"
}
variable "blackbox_password_hash" {
  description = "The hashed password required to get access to the probe"
}

# Instance
variable "instance_type" {
  description = "Instance type to run the probe as"
  default = "t2.micro"
}
variable "ssh_public_key" {
  description = "Public SSH key to login to the probe"
}
variable "os_username" {
  description = "Username to use when logging in with SSH to the probe"
  default = "blackbox"
}

# DNS
variable "dns_zone" {
  description = "DNS zone under which records are to be created"
}
variable "dns_name_prefix" {
  description = "Prefix for the probe DNS record. Format is <prefix>-<region>-<vpc>.<domain>"
  default = "probe"
}
variable "dns_ttl" {
  description = "TTL for the probe DNS record"
  default = "3600"
}

# Computed variables
locals {
  instance_fqdn = "${var.dns_name_prefix}-${var.region}-${aws_vpc.blackbox_vpc.id}.${data.aws_route53_zone.zone.name}"
}
