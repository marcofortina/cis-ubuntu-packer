#!/bin/bash

# CIS 1.6 - Configure Command Line Warning Banners
set -e

echo "Configuring command line warning banners for CIS compliance..."

# -------------------------
# CIS 1.6.1 Ensure message of the day is configured properly (Automated)
# -------------------------
echo "Configuring message of the day..."
if [ -f /etc/motd ]; then
    echo "Removing /etc/motd file as per CIS guidelines..."
    rm -f /etc/motd
else
    echo "/etc/motd does not exist, no action needed"
fi

# -------------------------
# CIS 1.6.2 Ensure local login warning banner is configured properly (Automated)
# -------------------------
echo "Configuring local login warning banner..."
cat << 'EOF' > /etc/issue
Authorized uses only. All activity may be monitored and reported.

EOF
chown root:root /etc/issue
chmod 644 /etc/issue

# -------------------------
# CIS 1.6.3 Ensure remote login warning banner is configured properly (Automated)
# -------------------------
echo "Configuring remote login warning banner..."
cat << 'EOF' > /etc/issue.net
Authorized uses only. All activity may be monitored and reported.

EOF
chown root:root /etc/issue.net
chmod 644 /etc/issue.net

# -------------------------
# CIS 1.6.4 Ensure access to /etc/motd is configured (Automated)
# -------------------------
# Only configure permissions if the file exists (we removed it above, but check anyway)
if [ -f /etc/motd ]; then
    echo "Configuring permissions for /etc/motd..."
    chown root:root /etc/motd
    chmod u-x,go-wx /etc/motd
else
    echo "/etc/motd does not exist, permission configuration not needed"
fi

# -------------------------
# CIS 1.6.5 Ensure access to /etc/issue is configured (Automated)
# -------------------------
echo "Configuring permissions for /etc/issue..."
chown root:root /etc/issue
chmod u-x,go-wx /etc/issue

# -------------------------
# CIS 1.6.6 Ensure access to /etc/issue.net is configured (Automated)
# -------------------------
echo "Configuring permissions for /etc/issue.net..."
chown root:root /etc/issue.net
chmod u-x,go-wx /etc/issue.net

echo "Command line warning banners configured successfully for CIS compliance."
