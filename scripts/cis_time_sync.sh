#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# CIS 2.3 - Configure Time Synchronization
set -e

echo "Configuring time synchronization for CIS compliance..."

# CIS 2.3.1.1 Ensure a single time synchronization daemon is in use (Automated)
echo "Ensuring only one time synchronization daemon is in use..."

# Remove chrony if installed to ensure only systemd-timesyncd is active
if dpkg-query -s chrony &>/dev/null; then
    echo "chrony is installed - removing to use systemd-timesyncd..."
    systemctl stop chrony 2>/dev/null || true
    apt-get purge -y chrony
else
    echo "chrony is not installed"
fi

# CIS 2.3.2.1 Ensure systemd-timesyncd configured with authorized timeserver (Automated)
echo "Configuring systemd-timesyncd with authorized timeserver..."
TIMESYNC_CONF="/etc/systemd/timesyncd.conf"

# Configure NTP servers
if ! grep -q "^NTP=" "$TIMESYNC_CONF" || grep -q "^#NTP=" "$TIMESYNC_CONF"; then
    # Add or uncomment and set NTP servers
    sed -i 's/^#NTP=.*/NTP=0.ubuntu.pool.ntp.org 1.ubuntu.pool.ntp.org 2.ubuntu.pool.ntp.org 3.ubuntu.pool.ntp.org/' "$TIMESYNC_CONF"
    if ! grep -q "^NTP=" "$TIMESYNC_CONF"; then
        echo "NTP=0.ubuntu.pool.ntp.org 1.ubuntu.pool.ntp.org 2.ubuntu.pool.ntp.org 3.ubuntu.pool.ntp.org" >> "$TIMESYNC_CONF"
    fi
    echo "NTP servers configured"
else
    echo "NTP servers already configured"
fi

# Ensure FallbackNTP is also set (optional but recommended)
if ! grep -q "^FallbackNTP=" "$TIMESYNC_CONF" || grep -q "^#FallbackNTP=" "$TIMESYNC_CONF"; then
    sed -i 's/^#FallbackNTP=.*/FallbackNTP=ntp.ubuntu.com/' "$TIMESYNC_CONF"
    if ! grep -q "^FallbackNTP=" "$TIMESYNC_CONF"; then
        echo "FallbackNTP=ntp.ubuntu.com" >> "$TIMESYNC_CONF"
    fi
    echo "Fallback NTP servers configured"
fi

# CIS 2.3.2.2 Ensure systemd-timesyncd is enabled and running (Automated)
echo "Enabling and starting systemd-timesyncd..."
systemctl enable systemd-timesyncd
systemctl start systemd-timesyncd

# Verify the service is running
if systemctl is-active systemd-timesyncd >/dev/null 2>&1; then
    echo "systemd-timesyncd is running"
else
    echo "Warning: systemd-timesyncd is not running. Starting it now..."
    systemctl start systemd-timesyncd
fi

# Force time synchronization
echo "Forcing initial time synchronization..."
systemctl restart systemd-timesyncd
timedatectl set-ntp true

echo "Time synchronization configuration completed successfully for CIS compliance."
