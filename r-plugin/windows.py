
import os
import string
import time
import vim
RConsole = 0
Rterm = False

try:
    import win32api
    import win32clipboard
    import win32com.client
    import win32con
    import win32gui
except ImportError:
    import platform
    myPyVersion = platform.python_version()
    myArch = platform.architecture()
    vim.command("call RWarningMsgInp('Please install PyWin32. The Python version being used is: " + myPyVersion + " (" + myArch[0] + ")')")

def RightClick():
    global RConsole
    myHandle = win32gui.GetForegroundWindow()
    RaiseRConsole()
    time.sleep(0.05)
    lParam = (100 << 16) | 100
    win32gui.SendMessage(RConsole, win32con.WM_RBUTTONDOWN, 0, lParam)
    win32gui.SendMessage(RConsole, win32con.WM_RBUTTONUP, 0, lParam)
    time.sleep(0.05)
    try:
        win32gui.SetForegroundWindow(myHandle)
    except:
        vim.command("call RWarningMsg('Could not put itself on foreground.')")

def CntrlV():
    global RConsole
    win32api.keybd_event(0x11, 0, 0, 0)
    try:
        win32api.PostMessage(RConsole, 0x100, 0x56, 0x002F0001)
    except:
        vim.command("call RWarningMsg('R Console window not found [1].')")
        RConsole = 0
        pass
    if RConsole:
        time.sleep(0.05)
        try:
            win32api.PostMessage(RConsole, 0x101, 0x56, 0xC02F0001)
        except:
            vim.command("call RWarningMsg('R Console window not found [2].')")
            pass
    win32api.keybd_event(0x11, 0, 2, 0)

def FindRConsole():
    global RConsole
    Rttl = vim.eval("g:vimrplugin_R_window_title")
    Rtitle = Rttl
    RConsole = win32gui.FindWindow(None, Rtitle)
    if RConsole == 0:
        Rtitle = Rttl + " (64-bit)"
        RConsole = win32gui.FindWindow(None, Rtitle)
        if RConsole == 0:
            Rtitle = Rttl + " (32-bit)"
            RConsole = win32gui.FindWindow(None, Rtitle)
            if RConsole == 0:
                vim.command("call RWarningMsg('Could not find R Console.')")
    if RConsole:
        vim.command("let g:rplugin_R_window_ttl = '" + Rtitle + "'")

def SendToRConsole(aString):
    global RConsole
    global Rterm
    SendToVimCom("\003Set R as busy [SendToRConsole()]")
    if sys.hexversion < 0x03000000:
        finalString = aString.decode("latin-1") + "\n"
    else:
        finalString = aString
    win32clipboard.OpenClipboard(0)
    win32clipboard.EmptyClipboard()
    win32clipboard.SetClipboardText(finalString)
    win32clipboard.CloseClipboard()
    if RConsole == 0:
        FindRConsole()
    if RConsole:
        if Rterm:
            RightClick()
        else:
            CntrlV()

def RClearConsolePy():
    global RConsole
    global Rterm
    if Rterm:
        return
    if RConsole == 0:
        FindRConsole()
    if RConsole:
        win32api.keybd_event(0x11, 0, 0, 0)
        try:
            win32api.PostMessage(RConsole, 0x100, 0x4C, 0x002F0001)
        except:
            vim.command("call RWarningMsg('R Console window not found [1].')")
            RConsole = 0
            pass
        if RConsole:
            time.sleep(0.05)
            try:
                win32api.PostMessage(RConsole, 0x101, 0x4C, 0xC02F0001)
            except:
                vim.command("call RWarningMsg('R Console window not found [2].')")
                pass
        win32api.keybd_event(0x11, 0, 2, 0)

def RaiseRConsole():
    global RConsole
    FindRConsole()
    if RConsole:
        win32gui.SetForegroundWindow(RConsole)
        time.sleep(0.1)

