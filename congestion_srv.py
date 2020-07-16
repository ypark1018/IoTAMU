# Server code responding to UDP messages during congestion testing

import socket, sys

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

server_address = ('192.168.1.17', 12346)
client_address = ('172.16.0.2', 12345)
sock.bind(server_address)
#listen for messages from client and respond with same payload
while True:
    data,address = sock.recvfrom(512)
    print(data)
    sock.sendto(data, client_address)
