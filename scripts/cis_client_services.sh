#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# CIS 2.2 - Configure Client Services
set -e

echo "Configuring client services for CIS compliance..."

# CIS 2.2.1 Ensure NIS Client is not installed (Automated)
echo "Checking NIS client..."
if dpkg-query -s nis &>/dev/null; then
    echo "nis is installed - removing..."
    apt-get purge -y nis
else
    echo "nis is not installed"
fi

# CIS 2.2.2 Ensure rsh client is not installed (Automated)
echo "Checking rsh client..."
if dpkg-query -s rsh-client &>/dev/null; then
    echo "rsh-client is installed - removing..."
    apt-get purge -y rsh-client
else
    echo "rsh-client is not installed"
fi

# CIS 2.2.3 Ensure talk client is not installed (Automated)
echo "Checking talk client..."
if dpkg-query -s talk &>/dev/null; then
    echo "talk is installed - removing..."
    apt-get purge -y talk
else
    echo "talk is not installed"
fi

# CIS 2.2.4 Ensure telnet client is not installed (Automated)
echo "Checking telnet client..."
if dpkg-query -s telnet &>/dev/null || dpkg-query -s inetutils-telnet &>/dev/null; then
    echo "telnet or inetutils-telnet is installed - removing..."
    apt-get purge -y telnet inetutils-telnet
else
    echo "telnet and inetutils-telnet are not installed"
fi

# CIS 2.2.5 Ensure ldap client is not installed (Automated)
echo "Checking LDAP client..."
if dpkg-query -s ldap-utils &>/dev/null; then
    echo "ldap-utils is installed - removing..."
    apt-get purge -y ldap-utils
else
    echo "ldap-utils is not installed"
fi

# CIS 2.2.6 Ensure ftp client is not installed (Automated)
echo "Checking FTP client..."
if dpkg-query -s ftp &>/dev/null || dpkg-query -s tnftp &>/dev/null; then
    echo "ftp ore tnftp is installed - removing..."
    apt-get purge -y ftp tnftp
else
    echo "ftp and tnftp are not installed"
fi

echo "Client services configuration completed successfully for CIS compliance."
