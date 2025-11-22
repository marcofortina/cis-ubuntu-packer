#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# CIS 2.4 - Configure Job Schedulers
set -e

echo "Configuring job schedulers for CIS compliance..."

# CIS 2.4.1 Configure cron
echo "Configuring cron job scheduler..."

# CIS 2.4.1.1 Ensure cron daemon is enabled and active (Automated)
echo "Ensuring cron daemon is enabled and active..."
systemctl enable cron
systemctl start cron

# CIS 2.4.1.2 Ensure permissions on /etc/crontab are configured (Automated)
echo "Configuring permissions on /etc/crontab..."
chown root:root /etc/crontab
chmod 600 /etc/crontab

# CIS 2.4.1.3 Ensure permissions on /etc/cron.hourly are configured (Automated)
echo "Configuring permissions on /etc/cron.hourly..."
chown root:root /etc/cron.hourly
chmod 700 /etc/cron.hourly

# CIS 2.4.1.4 Ensure permissions on /etc/cron.daily are configured (Automated)
echo "Configuring permissions on /etc/cron.daily..."
chown root:root /etc/cron.daily
chmod 700 /etc/cron.daily

# CIS 2.4.1.5 Ensure permissions on /etc/cron.weekly are configured (Automated)
echo "Configuring permissions on /etc/cron.weekly..."
chown root:root /etc/cron.weekly
chmod 700 /etc/cron.weekly

# CIS 2.4.1.6 Ensure permissions on /etc/cron.monthly are configured (Automated)
echo "Configuring permissions on /etc/cron.monthly..."
chown root:root /etc/cron.monthly
chmod 700 /etc/cron.monthly

# CIS 2.4.1.7 Ensure permissions on /etc/cron.d are configured (Automated)
echo "Configuring permissions on /etc/cron.d..."
chown root:root /etc/cron.d
chmod 700 /etc/cron.d

# CIS 2.4.1.8 Ensure crontab is restricted to authorized users (Automated)
echo "Restricting crontab to authorized users..."

# Create cron.allow file and remove cron.deny if it exists
echo "root" > /etc/cron.allow
chown root:root /etc/cron.allow
chmod 600 /etc/cron.allow

# Remove cron.deny file to ensure only cron.allow is used
if [ -f /etc/cron.deny ]; then
    rm -f /etc/cron.deny
    echo "Removed /etc/cron.deny"
fi

# CIS 2.4.2 Configure at (not used - ensuring it's not installed)
echo "Checking at job scheduler..."
if dpkg-query -s at &>/dev/null; then
    echo "at is installed - removing as it's not required..."
    # Stop and disable at service
    systemctl stop atd 2>/dev/null || true
    # Remove at package
    apt-get purge -y at
    echo "at removed successfully"
else
    echo "at is not installed"
fi

echo "Job schedulers configuration completed successfully for CIS compliance."
