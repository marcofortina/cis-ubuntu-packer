#!/bin/bash

# CIS 5.4 - Configure User Accounts and Environment
set -e

echo "Configuring user accounts and environment for CIS compliance..."

# CIS 5.4.1 Configure shadow password suite parameters

# CIS 5.4.1.1 Ensure password expiration is configured (Automated)
echo "CIS 5.4.1.1 Ensuring password expiration is configured..."
if grep -q '^PASS_MAX_DAYS' /etc/login.defs; then
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 365/' /etc/login.defs
else
    echo "PASS_MAX_DAYS 365" >> /etc/login.defs
fi

# CIS 5.4.1.2 Ensure minimum password days is configured (Manual)
echo "CIS 5.4.1.2 Ensuring minimum password days is configured..."
if grep -q '^PASS_MIN_DAYS' /etc/login.defs; then
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' /etc/login.defs
else
    echo "PASS_MIN_DAYS 1" >> /etc/login.defs
fi

# CIS 5.4.1.3 Ensure password expiration warning days is configured (Automated)
echo "CIS 5.4.1.3 Ensuring password expiration warning days is configured..."
if grep -q '^PASS_WARN_AGE' /etc/login.defs; then
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs
else
    echo "PASS_WARN_AGE 7" >> /etc/login.defs
fi

# CIS 5.4.1.4 Ensure strong password hashing algorithm is configured (Automated)
echo "CIS 5.4.1.4 Ensure strong password hashing algorithm is configured..."
if grep -q '^ENCRYPT_METHOD' /etc/login.defs; then
    sed -i 's/^ENCRYPT_METHOD.*/ENCRYPT_METHOD SHA512/' /etc/login.defs
else
    echo "ENCRYPT_METHOD SHA512" >> /etc/login.defs
fi

# CIS 5.4.1.5 Ensure inactive password lock is configured (Automated)
echo "CIS 5.4.1.5 Ensuring inactive password lock is configured..."
useradd -D -f 45

# Apply to existing users with interactive shells
awk -F: '($3 >= 1000 && $7 != "/usr/sbin/nologin" && $7 != "/bin/false") {print $1}' /etc/passwd | \
while read -r user; do
    chage --inactive 45 "$user"
done

# CIS 5.4.1.6 Ensure all users last password change date is in the past (Automated)
echo "CIS 5.4.1.6 Verifying all users last password change date is in the past..."
echo "Not required"

# CIS 5.4.2 Configure root and system accounts and environment

# CIS 5.4.2.1 Ensure root is the only UID 0 account (Automated)
echo "CIS 5.4.2.1 Ensuring root is the only UID 0 account..."
echo "Not required"

# CIS 5.4.2.2 Ensure root is the only GID 0 account (Automated)
echo "CIS 5.4.2.2 Ensuring root is the only GID 0 account..."
echo "Not required"

# CIS 5.4.2.3 Ensure group root is the only GID 0 group (Automated)
echo "CIS 5.4.2.3 Ensuring group root is the only GID 0 group..."
echo "Not required"

# CIS 5.4.2.4 Ensure root account access is controlled (Automated)
echo "CIS 5.4.2.4 Ensuring root account access is controlled..."
echo "Not required"

# CIS 5.4.2.5 Ensure root path integrity (Automated)
echo "CIS 5.4.2.5 Ensuring root path integrity..."
echo "Not required"

# CIS 5.4.2.6 Ensure root user umask is configured (Automated)
echo "CIS 5.4.2.6 Ensuring root user umask is configured..."
# Set umask for root in shell configuration files
for file in /root/.bashrc /root/.profile; do
    if [ -f "$file" ]; then
        if ! grep -q '^umask 027' "$file"; then
            echo "umask 027" >> "$file"
        fi
    fi
done

# CIS 5.4.2.7 Ensure system accounts do not have a valid login shell (Automated)
echo "CIS 5.4.2.7 Ensuring system accounts do not have a valid login shell..."
echo "Not required"

# CIS 5.4.2.8 Ensure accounts without a valid login shell are locked (Automated)
echo "CIS 5.4.2.8 Ensuring accounts without a valid login shell are locked..."
echo "Not required"

# CIS 5.4.3 Configure user default environment

# CIS 5.4.3.1 Ensure nologin is not listed in /etc/shells (Automated)
echo "CIS 5.4.3.1 Ensuring nologin is not listed in /etc/shells..."
# Remove nologin and false from /etc/shells
sed -i '\|/usr/sbin/nologin|d' /etc/shells
sed -i '\|/bin/false|d' /etc/shells

# CIS 5.4.3.2 Ensure default user shell timeout is configured (Automated)
echo "CIS 5.4.3.2 Ensuring default user shell timeout is configured..."
# Create timeout configuration file
cat > /etc/profile.d/cis-timeout.sh << 'EOF'
# CIS 5.4.3.2 - Configure shell timeout
TMOUT=900
readonly TMOUT
export TMOUT
EOF
chmod 644 /etc/profile.d/cis-timeout.sh

# CIS 5.4.3.3 Ensure default user umask is configured (Automated)
echo "CIS 5.4.3.3 Ensuring default user umask is configured..."
if grep -q '^UMASK' /etc/login.defs; then
    sed -i 's/^UMASK.*/UMASK 027/' /etc/login.defs
else
    echo "UMASK 027" >> /etc/login.defs
fi

# Set umask in shell configuration files
for file in /etc/profile /etc/bash.bashrc; do
    if [ -f "$file" ]; then
        if ! grep -q '^umask 027' "$file"; then
            echo "umask 027" >> "$file"
        fi
    fi
done

echo "User accounts and environment configuration completed successfully for CIS compliance."
