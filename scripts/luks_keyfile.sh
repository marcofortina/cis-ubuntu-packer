#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

set -e

echo "Starting LUKS key deployment and initramfs hardening..."

# -------------------------
# Set secure UMASK for initramfs (CIS-compliant)
# -------------------------
echo "Configuring secure UMASK=0077 for initramfs..."
echo UMASK=0077 >> /etc/initramfs-tools/initramfs.conf

# -------------------------
# Detect LUKS volume
# -------------------------
LUKS_UUID=$(blkid -t TYPE=crypto_LUKS -s UUID -o value)
LUKS_DEVICE=$(blkid -t UUID="$LUKS_UUID" -o device)

echo "Detected LUKS device: $LUKS_DEVICE ($LUKS_UUID)"

# -------------------------
# Generate a 256-bit random recovery key
# -------------------------
dd if=/dev/urandom of=/tmp/recovery-key.bin bs=32 count=1
chmod 0400 /tmp/recovery-key.bin
chown root:root /tmp/recovery-key.bin

# -------------------------
# Convert recovery key to readable hex & save
# -------------------------
xxd -p -c 256 /tmp/recovery-key.bin > /var/log/installer/recovery-key.txt
chmod 0400 /var/log/installer/recovery-key.txt
chown root:root /var/log/installer/recovery-key.txt
cat /var/log/installer/recovery-key.txt

# -------------------------
# Add recovery key to LUKS
# -------------------------
echo "Adding recovery key to LUKS keyslot..."
echo -n "${LUKS_KEY}" | cryptsetup luksAddKey $LUKS_DEVICE /tmp/recovery-key.bin --key-file=-

# Cleanup temporary binary recovery key
shred -u /tmp/recovery-key.bin

# -------------------------
# Install main LUKS key and enable keyfile support
# -------------------------
mkdir -p /etc/cryptsetup-keys.d /etc/cryptsetup-initramfs

dd if=/dev/random of=/etc/cryptsetup-keys.d/${LUKS_UUID}.key bs=4096 count=1
chmod 0400 /etc/cryptsetup-keys.d/${LUKS_UUID}.key
chown root:root /etc/cryptsetup-keys.d/${LUKS_UUID}.key

echo -n ${LUKS_KEY} | cryptsetup luksAddKey $LUKS_DEVICE /etc/cryptsetup-keys.d/${LUKS_UUID}.key --key-file=-

sed -i "s|^\(luks_lvm UUID=${LUKS_UUID}\) .*|\1 /etc/cryptsetup-keys.d/${LUKS_UUID}.key luks|" /etc/crypttab
sed -i 's|^#KEYFILE_PATTERN=.*|KEYFILE_PATTERN=/etc/cryptsetup-keys.d/*.key|' /etc/cryptsetup-initramfs/conf-hook

# -------------------------
# Display LUKS header for verification
# -------------------------
cryptsetup luksDump $LUKS_DEVICE

# -------------------------
# Regenerate initramfs
# -------------------------
echo "Regenerating initramfs to embed the LUKS keyfile..."
update-initramfs -c -k all

echo "LUKS key deployment and initramfs configuration completed successfully."
