#!/bin/bash

# CIS 4.4 - Configure iptables (Not Used)
set -e

echo "Configuring iptables for CIS compliance..."

echo "iptables is managed by UFW in this configuration"

# Ensure iptables services are not interfering with UFW
echo "Ensuring iptables services do not conflict with UFW..."
systemctl stop iptables 2>/dev/null || true
systemctl disable iptables 2>/dev/null || true

systemctl stop ip6tables 2>/dev/null || true
systemctl disable ip6tables 2>/dev/null || true

echo "iptables configuration completed successfully for CIS compliance."
