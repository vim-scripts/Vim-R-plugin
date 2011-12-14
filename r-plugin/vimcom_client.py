import socket

def SendToR(aString):
    HOST, PORT = "localhost", 9999

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(3.0)

    try:
        sock.connect((HOST, PORT))
        sock.send(aString)
        received = sock.recv(1024)
    finally:
        sock.close()

    print "Sent:     {}".format(aString)
    print "Received: {}".format(received)
