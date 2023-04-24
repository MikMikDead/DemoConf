#!/bin/bash

# Get interface information
interfaces=$(ip addr show | awk '/inet / {print $2}')
echo "Available interfaces: "
echo "$interfaces"
read -p "Enter the interface name to configure: " interface

# Get IP address information
read -p "Enter the IP address to configure (or 'dhcp' to use DHCP): " ip_address
if [[ "$ip_address" == "dhcp" ]]; then
    dhcp="true"
else
    dhcp="false"
    read -p "Enter the netmask to configure (e.g. 255.255.255.0): " netmask
    read -p "Enter the default gateway to configure: " gateway
fi

# Configure interface
if [[ "$dhcp" == "true" ]]; then
    echo "Configuring $interface with DHCP..."
    dhclient $interface
else
    echo "Configuring $interface with static IP address..."
    echo "auto $interface" >> /etc/network/interfaces
    echo "iface $interface inet static" >> /etc/network/interfaces
    echo "  address $ip_address" >> /etc/network/interfaces
    echo "  netmask $netmask" >> /etc/network/interfaces
    echo "  gateway $gateway" >> /etc/network/interfaces
    ifup $interface
fi

# Get port information
read -p "Enter the ports to open (e.g. 22,80,443): " open_ports
echo "Configuring firewall..."
# Flush existing rules
nft flush ruleset
# Configure default policies
nft add table inet filter
nft add chain inet filter input { type filter hook input priority 0\; }
nft add chain inet filter forward { type filter hook forward priority 0\; }
nft add chain inet filter output { type filter hook output priority 0\; }
nft add rule inet filter input ct state invalid drop
nft add rule inet filter input ct state established,related accept
nft add rule inet filter output ct state established,related accept
nft add rule inet filter forward ct state established,related accept
nft add rule inet filter forward ct state invalid drop
nft add rule inet filter forward iifname lo accept
# Open specified ports
for port in $(echo $open_ports | sed "s/,/ /g")
do
    nft add rule inet filter input tcp dport $port accept
done
# Close all other ports
nft add rule inet filter input tcp dport 0-65535 drop
