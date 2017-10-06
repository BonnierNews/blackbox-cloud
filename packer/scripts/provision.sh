#!/bin/bash
set -eu
set -o pipefail

echo "Installing blackbox_exporter ${BLACKBOX_VERSION}..."
useradd -rUM -s /sbin/nologin -d / blackbox_exporter
curl -sL https://github.com/prometheus/blackbox_exporter/releases/download/v${BLACKBOX_VERSION}/blackbox_exporter-${BLACKBOX_VERSION}.linux-amd64.tar.gz \
	| tar -xzC /usr/bin blackbox_exporter-${BLACKBOX_VERSION}.linux-amd64/blackbox_exporter --strip-components 1
chown blackbox_exporter:blackbox_exporter /usr/bin/blackbox_exporter /etc/sysconfig/blackbox_exporter
chmod 755 /usr/bin/blackbox_exporter
echo "Done"

echo "Installing haproxy..."
# Fix uploaded file permissions
chown -R root:root /etc/haproxy
chmod -R 600 /etc/haproxy/*
yum install -y https://s3.eu-central-1.amazonaws.com/public-rpms/haproxy-1.7.9-1.el7.centos.x86_64.rpm
# SELinux: Allow connections from haproxy to blackbox_exporter
semanage port --add --type http_port_t --proto tcp 9115
# Fix boot-script permissions
chmod +x /usr/local/bin/generate-haproxy-cert.sh
echo "Done"

echo "Reloading and enabling systemd units..."
systemctl daemon-reload
systemctl enable blackbox_exporter
systemctl enable haproxy
echo "Done"
