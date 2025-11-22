# --------------------------------------------------------------------------
# Packer Configuration
# --------------------------------------------------------------------------
packer {
  required_version = ">= 1.9.0"
  required_plugins {
    virtualbox = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

# --------------------------------------------------------------------------
# Sensitive Variables (use environment variables or vault)
# --------------------------------------------------------------------------
variable "hostname" {
  type    = string
}

variable "ssh_password" {
  type      = string
  sensitive = true
}

variable "hashed_ssh_password" {
  type      = string
  sensitive = true
}

variable "grub_password" {
  type      = string
  sensitive = true
}

variable "luks_key" {
  type      = string
  sensitive = true
}

variable "ssh_public_key" {
  type      = string
}

variable "iso_checksum" {
  type    = string
  default = "c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
}

variable "iso_url" {
  type    = string
  default = "file:///home/s0n1k/Downloads/ubuntu-24.04.3-live-server-amd64.iso"
}

locals {
  sudo_password = var.ssh_password
}

# --------------------------------------------------------------------------
# VirtualBox ISO Source
# --------------------------------------------------------------------------
source "virtualbox-iso" "ubuntu" {
  # Name of the VM to create
  vm_name      = var.hostname

  # ISO image location and checksum for verification
  iso_url      = var.iso_url
  iso_checksum = "sha256:${var.iso_checksum}"

  # Guest OS type, CPUs, RAM and disk size
  guest_os_type = "Ubuntu_64"
  cpus          = 2
  memory        = 4096
  disk_size     = 100000
  gfx_vram_size = 16
  firmware      = "efi"
  hard_drive_interface = "scsi"
  iso_interface = "sata"

  guest_additions_mode = "disable"

  # Serve cloud-init via HTTP directly
  http_content = {
    "/meta-data" = file("${path.root}/http/meta-data")
    "/user-data" = templatefile("${path.root}/http/user-data.tpl", {var = var, local = local})
  }

  # SSH credentials and timeout for Packer to connect to the VM
  ssh_username = "ubuntu"
  ssh_private_key_file = "~/.ssh/id_rsa"
  ssh_timeout  = "30m"

  # Wait time for the VM to boot before sending boot commands
  boot_wait = "5s"

  # Boot commands to perform automated installation (Autoinstall/Cloud-Init)
  boot_command = [
    "<esc><wait>",  # Escape to boot menu
    "c<wait5>",     # Enter command mode
    "linux /casper/vmlinuz --- autoinstall ",  # Boot Linux kernel with autoinstall
    "ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/' ",  # Cloud-init data source
    "<enter><wait>",
    "initrd /casper/initrd",  # Specify initial RAM disk
    "<enter><wait>",
    "boot<enter>"  # Boot the kernel
  ]

  # Command to gracefully shutdown the VM after provisioning
  shutdown_command = "echo ${local.sudo_password} | sudo -S shutdown -P now"

  # Extra VirtualBox options
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--nat-localhostreachable1", "on"],
    ["modifyvm", "{{.Name}}", "--audio", "none"],           # Disable audio
    ["modifyvm", "{{.Name}}", "--usb", "off"],              # Disable USB
    ["modifyvm", "{{.Name}}", "--clipboard", "disabled"],   # Disable clipboard
    ["modifyvm", "{{.Name}}", "--draganddrop", "disabled"], # Disable drag&drop
    ["modifyvm", "{{.Name}}", "--paravirtprovider", "kvm"], # Better performance
  ]

  # Keep VM registered in VirtualBox and skip export to OVF
  keep_registered = true
  #skip_export     = true
}

# --------------------------------------------------------------------------
# Build: CIS Hardening Steps
# --------------------------------------------------------------------------
build {
  name    = "ubuntu-2404-cis-web"
  sources = ["source.virtualbox-iso.ubuntu"]

  # ==========================================================================
  # Chapter 1: Initial Setup
  # ==========================================================================

  # --------------------------------------------------------------------------
  # CIS 1.1 - Filesystem Configuration
  # --------------------------------------------------------------------------

  # --------------------------------------------------------------------------
  # CIS 1.1.1 – Configure Filesystem Kernel Modules
  #
  # Includes:
  #
  # > 1.1.1.1 Ensure cramfs kernel module is not available
  # > 1.1.1.2 Ensure freevxfs kernel module is not available
  # > 1.1.1.3 Ensure hfs kernel module is not available
  # > 1.1.1.4 Ensure hfsplus kernel module is not available
  # > 1.1.1.5 Ensure jffs2 kernel module is not available
  # > 1.1.1.6 Ensure overlayfs kernel module is not available
  # > 1.1.1.7 Ensure squashfs kernel module is not available
  # > 1.1.1.8 Ensure udf kernel module is not available
  # > 1.1.1.9 Ensure usb-storage kernel module is not available
  # > 1.1.1.10 Ensure unused filesystems kernel modules are not available
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_fs_modules.sh"
    destination = "/tmp/cis_fs_modules.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_fs_modules.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_fs_modules.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 1.1.2 – Configure Filesystem Partitions
  #
  # Includes:
  #
  # > 1.1.2.1 Configure /tmp
  # > 1.1.2.1.1 Ensure /tmp is a separate partition
  # > 1.1.2.1.2 Ensure nodev option set on /tmp partition
  # > 1.1.2.1.3 Ensure nosuid option set on /tmp partition
  # > 1.1.2.1.4 Ensure noexec option set on /tmp partition
  # > 1.1.2.2 Configure /dev/shm
  # > 1.1.2.2.1 Ensure /dev/shm is a separate partition
  # > 1.1.2.2.2 Ensure nodev option set on /dev/shm partition
  # > 1.1.2.2.3 Ensure nosuid option set on /dev/shm partition
  # > 1.1.2.2.4 Ensure noexec option set on /dev/shm partition
  # > 1.1.2.3 Configure /home
  # > 1.1.2.3.1 Ensure separate partition exists for /home
  # > 1.1.2.3.2 Ensure nodev option set on /home partition
  # > 1.1.2.3.3 Ensure nosuid option set on /home partition
  # > 1.1.2.4 Configure /var
  # > 1.1.2.4.1 Ensure separate partition exists for /var
  # > 1.1.2.4.2 Ensure nodev option set on /var partition
  # > 1.1.2.4.3 Ensure nosuid option set on /var partition
  # > 1.1.2.5 Configure /var/tmp
  # > 1.1.2.5.1 Ensure separate partition exists for /var/tmp
  # > 1.1.2.5.2 Ensure nodev option set on /var/tmp partition
  # > 1.1.2.5.3 Ensure nosuid option set on /var/tmp partition
  # > 1.1.2.5.4 Ensure noexec option set on /var/tmp partition
  # > 1.1.2.6 Configure /var/log
  # > 1.1.2.6.1 Ensure separate partition exists for /var/log
  # > 1.1.2.6.2 Ensure nodev option set on /var/log partition
  # > 1.1.2.6.3 Ensure nosuid option set on /var/log partition
  # > 1.1.2.6.4 Ensure noexec option set on /var/log partition
  # > 1.1.2.7 Configure /var/log/audit
  # > 1.1.2.7.1 Ensure separate partition exists for /var/log/audit
  # > 1.1.2.7.2 Ensure nodev option set on /var/log/audit partition
  # > 1.1.2.7.3 Ensure nosuid option set on /var/log/audit partition
  # > 1.1.2.7.4 Ensure noexec option set on /var/log/audit partition
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_partitions.sh"
    destination = "/tmp/cis_partitions.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_partitions.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_partitions.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 1.2 - Package Management
  #
  # Includes:
  #
  # > 1.2.1 Configure Package Repositories
  # > 1.2.1.1 Ensure GPG keys are configured
  # > 1.2.1.2 Ensure package manager repositories are configured
  # > 1.2.2 Configure Package Updates
  # > 1.2.2.1 Ensure updates, patches, and additional security software are installed
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_package.sh"
    destination = "/tmp/cis_package.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_package.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_package.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 1.3 - Mandatory Access Control
  #
  # Includes:
  #
  # > 1.3.1 Configure AppArmor
  # > 1.3.1.1 Ensure AppArmor is installed
  # > 1.3.1.2 Ensure AppArmor is enabled in the bootloader configuration
  # > 1.3.1.3 Ensure all AppArmor profiles are in enforce or complain mode
  # > 1.3.1.4 Ensure all AppArmor profiles are enforcing
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_apparmor.sh"
    destination = "/tmp/cis_apparmor.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_apparmor.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_apparmor.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 1.4 – Configure Bootloader
  #
  # Includes:
  #
  # > 1.4.1 Ensure bootloader password is set
  # > 1.4.2 Ensure access to bootloader config is configured
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_grub.sh"
    destination = "/tmp/cis_grub.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_grub.sh",
      "echo ${local.sudo_password} | sudo -S GRUB_PASSWORD=${var.grub_password} /tmp/cis_grub.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 1.5 – Configure Additional Process Hardening
  #
  # Includes:
  #
  # > 1.5.1 Ensure address space layout randomization is enabled
  # > 1.5.2 Ensure ptrace_scope is restricted
  # > 1.5.3 Ensure core dumps are restricted
  # > 1.5.4 Ensure prelink is not installed
  # > 1.5.5 Ensure Automatic Error Reporting is not enabled
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_process_hardening.sh"
    destination = "/tmp/cis_process_hardening.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_process_hardening.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_process_hardening.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 1.6 – Configure Command Line Warning Banners
  #
  # Includes:
  #
  # > 1.6.1 Ensure message of the day is configured properly
  # > 1.6.2 Ensure local login warning banner is configured properly
  # > 1.6.3 Ensure remote login warning banner is configured properly
  # > 1.6.4 Ensure access to /etc/motd is configured
  # > 1.6.5 Ensure access to /etc/issue is configured
  # > 1.6.6 Ensure access to /etc/issue.net is configured
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_banners.sh"
    destination = "/tmp/cis_banners.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_banners.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_banners.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 1.7 – Configure GNOME Display Manager
  #
  # Includes:
  #
  # > 1.7.1 Ensure GDM is removed
  # > 1.7.2 Ensure GDM login banner is configured
  # > 1.7.3 Ensure GDM disable-user-list option is enabled
  # > 1.7.4 Ensure GDM screen locks when the user is idle
  # > 1.7.5 Ensure GDM screen locks cannot be overridden
  # > 1.7.6 Ensure GDM automatic mounting of removable media is disabled
  # > 1.7.7 Ensure GDM disabling automatic mounting of removable media is not overridden
  # > 1.7.8 Ensure GDM autorun-never is enabled
  # > 1.7.9 Ensure GDM autorun-never is not overridden
  # > 1.7.10 Ensure XDMCP is not enabled
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_gdm.sh"
    destination = "/tmp/cis_gdm.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_gdm.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_gdm.sh"
    ]
  }

  # ==========================================================================
  # Chapter 2: Services
  # ==========================================================================

  # --------------------------------------------------------------------------
  # CIS 2.1 – Configure Server Services
  #
  # Includes:
  #
  # > 2.1.1 Ensure autofs services are not in use
  # > 2.1.2 Ensure avahi daemon services are not in use
  # > 2.1.3 Ensure dhcp server services are not in use
  # > 2.1.4 Ensure dns server services are not in use
  # > 2.1.5 Ensure dnsmasq services are not in use
  # > 2.1.6 Ensure ftp server services are not in use
  # > 2.1.7 Ensure ldap server services are not in use
  # > 2.1.8 Ensure message access server services are not in use
  # > 2.1.9 Ensure network file system services are not in use
  # > 2.1.10 Ensure nis server services are not in use
  # > 2.1.11 Ensure print server services are not in use
  # > 2.1.12 Ensure rpcbind services are not in use
  # > 2.1.13 Ensure rsync services are not in use
  # > 2.1.14 Ensure samba file server services are not in use
  # > 2.1.15 Ensure snmp services are not in use
  # > 2.1.16 Ensure tftp server services are not in use
  # > 2.1.17 Ensure web proxy server services are not in use
  # > 2.1.18 Ensure web server services are not in use
  # > 2.1.19 Ensure xinetd services are not in use
  # > 2.1.20 Ensure X window server services are not in use
  # > 2.1.21 Ensure mail transfer agent is configured for local‑only mode
  # > 2.1.22 Ensure only approved services are listening on a network interface
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_server_services.sh"
    destination = "/tmp/cis_server_services.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_server_services.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_server_services.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 2.2 – Configure Client Services
  #
  # Includes:
  #
  # > 2.2.1 Ensure NIS Client is not installed
  # > 2.2.2 Ensure rsh client is not installed
  # > 2.2.3 Ensure talk client is not installed
  # > 2.2.4 Ensure telnet client is not installed
  # > 2.2.5 Ensure ldap client is not installed
  # > 2.2.6 Ensure ftp client is not installed
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_client_services.sh"
    destination = "/tmp/cis_client_services.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_client_services.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_client_services.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 2.3 – Configure Time Synchronization
  #
  # Includes:
  #
  # > 2.3.1 Ensure time synchronization is in use
  # > 2.3.1.1 Ensure a single time synchronization daemon is in use
  # > 2.3.2 Configure systemd-timesyncd
  # > 2.3.2.1 Ensure systemd-timesyncd configured with authorized timeserver
  # > 2.3.2.2 Ensure systemd-timesyncd is enabled and running
  # > 2.3.3 Configure chrony
  # > 2.3.3.1 Ensure chrony is configured with authorized timeserver
  # > 2.3.3.2 Ensure chrony is running as user _chrony
  # > 2.3.3.3 Ensure chrony is enabled and running
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_time_sync.sh"
    destination = "/tmp/cis_time_sync.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_time_sync.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_time_sync.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 2.4 - Job Schedulers
  #
  # Includes:
  #
  # > 2.4.1 Configure cron
  # > 2.4.1.1 Ensure cron daemon is enabled and active
  # > 2.4.1.2 Ensure permissions on /etc/crontab are configured
  # > 2.4.1.3 Ensure permissions on /etc/cron.hourly are configured
  # > 2.4.1.4 Ensure permissions on /etc/cron.daily are configured
  # > 2.4.1.5 Ensure permissions on /etc/cron.weekly are configured
  # > 2.4.1.6 Ensure permissions on /etc/cron.monthly are configured
  # > 2.4.1.7 Ensure permissions on /etc/cron.d are configured
  # > 2.4.1.8 Ensure crontab is restricted to authorized users
  # > 2.4.2 Configure at
  # > 2.4.2.1 Ensure at is restricted to authorized users
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_job_schedulers.sh"
    destination = "/tmp/cis_job_schedulers.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_job_schedulers.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_job_schedulers.sh"
    ]
  }

  # ==========================================================================
  # Chapter 3: Network
  # ==========================================================================

  # --------------------------------------------------------------------------
  # CIS 3.1 – Configure Network Devices
  #
  # Includes:
  #
  # > 3.1.1 Ensure IPv6 status is identified
  # > 3.1.2 Ensure wireless interfaces are disabled
  # > 3.1.3 Ensure bluetooth services are not in use
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_network_services.sh"
    destination = "/tmp/cis_network_services.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_network_services.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_network_services.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 3.2 – Configure Network Kernel Modules
  #
  # Includes:
  #
  # > 3.2.1 Ensure dccp kernel module is not available
  # > 3.2.2 Ensure tipc kernel module is not available
  # > 3.2.3 Ensure rds kernel module is not available
  # > 3.2.4 Ensure sctp kernel module is not available
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_network_modules.sh"
    destination = "/tmp/cis_network_modules.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_network_modules.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_network_modules.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 3.3 – Configure Network Kernel Parameters
  #
  # Includes:
  #
  # > 3.3.1 Ensure ip forwarding is disabled
  # > 3.3.2 Ensure packet redirect sending is disabled
  # > 3.3.3 Ensure bogus icmp responses are ignored
  # > 3.3.4 Ensure broadcast icmp requests are ignored
  # > 3.3.5 Ensure icmp redirects are not accepted
  # > 3.3.6 Ensure secure icmp redirects are not accepted
  # > 3.3.7 Ensure reverse path filtering is enabled
  # > 3.3.8 Ensure source routed packets are not accepted
  # > 3.3.9 Ensure suspicious packets are logged
  # > 3.3.10 Ensure tcp syn cookies is enabled
  # > 3.3.11 Ensure ipv6 router advertisements are not accepted
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_network_kernel_params.sh"
    destination = "/tmp/cis_network_kernel_params.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_network_kernel_params.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_network_kernel_params.sh"
    ]
  }

  # ==========================================================================
  # Chapter 4: Host Based Firewall
  # ==========================================================================

  # --------------------------------------------------------------------------
  # CIS 4.1 - Configure a single firewall utility
  #
  # Includes:
  #
  # > 4.1.1 Ensure a single firewall configuration utility is in use
  # --------------------------------------------------------------------------

  # --------------------------------------------------------------------------
  # CIS 4.2 - Configure UncomplicatedFirewall
  #
  # Includes:
  #
  # > 4.2.1 Ensure ufw is installed
  # > 4.2.2 Ensure iptables-persistent is not installed with ufw
  # > 4.2.3 Ensure ufw service is enabled
  # > 4.2.4 Ensure ufw loopback traffic is configured
  # > 4.2.5 Ensure ufw outbound connections are configured
  # > 4.2.6 Ensure ufw firewall rules exist for all open ports
  # > 4.2.7 Ensure ufw default deny firewall policy
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_firewall.sh"
    destination = "/tmp/cis_firewall.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_firewall.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_firewall.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 4.3 - Configure nftables
  #
  # Includes:
  #
  # > 4.3.1 Ensure nftables is installed
  # > 4.3.2 Ensure ufw is uninstalled or disabled with nftables
  # > 4.3.3 Ensure iptables are flushed with nftables
  # > 4.3.4 Ensure a nftables table exists
  # > 4.3.5 Ensure nftables base chains exist
  # > 4.3.6 Ensure nftables loopback traffic is configured
  # > 4.3.7 Ensure nftables outbound and established connections are configured
  # > 4.3.8 Ensure nftables default deny firewall policy
  # > 4.3.9 Ensure nftables service is enabled
  # > 4.3.10 Ensure nftables rules are permanent
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_nftables.sh"
    destination = "/tmp/cis_nftables.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_nftables.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_nftables.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 4.4 - Configure iptables
  #
  # Includes:
  #
  # > 4.4.1 Configure iptables software
  # > 4.4.1.1 Ensure iptables packages are installed
  # > 4.4.1.2 Ensure nftables is not in use with iptables
  # > 4.4.1.3 Ensure ufw is not in use with iptables
  # > 4.4.2 Configure IPv4 iptables
  # > 4.4.2.1 Ensure iptables default deny firewall policy
  # > 4.4.2.2 Ensure iptables loopback traffic is configured
  # > 4.4.2.3 Ensure iptables outbound and established connections are configured
  # > 4.4.2.4 Ensure iptables firewall rules exist for all open ports
  # > 4.4.3 Configure IPv6 ip6tables
  # > 4.4.3.1 Ensure ip6tables default deny firewall policy
  # > 4.4.3.2 Ensure ip6tables loopback traffic is configured
  # > 4.4.3.3 Ensure ip6tables outbound and established connections are configured
  # > 4.4.3.4 Ensure ip6tables firewall rules exist for all open ports
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_iptables.sh"
    destination = "/tmp/cis_iptables.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_iptables.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_iptables.sh"
    ]
  }

  # ==========================================================================
  # Chapter 5: Access Control
  # ==========================================================================

  # --------------------------------------------------------------------------
  # CIS 5.1 - Configure SSH Server
  #
  # Includes:
  #
  # >5.1.1 Ensure permissions on /etc/ssh/sshd_config are configured
  # >5.1.2 Ensure permissions on SSH private host key files are configured
  # >5.1.3 Ensure permissions on SSH public host key files are configured
  # >5.1.4 Ensure sshd access is configured
  # >5.1.5 Ensure sshd Banner is configured
  # >5.1.6 Ensure sshd Ciphers are configured
  # >5.1.7 Ensure sshd ClientAliveInterval and ClientAliveCountMax are configured
  # >5.1.8 Ensure sshd DisableForwarding is enabled
  # >5.1.9 Ensure sshd GSSAPIAuthentication is disabled
  # >5.1.10 Ensure sshd HostbasedAuthentication is disabled
  # >5.1.11 Ensure sshd IgnoreRhosts is enabled
  # >5.1.12 Ensure sshd KexAlgorithms is configured
  # >5.1.13 Ensure sshd LoginGraceTime is configured
  # >5.1.14 Ensure sshd LogLevel is configured
  # >5.1.15 Ensure sshd MACs are configured
  # >5.1.16 Ensure sshd MaxAuthTries is configured
  # >5.1.17 Ensure sshd MaxSessions is configured
  # >5.1.18 Ensure sshd MaxStartups is configured
  # >5.1.19 Ensure sshd PermitEmptyPasswords is disabled
  # >5.1.20 Ensure sshd PermitRootLogin is disabled
  # >5.1.21 Ensure sshd PermitUserEnvironment is disabled
  # >5.1.22 Ensure sshd UsePAM is enabled
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_ssh_server.sh"
    destination = "/tmp/cis_ssh_server.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_ssh_server.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_ssh_server.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 5.2 - Configure privilege escalation
  #
  # Includes:
  #
  # >5.2.1 Ensure sudo is installed
  # >5.2.2 Ensure sudo commands use pty
  # >5.2.3 Ensure sudo log file exists
  # >5.2.4 Ensure users must provide password for privilege escalation
  # >5.2.5 Ensure re-authentication for privilege escalation is not disabled globally
  # >5.2.6 Ensure sudo authentication timeout is configured correctly
  # >5.2.7 Ensure access to the su command is restricted
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_privilege_escalation.sh"
    destination = "/tmp/cis_privilege_escalation.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_privilege_escalation.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_privilege_escalation.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 5.3 - Pluggable Authentication Modules
  #
  # Includes:
  #
  # >5.3.1 Configure PAM software packages
  # >5.3.1.1 Ensure latest version of pam is installed
  # >5.3.1.2 Ensure libpam-modules is installed
  # >5.3.1.3 Ensure libpam-pwquality is installed
  # >5.3.2 Configure pam-auth-update profiles
  # >5.3.2.1 Ensure pam_unix module is enabled
  # >5.3.2.2 Ensure pam_faillock module is enabled
  # >5.3.2.3 Ensure pam_pwquality module is enabled
  # >5.3.2.4 Ensure pam_pwhistory module is enabled
  # >5.3.3 Configure PAM Arguments
  # >5.3.3.1 Configure pam_faillock module
  # >5.3.3.1.1 Ensure password failed attempts lockout is configured
  # >5.3.3.1.2 Ensure password unlock time is configured
  # >5.3.3.1.3 Ensure password failed attempts lockout includes root account
  # >5.3.3.2 Configure pam_pwquality module
  # >5.3.3.2.1 Ensure password number of changed characters is configured
  # >5.3.3.2.2 Ensure minimum password length is configured
  # >5.3.3.2.3 Ensure password complexity is configured
  # >5.3.3.2.4 Ensure password same consecutive characters is configured
  # >5.3.3.2.5 Ensure password maximum sequential characters is configured
  # >5.3.3.2.6 Ensure password dictionary check is enabled
  # >5.3.3.2.7 Ensure password quality checking is enforced
  # >5.3.3.2.8 Ensure password quality is enforced for the root user
  # >5.3.3.3 Configure pam_pwhistory module
  # >5.3.3.3.1 Ensure password history remember is configured
  # >5.3.3.3.2 Ensure password history is enforced for the root user
  # >5.3.3.3.3 Ensure pam_pwhistory includes use_authtok
  # >5.3.3.4 Configure pam_unix module
  # >5.3.3.4.1 Ensure pam_unix does not include nullok
  # >5.3.3.4.2 Ensure pam_unix does not include remember
  # >5.3.3.4.3 Ensure pam_unix includes a strong password hashing algorithm
  # >5.3.3.4.4 Ensure pam_unix includes use_authtok
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_pam.sh"
    destination = "/tmp/cis_pam.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_pam.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_pam.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 5.4 - User Accounts and Environment
  #
  # Includes:
  #
  # >5.4.1 Configure shadow password suite parameters
  # >5.4.1.1 Ensure password expiration is configured
  # >5.4.1.2 Ensure minimum password days is configured
  # >5.4.1.3 Ensure password expiration warning days is configured
  # >5.4.1.4 Ensure strong password hashing algorithm is configured
  # >5.4.1.5 Ensure inactive password lock is configured
  # >5.4.1.6 Ensure all users last password change date is in the past
  # >5.4.2 Configure root and system accounts and environment
  # >5.4.2.1 Ensure root is the only UID 0 account
  # >5.4.2.2 Ensure root is the only GID 0 account
  # >5.4.2.3 Ensure group root is the only GID 0 group
  # >5.4.2.4 Ensure root account access is controlled
  # >5.4.2.5 Ensure root path integrity
  # >5.4.2.6 Ensure root user umask is configured
  # >5.4.2.7 Ensure system accounts do not have a valid login shell
  # >5.4.2.8 Ensure accounts without a valid login shell are locked
  # >5.4.3 Configure user default environment
  # >5.4.3.1 Ensure nologin is not listed in /etc/shells
  # >5.4.3.2 Ensure default user shell timeout is configured
  # >5.4.3.3 Ensure default user umask is configured
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_user_accounts.sh"
    destination = "/tmp/cis_user_accounts.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_user_accounts.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_user_accounts.sh"
    ]
  }

  # ==========================================================================
  # Chapter 6: Logging and Auditing
  # ==========================================================================

  # --------------------------------------------------------------------------
  # CIS 6.1 - System Logging
  #
  # Includes:
  #
  # >6.1.1 Configure systemd-journald service
  # >6.1.1.1 Ensure journald service is enabled and active
  # >6.1.1.2 Ensure journald log file access is configured
  # >6.1.1.3 Ensure journald log file rotation is configured
  # >6.1.1.4 Ensure only one logging system is in use
  # >6.1.2 Configure journald
  # >6.1.2.1 Configure systemd-journal-remote
  # >6.1.2.1.1 Ensure systemd-journal-remote is installed
  # >6.1.2.1.2 Ensure systemd-journal-upload authentication is configured
  # >6.1.2.1.3 Ensure systemd-journal-upload is enabled and active
  # >6.1.2.1.4 Ensure systemd-journal-remote service is not in use
  # >6.1.2.2 Ensure journald ForwardToSyslog is disabled
  # >6.1.2.3 Ensure journald Compress is configured
  # >6.1.2.4 Ensure journald Storage is configured
  # >6.1.3 Configure rsyslog
  # >6.1.3.1 Ensure rsyslog is installed
  # >6.1.3.2 Ensure rsyslog service is enabled and active
  # >6.1.3.3 Ensure journald is configured to send logs to rsyslog
  # >6.1.3.4 Ensure rsyslog log file creation mode is configured
  # >6.1.3.5 Ensure rsyslog logging is configured
  # >6.1.3.6 Ensure rsyslog is configured to send logs to a remote log  host
  # >6.1.3.7 Ensure rsyslog is not configured to receive logs from a remote client
  # >6.1.3.8 Ensure logrotate is configured
  # >6.1.4 Configure Logfiles
  # >6.1.4.1 Ensure access to all logfiles has been configured
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_logging.sh"
    destination = "/tmp/cis_logging.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_logging.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_logging.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 6.2 - System Auditing
  #
  # Includes:
  #
  # >6.2.1 Configure auditd Service
  # >6.2.1.1 Ensure auditd packages are installed
  # >6.2.1.2 Ensure auditd service is enabled and active
  # >6.2.1.3 Ensure auditing for processes that start prior to auditd is enabled
  # >6.2.1.4 Ensure audit_backlog_limit is sufficient
  # >6.2.2 Configure Data Retention
  # >6.2.2.1 Ensure audit log storage size is configured
  # >6.2.2.2 Ensure audit logs are not automatically deleted
  # >6.2.2.3 Ensure system is disabled when audit logs are full
  # >6.2.2.4 Ensure system warns when audit logs are low on space
  # >6.2.3 Configure auditd Rules
  # >6.2.3.1 Ensure changes to system administration scope (sudoers) is collected
  # >6.2.3.2 Ensure actions as another user are always logged
  # >6.2.3.3 Ensure events that modify the sudo log file are collected
  # >6.2.3.4 Ensure events that modify date and time information are collected
  # >6.2.3.5 Ensure events that modify the system's network environment are collected
  # >6.2.3.6 Ensure use of privileged commands are collected
  # >6.2.3.7 Ensure unsuccessful file access attempts are collected
  # >6.2.3.8 Ensure events that modify user/group information are collected
  # >6.2.3.9 Ensure discretionary access control permission modification events are collected
  # >6.2.3.10 Ensure successful file system mounts are collected
  # >6.2.3.11 Ensure session initiation information is collected
  # >6.2.3.12 Ensure login and logout events are collected
  # >6.2.3.13 Ensure file deletion events by users are collected
  # >6.2.3.14 Ensure events that modify the system's Mandatory Access Controls are collected
  # >6.2.3.15 Ensure successful and unsuccessful attempts to use the chcon command are collected
  # >6.2.3.16 Ensure successful and unsuccessful attempts to use the setfacl command are collected
  # >6.2.3.17 Ensure successful and unsuccessful attempts to use the chacl command are collected
  # >6.2.3.18 Ensure successful and unsuccessful attempts to use the usermod command are collected
  # >6.2.3.19 Ensure kernel module loading unloading and modification is collected
  # >6.2.3.20 Ensure the audit configuration is immutable
  # >6.2.3.21 Ensure the running and on disk configuration is the same
  # >6.2.4 Configure auditd File Access
  # >6.2.4.1 Ensure audit log files mode is configured
  # >6.2.4.2 Ensure audit log files owner is configured
  # >6.2.4.3 Ensure audit log files group owner is configured
  # >6.2.4.4 Ensure the audit log file directory mode is configured
  # >6.2.4.5 Ensure audit configuration files mode is configured
  # >6.2.4.6 Ensure audit configuration files owner is configured
  # >6.2.4.7 Ensure audit configuration files group owner is configured
  # >6.2.4.8 Ensure audit tools mode is configured
  # >6.2.4.9 Ensure audit tools owner is configured
  # >6.2.4.10 Ensure audit tools group owner is configured
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_auditd.sh"
    destination = "/tmp/cis_auditd.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_auditd.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_auditd.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 6.3 - Configure Integrity Checking
  #
  # Includes:
  #
  # >6.3.1 Ensure AIDE is installed
  # >6.3.2 Ensure filesystem integrity is regularly checked
  # >6.3.3 Ensure cryptographic mechanisms are used to protect the integrity of audit tools
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_integrity.sh"
    destination = "/tmp/cis_integrity.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_integrity.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_integrity.sh"
    ]
  }

  # ==========================================================================
  # Chapter 7: System Maintenance
  # ==========================================================================

  # --------------------------------------------------------------------------
  # CIS 7.1 - System File Permissions
  #
  # Includes:
  #
  # >7.1.1 Ensure permissions on /etc/passwd are configured
  # >7.1.2 Ensure permissions on /etc/passwd- are configured
  # >7.1.3 Ensure permissions on /etc/group are configured
  # >7.1.4 Ensure permissions on /etc/group- are configured
  # >7.1.5 Ensure permissions on /etc/shadow are configured
  # >7.1.6 Ensure permissions on /etc/shadow- are configured
  # >7.1.7 Ensure permissions on /etc/gshadow are configured
  # >7.1.8 Ensure permissions on /etc/gshadow- are configured
  # >7.1.9 Ensure permissions on /etc/shells are configured
  # >7.1.10 Ensure permissions on /etc/security/opasswd are configured
  # >7.1.11 Ensure world writable files and directories are secured
  # >7.1.12 Ensure no files or directories without an owner and a group exist
  # >7.1.13 Ensure SUID and SGID files are reviewed
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_system_file_permissions.sh"
    destination = "/tmp/cis_system_file_permissions.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_system_file_permissions.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_system_file_permissions.sh"
    ]
  }

  # --------------------------------------------------------------------------
  # CIS 7.2 - Local User and Group Settings
  #
  # Includes:
  #
  # >7.2.1 Ensure accounts in /etc/passwd use shadowed passwords
  # >7.2.2 Ensure /etc/shadow password fields are not empty
  # >7.2.3 Ensure all groups in /etc/passwd exist in /etc/group
  # >7.2.4 Ensure shadow group is empty
  # >7.2.5 Ensure no duplicate UIDs exist
  # >7.2.6 Ensure no duplicate GIDs exist
  # >7.2.7 Ensure no duplicate user names exist
  # >7.2.8 Ensure no duplicate group names exist
  # >7.2.9 Ensure local interactive user home directories are configured
  # >7.2.10 Ensure local interactive user dot files access is configured
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "scripts/cis_local_user_and_group_settings.sh"
    destination = "/tmp/cis_local_user_and_group_settings.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_local_user_and_group_settings.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_local_user_and_group_settings.sh"
    ]
  }

  # ==========================================================================
  # Temporary Filesystems Configuration (moved from cloud-config due to curtin bug)
  # ==========================================================================
  provisioner "file" {
    source      = "scripts/cis_tmpfs_mounts.sh"
    destination = "/tmp/cis_tmpfs_mounts.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cis_tmpfs_mounts.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/cis_tmpfs_mounts.sh"
    ]
  }

  # ==========================================================================
  # LUKS Key Deployment & Initramfs Hardening
  # ==========================================================================
  provisioner "file" {
    source      = "scripts/luks_keyfile.sh"
    destination = "/tmp/luks_keyfile.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/luks_keyfile.sh",
      "echo ${local.sudo_password} | sudo -S LUKS_KEY=${var.luks_key} /tmp/luks_keyfile.sh"
    ]
  }

  # ==========================================================================
  # Final VM template cleanup and hardening
  # ==========================================================================
  provisioner "file" {
    source      = "scripts/finalize.sh"
    destination = "/tmp/finalize.sh"
  }
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/finalize.sh",
      "echo ${local.sudo_password} | sudo -S /tmp/finalize.sh"
    ]
  }
}
