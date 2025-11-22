#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

set -e

echo "Starting LUKS + vTPM + SecureBoot binding and initramfs hardening..."

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
# Install TPM2 + Secure Boot tools
# -------------------------
echo "Installing TPM2 + SecureBoot tools..."
apt-get update
apt-get install -y tpm2-tools systemd shim-signed grub-efi-amd64-signed mokutil

# -------------------------
# Verify TPM presence
# -------------------------
if [ ! -e /dev/tpm0 ]; then
    echo "ERROR: No TPM2 device detected! Aborting."
    exit 1
fi

# -------------------------
# Secure Boot: ensure shim + GRUB signed chain
# -------------------------
echo "Ensuring signed boot chain (shim → grub → kernel)..."
update-secureboot-policy || true

# -------------------------
# Enroll local Machine Owner Key (MOK)
# -------------------------
echo "Enrolling Machine Owner Key (MOK)..."
mokutil --import /usr/share/keyrings/ubuntu-archive-keyring.gpg || true

echo "If required, MOK enrollment will happen at next reboot."

# -------------------------
# Bind LUKS to TPM2 using systemd-cryptenroll
# Use PCR 0,2,4,7 (full SecureBoot + kernel + initramfs integrity)
# -------------------------
echo "Binding LUKS volume to TPM2 using systemd-cryptenroll..."

systemd-cryptenroll $LUKS_DEVICE \
    --tpm2-device=auto \
    --tpm2-pcrs=0,2,4,7

# -------------------------
# Display LUKS header for verification
# -------------------------
cryptsetup luksDump $LUKS_DEVICE

# -------------------------
# Update crypttab for TPM2 auto-unlock
# -------------------------
echo "Updating /etc/crypttab for TPM2 auto-unlock..."

sed -i "s|^\(luks_lvm UUID=${LUKS_UUID}.*\)$|\1,tpm2-device=auto|" /etc/crypttab

# -------------------------
# Regenerate initramfs
# -------------------------
echo "Regenerating initramfs for SecureBoot + TPM2 auto-unlock..."
update-initramfs -u -k all

echo "LUKS + TPM2 + SecureBoot configuration completed successfully."
