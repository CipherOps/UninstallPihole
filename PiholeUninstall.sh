#!/bin/bash

# display information about dependencies
echo -e '\033[0;33m'
echo "PI-HOLE WILL TRY TO REMOVE SYSTEM FILES DURING UNINSTALL!"
echo
echo "WHEN PIHOLE ASKS YOU IF YOU WANT TO REMOVE DEPENDENCIES HIT N AND LEAVE THEM ALL INSTALLED"
echo
echo "MAKE SURE NO DEVICE ON YOUR NETWORK IS STILL SET TO USE PI-HOLE FOR DNS"
echo
echo "Press C to proceed with the uninstallation, or any other key to cancel."
read -r confirm

if [ "$confirm" != "C" ]; then
  echo "Uninstallation cancelled."
  echo -e '\033[0m'
  exit
fi
  # uninstall pihole
  sudo pihole uninstall
  echo -e '\033[0;33m'
  echo "Pihole uninstalled, removed Pihole directory"
  # remove pihole directory
  sudo rm -rf /etc/pihole/
  echo "Pihole directory removed, restoring network configuraiton"
# check if /etc/resolv.conf.orig exists
if [ -f "/etc/resolv.conf.orig" ]; then
    mv /etc/resolv.conf.orig /etc/resolv.conf
    echo "Original resolv.conf moved to /etc/resolv.conf"
else
    # create a default /etc/resolv.conf file with 9.9.9.9 as the DNS
    echo "nameserver 9.9.9.9" > /etc/resolv.conf
    echo "New resolv.conf created"
fi

# check if systemd-resolvd is installed and enable it
if [ -f "/usr/lib/systemd/resolv.conf" ]; then
    ln -sf /usr/lib/systemd/resolv.conf /etc/resolv.conf
    systemctl enable --now systemd-resolved
    echo "systemd-resolved is re-enabled"
fi

  # check if system uses Network Manager or wicked
  if [ -f /etc/NetworkManager/NetworkManager.conf ]; then
    # restart Network Manager service
    sudo systemctl restart NetworkManager
    echo "NetworkManager restarted to apply DNS config change"
  elif [ -f /etc/sysconfig/network/config ]; then
    # restart wickd service
    sudo systemctl restart wicked
    echo "wickd network manager restarted to apply DNS config change"
  fi

  # check if system uses netplan
  if [ -d /etc/netplan/ ]; then
  echo "Netplan detetcted, installed default netplan.yaml"
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
  echo "Pihole is uninstalled"
  echo -e '\033[0m'
done
