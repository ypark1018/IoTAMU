import pyshark as ps
import binascii
import sys

IoT = {
    "Camera1": "EC:1A:59:E4:FD:41",
    "CameraTest": "EC:1A:59:E5:02:0D",
    "Camera2": "30:8C:FB:3A:1A:AD",
    "Camera3": "28:AD:3E:38:6F:B6",
    "Lightbulb1": "D0:73:D5:26:B8:4C",
    "LightbulbTest": "D0:73:D5:26:C9:27",
    "Lightbulb2": "B0:4E:26:C5:2A:41",
    "Switch1": "14:91:82:CD:DF:3D",
    "SwitchTest": "B4:75:0E:0D:94:65",
    "Switch2": "60:38:E0:EE:7C:E5",
    "Switch3": "70:4F:57:F9:E1:B8"
}
IoTMU = "A4:C4:94:3E:20:9C"

def main():
    if len(sys.argv) != 4:
        print("python iot_table.py [inputfile] [outputfile] [Type]\n")
        sys.exit()
    f_input = sys.argv[1]
    f_output = sys.argv[2]
    f_type = sys.argv[3]
    
    cap = ps.FileCapture(f_input, display_filter='frame contains %s && frame contains %s' % (IoT[f_type], IoTMU))

    f = open(f_output, "w")
    f.write('No.,Time,Direction,Length,IAT\n')
    lastOutPacket = 0
    lastInPacket = 0
    for packet in cap:
        #if the destination MAC addr is IoTAMU, then the packet is an outgoing packet
        if "80:2A:A8:9E:45:5A" in packet.wlan.da.upper():
            direction = "OUTGOING"
            iat = float(packet.sniff_timestamp) - float(lastOutPacket)
            lastOutPacket = packet.sniff_timestamp
        else:
            direction = "INCOMING"
            iat = float(packet.sniff_timestamp) - float(lastInPacket)
            lastInPacket = packet.sniff_timestamp
        f.write('%s,%s,%s,%s,%s\n' % (packet.number, packet.sniff_timestamp, direction, packet.length, '{:.20f}'.format(iat)))
    f.close()

if __name__ == '__main__':
    main()
