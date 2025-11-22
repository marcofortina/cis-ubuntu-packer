#cloud-config
autoinstall:
  version: 1

  # ------------------------------------------------------------
  # BASE SYSTEM IMAGE (CIS – General Hardening Principle)
  # ------------------------------------------------------------
  # CIS Section 1 – Initial System Configuration
  # CIS recommends installing the smallest possible base system
  source:
    id: ubuntu-server

  # ------------------------------------------------------------
  # KERNEL PACKAGE (Not a CIS requirement)
  # ------------------------------------------------------------
  kernel:
    package: linux-generic

  # ------------------------------------------------------------
  # LOCALE AND KEYBOARD (Not a CIS requirement)
  # ------------------------------------------------------------
  locale: en_US.UTF-8

  keyboard:
    layout: it
    variant: winkeys

  # ------------------------------------------------------------
  # TIMEZONE (Not a CIS requirement)
  # ------------------------------------------------------------
  timezone: Europe/Rome

  # ------------------------------------------------------------
  # APPLY ALL UPDATES (CIS – 1.2.2 Configure Package Updates)
  # ------------------------------------------------------------
  updates: all

  # ------------------------------------------------------------
  # SYSTEM IDENTITY (CIS 1.4.x – Secure Password Policy)
  # ------------------------------------------------------------
  identity:
    hostname: ${var.hostname}
    username: ubuntu
    password: "${var.hashed_ssh_password}"

  # ------------------------------------------------------------
  # SSH SERVER CONFIGURATION (CIS 5.2.x will be applied later)
  # ------------------------------------------------------------
  ssh:
    install-server: true
    allow-pw: true
    authorized-keys:
      - ${var.ssh_public_key}

  # ------------------------------------------------------------
  # GROUP DEFINITIONS
  # ------------------------------------------------------------
  groups:
    ssh-admins

  # ------------------------------------------------------------
  # NETWORKING (CIS 3.x will be applied later via scripts)
  # ------------------------------------------------------------
  network:
    version: 2
    ethernets:
      enp0s3:
        dhcp4: true

  # ------------------------------------------------------------
  # STORAGE CONFIGURATION (CIS 1.1.2 – Partitioning Guidelines)
  # ------------------------------------------------------------
  storage:
    config:

      # ------------------------------------------------------------
      # Disk definition – use the largest disk
      # ------------------------------------------------------------
      - type: disk
        id: disk0
        match:
          size: largest
        ptable: gpt
        wipe: superblock
        grub_device: false

      # ------------------------------------------------------------
      # EFI partition (1M) – required for GPT + EFI systems
      # ------------------------------------------------------------
      - id: efi
        type: partition
        device: disk0
        size: 1G
        flag: boot
        grub_device: true

      # ------------------------------------------------------------
      # /boot partition (2G)
      # ------------------------------------------------------------
      - id: boot
        type: partition
        device: disk0
        size: 2G
        grub_device: false

      # ------------------------------------------------------------
      # LVM PV partition (remaining disk space)
      # ------------------------------------------------------------
      - id: lvm
        type: partition
        device: disk0
        size: -1    # use all remaining space for LVM
        grub_device: false

      # ------------------------------------------------------------
      # LUKS Encryption Layer (dm-crypt)
      # ------------------------------------------------------------
      - id: luks_lvm
        type: dm_crypt
        volume: lvm
        keyfile: /tmp/luks.key

      # ------------------------------------------------------------
      # Volume Group
      # ------------------------------------------------------------
      - type: lvm_volgroup
        id: ubuntu
        name: ubuntu
        devices: [ luks_lvm ]

      # ------------------------------------------------------------
      # Logical Volumes (aligned with CIS 1.1.2.x guidelines)
      # ------------------------------------------------------------
      - { type: lvm_partition, id: lv_root,  name: lv_root,  volgroup: ubuntu, size: 15G }
      - { type: lvm_partition, id: lv_home,  name: lv_home,  volgroup: ubuntu, size: 2G }     # CIS 1.1.2.3
      - { type: lvm_partition, id: lv_var,   name: lv_var,   volgroup: ubuntu, size: 15G }    # CIS 1.1.2.4
      - { type: lvm_partition, id: lv_log,   name: lv_log,   volgroup: ubuntu, size: 10G }    # CIS 1.1.2.6
      - { type: lvm_partition, id: lv_audit, name: lv_audit, volgroup: ubuntu, size: 3G }     # CIS 1.1.2.7
      - { type: lvm_partition, id: lv_www,   name: lv_www,   volgroup: ubuntu, size: 40G }    # Hardening (not CIS)
      - { type: lvm_partition, id: lv_swap,  name: lv_swap,  volgroup: ubuntu, size: 2G }     # Hardening (not CIS)

      # ------------------------------------------------------------
      # Filesystem formatting
      # ------------------------------------------------------------
      - { id: fs_efi,   type: format, volume: efi,      fstype: fat32 }
      - { id: fs_boot,  type: format, volume: boot,     fstype: ext4 }
      - { id: fs_root,  type: format, volume: lv_root,  fstype: ext4 }
      - { id: fs_home,  type: format, volume: lv_home,  fstype: ext4 }
      - { id: fs_var,   type: format, volume: lv_var,   fstype: ext4 }
      - { id: fs_log,   type: format, volume: lv_log,   fstype: ext4 }
      - { id: fs_audit, type: format, volume: lv_audit, fstype: ext4 }
      - { id: fs_www,   type: format, volume: lv_www,   fstype: ext4 }
      - { id: fs_swap,  type: format, volume: lv_swap,  fstype: swap }

      # ------------------------------------------------------------
      # MOUNT CONFIGURATION – FULL CIS HARDENING (CIS 1.1.2.x)
      # ------------------------------------------------------------

      # Root filesystem
      - { id: mount_root, type: mount, device: fs_root, path: / }

      # /boot partition (no CIS restrictions)
      - { id: mount_boot, type: mount, device: fs_boot, path: /boot }

      # /boot/efi partition (no CIS restrictions)
      - { id: mount_efi, type: mount, device: fs_efi, path: /boot/efi }

      # --------------------------------------------------------
      # CIS 1.1.2.3 – /home must be separate and have nodev, nosuid
      # --------------------------------------------------------
      - { id: mount_home, type: mount, device: fs_home, path: /home, options: "nodev,nosuid" }

      # --------------------------------------------------------
      # CIS 1.1.2.4 – /var must be separate and have nodev, nosuid
      # --------------------------------------------------------
      - { id: mount_var, type: mount, device: fs_var, path: /var, options: "nodev,nosuid" }

      # --------------------------------------------------------
      # CIS 1.1.2.6 – /var/log must be separate and have nodev, nosuid, noexec
      # --------------------------------------------------------
      - { id: mount_log, type: mount, device: fs_log, path: /var/log, options: "nodev,nosuid,noexec" }

      # --------------------------------------------------------
      # CIS 1.1.2.7 – /var/log/audit must be separate and have nodev, nosuid, noexec
      # --------------------------------------------------------
      - { id: mount_audit, type: mount, device: fs_audit, path: /var/log/audit, options: "nodev,nosuid,noexec" }

      # --------------------------------------------------------
      # /var/www – not CIS, but recommended for web servers
      # --------------------------------------------------------
      - { id: mount_www, type: mount, device: fs_www, path: /var/www, options: "nodev,nosuid,noexec" }

      # --------------------------------------------------------
      # swap – not CIS, but recommended for all servers
      # --------------------------------------------------------
      - { id: mount_swap, type: mount, device: fs_swap, path: none, fstype: swap }

  packages:
    # ------------------------------------------------------------
    # REQUIRED BASE PACKAGES
    # ------------------------------------------------------------
    - openssh-server
    - curl
    - binutils
    - apt-utils
    - open-vm-tools
    - tpm2-tools
    - tpm2-initramfs-tool

    # ------------------------------------------------------------
    # BASE UTILITIES
    # ------------------------------------------------------------
    - less              # pager for reading text files
    - vim-tiny          # minimal vi editor
    - zip               # compress files
    - unzip             # extract compressed files
    - iputils-ping      # ping command
    - dnsutils          # provides dig and nslookup
    - net-tools         # legacy network commands: ifconfig, netstat, route, arp
    - traceroute        # trace network paths
    - rsync             # file transfer and synchronization tool
    - tar               # archive tool
    - htop              # interactive process viewer
    - lsof              # list open files
    - tcpdump           # network traffic analyzer

    # ------------------------------------------------------------
    # ADDITIONAL UTILITIES REQUESTED
    # ------------------------------------------------------------
    - wget              # download files via HTTP/FTP
    - gzip              # compress files using gzip
    - bzip2             # compress files using bzip2
    - xz-utils          # compress files using xz
    - parted            # disk partitioning tool (GPT/MBR)
    - iotop             # monitor disk I/O in real-time
    - dstat             # system resource statistics
    - arping            # send ARP requests to test layer 2 connectivity

  # ------------------------------------------------------------
  # Prepare LUKS keyfile before disk encryption
  # ------------------------------------------------------------
  early-commands:
    # Main LUKS key (plain text)
    - echo -n ${var.luks_key} > /tmp/luks.key
    - chmod 600 /tmp/luks.key

  # ------------------------------------------------------------
  # System update during installation
  # ------------------------------------------------------------
  late-commands:
    # Update package index
    - curtin in-target -- apt-get update

    # Cleanup temporary files and unused packages
    - curtin in-target -- apt-get autoremove -y
    - curtin in-target -- apt-get clean
