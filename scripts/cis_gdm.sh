#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# CIS 1.7 - Configure GNOME Display Manager
set -e

echo "Configuring GNOME Display Manager for CIS compliance..."

# -------------------------
# CIS 1.7.1 Ensure GDM is removed (Automated)
# -------------------------
echo "Checking for GDM installation..."
if dpkg-query -s gdm3 &>/dev/null; then
    echo "GDM is installed - removing as this is a server installation..."
    apt-get purge -y gdm3
    echo "GDM successfully removed"
else
    echo "GDM is not installed (appropriate for server installation)"
fi

echo "GNOME Display Manager configuration completed successfully for CIS compliance."
