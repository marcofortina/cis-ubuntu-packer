#!/bin/bash

# CIS 1.1.2 - Temporary Filesystem Configuration
set -e

echo "Configuring temporary filesystems for CIS compliance..."

# CIS 1.1.2.1 - Configure /tmp with proper mount options
if ! grep -q "tmpfs /tmp tmpfs" /etc/fstab; then
    echo "tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev,mode=1777 0 0" >> /etc/fstab
fi

# CIS 1.1.2.5 - Configure /var/tmp with proper mount options  
if ! grep -q "tmpfs /var/tmp tmpfs" /etc/fstab; then
    echo "tmpfs /var/tmp tmpfs defaults,noexec,nosuid,nodev,mode=1777 0 0" >> /etc/fstab
fi

# CIS 1.1.2.2 - Configure /dev/shm with proper mount options
if grep -q "tmpfs /dev/shm" /etc/fstab; then
    # Update existing entry
    sed -i 's|tmpfs /dev/shm tmpfs.*|tmpfs /dev/shm tmpfs defaults,noexec,nosuid,nodev,mode=1777 0 0|' /etc/fstab
else
    echo "tmpfs /dev/shm tmpfs defaults,noexec,nosuid,nodev,mode=1777 0 0" >> /etc/fstab
fi

echo "Temporary filesystems configured successfully for CIS compliance."
