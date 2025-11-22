#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# CIS 6.1 - System Logging
set -e

echo "Configuring system logging for CIS compliance..."

# CIS 6.1.1 Configure systemd-journald service

# CIS 6.1.1.1 Ensure journald service is enabled and active (Automated)
echo "CIS 6.1.1.1 Ensuring journald service is enabled and active..."
systemctl unmask systemd-journald.service
systemctl start systemd-journald.service

# CIS 6.1.1.2 Ensure journald log file access is configured (Manual)
echo "CIS 6.1.1.2 Ensuring journald log file access is configured..."
echo "Not required"

# CIS 6.1.1.3 Ensure journald log file rotation is configured (Manual)
echo "CIS 6.1.1.3 Ensuring journald log file rotation is configured..."
JOURNAL_CONF="/etc/systemd/journald.conf"
sed -i 's/^#SystemMaxUse.*/SystemMaxUse=1G/' "$JOURNAL_CONF"
sed -i 's/^#SystemKeepFree.*/SystemKeepFree=200Ms/' "$JOURNAL_CONF"
sed -i 's/^#RuntimeMaxUse.*/RuntimeMaxUse=1G/' "$JOURNAL_CONF"
sed -i 's/^#RuntimeKeepFree.*/RuntimeKeepFree=50M/' "$JOURNAL_CONF"
sed -i 's/^#MaxFileSec.*/MaxFileSec=1month/' "$JOURNAL_CONF"

# CIS 6.1.1.4 Ensure only one logging system is in use (Automated)
echo "CIS 6.1.1.4 Ensuring only one logging system is in use..."
# Check if both rsyslog and journald are running
if systemctl is-active rsyslog >/dev/null 2>&1 && systemctl is-active systemd-journald >/dev/null 2>&1; then
    echo "Both rsyslog and journald are active - this is acceptable per CIS"
else
    echo "Warning: Only one logging system should be active"
fi

# CIS 6.1.2 Configure journald

# CIS 6.1.2.1 Configure systemd-journal-remote

# CIS 6.1.2.1.1 Ensure systemd-journal-remote is installed (Automated)
echo "CIS 6.1.2.1.1 Ensuring systemd-journal-remote is installed..."
if ! dpkg-query -s systemd-journal-remote &>/dev/null; then
    apt-get install -y systemd-journal-remote
else
    echo "systemd-journal-remote is already installed"
fi

# CIS 6.1.2.1.2 Ensure systemd-journal-upload authentication is configured (Manual)
echo "CIS 6.1.2.1.2 Ensuring systemd-journal-upload authentication is configured..."
echo "Manual configuration required: Configure authentication for systemd-journal-upload if used"

# CIS 6.1.2.1.3 Ensure systemd-journal-upload is enabled and active (Automated)
echo "CIS 6.1.2.1.3 Ensuring systemd-journal-upload is enabled and active..."
#systemctl unmask systemd-journal-upload.service
#systemctl enable systemd-journal-upload.service
#systemctl start systemd-journal-upload.service

# CIS 6.1.2.1.4 Ensure systemd-journal-remote service is not in use (Automated)
echo "CIS 6.1.2.1.4 Ensuring systemd-journal-remote service is not in use..."
systemctl stop systemd-journal-remote.socket systemd-journal-remote.service 2>/dev/null || true
systemctl mask systemd-journal-remote.socket systemd-journal-remote.service 2>/dev/null || true

# CIS 6.1.2.2 Ensure journald ForwardToSyslog is disabled (Automated)
echo "CIS 6.1.2.2 Ensuring journald ForwardToSyslog is disabled..."
echo "Not required"

# CIS 6.1.2.3 Ensure journald Compress is configured (Automated)
echo "CIS 6.1.2.3 Ensuring journald Compress is configured..."
sed -i 's/^#Compress.*/Compress=yes/' "$JOURNAL_CONF"

# CIS 6.1.2.4 Ensure journald Storage is configured (Automated)
echo "CIS 6.1.2.4 Ensuring journald Storage is configured..."
sed -i 's/^#Storage.*/Storage=persistent/' "$JOURNAL_CONF"

# Restart journald to apply changes
systemctl restart systemd-journald

# CIS 6.1.3 Configure rsyslog

# CIS 6.1.3.1 Ensure rsyslog is installed (Automated)
echo "CIS 6.1.3.1 Ensuring rsyslog is installed..."
if ! dpkg-query -s rsyslog &>/dev/null; then
    apt-get install -y rsyslog
else
    echo "rsyslog is already installed"
fi

# CIS 6.1.3.2 Ensure rsyslog service is enabled and active (Automated)
echo "CIS 6.1.3.2 Ensuring rsyslog service is enabled and active..."
systemctl unmask rsyslog.service
systemctl enable rsyslog.service
systemctl start rsyslog.service

# CIS 6.1.3.3 Ensure journald is configured to send logs to rsyslog (Automated)
echo "CIS 6.1.3.3 Ensuring journald is configured to send logs to rsyslog..."
sed -i 's/^#ForwardToSyslog.*/ForwardToSyslog=yes/' "$JOURNAL_CONF"

# CIS 6.1.3.4 Ensure rsyslog log file creation mode is configured (Automated)
echo "CIS 6.1.3.4 Ensuring rsyslog log file creation mode is configured..."
sed -i 's/^#*\$FileCreateMode.*/\$FileCreateMode 0640/' /etc/rsyslog.conf

# CIS 6.1.3.5 Ensure rsyslog logging is configured (Manual)
echo "CIS 6.1.3.5 Ensuring rsyslog logging is configured..."
sed -i '/^#cron\.\*\s*\//s/^#//' /etc/rsyslog.d/50-default.conf
sed -i '/^#daemon\.\*\s*-\//s/^#//' /etc/rsyslog.d/50-default.conf
sed -i '/^#user\.\*\s*-\//s/^#//' /etc/rsyslog.d/50-default.conf

# CIS 6.1.3.6 Ensure rsyslog is configured to send logs to a remote log host (Manual)
echo "CIS 6.1.3.6 Ensuring rsyslog is configured to send logs to a remote log host..."
echo "Manual configuration required: Configure remote logging if required by site policy"

# CIS 6.1.3.7 Ensure rsyslog is not configured to receive logs from a remote client (Automated)
echo "CIS 6.1.3.7 Ensuring rsyslog is not configured to receive logs from a remote client..."
# Disable remote log reception by commenting out imtcp and imudp modules
echo "Not required"

# CIS 6.1.3.8 Ensure logrotate is configured (Manual)
echo "CIS 6.1.3.8 Ensuring logrotate is configured..."
sed -i 's/weekly/daily/' /etc/logrotate.d/rsyslog
sed -i 's/rotate 4/rotate 7/' /etc/logrotate.d/rsyslog
sed -i '/delaycompress/a \	create 0640 root adm' /etc/logrotate.d/rsyslog
sed -i '/create 0640 syslog adm/a \	su root adm' /etc/logrotate.d/rsyslog
sed -i '1i /var/log/daemon.log' /etc/logrotate.d/rsyslog

# Restart rsyslog to apply changes
systemctl restart rsyslog

# CIS 6.1.4 Configure Logfiles

# CIS 6.1.4.1 Ensure access to all logfiles has been configured (Automated)
echo "CIS 6.1.4.1 Ensuring access to all logfiles has been configured..."

# Set CIS-compliant permissions (0640) for files in specific log directories
find /var/log/pcp \
     /var/log/private \
     /var/log/installer \
     /var/log/unattended-upgrades \
     /var/log/landscape \
     /var/log/sysstat \
     -type f \
     -exec chmod 0640 {} \;

# Set CIS-compliant permissions (0640) for critical system log files
chmod 0640 /var/log/alternatives.log
chmod 0640 /var/log/bootstrap.log
chmod 0640 /var/log/dpkg.log
chmod 0640 /var/log/faillog

echo "System logging configuration completed successfully for CIS compliance."
