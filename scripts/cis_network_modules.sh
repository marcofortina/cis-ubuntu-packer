#!/bin/bash

# CIS 3.2 - Configure Network Kernel Modules
set -e

echo "Configuring network kernel modules for CIS compliance..."

MODULES=("dccp" "tipc" "rds" "sctp")
MODPROBE_DIR="/etc/modprobe.d"

# Create CIS network modules configuration
echo "Creating network modules blacklist configuration..."
CIS_MODULES_CONF="$MODPROBE_DIR/cis_network_modules.conf"

echo "# CIS 3.2.x - Disabled network kernel modules" > "$CIS_MODULES_CONF"

for mod in "${MODULES[@]}"; do
    echo "Disabling module: $mod"

    # Unload module if currently loaded
    if lsmod | grep -q "^$mod "; then
        echo "Unloading module: $mod"
        modprobe -r "$mod" 2>/dev/null || true
    fi

    # Add to blacklist configuration
    echo "install $mod /bin/true" >> "$CIS_MODULES_CONF"
    echo "blacklist $mod" >> "$CIS_MODULES_CONF"
done

echo "Network kernel modules configuration completed successfully for CIS compliance."
