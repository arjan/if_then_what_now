from noise import pnoise1
import random
import time
import socket
import json

axes = ["speed", "volume", "pitch"]
#axes = ["speed"]

D = 0.03
VALUES = [random.random() for _ in axes]
INCR = [D * (random.random() - 0.5) for _ in axes]

INCR = 0.1

x = 0.0

UDP_IP = "127.0.0.1"
UDP_PORT = 33333
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

points = 256
span = 5.0

while True:
    data = {}
    for i in range(len(axes)):
        VALUES[i] = max(0, min(1, VALUES[i] + D * (random.random() - 0.5)))
        k = axes[i]
        data[k] = VALUES[i]
        #print(data[k])
    print(data)
    sock.sendto(json.dumps(data).encode('utf-8'), (UDP_IP, UDP_PORT))
    x = x + INCR
    time.sleep(0.1)
