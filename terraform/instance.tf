data "aws_ami" "blackbox_ami" {
  provider   = "aws.selected_region"
  most_recent = true

  filter {
    name   = "name"
    values = ["blackbox-cloud/${var.blackbox_version}/*"]
  }
}

data "template_file" "cloud_init" {
  template = "${file("${path.module}/files/cloudinit.yaml")}"
  vars {
    fqdn          = "${local.instance_fqdn}"
    password_hash = "${var.blackbox_password_hash}"
    username      = "${var.os_username}"
  }
}

resource "aws_key_pair" "key_pair" {
  provider   = "aws.selected_region"
  key_name   = "blackbox"
  public_key = "${var.ssh_public_key}"
}

resource "aws_instance" "box" {
  provider      = "aws.selected_region"
  ami           = "${data.aws_ami.blackbox_ami.id}"
  instance_type = "${var.instance_type}"
  user_data     = "${data.template_file.cloud_init.rendered}"
  key_name      = "${aws_key_pair.key_pair.key_name}"

  vpc_security_group_ids      = ["${aws_security_group.sec_group.id}"]
  subnet_id                   = "${aws_subnet.blackbox_subnet.id}"
  associate_public_ip_address = true

  root_block_device {
    delete_on_termination = true
  }

  tags {
    module = "blackbox-cloud"
  }
}
