import os

# get available network interfaces
interfaces = os.listdir('/sys/class/net')
print('Available network interfaces:', interfaces)

# get user inputs
interface = input('Enter the network interface to configure: ')

# check if interface is valid
if interface not in interfaces:
    print('Invalid interface selected.')
else:
    # check if user wants to set IP address via DHCP
    ip = input('Enter IP address or "dhcp" to use DHCP: ')
    if ip == 'dhcp':
        dhcp = 'dhcp'
    else:
        dhcp = ''

        # get netmask based on IP address
        octets = ip.split('.')
        if int(octets[0]) < 128:
            netmask = '255.0.0.0'
        elif int(octets[0]) < 192:
            netmask = '255.255.0.0'
        else:
            netmask = '255.255.255.0'

        # get user inputs for gateway and ports to open
        gateway = input('Enter gateway IP address: ')
        ports = input('Enter ports to open (comma-separated): ')

        # configure /etc/network/interfaces file
        with open('/etc/network/interfaces', 'a') as f:
            f.write('\n')
            f.write('auto ' + interface + '\n')
            f.write('iface ' + interface + ' inet ' + dhcp + '\n')
            if not dhcp:
                f.write('address ' + ip + '\n')
                f.write('netmask ' + netmask + '\n')
                f.write('gateway ' + gateway + '\n')

        # configure nftables
        os.system('nft flush ruleset')
        os.system('nft add table inet filter')
        os.system('nft add chain inet filter input { type filter hook input priority 0 \; }')
        os.system('nft add rule inet filter input tcp dport {' + ports + '} accept')
        os.system('nft add rule inet filter input udp dport {' + ports + '} accept')
        os.system('nft add rule inet filter input ct state established,related accept')
        os.system('nft add rule inet filter input ct state invalid drop')
        os.system('nft add rule inet filter input ip protocol icmp accept')
        os.system('nft add rule inet filter input drop')
        os.system('nft list ruleset')
