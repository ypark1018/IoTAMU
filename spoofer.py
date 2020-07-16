#! /user/bin/env python
#
# FLAG: PARAMETER (variables that can be adjusted to better mimic live device signatures)
#
# Spoof network traffic based on AGPS
# USEAGE: python3 spoofer.py [AGPS file in csv format]

import socket, sys, csv, random, time, threading
import numpy as np
from scapy.all import *

#list of device names and respective MAC addresses
#comment out devices not being used for analysis
IoT = {
        "Camera3": "28:AD:3E:38:6F:B6",
        "Camera2": "30:8C:FB:3A:1A:AD",
        "Camera1": "EC:1A:59:E4:FD:41",
        "CameraTest": "EC:1A:59:E5:02:0D",
        "Lightbulb2": "B0:4E:26:C5:2A:41",
        "Lightbulb1": "D0:73:D5:26:B8:4C",
        "LightbulbTest": "D0:73:D5:26:C9:27",
        "Switch3": "70:4F:57:F9:E1:B8",
        "Switch2": "60:38:E0:EE:7C:E5",
        "Switch1": "14:91:82:CD:DF:3D",
        "SwitchTest": "B4:75:0E:0D:94:65"
    }
	
IoTAMU = "80:2A:A8:9E:45:5A"
STATE = ["active", "passive"]
DIST = {}
#encryption can be enabled for payload
SA = SecurityAssociation(ESP, spi=0x00000100, crypt_algo='AES-CBC', crypt_key=b'iotamukey16bytes')

# creates the actual packet and sends to network
def spoof(repeat, iat, spoof_list, direction, device):
    #generate payloads of specified sizes
    global SA
    payloads = []
    if direction == 1:
        eth_dst = IoT[device]
        eth_src = IoTAMU
    else:
        eth_dst = IoTAMU
        eth_src = IoT[device]
    ip_src = "1.2.3.4" #bogus IP
    ip_dst = "1.2.3.4" #bogus IP
    ttl = 1
    iface = "wlan0"
    for data in spoof_list:
        payloads.append("a"*data)
    payloads = payloads * repeat
    for payload in np.random.choice(payloads, len(payloads)):
        #packet = SA.encrypt(IP(src=ip_src,dst=ip_dst,ttl=ttl)/UDP()/payload)
        packet = IP(src=ip_src,dst=ip_dst,ttl=ttl)/UDP()/payload
        #sendp(Dot11(addr1=eth_dst,addr2=eth_src,addr3=eth_src,type = 2, subtype = 0)/packet,iface=iface, verbose=0)
        sendp(Ether(src=eth_src,dst=eth_dst)/packet,iface=iface, verbose=0)
            #debug lines
            #elapsed_time += time.time() - start
            #print "%s; ELASPED TIME: %f; SENT PACKET LENGTH: %d\n" % (state, elapsed_time, len(payload))
        time.sleep(iat)
		#debug lines
        #elapsed_time += iat
#    print "TOTAL DURATION: %f\n" % (elapsed_time)
            
def generate_packets(device, seed):
    #device = name of device
    #direction = [0 | 1]; 0:outgoing, 1:incoming
    #seed = seed for random number generators
    #algorithm:
    #infinite loop,
    #1. get state [passive/active]
    #2. for incoming and outgoing states
    #3. get interarrival time (IAT), length, duration [1:10 (seconds)]
    #4. spoof
    #5. sleep for some time
    while True:
        r_random = random.Random(seed)
        n_random = np.random.RandomState(seed)
        sub_threads = []
        #assumed the device is active 10% of the time
        s = n_random.choice(STATE, 1, p = (0.1, 0.9))[0]
        if s == "active":
            offset = 0
        else:
            offset = 18
        #duration of a segment
        #packets of sizes specified in the list "spoof_list" is spoofed during a segment
        duration = r_random.randrange(5,15) #PARAMETER
        #construct packets for outgoing(0) and incoming(1) states
        for direction in range(0,2):
            t_offset = offset + (8 * direction)
            device_dist = DIST[device][t_offset:t_offset+8]
            iat = float(DIST[device][offset + 16 + direction])
            iat = r_random.uniform(0.5*iat, 1.5*iat)
            #choose packet sizes at random in each range
            packet_200 = r_random.randrange(0,200)
            packet_400 = r_random.randrange(200,400)
            packet_600 = r_random.randrange(400,600)
            packet_800 = r_random.randrange(600,800)
            packet_1000 = r_random.randrange(800,1000)
            packet_1200 = r_random.randrange(1000,1200)
            packet_1400 = r_random.randrange(1200,1400)
            packet_1600 = r_random.randrange(1400,1441)
            packet_list = [packet_200, packet_400, packet_600, packet_800,
                           packet_1000, packet_1200, packet_1400, packet_1600]
            #number of repeats of the segment 
            repeat = r_random.randrange(1,10) #PARAMETER
            n_packets = int(duration/iat)
            spoof_list = n_random.choice(packet_list, n_packets, p = device_dist)
            device_info = device + s + str(direction)
            t = threading.Thread(target=spoof, args=(repeat,iat,spoof_list, direction, device))
            sub_threads.append(t)
        #start subthreads at the same time
        for t in sub_threads:
            t.start()
        #join threads
        for t in sub_threads:
            t.join()
        seed += 1
		#sleep for a random duration between 5-10 seconds
        time.sleep(r_random.randrange(5,10))
    
def main():
    #read in AGPS file
    in_file = sys.argv[1]
    with open(in_file, "r") as in_file:
        f_input = csv.reader(in_file)
        target_dist = [rows for rows in f_input]
    devicenames = [name[0] for name in target_dist][1:]
    for row in target_dist:
        del row[0]#remove header
	#dictionary containing the distribution of each sample
    global DIST
    DIST = dict(zip(devicenames, target_dist[1:]))

    #rotate random number seeds during loop
    seed = 42 #PARAMETER
    main_threads = []
	#create a thread for each sample being spoofed
    for device_name in devicenames:
        m = threading.Thread(target=generate_packets, args=(device_name, seed))
        main_threads.append(m)
        m.start()
        seed += 100
    for m in main_threads:
        m.join()
    
if __name__ == "__main__":
    main()
