#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# CIS 1.2 - Package Management Configuration
set -e

echo "Configuring package management for CIS compliance..."

# CIS 1.2.1 - Configure Package Repositories
echo "Configuring package repositories..."

# CIS 1.2.1.1 - Ensure GPG keys are configured (Manual)
echo "Checking GPG keys configuration as per CIS benchmark..."
for file in /etc/apt/trusted.gpg.d/*.{gpg,asc} /etc/apt/sources.list.d/*.{gpg,asc} ; do
    if [ -f "$file" ]; then
        echo -e "File: $file"
        gpg --list-packets "$file" 2>/dev/null | awk '/keyid/ && !seen[$NF]++ {print "keyid:", $NF}'
        gpg --list-packets "$file" 2>/dev/null | awk '/Signed-By:/ {print "signed-by:", $NF}'
        echo -e
    fi
done

# CIS 1.2.1.2 - Ensure package manager repositories are configured (Manual)
echo "Checking package manager repositories configuration as per CIS benchmark..."
apt-cache policy

# CIS 1.2.2 - Configure Package Updates
echo "Configuring package updates..."

# CIS 1.2.2.1 - Ensure updates, patches, and additional security software are installed (Manual)
echo "Applying updates, patches, and security software as per CIS benchmark..."
apt update
apt upgrade -y

echo "Package management configured successfully for CIS compliance."
