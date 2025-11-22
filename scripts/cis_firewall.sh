#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# CIS 4.1-4.2 - Configure UncomplicatedFirewall
set -e

echo "Configuring UncomplicatedFirewall for CIS compliance..."

# CIS 4.1.1 Ensure a single firewall configuration utility is in use (Automated)
echo "Ensuring single firewall configuration utility (UFW)..."

# CIS 4.2.1 Ensure ufw is installed (Automated)
echo "Installing ufw..."
apt-get install -y ufw

# CIS 4.2.2 Ensure iptables-persistent is not installed with ufw (Automated)
echo "Checking for iptables-persistent..."
if dpkg-query -s iptables-persistent &>/dev/null; then
    echo "iptables-persistent is installed - removing..."
    apt-get purge -y iptables-persistent
else
    echo "iptables-persistent is not installed"
fi

# CIS 4.2.3 Ensure ufw service is enabled (Automated)
echo "Enabling ufw service..."
systemctl enable ufw

# CIS 4.2.4 Ensure ufw loopback traffic is configured (Automated)
echo "Configuring ufw loopback traffic..."
ufw allow in on lo
ufw allow out on lo
ufw deny in from 127.0.0.0/8
ufw deny in from ::1

# CIS 4.2.5 Ensure ufw outbound connections are configured (Manual)
echo "Configuring ufw outbound connections..."
ufw allow out on all

# CIS 4.2.6 Ensure ufw firewall rules exist for all open ports (Automated)
echo "Configuring ufw rules for open ports..."
# Note: SSH port should be configured based on your specific needs
# This is just an example - adjust according to your requirements
ufw allow 22/tcp comment 'SSH access'

# CIS 4.2.7 Ensure ufw default deny firewall policy (Automated)
echo "Setting ufw default policies..."
ufw default deny incoming
ufw default deny outgoing
ufw default deny routed
ufw allow out 80/tcp                # HTTP
ufw allow out 443/tcp               # HTTPS
ufw allow out 53/udp                # DNS UDP
ufw allow out 53/tcp                # DNS TCP
ufw allow out 123/udp               # NTP
ufw allow out 853/tcp               # DNS over TLS
ufw logging on                      # Firewall logging

sed -i '/# ok icmp code for FORWARD/i \
# ok icmp codes for OUTPUT\
-A ufw-before-output -p icmp --icmp-type destination-unreachable -j ACCEPT\
-A ufw-before-output -p icmp --icmp-type time-exceeded -j ACCEPT\
-A ufw-before-output -p icmp --icmp-type parameter-problem -j ACCEPT\
-A ufw-before-output -p icmp --icmp-type echo-request -j ACCEPT\n' /etc/ufw/before.rules

# Enable UFW
echo "Enabling ufw firewall..."
ufw --force enable

# Verify ufw status
echo "UFW status:"
ufw status verbose

echo "UncomplicatedFirewall configuration completed successfully for CIS compliance."
