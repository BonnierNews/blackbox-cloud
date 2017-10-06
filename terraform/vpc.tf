resource "aws_vpc" "blackbox_vpc" {
  provider   = "aws.selected_region"
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    module = "blackbox-cloud"
  }
}

resource "aws_subnet" "blackbox_subnet" {
  provider   = "aws.selected_region"
  vpc_id     = "${aws_vpc.blackbox_vpc.id}"
  cidr_block = "${cidrsubnet(aws_vpc.blackbox_vpc.cidr_block, 4, 1)}"

  tags {
    module = "blackbox-cloud"
  }
}
resource "aws_internet_gateway" "gateway" {
  provider = "aws.selected_region"
  vpc_id   = "${aws_vpc.blackbox_vpc.id}"

  tags {
    module = "blackbox-cloud"
  }
}

resource "aws_default_route_table" "routes" {
  provider               = "aws.selected_region"
  default_route_table_id = "${aws_vpc.blackbox_vpc.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gateway.id}"
  }
}

resource "aws_security_group" "sec_group" {
  provider    = "aws.selected_region"
  vpc_id      = "${aws_vpc.blackbox_vpc.id}"
  name        = "blackbox-security"
  description = "Controls traffic to/from blackbox node"

  tags {
    module = "blackbox-cloud"
  }
}

resource "aws_security_group_rule" "allow_egress_all" {
  provider   = "aws.selected_region"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.sec_group.id}"
}

resource "aws_security_group_rule" "allow_ingress_ssh" {
  provider   = "aws.selected_region"
  type              = "ingress"
  from_port         = "22"
  to_port           = "22"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.sec_group.id}"
}

resource "aws_security_group_rule" "allow_ingress_https" {
  provider   = "aws.selected_region"
  type              = "ingress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.sec_group.id}"
}
