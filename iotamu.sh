#!bin/sh
### hostapd.conf : /etc/hostapd/hostapd.conf -> ./hostapd/hostapd.conf; /etc/default/hostapd;
### /etc/network/interfaces
### dnsmasq.conf : /etc/dnsmasq.conf
#IoTAMU initialization code
#uses iptables for firewall and hostapd to start the AP

IPTABLES=/sbin/iptables
EBTABLES=/sbin/ebtables

INT_NET=192.168.1.0/24
REMOTE=172.16.0.2
IOT=192.168.1.17

### flush existing rules and set chain policy setting to DROP
echo "[+] Flushing existing iptables rules..."
$IPTABLES -F
$IPTABLES -F -t nat
$IPTABLES -X
$IPTABLES -P INPUT DROP
$IPTABLES -P OUTPUT DROP
$IPTABLES -P FORWARD DROP

### ACCEPT rule for packets originating from the internal network
$IPTABLES -A FORWARD -i wlan0 -s $INT_NET -j ACCEPT

### DROP rules
# used for proof of concept encryption test
# drop packets with the MAC address of Laptop1 after routing:
$EBTABLES -P FORWARD ACCEPT
$EBTABLES -A FORWARD -i eth1 -d  C4:9D:ED:2D:AC:83 -j DROP

### enable forwarding
echo "[+] Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward

### enable AP
hostapd ./hostapd/hostapd.conf
