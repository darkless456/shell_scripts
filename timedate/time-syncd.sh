#!/bin/bash

# Update package list
apt-get update

# Install systemd-timesyncd
apt-get install -y systemd-timesyncd

# Enable systemd-timesyncd service
systemctl enable systemd-timesyncd

# Start systemd-timesyncd service
systemctl start systemd-timesyncd

# Check the status of the service
systemctl status systemd-timesyncd