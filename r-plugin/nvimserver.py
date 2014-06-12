import sys
import socket
import re
import os

def NeovimServer():
    sock = None
    FinishNow = False
    UDP_IP = "127.0.0.1"
    MyPort = 1899

    while True and MyPort < 1999:
        try:
            MyPort += 1
            sock = socket.socket( socket.AF_INET, socket.SOCK_DGRAM )
            sock.bind( (UDP_IP,MyPort) )
        except:
            continue
        else:
            break

    if sock == None:
        MyPort = 0
        print "RWarningMsg('Could not bind to any port.')\n"
        sys.stdout.flush()
        return
    else:
        print "RSetMyPort(" + str(MyPort) + ")\n"
        sys.stdout.flush()

    while FinishNow == False:
        try:
            data, addr = sock.recvfrom( 1024 ) # buffer size is 1024 bytes
            if re.match("EXPR ", data):
                print re.sub("^EXPR ", "", data) + "\n"
                sys.stdout.flush()
            else:
                if data != "":
                    print "RWarningMsg('Strange string received: " + '"' + data + '"' + "')\n"
                    sys.stdout.flush()

        except Exception as errmsg:
            print "RWarningMsg('Server failed to read data: " + str(errmsg) + "')\n"
            sys.stdout.flush()
            MyPort = 0
            try:
                sock.shutdown(socket.SHUT_RD)
            except:
                pass
            sock.close()
            return
        try:
            sock.shutdown(socket.SHUT_RD)
        except:
            pass
        sock.close()
        if FinishNow == False:
            try:
                sock = socket.socket( socket.AF_INET, socket.SOCK_DGRAM )
                sock.bind( (UDP_IP,MyPort) )
            except Exception as errmsg:
                print "let g:rplugin_myport = 0 | call RWarningMsg('" + str(errmsg) + "')\n"
                sys.stdout.flush()
                pass

NeovimServer()

