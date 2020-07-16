#client code used during proof of concept encryption test
#sends a message to the RI and waits for a response

import socket
import sys

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

server_address = ("172.16.0.2", 12345)
client_address = ("192.168.1.17", 12345)
sock.bind(client_address)
#send message to RI
message = b"this is a secret message 1234567"
sock.sendto(message, server_address)
print('Client sent: ' + str(message))
#wait for response from the RI
while True:
    data,address = sock.recvfrom(4096)
    print('Client received: ' + str(data))
