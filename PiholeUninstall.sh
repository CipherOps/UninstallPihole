#!/bin/bash

# display information about dependencies
echo "PI-HOLE WILL TRY TO REMOVE SYSTEM FILES DURING UNINSTALL!"
echo
echo "PLEASE READ WHAT EACH DEPENDENCY IS BEFORE HITTING Y TO REMOVE"
echo "MAKE SURE NO DEVICE ON YOUR NETWORK IS STILL SET TO USE PI-HOLE FOR DNS"
echo
echo "Press C to proceed with the uninstallation, or any other key to cancel."
read -r confirm

if [ "$confirm" = "C" ]; then
  # uninstall pihole
  sudo pihole uninstall

  # remove pihole directory
  sudo rm -rf /etc/pihole/

# check if /etc/resolv.conf.orig exists
if [ -f "/etc/resolv.conf.orig" ]; then
    mv /etc/resolv.conf.orig /etc/resolv.conf
else
    # create a default /etc/resolv.conf file with 9.9.9.9 as the DNS
    echo "nameserver 9.9.9.9" > /etc/resolv.conf
fi

# check if systemd-resolvd is installed and enable it
if [ -f "/usr/lib/systemd/resolv.conf" ]; then
    ln -sf /usr/lib/systemd/resolv.conf /etc/resolv.conf
    systemctl enable --now systemd-resolved
fi

  # check if system uses Network Manager or wicked
  if [ -f /etc/NetworkManager/NetworkManager.conf ]; then
    # restart Network Manager service
    sudo service NetworkManager restart
  elif [ -f /etc/sysconfig/network/config ]; then
    # restart wickd service
    sudo service wickd restart
  fi

  # check if system uses netplan
  if [ -d /etc/netplan/ ]; then
    # create basic netplan configuration
    sudo touch /etc/netplan/00-netplan.yaml
    sudo cat <<'EOT' >> /etc/netplan/00-netplan.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: yes
EOT
    # apply netplan configuration
    sudo netplan apply
    echo "Check your interface with `ip a` and edit the eth0 line in /etc/netplan/00-netplan.yaml if your network interface is different!"
  fi
  else
    # unable to determine how to restart networking service
    echo "Error: unable to determine how to restart networking service. Please restart it manually."
  fi
else
  echo "Uninstallation cancelled."
fi
