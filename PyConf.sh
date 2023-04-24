#!/bin/bash

# Configuration parameters
INTERFACE=""
IP=""
NETMASK=""
GATEWAY=""
PORTS="22,80,443"

# Prompt the user for input
read -p "Enter interface name (e.g. eth0): " INTERFACE
read -p "Enter IP address (or 'dhcp' for DHCP): " IP
read -p "Enter netmask (e.g. 255.255.255.0): " NETMASK
read -p "Enter gateway (e.g. 192.168.1.1): " GATEWAY
read -p "Enter ports to leave open (default is 22,80,443): " PORTS

# Configure network interface
if [ "$IP" = "dhcp" ]; then
  echo "Configuring $INTERFACE for DHCP..."
  echo "auto $INTERFACE" >> /etc/network/interfaces
  echo "iface $INTERFACE inet dhcp" >> /etc/network/interfaces
else
  echo "Configuring $INTERFACE with static IP address $IP..."
  echo "auto $INTERFACE" >> /etc/network/interfaces
  echo "iface $INTERFACE inet static" >> /etc/network/interfaces
  echo "  address $IP" >> /etc/network/interfaces
  echo "  netmask $NETMASK" >> /etc/network/interfaces
  echo "  gateway $GATEWAY" >> /etc/network/interfaces
fi

# Restart networking
systemctl restart networking

# Configure nftables
echo "Configuring nftables..."
echo "flush ruleset" > /etc/nftables.conf
echo "table ip filter {" >> /etc/nftables.conf
echo "  chain input {" >> /etc/nftables.conf
echo "    type filter hook input priority 0;" >> /etc/nftables.conf
echo "    policy drop;" >> /etc/nftables.conf
echo "    ct state established,related accept" >> /etc/nftables.conf
echo "    tcp dport { $PORTS } accept" >> /etc/nftables.conf
echo "    icmp type echo-request accept" >> /etc/nftables.conf
echo "  }" >> /etc/nftables.conf
echo "}" >> /etc/nftables.conf

# Restart nftables
systemctl restart nftables
