#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# CIS 4.3 - Configure nftables (Not Used - Removing)
set -e

echo "Configuring nftables for CIS compliance..."

# Remove nftables since we're using UFW
if dpkg-query -s nftables &>/dev/null; then
    echo "nftables is installed - removing as we're using UFW..."
    systemctl stop nftables 2>/dev/null || true
    apt-get purge -y nftables libnftables1
    echo "nftables successfully removed"
else
    echo "nftables is not installed"
fi

echo "nftables configuration completed successfully for CIS compliance."
