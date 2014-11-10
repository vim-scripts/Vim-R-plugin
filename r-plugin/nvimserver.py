import sys
import socket
import re
import os

def NeovimServer():
    sock = None
    FinishNow = False
    UDP_IP = "127.0.0.1"
    MyPort = 1899
    VimSecret = os.getenv("VIMRPLUGIN_SECRET")

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
        sys.stderr.write("Could not bind to any port.")
        sys.stderr.flush()
        return
    else:
        sys.stdout.write("call RSetMyPort(" + str(MyPort) + ")\n")
        sys.stdout.flush()

    while FinishNow == False:
        try:
            data, addr = sock.recvfrom( 1024 ) # buffer size is 1024 bytes
            if re.match(VimSecret, data):
                sys.stdout.write(re.sub(VimSecret, "", data) + "\n")
                sys.stdout.flush()
            else:
                if data != "":
                    sys.stderr.write('Strange string received: "' + data + '"')
                    sys.stderr.flush()

        except Exception as errmsg:
            sys.stderr.write('Server failed to read data: "' + str(errmsg) + '"')
            sys.stderr.flush()
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
                sys.stdout.write("let g:rplugin_myport = 0 | call RWarningMsg('" + str(errmsg) + "')\n")
                sys.stdout.flush()
                pass

NeovimServer()

