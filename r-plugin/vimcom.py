
import socket
import vim
import os
import re
VimComPort = 0
PortWarn = False

def DiscoverVimComPort():
    global PortWarn
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
        vim.command("let g:rplugin_vimcomport = 0")
        if not PortWarn:
            vim.command("call RWarningMsg('VimCom port not found.')")
        PortWarn = True
    else:
        vim.command("let g:rplugin_vimcomport = " + str(VimComPort))
        PortWarn = False
        if repl.find("0.9-4") != 0:
            vim.command("call RWarningMsg('This version of Vim-R-plugin requires vimcom 0.9-4.')")
            vim.command("sleep 1")
    return(VimComPort)


def SendToVimCom(aString):
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
        received = sock.recv(5012)
    except:
        pass
    finally:
        sock.close()

    if received is None:
        vim.command("let g:rplugin_lastrpl = 'NOANSWER'")
    else:
        received = received.replace("'", "' . \"'\" . '")
        vim.command("let g:rplugin_lastrpl = '" + received + "'")


