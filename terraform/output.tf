output "instance_ip" {
  value = "${aws_instance.box.public_ip}"
}

output "dns_name" {
  value = "${aws_route53_record.dns_record.name}"
}
