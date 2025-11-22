#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

set -e

echo "Starting VM finalization for template creation..."

ls -la /home/

# -------------------------
# Create /etc/rc.local to set a random hostname on first boot
# and generate SSH host keys (with CIS-compliant permissions) if missing
# -------------------------
echo "Creating /etc/rc.local for hostname initialization and SSH key generation..."
cat << 'EOF' > /etc/rc.local
#!/bin/sh -ef
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "" on success or any other
# value on error.
#
# By default this script does nothing.

# dynamically create hostname (optional)
if hostname | grep localhost >/dev/null 2>&1; then
    hostnamectl set-hostname "ubuntu-$(head /dev/urandom | tr -dc 0-9 | head -c 13)"
fi

# Generate SSH host keys if missing
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    dpkg-reconfigure openssh-server

    # CIS 5.1.2 – Private keys
    echo "Configuring permissions on SSH private host keys..."
    find /etc/ssh -xdev -type f -name 'ssh_host_*_key' \
        -exec chown root:root {} \; -exec chmod 600 {} \;

    # CIS 5.1.3 – Public keys
    echo "Configuring permissions on SSH public host keys..."
    find /etc/ssh -xdev -type f -name 'ssh_host_*_key.pub' \
        -exec chown root:root {} \; -exec chmod 644 {} \;
fi

exit 0
EOF
chmod +x /etc/rc.local
echo "/etc/rc.local created and executable."

# -------------------------
# Enable open-vm-tools
# -------------------------
systemctl enable open-vm-tools

# -------------------------
# Update GRUB_CMDLINE_LINUX_DEFAULT
# -------------------------
echo "Updating GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/grub..."
sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"|' /etc/default/grub
echo "GRUB_CMDLINE_LINUX_DEFAULT updated to 'quiet splash'."

# Update grub configuration
update-grub
echo "GRUB configuration updated."

# -------------------------
# Enable automatic cleanup of /var/tmp (CIS-compliant)
# -------------------------
echo "Enabling /var/tmp cleanup by uncommenting the tmpfiles.d rule..."
sed -i 's|^#q /var/tmp|q /var/tmp|' /usr/lib/tmpfiles.d/tmp.conf
echo "Automatic cleanup for /var/tmp enabled in /usr/lib/tmpfiles.d/tmp.conf"

# -------------------------
# [SRU] Fix login bug by disabling pam_lastlog.so in /etc/pam.d/login
# -------------------------
sed -i '/pam_lastlog.so/s/^/#/' /etc/pam.d/login

# -------------------------
# Configure multipath blacklist for VMware and VirtualBox disks
# -------------------------
echo "Configuring multipath blacklist for VMware and VirtualBox disks..."

# Ensure /etc/multipath.conf exists
if [ ! -f /etc/multipath.conf ]; then
    echo "# multipath configuration" > /etc/multipath.conf
fi

# Add blacklist section if not already present
if ! grep -q "vendor \"VMware\"" /etc/multipath.conf; then
    cat << 'EOF' >> /etc/multipath.conf

blacklist {
    device {
        vendor "VMware"
        product "Virtual disk"
    }
    device {
        vendor "VBOX"
        product "HARDDISK"
    }
}
EOF
    echo "Multipath blacklist added for VMware and VirtualBox."
else
    echo "Multipath blacklist for VMware/VirtualBox already present, skipping."
fi

# -------------------------
# Reset current hostname to localhost
# -------------------------
echo "Resetting current hostname to 'localhost'..."
hostnamectl set-hostname localhost
sed -i 's/^\(127\.0\.1\.1\s*\).*/\1localhost/' /etc/hosts
echo "Hostname reset to localhost in system and /etc/hosts."

# -------------------------
# Clean SSH host keys
# -------------------------
echo "Cleaning SSH host keys (they will be regenerated on first boot)..."
rm -fv /etc/ssh/ssh_host_*
echo "SSH host keys removed."

# -------------------------
# Clean temporary directories
# -------------------------
echo "Cleaning /tmp and /var/tmp directories..."
rm -rf /tmp/* /var/tmp/*
echo "/tmp and /var/tmp cleaned."

# -------------------------
# Clean cloud-init data and reset machine-id
# -------------------------
echo "Cleaning cloud-init state, logs, seed data, and resetting machine-id..."
cloud-init clean --logs --seed --machine-id
echo "Cloud-init cleanup completed and machine-id reset."

# -------------------------
# Disable cloud-init for template
# -------------------------
echo "Disabling cloud-init for template..."
touch /etc/cloud/cloud-init.disabled
echo "cloud-init disabled."

# -------------------------
# Ensure open-vm-tools is installed and active
# -------------------------
echo "Installing and enabling open-vm-tools..."
apt-get install -y open-vm-tools
systemctl enable open-vm-tools
systemctl start open-vm-tools
echo "open-vm-tools installed and active."

# -------------------------
# Remove unnecessary packages to reduce system footprint
# -------------------------
echo "Removing unnecessary packages..."
apt-get autoremove -y
echo "Unnecessary packages removed."

# -------------------------
# Clean APT package cache to reduce template size
# -------------------------
echo "Cleaning APT package cache..."
apt-get clean
echo "Package cache cleaned."

# -------------------------
# Clean shell history
# -------------------------
echo "Cleaning shell history..."
unset HISTFILE
history -cw
rm -fv /root/.bash_history /home/ubuntu/.bash_history
echo "Shell history cleaned."

# -------------------------
# Finalization completed
# -------------------------
echo "VM finalization completed successfully. Template is ready for deployment."
