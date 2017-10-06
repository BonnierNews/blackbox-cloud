data "aws_route53_zone" "zone" {
  name = "${var.dns_zone}"
}

resource "aws_route53_record" "dns_record" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "${local.instance_fqdn}"
  type    = "A"
  ttl     = "${var.dns_ttl}"
  records = ["${aws_instance.box.public_ip}"]
}
