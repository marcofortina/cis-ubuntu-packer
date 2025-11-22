#!/bin/bash

# CIS 1.4 - Configure Bootloader
set -e

echo "Configuring bootloader for CIS compliance..."

# -------------------------
# Configuration
# -------------------------
GRUB_USER="admin"
GRUB_CUSTOM="/etc/grub.d/40_custom"
GRUB_DEFAULT="/etc/default/grub"
GRUB_DIR="/boot/grub"
GRUB_10_LINUX="/etc/grub.d/10_linux"

# -------------------------
# CIS 1.4.1 Ensure bootloader password is set (Automated)
# -------------------------
echo "Configuring bootloader password..."

# Generate GRUB password hash
echo "Generating GRUB password hash..."
GRUB_HASH=$(echo -e "$GRUB_PASSWORD\n$GRUB_PASSWORD" | grub-mkpasswd-pbkdf2 2>/dev/null | awk '/grub.pbkdf2/ {print $NF}')

if [ -z "$GRUB_HASH" ]; then
    echo "Error: Failed to generate GRUB password hash"
    exit 1
fi

# Configure superuser and password in custom GRUB file
if ! grep -q "set superusers=\"$GRUB_USER\"" "$GRUB_CUSTOM"; then
    echo "Adding GRUB superuser configuration..."
    {
        echo ""
        echo "# CIS 1.4.1 - Bootloader password configuration"
        echo "set superusers=\"$GRUB_USER\""
        echo "password_pbkdf2 $GRUB_USER $GRUB_HASH"
    } >> "$GRUB_CUSTOM"
else
    echo "GRUB superuser already configured."
fi

# Add --unrestricted to allow normal boot without password
echo "Configuring unrestricted boot for normal entries..."
if grep -q "CLASS=.*--class.*--class.*--class" "$GRUB_10_LINUX" && ! grep -q "CLASS=.*--unrestricted" "$GRUB_10_LINUX"; then
    sed -i 's/CLASS="--class gnu-linux --class gnu --class os"/CLASS="--class gnu-linux --class gnu --class os --unrestricted"/' "$GRUB_10_LINUX"
    echo "Added --unrestricted to normal boot entries"
else
    echo "Unrestricted boot already configured or pattern not found"
fi

# -------------------------
# CIS 1.4.2 Ensure access to bootloader config is configured (Automated)
# -------------------------
echo "Securing bootloader configuration files..."

# Set ownership and permissions on GRUB configuration files
chown root:root "$GRUB_DEFAULT"
chmod 600 "$GRUB_DEFAULT"

chown root:root "$GRUB_CUSTOM"
chmod 755 "$GRUB_CUSTOM"

chown root:root "$GRUB_10_LINUX"
chmod 755 "$GRUB_10_LINUX"

# Secure the GRUB directory
if [ -d "$GRUB_DIR" ]; then
    chown -R root:root "$GRUB_DIR"
    chmod -R 700 "$GRUB_DIR"
else
    echo "Warning: GRUB directory $GRUB_DIR not found"
fi

# -------------------------
# Update GRUB configuration
# -------------------------
echo "Updating GRUB configuration..."
update-grub

echo "Bootloader configuration completed successfully for CIS compliance."
echo "GRUB superuser: $GRUB_USER"
echo "Normal boot: No password required"
echo "Recovery/edit mode: Password required"
echo "IMPORTANT: Record the GRUB password securely and change the default!"
