# Client code to send series of UDP messages during congestion testing
# Measures NL and PD

import socket, sys, time

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

client_address = ('localhost', 12345)
server_address = ("172.16.0.2", 12345)
sock.bind(client_address)
#send 50 UDP messages with payload from "0" to "49"
for x in range(50):
    message = str(x)
    start = time.time()
    sock.sendto(message.encode('utf-8'), server_address)
    sock.settimeout(2) #set 2 seconds timeout while waiting for a response
    data,address = sock.recvfrom(512)
    if data == str(x): #ensure that response is for the message sent
        print(time.time() - start) #print NL time

