#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# CIS 1.5 - Configure Additional Process Hardening
set -e

echo "Configuring additional process hardening for CIS compliance..."

# -------------------------
# CIS 1.5.1 Ensure address space layout randomization is enabled (Automated)
# -------------------------
echo "Configuring Address Space Layout Randomization (ASLR)..."
SYSCTL_CONF="/etc/sysctl.d/60-cis.conf"

# Ensure ASLR is set to full randomization (2)
if ! grep -q "kernel.randomize_va_space" "$SYSCTL_CONF" 2>/dev/null; then
    echo "kernel.randomize_va_space = 2" >> "$SYSCTL_CONF"
    echo "Added ASLR configuration to $SYSCTL_CONF"
else
    echo "ASLR configuration already present in $SYSCTL_CONF"
fi

# Apply immediately
sysctl -w kernel.randomize_va_space=2

# -------------------------
# CIS 1.5.2 Ensure ptrace_scope is restricted (Automated)
# -------------------------
echo "Configuring ptrace scope restriction..."

if ! grep -q "kernel.yama.ptrace_scope" "$SYSCTL_CONF" 2>/dev/null; then
    echo "kernel.yama.ptrace_scope = 1" >> "$SYSCTL_CONF"
    echo "Added ptrace scope restriction to $SYSCTL_CONF"
else
    echo "Ptrace scope restriction already present in $SYSCTL_CONF"
fi

# Apply immediately
sysctl -w kernel.yama.ptrace_scope=1

# -------------------------
# CIS 1.5.3 Ensure core dumps are restricted (Automated)
# -------------------------
echo "Configuring core dump restrictions..."

# Add to sysctl configuration
if ! grep -q "fs.suid_dumpable" "$SYSCTL_CONF" 2>/dev/null; then
    echo "fs.suid_dumpable = 0" >> "$SYSCTL_CONF"
    echo "Added suid_dumpable restriction to $SYSCTL_CONF"
else
    echo "suid_dumpable restriction already present in $SYSCTL_CONF"
fi

# Apply immediately
sysctl -w fs.suid_dumpable=0

# Configure core dump restriction in limits.d instead of limits.conf
CORE_LIMITS_FILE="/etc/security/limits.d/90-cis-core-dumps.conf"
CORE_LIMIT_SET=0

# Check if the restriction exists in limits.conf
if grep -q "^\* hard core 0" /etc/security/limits.conf; then
    CORE_LIMIT_SET=1
    echo "Core dump restriction found in /etc/security/limits.conf"
fi

# Check if the restriction exists in any file in limits.d
for file in /etc/security/limits.d/*; do
    if [ -f "$file" ] && grep -q "^\* hard core 0" "$file"; then
        CORE_LIMIT_SET=1
        echo "Core dump restriction found in $file"
        break
    fi
done

# If not found anywhere, create the file in limits.d
if [ $CORE_LIMIT_SET -eq 0 ]; then
    echo "* hard core 0" > "$CORE_LIMITS_FILE"
    echo "Added core dump restriction to $CORE_LIMITS_FILE"
fi

# Configure systemd-coredump (Ubuntu 24.04 uses systemd-coredump)
COREDUMP_CONF="/etc/systemd/coredump.conf"
if [ -f "$COREDUMP_CONF" ]; then
    # Ensure storage is set to none
    if grep -q "^Storage=" "$COREDUMP_CONF"; then
        sed -i 's/^Storage=.*/Storage=none/' "$COREDUMP_CONF"
    else
        echo "Storage=none" >> "$COREDUMP_CONF"
    fi
    echo "Configured systemd-coredump to disable storage"
fi

# Disable coredump socket
systemctl stop systemd-coredump.socket 2>/dev/null || true
systemctl mask systemd-coredump.socket 2>/dev/null || true

# -------------------------
# CIS 1.5.4 Ensure prelink is not installed (Automated)
# -------------------------
echo "Checking for prelink installation..."
if dpkg-query -s prelink &>/dev/null; then
    echo "prelink is installed, removing as per CIS guidelines..."
    # First, restore binaries to their original state
    prelink -ua 2>/dev/null || echo "Prelink restoration completed or not needed"
    # Then completely remove the package
    apt-get purge -y prelink
    echo "Prelink completely purged from system"
else
    echo "Prelink is not installed"
fi

# -------------------------
# CIS 1.5.5 Ensure Automatic Error Reporting is not enabled (Automated)
# -------------------------
echo "Configuring automatic error reporting..."

# Ubuntu 24.04 uses apport for error reporting
if systemctl is-enabled apport.service >/dev/null 2>&1; then
    echo "Disabling apport service..."
    systemctl stop apport.service
    systemctl disable apport.service
    systemctl mask apport.service
    echo "Apport service disabled"
else
    echo "Apport service already disabled"
fi

# Ensure apport is configured to be disabled
APPORT_CONF="/etc/default/apport"
if [ -f "$APPORT_CONF" ]; then
    if grep -q "^enabled=1" "$APPORT_CONF"; then
        sed -i 's/^enabled=1/enabled=0/' "$APPORT_CONF"
        echo "Disabled apport in configuration file"
    else
        echo "Apport already disabled in configuration"
    fi
fi

# -------------------------
# Apply all sysctl configurations
# -------------------------
echo "Applying all sysctl configurations..."
sysctl --system >/dev/null 2>&1 || true

echo "Additional process hardening configured successfully for CIS compliance."
