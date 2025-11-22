#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# CIS 3.1 - Configure Network Devices
set -e

echo "Configuring network devices for CIS compliance..."

# CIS 3.1.1 Ensure IPv6 status is identified (Manual)
echo "IPv6 status requires manual verification (CIS 3.1.1)"

# CIS 3.1.2 Ensure wireless interfaces are disabled (Automated)
echo "Disabling wireless kernel modules..."

module_fix() {
    local l_mname="$1"

    if ! modprobe -n -v "$l_mname" | grep -P -- '^\h*install \/bin\/(true|false)'; then
        echo " - setting module: \"$l_mname\" to be un-loadable"
        echo "install $l_mname /bin/false" >> "/etc/modprobe.d/$l_mname.conf"
    fi

    if lsmod | grep "$l_mname" > /dev/null 2>&1; then
        echo " - unloading module \"$l_mname\""
        modprobe -r "$l_mname"
    fi

    if ! grep -Pq -- "^\h*blacklist\h+$l_mname\b" /etc/modprobe.d/*; then
        echo " - deny listing \"$l_mname\""
        echo "blacklist $l_mname" >> "/etc/modprobe.d/$l_mname.conf"
    fi
}

# Find wireless modules and disable them
if [ -n "$(find /sys/class/net/*/ -type d -name wireless 2>/dev/null)" ]; then
    l_dname=$(for driverdir in $(find /sys/class/net/*/ -type d -name wireless | xargs -0 dirname); do
        basename "$(readlink -f "$driverdir"/device/driver/module 2>/dev/null)" 2>/dev/null
    done | sort -u)

    for l_mname in $l_dname; do
        if [ -n "$l_mname" ]; then
            echo "Disabling wireless module: $l_mname"
            module_fix "$l_mname"
        fi
    done
else
    echo "No wireless interfaces found"
fi

# CIS 3.1.3 Ensure bluetooth services are not in use (Automated)
echo "Checking bluetooth services..."
if dpkg-query -s bluez &>/dev/null; then
    echo "bluetooth packages are installed - removing..."
    systemctl stop bluetooth 2>/dev/null || true
    systemctl disable bluetooth 2>/dev/null || true
    apt-get purge -y bluez
else
    echo "bluetooth packages are not installed"
fi

echo "Network devices configuration completed successfully for CIS compliance."
