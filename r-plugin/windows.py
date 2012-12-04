
import os
import string
import time
import vim
RConsole = 0

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
    vim.command("let rplugin_pywin32 = 0")

def FindRConsole():
    global RConsole
    RConsole = win32gui.FindWindow(None, "R Console")
    if RConsole == 0:
        RConsole = win32gui.FindWindow(None, "R Console (64-bit)")
        if RConsole == 0:
            RConsole = win32gui.FindWindow(None, "R Console (32-bit)")
            if RConsole == 0:
                vim.command("call RWarningMsg('Could not find R Console.')")

def SendToRConsole(aString):
    global RConsole
    SendToVimCom("\x09Set R as busy [SendToRConsole()]")
    finalString = aString.decode("latin-1") + "\n"
    win32clipboard.OpenClipboard(0)
    win32clipboard.EmptyClipboard()
    win32clipboard.SetClipboardText(finalString)
    win32clipboard.CloseClipboard()
    if RConsole == 0:
        FindRConsole()
    if RConsole:
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

def RClearConsolePy():
    global RConsole
    SendToVimCom("\x09Set R as busy [RClearConsolePy()]")
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

def SendQuitMsg(aString):
    SendToVimCom("\x09Set R as busy [SendQuitMsg()]")
    finalString = aString.decode("latin-1") + "\n"
    win32clipboard.OpenClipboard(0)
    win32clipboard.EmptyClipboard()
    win32clipboard.SetClipboardText(finalString)
    win32clipboard.CloseClipboard()
    sleepTime = float(vim.eval("g:vimrplugin_sleeptime"))
    RaiseRConsole()
    if RConsole:
        time.sleep(sleepTime)
        win32api.keybd_event(win32con.VK_CONTROL, 0, 0, 0)
        win32api.keybd_event(ord('V'), 0, win32con.KEYEVENTF_EXTENDEDKEY | 0, 0)
        time.sleep(0.05)
        win32api.keybd_event(ord('V'), 0, win32con.KEYEVENTF_EXTENDEDKEY | win32con.KEYEVENTF_KEYUP, 0)
        win32api.keybd_event(win32con.VK_CONTROL, 0, win32con.KEYEVENTF_KEYUP, 0)
        time.sleep(0.05)



def GetRPath():
    keyName = "SOFTWARE\\R-core\\R"
    kHandle = None
    try:
        kHandle = win32api.RegOpenKeyEx(win32con.HKEY_LOCAL_MACHINE, keyName, 0, win32con.KEY_READ)
        rVersion, reserved, kclass, lastwrite = win32api.RegEnumKeyEx(kHandle)[-1]
        keyName = keyName + "\\" + rVersion
        kHandle = win32api.RegOpenKeyEx(win32con.HKEY_LOCAL_MACHINE, keyName, 0, win32con.KEY_READ)
    except:
        try:
            kHandle = win32api.RegOpenKeyEx(win32con.HKEY_CURRENT_USER, keyName, 0, win32con.KEY_READ)
            rVersion, reserved, kclass, lastwrite = win32api.RegEnumKeyEx(kHandle)[-1]
            keyName = keyName + "\\" + rVersion
            kHandle = win32api.RegOpenKeyEx(win32con.HKEY_CURRENT_USER, keyName, 0, win32con.KEY_READ)
        except:
            vim.command("let s:rinstallpath =  'Not found'")
    if kHandle:
        (kname, rpath, vtype) = win32api.RegEnumValue(kHandle, 0)
        win32api.RegCloseKey(kHandle)
        if kname == 'InstallPath':
            vim.command("let s:rinstallpath = '" + rpath + "'")
        else:
            vim.command("let s:rinstallpath =  'Not found'")

def StartRPy():
    rpath = vim.eval("g:rplugin_Rgui")
    rargs = ['"' + rpath + '"']
    r_args = vim.eval("b:rplugin_r_args")
    if r_args != " ":
        r_args = r_args.split(' ')
        i = 0
        alen = len(r_args)
        while i < alen:
            rargs.append(r_args[i])
            i = i + 1

    kHandle = None
    keyName = "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders"
    try:
        kHandle = win32api.RegOpenKeyEx(win32con.HKEY_CURRENT_USER, keyName, 0, win32con.KEY_READ)
    except:
        vim.command("RWarningMsg('Personal folder not found in registry')")

    if kHandle:
        i = 0
        folder = "none"
        while folder != "Personal":
            try:
                (folder, fpath, vtype) = win32api.RegEnumValue(kHandle, i)
            except:
                break
            i = i + 1
        win32api.RegCloseKey(kHandle)
        if folder == "Personal":
            rargs.append('HOME="' + fpath + '"')
        else:
            vim.command("RWarningMsg('Personal folder not found in registry')")

    if os.path.isfile(rpath):
        os.spawnv(os.P_NOWAIT, rpath, rargs)
    else:
        vim.command("echoerr 'File ' . g:rplugin_Rgui . ' not found.'")

def OpenPDF(fn):
    try:
        os.startfile(fn)
    except Exception as errmsg:
        errstr = str(errmsg)
        errstr = errstr.replace("'", '"')
        vim.command("call RWarningMsg('" + errstr + "')")
        pass


