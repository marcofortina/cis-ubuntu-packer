#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# CIS 6.3 - Configure Integrity Checking
set -e

echo "Configuring integrity checking for CIS compliance..."

# CIS 6.3.1 Ensure AIDE is installed (Automated)
echo "CIS 6.3.1 Ensuring AIDE is installed..."
if ! dpkg-query -s aide &>/dev/null || ! dpkg-query -s aide-common &>/dev/null; then
    apt-get update
    apt-get install -y aide aide-common
else
    echo "AIDE and AIDE-COMMON are already installed"
fi

# Initialize AIDE database
aideinit --yes
mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
chown _aide:_aide /var/lib/aide/aide.db
chmod 600 /var/lib/aide/aide.db

# CIS 6.3.2 Ensure filesystem integrity is regularly checked (Automated)
echo "CIS 6.3.2 Ensuring filesystem integrity is regularly checked..."
systemctl unmask dailyaidecheck.timer dailyaidecheck.service
systemctl enable dailyaidecheck.timer
systemctl start dailyaidecheck.timer

# CIS 6.3.3 Ensure cryptographic mechanisms are used to protect the integrity of audit tools (Automated)
echo "CIS 6.3.3 Ensuring cryptographic mechanisms are used to protect the integrity of audit tools..."

AIDE_CONF="/etc/aide/aide.conf.d/50-audittools"
cat > "$AIDE_CONF" << 'EOF'
# CIS 6.3.3 - Audit Tools Integrity Checks
/usr/sbin/auditctl p+i+n+u+g+s+b+acl+xattrs+sha512
/usr/sbin/auditd p+i+n+u+g+s+b+acl+xattrs+sha512
/usr/sbin/ausearch p+i+n+u+g+s+b+acl+xattrs+sha512
/usr/sbin/aureport p+i+n+u+g+s+b+acl+xattrs+sha512
/usr/sbin/autrace p+i+n+u+g+s+b+acl+xattrs+sha512
/usr/sbin/augenrules p+i+n+u+g+s+b+acl+xattrs+sha512
EOF
chmod 644 $AIDE_CONF
chown root:root $AIDE_CONF

AIDE_CONF="/etc/aide/aide.conf.d/99-excludes"
cat > "$AIDE_CONF" << 'EOF'
# AIDE - exclude temporary and dynamic files

# Exclude PCP temp
!/var/lib/pcp/tmp/

# Exclude system temp
!/tmp/
!/var/tmp/
!/dev/shm/

# Exclude runtime files (pid, sockets)
!/run/
!/var/run/

# Exclude dynamic logs
!/var/log/

# Optional cache directories
!/var/cache/

# Monitor critical logs (attributes only)
/var/log/auth.log          p+i+n+u+g+s+b+acl+xattrs
/var/log/syslog            p+i+n+u+g+s+b+acl+xattrs
/var/log/kern.log          p+i+n+u+g+s+b+acl+xattrs
/var/log/daemon.log        p+i+n+u+g+s+b+acl+xattrs
/var/log/cron.log          p+i+n+u+g+s+b+acl+xattrs
/var/log/sudo.log          p+i+n+u+g+s+b+acl+xattrs
/var/log/user.log          p+i+n+u+g+s+b+acl+xattrs

# Monitor login logs (attributes only)
/var/log/faillog           p+i+n+u+g+s+b+acl+xattrs
/var/log/lastlog           p+i+n+u+g+s+b+acl+xattrs
/var/log/btmp              p+i+n+u+g+s+b+acl+xattrs
/var/log/wtmp              p+i+n+u+g+s+b+acl+xattrs

# Exclude dynamic spool
!/var/spool/

# Monitor cron spool (hash + attributes)
/var/spool/cron/           p+i+n+u+g+s+b+acl+xattrs+sha512

# Exclude user mailboxes
!/var/mail/

# Exclude MySQL data directory to avoid false positives from continuously changing database files
!/var/lib/mysql/
EOF
chmod 644 "$AIDE_CONF"
chown root:root "$AIDE_CONF"

# Update AIDE database if configuration changed
if [ -f /var/lib/aide/aide.db ]; then
    echo "Updating AIDE database..."
    aide --config /etc/aide/aide.conf --update || true
    # Check if new database was created and replace the old one
    if [ -f /var/lib/aide/aide.db.new ]; then
        mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
        chown _aide:_aide /var/lib/aide/aide.db
        chmod 600 /var/lib/aide/aide.db
    fi
fi

echo "Integrity checking configuration completed successfully for CIS compliance."
