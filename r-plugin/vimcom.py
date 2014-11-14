
import socket
import vim
import os
import re
import subprocess
VimComPort = 0
PortWarn = 0
VimComFamily = None

def DiscoverVimComPort():
    global PortWarn
    global VimComPort
    global VimComFamily
    HOST = "localhost"
    VimComPort = 10000
    repl = "NOTHING"
    vii = vim.eval("$VIMINSTANCEID")
    if vii is None:
        vii = os.getenv("VIMINSTANCEID")
        if vii is None:
            vim.command("call RWarningMsg('VIMINSTANCEID not found.')")
            return
    scrt = vim.eval("$VIMRPLUGIN_SECRET")
    if scrt is None:
        scrt = os.getenv("VIMRPLUGIN_SECRET")
        if scrt is None:
            vim.command("call RWarningMsg('VIMRPLUGIN_SECRET not found.')")
            return

    while repl.find(scrt) < 0 and VimComPort < 10049:
        VimComPort = VimComPort + 1
        for res in socket.getaddrinfo(HOST, VimComPort, socket.AF_UNSPEC, socket.SOCK_DGRAM):
            af, socktype, proto, canonname, sa = res
            try:
                sock = socket.socket(af, socktype, proto)
                sock.settimeout(0.1)
                sock.connect(sa)
                if sys.hexversion < 0x03000000:
                    sock.send("\001" + vii + " What port [Python 2]?")
                    repl = sock.recv(1024)
                else:
                    sock.send("\001" + vii + " What port [Python 3]?".encode())
                    repl = sock.recv(1024).decode()
                sock.close()
                if repl.find(scrt):
                    VimComFamily = af
                    break
            except:
                sock = None
                continue

    if VimComPort >= 10049:
        VimComPort = 0
        vim.command("let g:rplugin_vimcomport = 0")
        if PortWarn < 2:
            vim.command("call RWarningMsg('VimCom port not found.')")
        PortWarn = PortWarn + 1
    else:
        vim.command("let g:rplugin_vimcomport = " + str(VimComPort))
        PortWarn = 0
        if repl.find("1.1-0") != 0:
            vim.command("call RWarningMsg('This version of Vim-R-plugin requires vimcom 1.1-0.')")
            vim.command("sleep 1")
    return(VimComPort)


def SendToVimCom(aString):
    HOST = "localhost"
    global VimComPort
    global VimComFamily
    if VimComPort == 0:
        VimComPort = DiscoverVimComPort()
        if VimComPort == 0:
            return
    received = None

    sock = socket.socket(VimComFamily, socket.SOCK_DGRAM)
    sock.settimeout(3.0)

    try:
        sock.connect((HOST, VimComPort))
        if sys.hexversion < 0x03000000:
            sock.send(aString)
            received = sock.recv(5012)
        else:
            sock.send(aString.encode())
            received = sock.recv(5012).decode()
    except:
        pass
    finally:
        sock.close()

    if received is None:
        vim.command("let g:rplugin_lastrpl = 'NOANSWER'")
        VimComPort = 0
        vim.command("let g:rplugin_vimcomport = 0")
    else:
        received = received.replace("'", "' . \"'\" . '")
        vim.command("let g:rplugin_lastrpl = '" + received + "'")


def Start_Zathura(basenm, sname):
    a1 = '--synctex-editor-command'
    a2 = 'vim --servername ' + sname + " --remote-expr SyncTeX_backward(\\'%{input}\\',%{line})"
    a3 = basenm + ".pdf"
    FNULL = open(os.devnull, 'w')
    zpid = subprocess.Popen(["zathura", a1, a2, a3], stdout = FNULL, stderr = FNULL).pid
    vim.command("let g:rplugin_zathura_pid['" + basenm + "'] = " + str(zpid))

