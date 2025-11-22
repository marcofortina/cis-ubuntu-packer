#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# CIS 6.2 - Configure System Auditing
set -e

echo "Configuring system auditing for CIS compliance..."

# CIS 6.2.1 Configure auditd Service

# CIS 6.2.1.1 Ensure auditd packages are installed (Automated)
echo "CIS 6.2.1.1 Ensuring auditd packages are installed..."
if ! dpkg-query -s auditd audispd-plugins &>/dev/null; then
    apt-get update
    apt-get install -y auditd audispd-plugins
else
    echo "auditd packages are already installed"
fi

# CIS 6.2.1.2 Ensure auditd service is enabled and active (Automated)
echo "CIS 6.2.1.2 Ensuring auditd service is enabled and active..."
systemctl unmask auditd
systemctl enable auditd
systemctl start auditd

# CIS 6.2.1.3 Ensure auditing for processes that start prior to auditd is enabled (Automated)
echo "CIS 6.2.1.3 Ensuring auditing for processes that start prior to auditd is enabled..."
GRUB_FILE="/etc/default/grub"
if ! grep -q "audit=1" "$GRUB_FILE"; then
    sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 audit=1"/' "$GRUB_FILE"
    update-grub
else
    echo "audit=1 is already configured in GRUB"
fi

# CIS 6.2.1.4 Ensure audit_backlog_limit is sufficient (Automated)
echo "CIS 6.2.1.4 Ensuring audit_backlog_limit is sufficient..."
if ! grep -q "audit_backlog_limit=8192" "$GRUB_FILE"; then
    sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 audit_backlog_limit=8192"/' "$GRUB_FILE"
    update-grub
else
    echo "audit_backlog_limit=8192 is already configured in GRUB"
fi

# CIS 6.2.2 Configure Data Retention

# CIS 6.2.2.1 Ensure audit log storage size is configured (Automated)
echo "CIS 6.2.2.1 Ensuring audit log storage size is configured..."
AUDITD_CONF="/etc/audit/auditd.conf"
sed -i 's/^max_log_file =.*/max_log_file = 8/' "$AUDITD_CONF"

# CIS 6.2.2.2 Ensure audit logs are not automatically deleted (Automated)
echo "CIS 6.2.2.2 Ensuring audit logs are not automatically deleted..."
sed -i 's/^max_log_file_action =.*/max_log_file_action = keep_logs/' "$AUDITD_CONF"

# CIS 6.2.2.3 Ensure system is disabled when audit logs are full (Automated)
echo "CIS 6.2.2.3 Ensuring system is disabled when audit logs are full..."
sed -i 's/^disk_full_action =.*/disk_full_action = single/' "$AUDITD_CONF"
sed -i 's/^disk_error_action =.*/disk_error_action = single/' "$AUDITD_CONF"


# CIS 6.2.2.4 Ensure system warns when audit logs are low on space (Automated)
echo "CIS 6.2.2.4 Ensure system warns when audit logs are low on space..."
sed -i 's/^space_left_action =.*/space_left_action = email/' "$AUDITD_CONF"
sed -i 's/^action_mail_acct =.*/action_mail_acct = root/' "$AUDITD_CONF"
sed -i 's/^admin_space_left_action =.*/admin_space_left_action = single/' "$AUDITD_CONF"

# CIS 6.2.3 Configure auditd Rules
echo "CIS 6.2.3 Configuring auditd rules..."

# Create CIS audit rules file
RULES_FILE="/etc/audit/rules.d/50-scope.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.1 Ensure changes to system administration scope (sudoers) is collected
-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d -p wa -k scope
EOF

RULES_FILE="/etc/audit/rules.d/50-user_emulation.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.2 Ensure actions as another user are always logged
-a always,exit -F arch=b64 -C euid!=uid -F auid!=unset -S execve -k user_emulation
-a always,exit -F arch=b32 -C euid!=uid -F auid!=unset -S execve -k user_emulation
EOF

RULES_FILE="/etc/audit/rules.d/50-sudo.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.3 Ensure events that modify the sudo log file are collected
-w /var/log/sudo.log -p wa -k sudo_log_file
EOF

RULES_FILE="/etc/audit/rules.d/50-time-change.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.4 Ensure events that modify date and time information are collected
-a always,exit -F arch=b64 -S adjtimex,settimeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex,settimeofday -k time-change
-a always,exit -F arch=b64 -S clock_settime -F a0=0x0 -k time-change
-a always,exit -F arch=b32 -S clock_settime -F a0=0x0 -k time-change
-w /etc/localtime -p wa -k time-change
EOF

RULES_FILE="/etc/audit/rules.d/50-system_locale.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.5 Ensure events that modify the system's network environment are collected
-a always,exit -F arch=b64 -S sethostname,setdomainname -k system-locale
-a always,exit -F arch=b32 -S sethostname,setdomainname -k system-locale
-w /etc/issue -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/networks -p wa -k system-locale
-w /etc/network/ -p wa -k system-locale
-w /etc/netplan/ -p wa -k system-locale
EOF

RULES_FILE="/etc/audit/rules.d/50-privileged.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.6 Ensure use of privileged commands are collected
-a always,exit -F path=/usr/bin/chage -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/bin/chfn -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/bin/chsh -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/bin/crontab -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/bin/expiry -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/bin/fusermount3 -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/bin/gpasswd -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/bin/mount -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/bin/newgrp -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/bin/passwd -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/bin/ssh-agent -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/bin/su -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/bin/umount -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/lib/dbus-1.0/dbus-daemon-launch-helper -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/lib/openssh/ssh-keysign -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/lib/polkit-1/polkit-agent-helper-1 -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/lib/x86_64-linux-gnu/utempter/utempter -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/sbin/pam_extrausers_chkpwd -F perm=x -F auid>=1000 -F auid!=unset -k privileged
-a always,exit -F path=/usr/sbin/unix_chkpwd -F perm=x -F auid>=1000 -F auid!=unset -k privileged
EOF

RULES_FILE="/etc/audit/rules.d/50-access.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.7 Ensure unsuccessful file access attempts are collected
-a always,exit -F arch=b64 -S creat,open,openat,truncate,ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=unset -k access
-a always,exit -F arch=b64 -S creat,open,openat,truncate,ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=unset -k access
-a always,exit -F arch=b32 -S creat,open,openat,truncate,ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=unset -k access
-a always,exit -F arch=b32 -S creat,open,openat,truncate,ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=unset -k access
EOF

RULES_FILE="/etc/audit/rules.d/50-identity.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.8 Ensure events that modify user/group information are collected
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity
-w /etc/nsswitch.conf -p wa -k identity
-w /etc/pam.conf -p wa -k identity
-w /etc/pam.d -p wa -k identity
EOF

RULES_FILE="/etc/audit/rules.d/50-perm_mod.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.9 Ensure discretionary access control permission modification events are collected
-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat -F auid>=1000 -F auid!=unset -F key=perm_mod
-a always,exit -F arch=b64 -S chown,fchown,lchown,fchownat -F auid>=1000 -F auid!=unset -F key=perm_mod
-a always,exit -F arch=b32 -S chmod,fchmod,fchmodat -F auid>=1000 -F auid!=unset -F key=perm_mod
-a always,exit -F arch=b32 -S lchown,fchown,chown,fchownat -F auid>=1000 -F auid!=unset -F key=perm_mod
-a always,exit -F arch=b64 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=1000 -F auid!=unset -F key=perm_mod
-a always,exit -F arch=b32 -S  setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=1000 -F auid!=unset -F key=perm_mod
EOF

RULES_FILE="/etc/audit/rules.d/50-mounts.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.10 Ensure successful file system mounts are collected
-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=unset -k mounts
-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=unset -k mounts
EOF

RULES_FILE="/etc/audit/rules.d/50-session.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.11 Ensure session initiation information is collected
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k session
-w /var/log/btmp -p wa -k session
EOF

RULES_FILE="/etc/audit/rules.d/50-login.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.12 Ensure login and logout events are collected
-w /var/log/lastlog -p wa -k logins
-w /var/run/faillock -p wa -k logins
EOF

RULES_FILE="/etc/audit/rules.d/50-delete.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.13 Ensure file deletion events by users are collected
-a always,exit -F arch=b64 -S rename,unlink,unlinkat,renameat -F auid>=1000 -F auid!=unset -F key=delete
-a always,exit -F arch=b32 -S rename,unlink,unlinkat,renameat -F auid>=1000 -F auid!=unset -F key=delete
EOF

RULES_FILE="/etc/audit/rules.d/50-MAC-policy.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.14 Ensure events that modify the system's Mandatory Access Controls are collected
-w /etc/apparmor/ -p wa -k MAC-policy
-w /etc/apparmor.d/ -p wa -k MAC-policy
EOF

RULES_FILE="/etc/audit/rules.d/50-perm_chng.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.15 Ensure successful and unsuccessful attempts to use the chcon command are collected
-a always,exit -F path=/usr/bin/chcon -F perm=x -F auid>=1000 -F auid!=unset -k perm_chng

# CIS 6.2.3.16 Ensure successful and unsuccessful attempts to use the setfacl command are collected
-a always,exit -F path=/usr/bin/setfacl -F perm=x -F auid>=1000 -F auid!=unset -k perm_chng

# CIS 6.2.3.17 Ensure successful and unsuccessful attempts to use the chacl command are collected
-a always,exit -F path=/usr/bin/chacl -F perm=x -F auid>=1000 -F auid!=unset -k perm_chng
EOF

RULES_FILE="/etc/audit/rules.d/50-usermod.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.18 Ensure successful and unsuccessful attempts to use the usermod command are collected
-a always,exit -F path=/usr/sbin/usermod -F perm=x -F auid>=1000 -F auid!=unset -k usermod
EOF

RULES_FILE="/etc/audit/rules.d/50-kernel_modules.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.19 Ensure kernel module loading unloading and modification is collected
-a always,exit -F arch=b64 -S init_module,finit_module,delete_module,create_module,query_module -F auid>=1000 -F auid!=unset -k kernel_modules
-a always,exit -F path=/usr/bin/kmod -F perm=x -F auid>=1000 -F auid!=unset -k kernel_modules
EOF

RULES_FILE="/etc/audit/rules.d/99-finalize.rules"
cat > "$RULES_FILE" << 'EOF'
# CIS 6.2.3.20 Ensure the audit configuration is immutable
-e 2
EOF

# CIS 6.2.3.21 Ensure the running and on disk configuration is the same (Manual)
echo "CIS 6.2.3.21 Manual verification required for running and on disk configuration"
augenrules --check
augenrules --load
systemctl restart auditd

# CIS 6.2.3 Configure auditd File Access
echo "CIS 6.2.3 Configuring auditd file access..."

# CIS 6.2.4.1 Ensure audit log files mode is configured (Automated)
echo "CIS 6.2.4.1 Ensuring audit log files mode is configured..."
chmod 0640 /var/log/audit/audit.log

# CIS 6.2.4.2 Ensure audit log files owner is configured (Automated)
echo "CIS 6.2.4.2 Ensuring audit log files owner is configured..."
chown root /var/log/audit/audit.log

# CIS 6.2.4.3 Ensure audit log files group owner is configured (Automated)
echo "CIS 6.2.4.3 Ensuring audit log files group owner is configured..."
chgrp adm /var/log/audit/audit.log

# CIS 6.2.4.4 Ensure the audit log file directory mode is configured (Automated)
echo "CIS 6.2.4.4 Ensuring the audit log file directory mode is configured..."
chmod 0750 /var/log/audit

# CIS 6.2.4.5 Ensure audit configuration files mode is configured (Automated)
echo "CIS 6.2.4.5 Ensuring audit configuration files mode is configured..."
find /etc/audit/ -type f \( -name '*.conf' -o -name '*.rules' \) -exec chmod 0640 {} \;

# CIS 6.2.4.6 Ensure audit configuration files owner is configured (Automated)
echo "CIS 6.2.4.6 Ensuring audit configuration files owner is configured..."
find /etc/audit/ -type f \( -name '*.conf' -o -name '*.rules' \) -exec chown root {} \;

# CIS 6.2.4.7 Ensure audit configuration files group owner is configured (Automated)
echo "CIS 6.2.4.7 Ensuring audit configuration files group owner is configured..."
find /etc/audit/ -type f \( -name '*.conf' -o -name '*.rules' \) -exec chgrp root {} \;

# CIS 6.2.4.8 Ensure audit tools mode is configured (Automated)
echo "CIS 6.2.4.8 Ensuring audit tools mode is configured..."
echo "Not required"

# CIS 6.2.4.9 Ensure audit tools owner is configured (Automated)
echo "Not required"

# CIS 6.2.4.10 Ensure audit tools group owner is configured (Automated)
echo "CIS 6.2.4.10 Ensuring audit tools group owner is configured..."
echo "Not required"

echo "System auditing configuration completed successfully for CIS compliance."
