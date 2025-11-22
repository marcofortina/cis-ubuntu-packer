#!/bin/bash

# CIS 1.1.1 - Filesystem Kernel Module Restrictions
set -e

echo "Configuring filesystem kernel module restrictions for CIS compliance..."

MODPROBE_DIR="/etc/modprobe.d"

declare -A MODULES=(
  ["cramfs"]="1.1.1.1"
  ["freevxfs"]="1.1.1.2"
  ["hfs"]="1.1.1.3"
  ["hfsplus"]="1.1.1.4"
  ["jffs2"]="1.1.1.5"
  ["overlay"]="1.1.1.6"
  ["squashfs"]="1.1.1.7"
  ["udf"]="1.1.1.8"
  ["usb-storage"]="1.1.1.9"
)

UNUSED_MODULES=(
  "befs"
  "befs_fs"
  "efs"
  "jfs"
  "minix"
  "omfs"
  "qnx4"
  "qnx6"
  "sysv"
  "vfat"
)

# CIS 1.1.1.1-1.1.1.9 - Disable unused filesystem modules
echo "Creating CIS disabled filesystem configuration..."
DISABLED_CONF="$MODPROBE_DIR/cis_disabled_fs.conf"
echo "# CIS 1.1.1.x Disabled FS modules" > "$DISABLED_CONF"

for module in "${!MODULES[@]}"; do
  echo "Disabling module: $module (CIS ${MODULES[$module]})"
  echo "install $module /bin/true" >> "$DISABLED_CONF"
  echo "blacklist $module" >> "$DISABLED_CONF"
done

# CIS 1.1.1.10 - Disable additional unused filesystem modules
echo "Creating CIS unused filesystem configuration..."
UNUSED_CONF="$MODPROBE_DIR/cis_unused_fs.conf"
echo "# CIS 1.1.1.10 Unused FS modules" > "$UNUSED_CONF"

for module in "${UNUSED_MODULES[@]}"; do
  echo "Disabling unused FS module: $module"
  echo "install $module /bin/true" >> "$UNUSED_CONF"
  echo "blacklist $module" >> "$UNUSED_CONF"
done

echo "Updating initramfs..."
update-initramfs -u

echo "Filesystem kernel module restrictions configured successfully for CIS compliance."
