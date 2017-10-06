# blackbox-cloud
This repo contains a [Packer](https://www.packer.io) template and [Terraform](https://www.terraform.io) module to build and deploy [Prometheus](https://prometheus.io) [blackbox probes](https://github.com/prometheus/blackbox_exporter) to AWS.

The probe is accessible over https only (by default, a self-signed cert is generated on first boot), and uses basic auth.

Main expected use case is to deploy several probes across different AWS regions, to perform external checking of services from multiple locations.

# Usage
To build your own probes, follow the below steps.

## Packer
The Packer template will generate an EC2 AMI containing the blackbox_exporter, and a reverse proxy for authentication. This AMI is then copied to a given set of AWS regions. 

To build it, run `packer build probe.json` in the packer directory, and fill in the required variables.

## Terraform
The Terraform module deploys the AMI built by Packer. To use it, pull in the module in your Terraform files:

```terraform
locals {
  blackbox_version = "0.9.1"
  blackbox_password_hash = "$1$uxV...R1" # Generated with eg 'openssl passwd -1 my-password'
  ssh_key = "ssh-rsa (...)"              # Public ssh key for logging in to machines (default username is blackbox)
  vpc_internal_cidr = "172.16.0.0/24"
  dns_name_prefix = "probe"              # Probe instance DNS records are on the form <prefix>-<region>-<vpc>.<domain>
}
data "aws_route53_zone" "probe-domain" {
  name = "example.com"
}

module "probe_eu-central-1" {
  region = "eu-central-1"
  source = "github.com/BonnierNews/blackbox-cloud//terraform"
  vpc_cidr = "${local.vpc_internal_cidr}"
  blackbox_version = "${local.blackbox_version}"
  blackbox_password_hash = "${local.blackbox_password_hash}"
  ssh_public_key = "${local.ssh_key}"
  dns_zone = "${data.aws_route53_zone.probe-domain.name}"
  dns_name_prefix = "${local.dns_name_prefix}"
}
module "probe_eu-west-1" {
  region = "eu-west-1"
  source = "github.com/BonnierNews/blackbox-cloud//terraform"
  vpc_cidr = "${local.vpc_internal_cidr}"
  blackbox_version = "${local.blackbox_version}"
  blackbox_password_hash = "${local.blackbox_password_hash}"
  ssh_public_key = "${local.ssh_key}"
  dns_zone = "${data.aws_route53_zone.probe-domain.name}"
  dns_name_prefix = "${local.dns_name_prefix}"
}

resource "aws_route53_record" "srv_record" {
  zone_id = "${data.aws_route53_zone.probe-domain.id}"
  name    = "probes.${data.aws_route53_zone.probe-domain.name}"
  type    = "SRV"
  ttl     = "3600"
  records = [
    "1 1 443 ${module.probe_eu-central-1.dns_name}",
    "1 1 443 ${module.probe_eu-west-1.dns_name}",
  ]
}
```

This will set up two probes in eu-central-1 and eu-west-1, and setup a SRV record which Prometheus can use to find the probes.

## Prometheus job
This is a basic job template for Prometheus to probe a single target from your probes:

```yaml
- job_name: 'blackbox-cloud'
  scheme: https
  basic_auth:
    username: blackbox
    password: my-password
  tls_config:
    insecure_skip_verify: true
  metrics_path: /probe
  params:
    module: [http_2xx]
    target: ['https://prometheus.io']
  dns_sd_configs:
  - names:
    - probes.example.com # The name of the SRV record created by Terraform above
  relabel_configs:
    - target_label: target
      source_labels: [__param_target]
    - target_label: region
      source_labels: [__address__]
      regex: 'probe-(.+)-vpc-.+'
      replacement: '$1'
```

This will give metrics like `probe_duration_seconds{instance="probe-eu-west-1-vpc-9db998f9.example.com:443",job="blackbox-cloud",region="eu-west-1",target="https://prometheus.io"} 0.079127814`.

Due to how the blackbox_exporter jobs are created, you will need to duplicate this job for each target you wish to probe. As an alternative, you could skip the SRV record and have multiple targets in each job and duplicate for each probe instead. See the blackbox_exporter documentation for an example of the approach.