#!/bin/bash

# CIS 3.3 - Configure Network Kernel Parameters
set -e

echo "Configuring network kernel parameters for CIS compliance..."

SYSCTL_FILE="/etc/sysctl.d/60-cis-network.conf"

echo "Creating network kernel parameters configuration..."
cat > "$SYSCTL_FILE" << 'EOF'
# CIS 3.3.1 Ensure ip forwarding is disabled
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# CIS 3.3.2 Ensure packet redirect sending is disabled
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# CIS 3.3.3 Ensure bogus icmp responses are ignored
net.ipv4.icmp_ignore_bogus_error_responses = 1

# CIS 3.3.4 Ensure broadcast icmp requests are ignored
net.ipv4.icmp_echo_ignore_broadcasts = 1

# CIS 3.3.5 Ensure icmp redirects are not accepted
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# CIS 3.3.6 Ensure secure icmp redirects are not accepted
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0

# CIS 3.3.7 Ensure reverse path filtering is enabled
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# CIS 3.3.8 Ensure source routed packets are not accepted
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# CIS 3.3.9 Ensure suspicious packets are logged
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# CIS 3.3.10 Ensure tcp syn cookies is enabled
net.ipv4.tcp_syncookies = 1

# CIS 3.3.11 Ensure ipv6 router advertisements are not accepted
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
EOF

# Apply the settings immediately
echo "Applying network kernel parameters..."
sysctl --system >/dev/null 2>&1

echo "Network kernel parameters configuration completed successfully for CIS compliance."
