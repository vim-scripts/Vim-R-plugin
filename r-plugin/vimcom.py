
import socket
import vim
import threading
from os import getenv
PORT = 0
KeepChecking = 1


def DiscoverVimComPort():
    global PORT
    HOST = "localhost"
    PORT = 9998
    repl = "NOTHING"
    correct_repl = getenv("VIMINSTANCEID")

    while repl != correct_repl and PORT < 10050:
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

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(3.0)

    try:
        sock.connect((HOST, PORT))
        sock.send(aString)
        received = sock.recv(1024)
    finally:
        sock.close()

    if received is None:
        vim.command("let g:rplugin_lastrpl = 'NOANSWER'")
    else:
        vim.command("let g:rplugin_lastrpl = '" + received + "'")


def CheckObjects():
    global KeepChecking
    if KeepChecking == 0:
        return
    SendToR("\007Objects and Libraries?")
    ans = vim.eval("g:rplugin_lastrpl")
    if ans == "1":
        vim.command("call UpdateGlobalEnv()")
    else:
        if ans == "2":
            vim.command("call UpdateLibraries()")
        else:
            if ans == "3":
                vim.command("call UpdateGlobalEnv()")
                vim.command("call UpdateLibraries()")
    t = threading.Timer(1.0, CheckObjects)
    t.start()

