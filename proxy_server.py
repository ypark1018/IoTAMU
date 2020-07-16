#! /user/bin/env python
#
# Decrypt data received from the RI
#
# encryption source: https://cryptography.io/en/latest/hazmat/primitives/symmetric-encryption/

import socket, sys, parse, os, binascii, struct

from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend

max_conn = 3 # Max Connection Queues To Hold
buf_size = 4096

def main():
    #create socket
    try:
        s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.ntohs(3))
        t = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.ntohs(3))
    except Exception as e:
        sys.exit(2)
    
    s.bind(("eth1",0))
    t.bind(("wlan0",0))
    
    encryptor, decryptor = initialize_enc()
    while 1:
        eth_proto = 0
        ip_proto = 0
        payload = 0
        try:
            #create another thread to receive data going other direction
            raw_data,addr=s.recvfrom(65536) #data received from eth0
            dst_mac, src_mac, eth_proto, ip_data = parse.ethernet_frame(raw_data)
            if eth_proto==8:
                version,header_length,ttl,ip_proto,src_ip,dst_ip,data=parse.ipv4_packet(ip_data)
                if ip_proto == 17: #UDP packet received
                    src_port,dst_port,length,payload = parse.udp_packet(data)
                elif ip_proto == 6: #TCP packet received
                    src_port,dst_port,seq,ack,flag_urg,flag_ack,flag_psh,flag_rst,flag_syn,flag_fin,offset,payload = parse.tcp_packet(data)

            if payload != 0:
                if parse.ipv4(src_ip) != "172.16.0.2":
                    continue
                print("Message received: " + str(payload))
                new_data = dec_data(payload, decryptor)
                print("Message decrypted: " + str(new_data))

                #MAC address of the gateway router
                dst_mac = b"\xc4\x9d\xed\x2d\xac\x83"

                #construct new headers
                checksum = 0
                length = 8 + len(new_data) #calculate new length for Transport layer header
                p_header = struct.pack('!2H', ip_proto, length)
                p_header = src_ip + dst_ip + p_header
                
                if ip_proto == 17: #new headers
                    #new IP header
                    checksum = 0
                    total_length = header_length + length
                    i_header = struct.pack('!2s H', ip_data[:2], total_length) + ip_data[4:10] + struct.pack('!H', checksum) + ip_data[12:20] + ip_data[20:header_length]
                    checksum = parse.checksum(i_header)
                    i_header = struct.pack('!2s H', ip_data[:2], total_length) + ip_data[4:10] + struct.pack('!H', checksum) + ip_data[12:20] + ip_data[20:header_length]
                    
                    #new UDP header
                    checksum = 0
                    t_header = struct.pack('!4H', src_port, dst_port, length, checksum)
                    checksum = parse.checksum(p_header + t_header + new_data)
                    t_header = struct.pack('!4H', src_port, dst_port, length, checksum)
                i_offset = 14 #offset to ip layer
                t.send(dst_mac+raw_data[6:i_offset]+i_header+t_header+new_data)

        except KeyboardInterrupt:
            t.close()
            s.close()
            sys.exit(1)
    s.close()
    t.close()

#initializer for encryption
def initialize_enc():
    backend = default_backend()
    key = b"11111111111111111111111111111111" #Same key is used for RI and IoTAMU
    iv = b"2222222222222222"
    cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=backend)
    encryptor = cipher.encryptor()
    decryptor = cipher.decryptor()
    return encryptor, decryptor

#encrypt data
def enc_data(data, encryptor):
    ctext = encryptor.update(data) + encryptor.finalize()
    return ctext

#decrypt data
def dec_data(data, decryptor):
    pt = decryptor.update(data) + decryptor.finalize()
    return pt

#debug function used to test if encryption is working
def debug():
    encryptor, decryptor = initialize_enc()
    data = b"12345678901234567890123456789012"
    encrypted = enc_data(data, encryptor)
    decrypted = enc_data(encrypted, decryptor)
    print(data)
    print(encrypted)
    print(decrypted)

if __name__ == "__main__":
    main()
    #debug()
