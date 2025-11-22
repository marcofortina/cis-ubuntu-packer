#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# CIS 5.2 - Configure Privilege Escalation
set -e

echo "Configuring privilege escalation for CIS compliance..."

# CIS 5.2.1 Ensure sudo is installed (Automated)
echo "CIS 5.2.1 Ensure sudo is installed..."
if ! dpkg-query -s sudo &>/dev/null; then
    echo "Installing sudo..."
    apt-get update
    apt-get install -y sudo
else
    echo "sudo is already installed"
fi

# Create CIS sudoers file with comments
SUDOERS_FILE="/etc/sudoers.d/99-cis-sudo"

# Create the sudoers file with CIS comments
cat > "$SUDOERS_FILE" << 'EOF'
# CIS 5.2.2 Ensure sudo commands use pty (Automated)
Defaults use_pty

# CIS 5.2.3 Ensure sudo log file exists (Automated)
Defaults logfile="/var/log/sudo.log"

# CIS 5.2.6 Ensure sudo authentication timeout is configured correctly (Automated)
Defaults timestamp_timeout=5
EOF

echo "Created CIS sudoers configuration file"

# Create and secure the sudo log file
SUDO_LOG="/var/log/sudo.log"
touch "$SUDO_LOG"
chown root:root "$SUDO_LOG"
chmod 600 "$SUDO_LOG"

# CIS 5.2.4 Ensure users must provide password for privilege escalation (Automated)
echo "CIS 5.2.4 Ensure users must provide password for privilege escalation..."
# Remove any occurrences of NOPASSWD tags in the file(s)
for file in /etc/sudoers /etc/sudoers.d/*; do
    if [ -f "$file" ] && [ "$file" != "$SUDOERS_FILE" ]; then
        if grep -q 'NOPASSWD' "$file"; then
            echo "Removing NOPASSWD from $file"
            sed -i '/NOPASSWD/d' "$file"
        fi
    fi
done

# CIS 5.2.5 Ensure re-authentication for privilege escalation is not disabled globally (Automated)
echo "CIS 5.2.5 Ensure re-authentication for privilege escalation is not disabled globally..."
# Remove any occurrences of !authenticate tags in the file(s)
for file in /etc/sudoers /etc/sudoers.d/*; do
    if [ -f "$file" ] && [ "$file" != "$SUDOERS_FILE" ]; then
        if grep -q '\!authenticate' "$file"; then
            echo "Removing !authenticate from $file"
            sed -i '/\!authenticate/d' "$file"
        fi
    fi
done

# CIS 5.2.7 Ensure access to the su command is restricted (Automated)
echo "CIS 5.2.7 Ensure access to the su command is restricted..."
# Create an empty group for su access restriction
SU_GROUP="sugroup"
if ! getent group "$SU_GROUP" > /dev/null; then
    groupadd "$SU_GROUP"
    echo "Created empty group: $SU_GROUP"
fi

# Configure PAM to restrict su access to the empty group
PAM_SU_FILE="/etc/pam.d/su"
# Remove any existing occurrence of our line to avoid duplicates
sed -i '/auth required pam_wheel.so use_uid group=sugroup/d' "$PAM_SU_FILE"

# Insert the line after the specific comment
sed -i '/# auth       required   pam_wheel.so deny group=nosu/a auth required pam_wheel.so use_uid group=sugroup' "$PAM_SU_FILE"

echo "Configured PAM to restrict su to group: $SU_GROUP"

# Verify the group is empty
GROUP_MEMBERS=$(getent group "$SU_GROUP" | cut -d: -f4)
if [ -n "$GROUP_MEMBERS" ]; then
    echo "Warning: Group $SU_GROUP should be empty but contains: $GROUP_MEMBERS"
else
    echo "Group $SU_GROUP is properly empty"
fi

# Set proper permissions on sudoers file
chown root:root "$SUDOERS_FILE"
chmod 440 "$SUDOERS_FILE"

echo "Privilege escalation configuration completed successfully for CIS compliance."
