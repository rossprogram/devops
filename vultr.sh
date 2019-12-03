#!/bin/sh
#
# Install NixOS on a Vultr VPS

umount /dev/vda*

# create partitions (with 2G swap)
(
echo g

# swap
echo n
echo
echo
echo +2GB
echo t
echo
echo 19

# bios boot (for grub)
echo n
echo
echo
echo +16MB
echo t
echo
echo 4

# /
echo n
echo
echo
echo

echo w
) | fdisk /dev/vda

fdisk -l /dev/vda

# enable swap
mkswap -f /dev/vda1
swapon /dev/vda1
free -h

# wait
sleep 5

# create filesystem and mount
mkfs.ext4 /dev/vda3 -Lroot
mount /dev/vda3 /mnt

# generate Nixos config
nixos-generate-config --root /mnt
echo "System configuration.nix:"
tee /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  environment.systemPackages = with pkgs; [
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/vda";

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";
  services.openssh.passwordAuthentication = false;
  services.openssh.challengeResponseAuthentication =
false;

  time.timeZone = "America/New_York";

  users.users.root = {
    openssh.authorizedKeys.keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDbqW6Df+2U1UM5UJ5na3pzMlvnF+/0DCVvMdfgpe8g0HVSFD7Hb4ScTSAJRO+atZe22c/9wvAgr8L6BjWDpM/iL7CDArgxZ3isgDBiM8u7arp+9qWHa6GUKVtDTKc3D344pbEXTa8cS+7PWMjY2allJvSYig7EghVFXj0JKBFEep/I+ekR/poZXi7Bj6mG3FZaUHCaCAN1iM4UT9mETM50VcuP/0/Z659YYGcgG06AII4a3h5pWpPa05FJHbcuFNgfnGh9dJrVnzidPJAT3dpww6s530WdnGMdWgHiFIlK5j7ZbuDm3Ga/VKa2n5NUDriaXJGzBq5eO2g8YKagAZDFIqCUErhsUag9MSxl6CLE7gEb9B2cD6xst8YwzLKfEEy10RinTxgl+zfLbsSQGpMr/juLtzuJTVNpFkp2omWxf+2i5ESaZr/vGh35+aWCXN3kbgWPEhafytxLdS6gqYDRG/ict67zifgfuCBwEXwT0Qek1deBLtv9VlGE1aANnb/p/NuvGT2hc8TEWhFIF6GJUA3OKRuwUiza/nS50W0U4RvOrqlFlyVX8ltOqMg3vMzmcjcQOgCHDHIVL429i05H4VhOQmzsmsD3s6o178CczGuQ2xXzWNYarFAJzKKk6zWHOYflVbxC9BV3yoqzvdOlt33PziKd5vpfREexhaM3mw== jim@dual"];
  };

  system.stateVersion = "19.09";
}
EOF

# install Nixos
nixos-install

# unmount
sync
umount /dev/vda3

echo "Done. Now reboot via \"Remove ISO\" on the Vultr web UI."
