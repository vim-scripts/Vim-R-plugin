
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
    vim.command("let rplugin_pywin32 = 0")

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

def SendQuitMsg(aString):
    global RConsole
    global Rterm
    SendToVimCom("\003Set R as busy [SendQuitMsg()]")
    if sys.hexversion < 0x03000000:
        finalString = aString.decode("latin-1") + "\n"
    else:
        finalString = aString + "\n"
    win32clipboard.OpenClipboard(0)
    win32clipboard.EmptyClipboard()
    win32clipboard.SetClipboardText(finalString)
    win32clipboard.CloseClipboard()
    sleepTime = float(vim.eval("g:vimrplugin_sleeptime"))
    RaiseRConsole()
    if RConsole and not Rterm:
        time.sleep(sleepTime)
        win32api.keybd_event(win32con.VK_CONTROL, 0, 0, 0)
        win32api.keybd_event(ord('V'), 0, win32con.KEYEVENTF_EXTENDEDKEY | 0, 0)
        time.sleep(0.05)
        win32api.keybd_event(ord('V'), 0, win32con.KEYEVENTF_EXTENDEDKEY | win32con.KEYEVENTF_KEYUP, 0)
        win32api.keybd_event(win32con.VK_CONTROL, 0, win32con.KEYEVENTF_KEYUP, 0)
        time.sleep(0.05)
        RConsole = 0
    if RConsole and Rterm:
        RightClick()
        RConsole = 0

def GetRPath():
    keyName = "SOFTWARE\\R-core\\R"
    kHandle = None
    try:
        kHandle = win32api.RegOpenKeyEx(win32con.HKEY_LOCAL_MACHINE, keyName, 0, win32con.KEY_READ)
        rVersion, reserved, kclass, lastwrite = win32api.RegEnumKeyEx(kHandle)[-1]
        win32api.RegCloseKey(kHandle)
        kHandle = None
        keyName = keyName + "\\" + rVersion
        kHandle = win32api.RegOpenKeyEx(win32con.HKEY_LOCAL_MACHINE, keyName, 0, win32con.KEY_READ)
    except:
        try:
            kHandle = win32api.RegOpenKeyEx(win32con.HKEY_CURRENT_USER, keyName, 0, win32con.KEY_READ)
            rVersion, reserved, kclass, lastwrite = win32api.RegEnumKeyEx(kHandle)[-1]
            win32api.RegCloseKey(kHandle)
            kHandle = None
            keyName = keyName + "\\" + rVersion
            kHandle = win32api.RegOpenKeyEx(win32con.HKEY_CURRENT_USER, keyName, 0, win32con.KEY_READ)
        except:
            vim.command("let s:rinstallpath =  'Key not found'")
    if kHandle:
        (kname, rpath, vtype) = win32api.RegEnumValue(kHandle, 0)
        win32api.RegCloseKey(kHandle)
        if kname == 'InstallPath':
            vim.command("let s:rinstallpath = '" + rpath + "'")
        else:
            vim.command("let s:rinstallpath =  'Path not found'")

def StartRPy():
    global Rterm
    if vim.eval("g:vimrplugin_Rterm") == "1":
        Rterm = True
    else:
        Rterm = False
    rpath = vim.eval("g:rplugin_Rgui")
    rpath = rpath.replace("\\", "\\\\")
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


