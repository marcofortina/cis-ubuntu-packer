#!/usr/bin/env bash

set -euo pipefail

# --------------------------------------------------------------------------
# Packer Build Launcher
# Loads environment variables and builds the Ubuntu image
# --------------------------------------------------------------------------

# Load environment variables
if [ -f .env ]; then
  source .env
else
  echo ".env file not found! Exiting."
  exit 1
fi

# Validate Packer template
echo "==> Validating Packer template..."
packer validate \
  -var "ssh_password=$SSH_PASSWORD" \
  -var "grub_password=$GRUB_PASSWORD" \
  -var "luks_key=$LUKS_KEY" \
  -var "hostname=$VM_NAME" \
  -var "hashed_ssh_password=$(openssl passwd -6 "$SSH_PASSWORD")" \
  -var "ssh_public_key=$(cat ~/.ssh/id_rsa.pub)" \
  ubuntu.pkr.hcl
VALIDATE_STATUS=$?

if [ $VALIDATE_STATUS -ne 0 ]; then
  echo "Packer template validation failed (exit code $VALIDATE_STATUS)! Exiting."
  exit $VALIDATE_STATUS
fi

# Build the Packer image
echo "==> Building Packer image..."
packer build \
  -var "ssh_password=$SSH_PASSWORD" \
  -var "grub_password=$GRUB_PASSWORD" \
  -var "luks_key=$LUKS_KEY" \
  -var "hostname=$VM_NAME" \
  -var "hashed_ssh_password=$(openssl passwd -6 "$SSH_PASSWORD")" \
  -var "ssh_public_key=$(cat ~/.ssh/id_rsa.pub)" \
  ubuntu.pkr.hcl
