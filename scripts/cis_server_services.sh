#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# CIS 2.1 - Configure Server Services
set -e

echo "Configuring server services for CIS compliance..."

# CIS 2.1.1 Ensure autofs services are not in use (Automated)
echo "Checking autofs services..."
if dpkg-query -s autofs &>/dev/null; then
    echo "autofs is installed - removing..."
    systemctl stop autofs.service 2>/dev/null || true
    apt-get purge -y autofs
else
    echo "autofs is not installed"
fi

# CIS 2.1.2 Ensure avahi daemon services are not in use (Automated)
echo "Checking avahi-daemon services..."
if dpkg-query -s avahi-daemon &>/dev/null; then
    echo "avahi-daemon is installed - removing..."
    systemctl stop avahi-daemon.socket avahi-daemon.service 2>/dev/null || true
    apt-get purge -y avahi-daemon
else
    echo "avahi-daemon is not installed"
fi

# CIS 2.1.3 Ensure dhcp server services are not in use (Automated)
echo "Checking DHCP server services..."
if dpkg-query -s isc-dhcp-server &>/dev/null; then
    echo "isc-dhcp-server is installed - removing..."
    systemctl stop isc-dhcp-server.service isc-dhcp-server6.service 2>/dev/null || true
    apt-get purge -y isc-dhcp-server
else
    echo "isc-dhcp-server is not installed"
fi

# CIS 2.1.4 Ensure dns server services are not in use (Automated)
echo "Checking DNS server services..."
if dpkg-query -s bind9 &>/dev/null; then
    echo "bind9 is installed - removing..."
    systemctl stop named.services 2>/dev/null || true
    apt-get purge -y bind9
else
    echo "bind9 is not installed"
fi

# CIS 2.1.5 Ensure dnsmasq services are not in use (Automated)
echo "Checking dnsmasq services..."
if dpkg-query -s dnsmasq &>/dev/null; then
    echo "dnsmasq is installed - removing..."
    systemctl stop dnsmasq.service 2>/dev/null || true
    apt-get purge -y dnsmasq
else
    echo "dnsmasq is not installed"
fi

# CIS 2.1.6 Ensure ftp server services are not in use (Automated)
echo "Checking FTP server services..."
if dpkg-query -s vsftpd &>/dev/null; then
    echo "vsftpd is installed - removing..."
    systemctl stop vsftpd.service 2>/dev/null || true
    apt-get purge -y vsftpd
else
    echo "vsftpd is not installed"
fi

# CIS 2.1.7 Ensure ldap server services are not in use (Automated)
echo "Checking LDAP server services..."
if dpkg-query -s slapd &>/dev/null; then
    echo "slapd is installed - removing..."
    systemctl stop slapd.service 2>/dev/null || true
    apt-get purge -y slapd
else
    echo "slapd is not installed"
fi

# CIS 2.1.8 Ensure message access server services are not in use (Automated)
echo "Checking message access server services..."
if dpkg-query -s dovecot-imapd &>/dev/null || dpkg-query -s dovecot-pop3d &>/dev/null; then
    echo "dovecot-imapd or dovecot-pop3d is installed - removing..."
    systemctl stop dovecot.socket dovecot.service 2>/dev/null || true
    apt-get purge -y dovecot-imapd dovecot-pop3d
else
    echo "dovecot-imapd and dovecot-pop3d are not installed"
fi

# CIS 2.1.9 Ensure network file system services are not in use (Automated)
echo "Checking NFS services..."
if dpkg-query -s nfs-kernel-server &>/dev/null; then
    echo "nfs-kernel-server is installed - removing..."
    systemctl stop nfs-server.service 2>/dev/null || true
    apt-get purge -y nfs-kernel-server
else
    echo "nfs-kernel-server is not installed"
fi

# CIS 2.1.10 Ensure nis server services are not in use (Automated)
echo "Checking NIS server services..."
if dpkg-query -s ypserv &>/dev/null; then
    echo "ypserv is installed - removing..."
    systemctl stop ypserv.service 2>/dev/null || true
    apt-get purge -y ypserv
else
    echo "ypserv is not installed"
fi

# CIS 2.1.11 Ensure print server services are not in use (Automated)
echo "Checking print server services..."
if dpkg-query -s cups &>/dev/null; then
    echo "cups is installed - removing..."
    ssystemctl stop cups.socket cups.service 2>/dev/null || true
    apt-get purge -y cups
else
    echo "cups is not installed"
fi

# CIS 2.1.12 Ensure rpcbind services are not in use (Automated)
echo "Checking rpcbind services..."
if dpkg-query -s rpcbind &>/dev/null; then
    echo "rpcbind is installed - removing..."
    systemctl stop rpcbind.socket rpcbind.service 2>/dev/null || true
    apt-get purge -y rpcbind
else
    echo "rpcbind is not installed"
fi

# CIS 2.1.13 Ensure rsync services are not in use (Automated)
echo "Checking rsync services..."
if dpkg-query -s rsync &>/dev/null; then
    echo "rsync is installed - removing..."
    systemctl stop rsync.service 2>/dev/null || true
    apt-get purge -y rsync
else
    echo "rsync is not installed"
fi

# CIS 2.1.14 Ensure samba file server services are not in use (Automated)
echo "Checking Samba file server services..."
if dpkg-query -s samba &>/dev/null; then
    echo "samba is installed - removing..."
    systemctl stop smbd.service 2>/dev/null || true
    apt-get purge -y samba
else
    echo "samba is not installed"
fi

# CIS 2.1.15 Ensure snmp services are not in use (Automated)
echo "Checking SNMP services..."
if dpkg-query -s snmpd &>/dev/null; then
    echo "snmpd is installed - removing..."
    systemctl stop snmpd.service 2>/dev/null || true
    apt-get purge -y snmpd
else
    echo "snmpd is not installed"
fi

# CIS 2.1.16 Ensure tftp server services are not in use (Automated)
echo "Checking TFTP server services..."
if dpkg-query -s tftpd-hpa &>/dev/null; then
    echo "tftpd-hpa is installed - removing..."
    systemctl stop tftpd-hpa.service 2>/dev/null || true
    apt-get purge -y tftpd-hpa
else
    echo "tftpd-hpa is not installed"
fi

# CIS 2.1.17 Ensure web proxy server services are not in use (Automated)
echo "Checking web proxy server services..."
if dpkg-query -s squid &>/dev/null; then
    echo "squid is installed - removing..."
    systemctl stop squid.service 2>/dev/null || true
    apt-get purge -y squid
else
    echo "squid is not installed"
fi

# CIS 2.1.18 Ensure web server services are not in use (Automated)
echo "Checking web server services..."
if dpkg-query -s apache2 &>/dev/null || dpkg-query -s nginx &>/dev/null; then
    echo "apache2 is installed - removing..."
    systemctl stop apache2.socket apache2.service nginx.service 2>/dev/null || true
    apt-get purge -y apache2 nginx
else
    echo "apache2 and nginx are not installed"
fi

# CIS 2.1.19 Ensure xinetd services are not in use (Automated)
echo "Checking xinetd services..."
if dpkg-query -s xinetd &>/dev/null; then
    echo "xinetd is installed - removing..."
    systemctl stop xinetd.service 2>/dev/null || true
    apt-get purge -y xinetd
else
    echo "xinetd is not installed"
fi

# CIS 2.1.20 Ensure X window server services are not in use (Automated)
echo "Checking X Window System services..."
if dpkg-query -s xserver-common &>/dev/null; then
    echo "xserver-common is installed - removing X Window System packages..."
    apt-get purge -y xserver-common
else
    echo "xserver-common is not installed"
fi

# CIS 2.1.21 Ensure mail transfer agent is configured for local-only mode (Automated)
echo "Configuring mail transfer agent for local-only mode..."

# Check if any MTA is installed
if dpkg-query -s postfix &>/dev/null || dpkg-query -s sendmail &>/dev/null || dpkg-query -s exim4 &>/dev/null; then

    # Configure Postfix if installed
    if dpkg-query -s postfix &>/dev/null; then
        echo "Configuring Postfix for local-only mode..."
        systemctl stop postfix.service 2>/dev/null || true
        postconf -e "inet_interfaces = loopback-only"
        systemctl start postfix.service 2>/dev/null || true
        echo "Postfix configured for local-only mode"
    fi

    # Note: Sendmail and Exim would require additional configuration
    if dpkg-query -s sendmail &>/dev/null; then
        echo "Note: Sendmail is installed. Manual configuration required for local-only mode."
    fi

    if dpkg-query -s exim4 &>/dev/null; then
        echo "Note: Exim4 is installed. Manual configuration required for local-only mode."
    fi
else
    echo "No mail transfer agent installed"
fi

# CIS 2.1.22 Ensure only approved services are listening on a network interface (Manual)
echo "Manual verification required for network listening services (CIS 2.1.22)"
echo "Run 'ss -tuln' to review listening services and ensure only approved services are enabled"

echo "Server services configuration completed successfully for CIS compliance."
