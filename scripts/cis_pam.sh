#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# CIS 5.3 - Configure Pluggable Authentication Modules
set -e

echo "Configuring PAM for CIS compliance..."

# CIS 5.3.1 Configure PAM software packages
echo "Configuring PAM software packages..."

# CIS 5.3.1.1 Ensure latest version of pam is installed (Automated)
echo "CIS 5.3.1.1 Ensuring latest version of pam is installed..."
apt-get update
apt-get upgrade -y libpam-runtime

# CIS 5.3.1.2 Ensure libpam-modules is installed (Automated)
echo "CIS 5.3.1.2 Ensuring libpam-modules is installed..."
apt-get install -y libpam-modules

# CIS 5.3.1.3 Ensure libpam-pwquality is installed (Automated)
echo "CIS 5.3.1.3 Ensuring libpam-pwquality is installed..."
apt-get install -y libpam-pwquality

# CIS 5.3.2 Configure pam-auth-update profiles
echo "Configuring pam-auth-update profiles..."

# CIS 5.3.2.1 Ensure pam_unix module is enabled (Automated)
echo "CIS 5.3.2.1 Ensuring pam_unix module is enabled..."
# pam_unix is enabled by default on Ubuntu, no action needed
echo "pam_unix module is enabled by default"

# CIS 5.3.2.2 Ensure pam_faillock module is enabled (Automated)
echo "CIS 5.3.2.2 Ensuring pam_faillock module is enabled..."

# Create faillock profile
cat > /usr/share/pam-configs/faillock << 'EOF'
Name: Enable pam_faillock to deny access
Default: yes
Priority: 0
Account-Type: Primary
Account:
	[default=die]			pam_faillock.so authfail
EOF

# Create faillock_notify profile
cat > /usr/share/pam-configs/faillock_notify << 'EOF'
Name: Notify of failed login attempts and reset count upon success
Default: yes
Priority: 1024
Auth-Type: Primary
Auth:
	requisite			pam_faillock.so preauth
Account-Type: Primary
Account:
	required			pam_faillock.so
EOF

# Enable the profiles
pam-auth-update --enable faillock
pam-auth-update --enable faillock_notify

echo "Configured pam_faillock with pam-auth-update"

# CIS 5.3.2.3 Ensure pam_pwquality module is enabled (Automated)
echo "CIS 5.3.2.3 Ensuring pam_pwquality module is enabled..."
pam-auth-update --enable pwquality

# CIS 5.3.2.4 Ensure pam_pwhistory module is enabled (Automated)
echo "CIS 5.3.2.4 Ensuring pam_pwhistory module is enabled..."
cat > /usr/share/pam-configs/pwhistory << 'EOF'
Name: pwhistory password history checking
Default: yes
Priority: 1024
Password-Type: Primary
Password:
	requisite	pam_pwhistory.so remember=24 enforce_for_root try_first_pass use_authtok
EOF
pam-auth-update --enable pwhistory

# CIS 5.3.3 Configure PAM Arguments
echo "Configuring PAM arguments..."

# CIS 5.3.3.1 Configure pam_faillock module
echo "Configuring pam_faillock module..."

# CIS 5.3.3.1.1 Ensure password failed attempts lockout is configured (Automated)
# CIS 5.3.3.1.2 Ensure password unlock time is configured (Automated) 
# CIS 5.3.3.1.3 Ensure password failed attempts lockout includes root account (Automated)
# Configure /etc/security/faillock.conf
FAILLOCK_CONF="/etc/security/faillock.conf"

# Create file if it doesn't exist
touch "$FAILLOCK_CONF"

# Comment out existing conflicting parameters
sed -i 's/^\s*deny\s*=/# &/' "$FAILLOCK_CONF"
sed -i 's/^\s*unlock_time\s*=/# &/' "$FAILLOCK_CONF"
sed -i 's/^\s*even_deny_root\s*$/# &/' "$FAILLOCK_CONF"
sed -i 's/^\s*root_unlock_time\s*=/# &/' "$FAILLOCK_CONF"

# Add CIS-compliant parameters at the end of file
{
    echo "# CIS 5.3.3.1.1 - Password failed attempts lockout"
    echo "deny = 5"
    echo "# CIS 5.3.3.1.2 - Password unlock time"
    echo "unlock_time = 900"
    echo "# CIS 5.3.3.1.3 - Include root account in lockout"
    echo "even_deny_root"
} >> "$FAILLOCK_CONF"

# Remove duplicate empty lines and clean up the file
sed -i '/^$/N;/^\n$/d' "$FAILLOCK_CONF"

# Set proper permissions on faillock.conf
chown root:root "$FAILLOCK_CONF"
chmod 644 "$FAILLOCK_CONF"

echo "Configured faillock with deny=5, unlock_time=900, and even_deny_root"

# CIS 5.3.3.2 Configure pam_pwquality module
echo "Configuring pam_pwquality module..."

# Create and configure /etc/security/pwquality.conf
PWQUALITY_CONF="/etc/security/pwquality.conf"

# CIS 5.3.3.2.1 Ensure password number of changed characters is configured (Automated)
# CIS 5.3.3.2.2 Ensure minimum password length is configured (Automated)
# CIS 5.3.3.2.3 Ensure password complexity is configured (Manual)
# CIS 5.3.3.2.4 Ensure password same consecutive characters is configured (Automated)
# CIS 5.3.3.2.5 Ensure password maximum sequential characters is configured (Automated)
# CIS 5.3.3.2.6 Ensure password dictionary check is enabled (Automated)
# CIS 5.3.3.2.7 Ensure password quality checking is enforced (Automated)
cat > "$PWQUALITY_CONF" << 'EOF'
# CIS 5.3.3.2.1 - Ensure password number of changed characters
difok = 2
# CIS 5.3.3.2.2 - Minimum password length
minlen = 14
# CIS 5.3.3.2.3 - Password complexity (Manual)
minclass = 3
dcredit = -1
ucredit = -1
ocredit = -1
lcredit = -1
# CIS 5.3.3.2.4 - Same consecutive characters
maxrepeat = 3
# CIS 5.3.3.2.5 - Maximum sequential characters
maxsequence = 3
# CIS 5.3.3.2.6 - Dictionary check
dictcheck = 1
# CIS 5.3.3.2.7 - Password quality checking is enforced
# (enforced by having the file present and parameter enforcing=0 not set)
EOF

# Set proper permissions on pwquality.conf
chown root:root "$PWQUALITY_CONF"
chmod 644 "$PWQUALITY_CONF"

# CIS 5.3.3.3 Configure pam_pwhistory module
echo "Configuring pam_pwhistory module..."
# CIS 5.3.3.3.1, 5.3.3.3.2, 5.3.3.3.3 already configured above with remember=5 and use_authtok

# CIS 5.3.3.4 Configure pam_unix module
echo "Configuring pam_unix module..."

# Check if the current unix profile satisfies CIS requirements
UNIX_PROFILE="/usr/share/pam-configs/unix"

# CIS 5.3.3.4.1 Ensure pam_unix does not include nullok (Automated)
echo "CIS 5.3.3.4.1 Ensuring pam_unix does not include nullok..."
# Remove nullok from the unix profile if present
if grep -q "nullok" "$UNIX_PROFILE"; then
    sed -i 's/\snullok//g' "$UNIX_PROFILE"
    echo "Removed nullok from unix profile"
else
    echo "nullok not found in unix profile - already compliant"
fi

# Also remove nullok from any existing PAM configuration files
for file in /etc/pam.d/common-*; do
    if [ -f "$file" ]; then
        if grep -q "nullok" "$file"; then
            sed -i 's/\snullok//g' "$file"
            echo "Removed nullok from $file"
        fi
    fi
done

# CIS 5.3.3.4.2 Ensure pam_unix does not include remember (Automated)
echo "CIS 5.3.3.4.2 Ensuring pam_unix does not include remember..."
# Remove remember parameters from pam_unix lines (we use pam_pwhistory instead)
for file in /etc/pam.d/common-*; do
    if [ -f "$file" ]; then
        if grep -q "pam_unix.*remember" "$file"; then
            sed -i 's/\sremember=[0-9]*//g' "$file"
            echo "Removed remember from pam_unix in $file"
        fi
    fi
done

# CIS 5.3.3.4.3 Ensure pam_unix includes a strong password hashing algorithm (Automated)
echo "CIS 5.3.3.4.3 Ensuring pam_unix includes strong password hashing..."
# Check if yescrypt is used (strong algorithm)
if grep -q "yescrypt" "$UNIX_PROFILE"; then
    echo "yescrypt found in unix profile - compliant with CIS requirements"
else
    # If not yescrypt, ensure sha512 is used
    if grep -q "pam_unix.so" /etc/pam.d/common-password; then
        if ! grep -q "sha512" /etc/pam.d/common-password; then
            sed -i 's/pam_unix\.so[^#]*/pam_unix.so sha512 use_authtok/' /etc/pam.d/common-password
            echo "Configured pam_unix to use sha512"
        else
            echo "sha512 already configured in common-password"
        fi
    fi
fi

# CIS 5.3.3.4.4 Ensure pam_unix includes use_authtok (Automated)
echo "CIS 5.3.3.4.4 Ensuring pam_unix includes use_authtok..."
# Check if use_authtok is present in the password section
if grep -q "pam_unix.so" /etc/pam.d/common-password; then
    if ! grep -q "use_authtok" /etc/pam.d/common-password; then
        sed -i 's/pam_unix\.so[^#]*/& use_authtok/' /etc/pam.d/common-password
        echo "Added use_authtok to pam_unix in common-password"
    else
        echo "use_authtok already present in pam_unix configuration"
    fi
fi

# Update PAM configuration to apply changes
pam-auth-update --package --force

echo "PAM configuration completed successfully for CIS compliance."
