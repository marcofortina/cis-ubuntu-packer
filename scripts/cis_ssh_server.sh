#!/bin/bash

# CIS 5.1 - Configure SSH Server
set -e

echo "Configuring SSH server for CIS compliance..."

SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_CONFIG_DIR="/etc/ssh/sshd_config.d"
CIS_CONFIG_FILE="$SSHD_CONFIG_DIR/60-cis.conf"

# Create sshd_config.d directory if it doesn't exist
mkdir -p "$SSHD_CONFIG_DIR"

# CIS 5.1.1 Ensure permissions on /etc/ssh/sshd_config are configured (Automated)
echo "Configuring permissions on sshd_config..."
chown root:root "$SSHD_CONFIG"
chmod 600 "$SSHD_CONFIG"

# CIS 5.1.2 Ensure permissions on SSH private host key files are configured (Automated)
echo "Configuring permissions on SSH private host keys..."
find /etc/ssh -xdev -type f -name 'ssh_host_*_key' -exec chown root:root {} \;
find /etc/ssh -xdev -type f -name 'ssh_host_*_key' -exec chmod 600 {} \;

# CIS 5.1.3 Ensure permissions on SSH public host key files are configured (Automated)
echo "Configuring permissions on SSH public host keys..."
find /etc/ssh -xdev -type f -name 'ssh_host_*_key.pub' -exec chown root:root {} \;
find /etc/ssh -xdev -type f -name 'ssh_host_*_key.pub' -exec chmod 644 {} \;

# Comment out existing directives in main config file and create CIS config
echo "Creating CIS SSH configuration in $CIS_CONFIG_FILE..."

# Define admin group
ADMIN_GROUP="ssh-admins"

# Check if admin group exists, create if it doesn't
if ! getent group "$ADMIN_GROUP" > /dev/null; then
    groupadd "$ADMIN_GROUP"
    echo "Created group: $ADMIN_GROUP"
else
    echo "Using existing group: $ADMIN_GROUP"
fi

# Add ubuntu user to the admin group
usermod -aG "$ADMIN_GROUP" ubuntu
echo "Added ubuntu to $ADMIN_GROUP"

# Configure sudo for the admin group
SUDOERS_FILE="/etc/sudoers.d/ssh-admins"
cat > "$SUDOERS_FILE" << 'EOF'
# Allow ssh-admins group to run any command with their own password
%ssh-admins ALL=(ALL:ALL) ALL
EOF
chmod 440 "$SUDOERS_FILE"

# Remove cloud-init.conf
rm -f /etc/ssh/sshd_config.d/*-cloud-init.conf

# Now create the CIS configuration file
cat > "$CIS_CONFIG_FILE" << 'EOF'
# CIS 5.1.x - SSH Server Hardening Configuration
# This file contains all CIS-mandated SSH configurations

# CIS 5.1.4 - SSH access controls
AllowGroups ssh-admins

# CIS 5.1.5 - SSH banner
Banner /etc/issue.net

# CIS 5.1.6 - SSH ciphers
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com

# CIS 5.1.7 - SSH client alive settings
ClientAliveInterval 300
ClientAliveCountMax 0

# CIS 5.1.8 - SSH forwarding restrictions
AllowTcpForwarding no
X11Forwarding no

# CIS 5.1.9 - Disable GSSAPI authentication
GSSAPIAuthentication no

# CIS 5.1.10 - Disable host-based authentication
HostbasedAuthentication no

# CIS 5.1.11 - Enable IgnoreRhosts
IgnoreRhosts yes

# CIS 5.1.12 - SSH key exchange algorithms
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group-exchange-sha256

# CIS 5.1.13 - Login grace time
LoginGraceTime 60

# CIS 5.1.14 - SSH log level
LogLevel VERBOSE

# CIS 5.1.15 - SSH MAC algorithms
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256

# CIS 5.1.16 - Maximum authentication attempts
MaxAuthTries 4

# CIS 5.1.17 - Maximum sessions
MaxSessions 10

# CIS 5.1.18 - Maximum startups
MaxStartups 10:30:60

# CIS 5.1.19 - Disable empty passwords
PermitEmptyPasswords no

# CIS 5.1.20 - Disable root login
PermitRootLogin no

# CIS 5.1.21 - Disable user environment
PermitUserEnvironment no

# CIS 5.1.22 - Enable PAM
UsePAM yes
EOF

# Set proper permissions on the CIS config file
chown root:root "$CIS_CONFIG_FILE"
chmod 600 "$CIS_CONFIG_FILE"

# CIS 5.1.4 - Configure SSH access controls with admin group
echo "Configuring SSH access controls..."

# Restart SSH service to apply changes
echo "Reloading SSH service..."
systemctl reload ssh

echo "SSH server configuration completed successfully for CIS compliance."
echo "SSH access restricted to group: $ADMIN_GROUP"
echo "IMPORTANT: Add authorized users to the $ADMIN_GROUP group using: usermod -a -G $ADMIN_GROUP username"
