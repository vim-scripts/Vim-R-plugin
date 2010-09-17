
function! SendToRPy(aString)
python << EOL
import vim
import time
import string
import win32com.client
import win32clipboard as w

# backup the clipboard content (if text)
w.OpenClipboard(0)
if w.IsClipboardFormatAvailable(w.CF_TEXT):
    cdata = w.GetClipboardData()
else:
    cdata = None
w.CloseClipboard()

aString = vim.eval("a:aString")
sleepTime = string.atof(vim.eval("g:vimrplugin_sleeptime"))
w.OpenClipboard(0)
w.EmptyClipboard()
w.SetClipboardText(aString)
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
EOL
endfunction

function! RestoreClipboardPy()
python << EOL
if cdata:
    w.OpenClipboard(0)
    w.EmptyClipboard()
    w.SetClipboardText(cdata)
    w.CloseClipboard()
EOL
endfunction

function! RClearConsolePy()
python << EOL
import vim
import time
import string
import win32com.client

sleepTime = string.atof(vim.eval("g:vimrplugin_sleeptime"))
shell = win32com.client.Dispatch("WScript.Shell")
ok = shell.AppActivate("R Console")
if ok:
    shell.SendKeys("^l")
    time.sleep(sleepTime)
else:
    vim.command("call RWarningMsg('Is R running?')")
    time.sleep(1)
EOL
endfunction

function! GetRPathPy()
python << EOL
import win32api
import win32con
import vim

keyName = "SOFTWARE\\R-core\\R"
kHandle = None
try:
    kHandle = win32api.RegOpenKeyEx(win32con.HKEY_LOCAL_MACHINE, keyName, 0, win32con.KEY_READ)
except:
    try:
	kHandle = win32api.RegOpenKeyEx(win32con.HKEY_CURRENT_USER, keyName, 0, win32con.KEY_READ)
    except:
	vim.command("return 'Not found'")
if kHandle:
    (kname, rpath, vtype) = win32api.RegEnumValue(kHandle, 0)
    win32api.RegCloseKey(kHandle)
    if kname == 'InstallPath':
	vim.command("return '" + rpath + "'")
    else:
	vim.command("return 'Not found'")
EOL
endfunction

function! StartRPy()
python << EOL
import win32api
import win32con
import string
import vim
import os

rpath = vim.eval("b:Rgui")
rargs = ['"' + rpath + '"']
r_args = vim.eval("b:r_args")
if r_args != " ":
    r_args = string.split(r_args, sep = " ")
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

os.spawnv(os.P_NOWAIT, rpath, rargs)
EOL
endfunction

" vim: sw=4
