
import os
import string
import time
import vim

try:
    import win32api
    import win32clipboard as w
    import win32com.client
    import win32con
except ImportError:
    import platform
    myPyVersion = platform.python_version()
    myArch = platform.architecture()
    vim.command("call RWarningMsgInp('Please install PyWin32. The Python version being used is: " + myPyVersion + " (" + myArch[0] + ")')")
    vim.command("let rplugin_pywin32 = 0")


def SendToRPy(aString):
    # backup the clipboard content (if text)
    w.OpenClipboard(0)
    if w.IsClipboardFormatAvailable(w.CF_TEXT):
        cdata = w.GetClipboardData()
    else:
        cdata = None
    w.CloseClipboard()

    finalString = aString.decode("latin-1")

    sleepTime = float(vim.eval("g:vimrplugin_sleeptime"))
    w.OpenClipboard(0)
    w.EmptyClipboard()
    w.SetClipboardText(finalString)
    w.CloseClipboard()

    shell = win32com.client.Dispatch("WScript.Shell")
    ok = shell.AppActivate("R Console")
    if ok:
        time.sleep(sleepTime)
        shell.SendKeys("^v")
        time.sleep(sleepTime)
    else:
        vim.command("call RWarningMsg('Is R running?')")
        time.sleep(1)
    
def RestoreClipboardPy():
    if cdata:
        w.OpenClipboard(0)
        w.EmptyClipboard()
        w.SetClipboardText(cdata)
        w.CloseClipboard()

def RClearConsolePy():

    sleepTime = string.atof(vim.eval("g:vimrplugin_sleeptime"))
    shell = win32com.client.Dispatch("WScript.Shell")
    ok = shell.AppActivate("R Console")
    if ok:
        shell.SendKeys("^l")
        time.sleep(sleepTime)
    else:
        vim.command("call RWarningMsg('Is R running?')")
        time.sleep(1)

def GetRPathPy():
    keyName = "SOFTWARE\\R-core\\R"
    kHandle = None
    try:
        kHandle = win32api.RegOpenKeyEx(win32con.HKEY_LOCAL_MACHINE, keyName, 0, win32con.KEY_READ)
    except:
        try:
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
    rpath = vim.eval("b:rplugin_Rgui")
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

# vim: sw=4 tabstop=4 expandtab
