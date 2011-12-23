
import socket
import vim
import threading
import os
PORT = 0
OBPort = 0
sock = None


def DiscoverVimComPort():
    global PORT
    HOST = "localhost"
    PORT = 9998
    repl = "NOTHING"
    correct_repl = vim.eval("$VIMINSTANCEID")
    if correct_repl is None:
        correct_repl = os.getenv("VIMINSTANCEID")
        if correct_repl is None:
            vim.command("call RWarningMsg('VIMINSTANCEID not found.')")
            return

    while correct_repl.find(repl) < 0 and PORT < 10050:
        PORT = PORT + 1
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.settimeout(0.1)
        try:
            sock.connect((HOST, PORT))
            sock.send("\002What port?")
            repl = sock.recv(1024)
        except:
            pass
        sock.close()

    if PORT >= 10050:
        PORT = 0
        vim.command("call RWarningMsg('VimCom Port not found.')")
    return(PORT)


def SendToR(aString):
    HOST = "localhost"
    global PORT
    if PORT == 0:
        PORT = DiscoverVimComPort()
        if PORT == 0:
            return
    received = None

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(3.0)

    try:
        sock.connect((HOST, PORT))
        sock.send(aString)
        received = sock.recv(1024)
    except:
        pass
    finally:
        sock.close()

    if received is None:
        vim.command("let g:rplugin_lastrpl = 'NOANSWER'")
    else:
        vim.command("let g:rplugin_lastrpl = '" + received + "'")


def OBServer():
    global sock
    global OBPort
    UDP_IP="127.0.0.1"
    OBPort=5005

    while True and OBPort < 5100:
        try:
            OBPort += 1
            sock = socket.socket( socket.AF_INET, socket.SOCK_DGRAM )
            sock.bind( (UDP_IP,OBPort) )
        except:
            continue
        else:
            break

    if sock == None:
        OBPort = 0
        return
    else:
        SendToR("\007" + str(OBPort))

    while True:
        try:
            data, addr = sock.recvfrom( 1024 ) # buffer size is 1024 bytes
            if data.find("G") >= 0:
                vim.command("call UpdateOB('GlobalEnv')")
            else:
                if data.find("L") >= 0:
                    vim.command("call UpdateOB('libraries')")
                else:
                    if data.find("B") >= 0:
                        vim.command("call UpdateOB('GlobalEnv')")
                        vim.command("call UpdateOB('libraries')")
                    else:
                        try:
                            sock.shutdown(socket.SHUT_RD)
                        except:
                            pass
                            sock.close()
                            return
        except:
            OBPort = 0
            vim.command("call RWarningMsg('OBS 002')")
            try:
                sock.shutdown(socket.SHUT_RD)
            except:
                vim.command("call RWarningMsg('OBS 003')")
            sock.close()
            return
        try:
            sock.shutdown(socket.SHUT_RD)
        except:
            pass
        sock.close()
        sock = socket.socket( socket.AF_INET, socket.SOCK_DGRAM )
        sock.bind( (UDP_IP,OBPort) )


def RunOBServer():
    th = threading.Thread(target=OBServer)
    th.start()

def StopOBServer():
    global sock
    global OBPort
    SendToR("\x08Stop Updating Info")
    if OBPort == 0:
        return
    try:
        sock.shutdown(socket.SHUT_RD)
    except:
        pass
    sock.close()
    OBPort = 0

