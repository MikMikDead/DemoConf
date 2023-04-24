#!/bin/bash

# User inputs
read -p "Enter the interface name: " interface_name
read -p "Enter the desired IP address (or type 'dhcp' for DHCP): " ip_address
read -p "Enter the gateway IP address: " gateway_ip

# Automatic netmask selection based on entered IP address
IFS=. read -r i1 i2 i3 i4 <<< "$ip_address"
if [ "$i1" -eq 10 ]; then
  netmask="255.0.0.0"
elif [ "$i1" -eq 172 -a "$i2" -ge 16 -a "$i2" -le 31 ]; then
  netmask="255.255.0.0"
elif [ "$i1" -eq 192 -a "$i2" -eq 168 ]; then
  netmask="255.255.255.0"
else
  echo "Invalid IP address entered"
  exit 1
fi

# Set up the networking using systemd-resolved
cat <<EOF > /etc/systemd/network/${interface_name}.network
[Match]
Name=${interface_name}

[Network]
Address=${ip_address}/${netmask}
Gateway=${gateway_ip}
EOF

systemctl restart systemd-networkd

# Configure nftables
read -p "Enter the ports to leave open (comma-separated): " open_ports

if [ -n "$open_ports" ]; then
  IFS=',' read -ra ports <<< "$open_ports"

  # Set up nftables to allow incoming traffic on the specified ports
  for port in "${ports[@]}"; do
    nft add rule inet filter input tcp dport "$port" accept
  done
fi

# Set the default nftables policy to drop incoming traffic
nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }
