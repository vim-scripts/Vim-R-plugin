
import socket
import vim
import os
import re
import subprocess

def SendToVimCom(aString, VimComPort):
    received = None

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(3.0)

    try:
        sock.connect(("localhost", VimComPort))
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

