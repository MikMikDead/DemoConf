#!/bin/bash

# get available network interfaces
interfaces=( $(ls -1 /sys/class/net/) )
echo "Available network interfaces: ${interfaces[*]}"

# get user input
read -p "Enter the network interface to configure: " interface

# check if interface is valid
if ! echo "${interfaces[*]}" | grep -qw "${interface}"; then
    echo "Invalid interface selected."
else
    # get user input for IP address
    read -p "Enter IP address or 'dhcp' to use DHCP: " ip

    if [[ "${ip}" == "dhcp" ]]; then
        dhcp="dhcp"
    else
        dhcp=""

        # get netmask based on IP address
        IFS=. read -r -a octets <<< "$ip"
        if [[ "${octets[0]}" -lt 128 ]]; then
            netmask="255.0.0.0"
        elif [[ "${octets[0]}" -lt 192 ]]; then
            netmask="255.255.0.0"
        else
            netmask="255.255.255.0"
        fi

        # get user inputs for gateway and ports to open
        read -p "Enter gateway IP address: " gateway
        read -p "Enter ports to open (comma-separated): " ports

        # configure /etc/network/interfaces file
        cat <<EOF >> /etc/network/interfaces

auto ${interface}
iface ${interface} inet ${dhcp}
EOF
        if [[ "${dhcp}" == "" ]]; then
            cat <<EOF >> /etc/network/interfaces
    address ${ip}
    netmask ${netmask}
    gateway ${gateway}
EOF
        fi

        # configure nftables
        nft flush ruleset
        nft add table inet filter
        nft add chain inet filter input { type filter hook input priority 0 \; }
        nft add rule inet filter input tcp dport {${ports}} accept
        nft add rule inet filter input udp dport {${ports}} accept
        nft add rule inet filter input ct state established,related accept
        nft add rule inet filter input ct state invalid drop
        nft add rule inet filter input ip protocol icmp accept
        nft add rule inet filter input drop
        nft list ruleset
    fi
fi
