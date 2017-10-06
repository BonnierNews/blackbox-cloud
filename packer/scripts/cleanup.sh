#!/bin/bash
# Ensure we do not re-use machine-id:s. The file is regenerated on boot if empty (but not if missing!)
echo > /etc/machine-id

# Remove yum cache
yum -y --enablerepo='*' clean all

# Remove misc cruft
rm -rf /tmp/*
rpmdb --rebuilddb
rm -f /var/lib/rpm/__db*

# Ensure cloud-init runs on next boot
rm -rf /var/lib/cloud/*
