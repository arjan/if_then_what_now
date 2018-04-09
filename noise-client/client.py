from noise import pnoise1
import random
import time
import socket
import json

axes = ["speed", "volume", "pitch"]

BASES = [random.randint(0, 1024) for _ in axes]
REPEAT = [1000, 2000, 1450]

INCR = 0.1

x = 0.0

UDP_IP = "127.0.0.1"
UDP_PORT = 33333
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)



while True:
    data = {}
    for i in range(len(axes)):
        k = axes[i]
        data[k] = 1 + 0.5 * pnoise1(x, base=BASES[i], repeat=REPEAT[i])
        data[k] = 0.2 + 3 * max(0, pnoise1(x, base=BASES[i], repeat=REPEAT[i]))
    print(data)
    print(x)
    sock.sendto(json.dumps(data).encode('utf-8'), (UDP_IP, UDP_PORT))
    x = x + INCR
    time.sleep(0.1)
