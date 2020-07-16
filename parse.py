# Parse received packet from an interface to extract header information and payload
# source:
# github.com/koehlma/snippets/blob/master/python/network/sniffer.py
# github.com/vduddu/Malware/blob/master/Sniffer/Ethernet/ethernet_sniffer.py


import socket
import struct

#parse link layer
def ethernet_frame(data):
    dst_mac,src_mac,protocol=struct.unpack('! 6s 6s H',data[:14])
    return dst_mac, src_mac, socket.htons(protocol), data[14:]

#retrieve mac address from ethernet frame
def get_mac_address(bytes_addr):
    bytes_str=map('{:02x}'.format, bytes_addr)
    mac_addr=':'.join(bytes_str).upper()
    return mac_addr

#parse IP layer
def ipv4_packet(data):
    version_header_length=data[0]
    version=version_header_length >> 4
    header_length = (version_header_length & 15) * 4
    ttl,protocol,src_ip,dst_ip=struct.unpack('! 8x B B 2x 4s 4s',data[:20])
    return version,header_length,ttl,protocol,src_ip,dst_ip,data[header_length:]

#retrieve IP address from IP datagram
def ipv4(addr):
    return '.'.join(map(str,addr))

#parse UDP packet
def udp_packet(data):
    src_port,dst_port,size=struct.unpack('! H H H 2x',data[:8])
    return src_port,dst_port,size,data[8:]

#parse TCP packet
def tcp_packet(data):
    src_port,dst_port,seq,ack,flags=struct.unpack('! H H L L H',data[:14])
    offset=(flags >> 12) * 4
    flag_urg=(flags & 32) >> 5
    flag_ack=(flags & 16) >> 4
    flag_psh=(flags & 8) >> 3
    flag_rst=(flags & 4) >> 2
    flag_syn=(flags & 2) >> 1
    flag_fin=(flags & 1)
    return src_port,dst_port,seq,ack,flag_urg,flag_ack,flag_psh,flag_rst,flag_syn,flag_fin,offset,data[offset:]

#create checksum from packet
def checksum(data):
    checksum = 0
    data_len = len(data)
    if (data_len % 2):
        data_len += 1
        data += struct.pack('!B', 0)
    
    for i in range(0, data_len, 2):
        w = (data[i] << 8) + (data[i + 1])
        checksum += w

    checksum = (checksum >> 16) + (checksum & 0xFFFF)
    checksum = ~checksum & 0xFFFF
    return checksum

#parse contents of received packet and print header information
#this is used for debugging purpose
def parse(sock):
    raw_data,addr=sock.recvfrom(65536)
    dst_mac, src_mac, eth_proto, data = ethernet_frame(raw_data)
    print("\nEthernet Frame:")
    print("Destination: {}, Source: {}, Protocol: {}".format(get_mac_address(dst_mac),get_mac_address(src_mac),eth_proto))

	#check for IP packets
    if eth_proto==8:
        version,header_length,ttl,ip_proto,src_ip,dst_ip,data=ipv4_packet(data)
        print("IPv4 Packet:")
        print("Version: {}, Src IP: {}, Dst IP: {}, Protocol: {}".format(version,ipv4(src_ip),ipv4(dst_ip),ip_proto))

		#check for UDP packets
        if ip_proto == 17:
            src_port,dst_port,length,data = udp_packet(data)
            print("UDP Segment:")
            print("Source Port: {}, Destination Port {}, Length: {}".format(src_port,dst_port, length))
            print(data)
        
		#check for TCP packets
        elif ip_proto == 6:
            src_port,dst_port,seq,ack,flag_urg,flag_ack,flag_psh,flag_rst,flag_syn,flag_fin,offset,data = tcp_packet(data)
            print("TCP Segment:")
            print(data)

def main():
    s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.ntohs(3))
    while True:
        parse(s)
                
if __name__ == '__main__':
    main()
