#server code used during proof of concept encryption test
#decrypts received encrypted message and sends an encrypted response

import socket
import sys
import proxy_server

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

server_address = ("10.0.0.4", 12345)
client_address = ("192.168.1.17", 12345)
sock.bind(server_address)

encryptor, decryptor = proxy_server.initialize_enc()
message = "This is a secret response 123456"
while True:
    data,address = sock.recvfrom(4096)
    if data:
        print("Received encrypted message: " + str(data))
		#decrypt encrypted message
		decrypted = proxy_server.dec_data(data, decryptor)
		#encrypt response
        encrypted = proxy_server.enc_data(message, encryptor)
        print("Message decrypted: " + str(decrypted))
		print("Sending response . . .")
		#send encrypted response to client
        sock.sendto(encrypted, address)
