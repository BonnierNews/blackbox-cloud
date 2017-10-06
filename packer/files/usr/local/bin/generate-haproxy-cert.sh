#!/bin/bash
CERT_CN=$(hostnamectl --static)
openssl req -newkey rsa:2048 -keyout /etc/haproxy/probe.pem -days 3650 -nodes -subj "/OU=blackbox-cloud/CN=${CERT_CN}" | \
	openssl x509 -req -signkey /etc/haproxy/probe.pem >> /etc/haproxy/probe.pem