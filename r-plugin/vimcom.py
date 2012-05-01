
import socket
import vim
import threading
import os
import re
VimComPort = 0
OtherPort = 0
MyPort = 0
sock = None
th = None
FinishNow = False

def DiscoverVimComPort():
    global VimComPort
    HOST = "localhost"
    VimComPort = 9998
    repl = "NOTHING"
    correct_repl = vim.eval("$VIMINSTANCEID")
    if correct_repl is None:
        correct_repl = os.getenv("VIMINSTANCEID")
        if correct_repl is None:
            vim.command("call RWarningMsg('VIMINSTANCEID not found.')")
            return

    while repl.find(correct_repl) < 0 and VimComPort < 10050:
        VimComPort = VimComPort + 1
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.settimeout(0.1)
        try:
            sock.connect((HOST, VimComPort))
            sock.send("\002What port?")
            repl = sock.recv(1024)
        except:
            pass
        sock.close()

    if VimComPort >= 10050:
        VimComPort = 0
        vim.command("call RWarningMsg('VimCom Port not found.')")
    else:
        vim.command("let g:rplugin_vimcomport = " + str(VimComPort))
        if repl.find("0.9-2 ") != 0:
            vim.command("call RWarningMsg('This version of Vim-R-plugin requires vimcom 0.9-2.')")
    return(VimComPort)


def SendToR(aString):
    HOST = "localhost"
    global VimComPort
    if VimComPort == 0:
        VimComPort = DiscoverVimComPort()
        if VimComPort == 0:
            return
    received = None

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(3.0)

    try:
        sock.connect((HOST, VimComPort))
        sock.send(aString)
        received = sock.recv(1024)
    except:
        pass
    finally:
        sock.close()

    if received is None:
        vim.command("let g:rplugin_lastrpl = 'NOANSWER'")
    else:
        received = received.replace("'", "' . \"'\" . '")
        vim.command("let g:rplugin_lastrpl = '" + received + "'")


def VimServer():
    global sock
    global MyPort
    global FinishNow
    UDP_IP = "127.0.0.1"
    MyPort = int(vim.eval("g:rplugin_myport1"))
    PortLim = int(vim.eval("g:rplugin_myport2"))

    while True and MyPort < PortLim:
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
        vim.command("call RWarningMsg('Could not bind to any port.')")
        return
    else:
        vim.command("let g:rplugin_myport = " + str(MyPort))
        SendToR("\007" + str(MyPort))

    while FinishNow == False:
        try:
            data, addr = sock.recvfrom( 1024 ) # buffer size is 1024 bytes
            if vim.eval("g:rplugin_ob_busy") == "1":
                data = ""
            if re.match("EXPR ", data):
                vim.command("silent exe '" + re.sub("^EXPR ", "", data) + "'")
            else:
                if re.match("^G", data):
                    vim.command("call UpdateOB('GlobalEnv')")
                else:
                    if re.match("^L", data):
                        vim.command("call UpdateOB('libraries')")
                    else:
                        if re.match("^B", data):
                            vim.command("call UpdateOB('GlobalEnv')")
                            vim.command("call UpdateOB('libraries')")
                        else:
                            if re.match("^FINISH", data):
                                FinishNow = True
                                MyPort = 0
                            else:
                                if data != "":
                                    vim.command("call RWarningMsg('Strange string received: " + '"' + data + '"' + "')")
                                    vim.command("sleep 1")

        except Exception as errmsg:
            vim.command("call RWarningMsg('Server failed to read data: " + str(errmsg) + "')")
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
                vim.command("let g:rplugin_myport = 0")
                vim.command("call RWarningMsg('" + str(errmsg) + "')")
                pass

def RunServer():
    global th
    global FinishNow
    FinishNow = False
    th = threading.Thread(target=VimServer)
    th.start()

def StopServer():
    global sock
    global MyPort
    global FinishNow
    FinishNow = True
    if VimComPort:
        SendToR("\x08Stop Updating Info")
    vim.command("let g:rplugin_myport = 0")
    ft = vim.eval("&filetype")
    if ft == "rbrowser":
        VimClient("EXPR let g:rplugin_objbr_port = 0 | let g:vimrplugin_objbr_w = " + vim.eval("&columns"))
    if MyPort == 0:
        return
    try:
        sock.shutdown(socket.SHUT_RD)
    except:
        pass
    try:
        sock.close()
    except:
        pass
    try:
        th.join(0.3)
    except:
        pass
    MyPort = 0

def VimClient(msg):
    if OtherPort == 0:
        return
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.sendto(msg, ("127.0.0.1", OtherPort))
    sock.close()

