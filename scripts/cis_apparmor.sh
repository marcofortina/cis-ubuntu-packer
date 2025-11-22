#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# CIS 1.3.1 - Configure AppArmor
set -e

echo "Configuring AppArmor for CIS compliance..."

# CIS 1.3.1.1 Ensure AppArmor is installed (Automated)
echo "Installing AppArmor packages..."
apt-get update
apt-get install -y apparmor apparmor-utils

# CIS 1.3.1.2 Ensure AppArmor is enabled in the bootloader configuration (Automated)
echo "Configuring bootloader for AppArmor..."
GRUB_FILE="/etc/default/grub"
PARAMS="apparmor=1 security=apparmor"

# Check current kernel command line
if ! grep -q "GRUB_CMDLINE_LINUX.*apparmor=1" "$GRUB_FILE" || ! grep -q "GRUB_CMDLINE_LINUX.*security=apparmor" "$GRUB_FILE"; then
    # Remove any existing apparmor parameters first
    sed -i 's/\(GRUB_CMDLINE_LINUX=".*\)apparmor=[^ "]*\(.*\)"/\1\2"/' "$GRUB_FILE"
    sed -i 's/\(GRUB_CMDLINE_LINUX=".*\)security=[^ "]*\(.*\)"/\1\2"/' "$GRUB_FILE"
    
    # Add the correct parameters
    sed -i "/^GRUB_CMDLINE_LINUX=/ s/\"$/ $PARAMS\"/" "$GRUB_FILE"
    echo "Updating GRUB configuration..."
    update-grub
else
    echo "AppArmor kernel parameters already properly configured in GRUB."
fi

# Enable and start AppArmor service
echo "Enabling and starting AppArmor service..."
systemctl enable apparmor
systemctl start apparmor

# CIS 1.3.1.3 Ensure all AppArmor Profiles are in enforce or complain mode (Automated)
echo "Checking AppArmor profiles status..."
aa-status

# CIS 1.3.1.4 Ensure all AppArmor Profiles are enforcing (Automated)
echo "Setting all AppArmor profiles to enforce mode..."

# First, enforce all profiles using aa-enforce
aa-enforce /etc/apparmor.d/*

# Check for any profiles still in complain mode and enforce them individually
COMPLAIN_PROFILES=$(aa-status | awk '/profiles are in complain mode/{getline; while($0 ~ /^ /) {print $1; getline}}' 2>/dev/null || true)

if [ -n "$COMPLAIN_PROFILES" ]; then
    echo "The following profiles are still in complain mode and will be set to enforce:"
    echo "$COMPLAIN_PROFILES"
    for profile in $COMPLAIN_PROFILES; do
        echo "Enforcing profile: $profile"
        aa-enforce "$profile" 2>/dev/null || echo "Warning: Could not enforce profile $profile"
    done
fi

# Final verification
echo "Final AppArmor status:"
aa-status

ENFORCED_PROFILES=$(aa-status | grep "profiles are in enforce mode" | cut -d' ' -f1)
COMPLAIN_PROFILES=$(aa-status | grep "profiles are in complain mode" | cut -d' ' -f1)

echo "AppArmor enforcement summary:"
echo "- $ENFORCED_PROFILES profiles in enforce mode"
echo "- $COMPLAIN_PROFILES profiles in complain mode"

if [ "$COMPLAIN_PROFILES" -eq 0 ]; then
    echo "SUCCESS: All AppArmor profiles are now in enforce mode."
else
    echo "WARNING: $COMPLAIN_PROFILES profiles remain in complain mode."
    echo "These may be third-party applications that require manual configuration."
fi

echo "AppArmor configuration completed successfully for CIS compliance."
