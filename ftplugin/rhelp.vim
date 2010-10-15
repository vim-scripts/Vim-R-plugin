"  This program is free software; you can redistribute it and/or modify
"  it under the terms of the GNU General Public License as published by
"  the Free Software Foundation; either version 2 of the License, or
"  (at your option) any later version.
"
"  This program is distributed in the hope that it will be useful,
"  but WITHOUT ANY WARRANTY; without even the implied warranty of
"  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"  GNU General Public License for more details.
"
"  A copy of the GNU General Public License is available at
"  http://www.r-project.org/Licenses/

"==========================================================================
" ftplugin for R files
"
" Authors: Jakson Alves de Aquino <jalvesaq@gmail.com>
"          Jose Claudio Faria
"          
"          Based on previous work by Johannes Ranke
"
" Last Change: Thu Oct 14, 2010  10:23PM
"
" Please see doc/r-plugin.txt for usage details.
"==========================================================================

" Only do this when not yet done for this buffer
if exists("b:did_ftplugin")
  finish
endif

" Don't load another plugin for this buffer
let b:did_ftplugin = 1

function! RWarningMsg(wmsg)
  echohl WarningMsg
  echomsg a:wmsg
  echohl Normal
endfunction

" Set completion with CTRL-X CTRL-O to autoloaded function.
if exists('&ofu')
  setlocal ofu=rcomplete#CompleteR
endif


" b:user_vimfiles should be the directory where the user put
" personal stuff: plugins, colorschemes etc... By default, it is ~/.vim or
" ~/vimfiles and this is the first directory of runtimepath.
let b:user_vimfiles = split(&runtimepath, ",")[0]

" b:r_plugin_home should be the directory where the r-plugin files are.  For
" users following the installation instructions it will be at ~/.vim or
" ~/vimfiles, that is, the same value of b:user_vimfiles. However the
" variables will have different values if the plugin is installed somewhere
" else in the runtimepath.
let b:r_plugin_home = expand("<sfile>:h:h")


" Automatically rebuild the file listing .GlobalEnv objects for omni
" completion if the user press <C-X><C-O> and we know that the file either was
" not created yet or is outdated.
let b:needsnewomnilist = 1

" From changelog.vim
let s:userlogin = system('whoami')
if v:shell_error
  let s:userlogin = 'unknown'
else
  let newline = stridx(s:userlogin, "\n")
  if newline != -1
    let s:userlogin = strpart(s:userlogin, 0, newline)
  endif
endif

if has("gui_win32")
  let b:vimjspath = b:r_plugin_home . "\\r-plugin\\vimActivate.js"
  let b:r_plugin_home = substitute(b:r_plugin_home, "\\", "/", "g")
  let b:user_vimfiles = substitute(b:user_vimfiles, "\\", "/", "g")
  if !has("python")
    call RWarningMsg("Python interface must be enabled to run Vim-R-Plugin.")
    call RWarningMsg("Please do  ':h r-plugin-installation'  for details.")
    call input("Press <Enter> to continue. ")
    let b:needsnewomnilist = 0
    finish
  endif
  exe "source " . b:r_plugin_home . "/r-plugin/rpython.vim"
  if !exists("g:rplugin_rpathadded")
    if exists("g:vimrplugin_r_path")
      let $PATH = g:vimrplugin_r_path . ";" . $PATH
      let b:Rgui = g:vimrplugin_r_path . "\\Rgui.exe"
    else
      let b:rinstallpath = GetRPathPy()
      if b:rinstallpath == "Not found"
	call RWarningMsg('Could not find R path in Windows Registry.')
	call input("Press <Enter> to continue. ")
	finish
      endif
      let $PATH = b:rinstallpath . '\bin;' . $PATH
      let b:Rgui = b:rinstallpath . "\\bin\\Rgui.exe"
    endif
    let g:rplugin_rpathadded = 1
  endif
  let b:R = "Rgui.exe"
  let g:vimrplugin_term_cmd = "none"
  let g:vimrplugin_term = "none"
  let g:vimrplugin_noscreenrc = 1
  if !exists("g:vimrplugin_r_args")
    let g:vimrplugin_r_args = "--sdi"
  endif
  if !exists("g:vimrplugin_sleeptime")
    let g:vimrplugin_sleeptime = 0.02
  endif
  let g:vimrplugin_vimpager = "no"
else
  if !executable('screen') && !exists("g:ConqueTerm_Version")
    if has("python")
      call RWarningMsg("Please, install either the 'screen' application or the 'Conque Shell' plugin to enable the Vim-R-plugin.")
    else
      call RWarningMsg("Please, install the 'screen' application to enable the Vim-R-plugin.")
    endif
    call input("Press <Enter> to continue. ")
    finish
  endif
  if exists("g:vimrplugin_r_path")
    let b:R = g:vimrplugin_r_path . "/R"
  else
    let b:R = "R"
  endif
  if !exists("g:vimrplugin_r_args")
    let g:vimrplugin_r_args = " "
  endif
endif


" Set default value of some variables:
function! RSetDefaultValue(var, val)
  if !exists(a:var)
    exe "let " . a:var . " = " . a:val
  endif
endfunction

call RSetDefaultValue("g:vimrplugin_map_r",        0)
call RSetDefaultValue("g:vimrplugin_open_df",      1)
call RSetDefaultValue("g:vimrplugin_open_list",    0)
call RSetDefaultValue("g:vimrplugin_underscore",   1)
call RSetDefaultValue("g:vimrplugin_conquevsplit", 0)
call RSetDefaultValue("g:vimrplugin_listmethods",  0)
call RSetDefaultValue("g:vimrplugin_specialplot",  0)
call RSetDefaultValue("g:vimrplugin_nosingler",    0)
call RSetDefaultValue("g:vimrplugin_noscreenrc",   0)
call RSetDefaultValue("g:vimrplugin_routnotab",    0) 
call RSetDefaultValue("g:vimrplugin_editor_w",    66)
call RSetDefaultValue("g:vimrplugin_help_w",      46)
call RSetDefaultValue("g:vimrplugin_buildwait",  120)
call RSetDefaultValue("g:vimrplugin_by_vim_instance", 0)
call RSetDefaultValue("g:vimrplugin_never_unmake_menu", 0)
call RSetDefaultValue("g:vimrplugin_vimpager",       "'no'")
call RSetDefaultValue("g:vimrplugin_latexcmd", "'pdflatex'")

if isdirectory("/tmp")
  let $VIMRPLUGIN_TMPDIR = "/tmp/r-plugin-" . s:userlogin
else
  let $VIMRPLUGIN_TMPDIR = b:user_vimfiles . "/r-plugin"
endif

if !isdirectory($VIMRPLUGIN_TMPDIR)
  call mkdir($VIMRPLUGIN_TMPDIR, "p", 0700)
endif

let g:rplugin_docfile = $VIMRPLUGIN_TMPDIR . "/Rdoc"
let b:globalenvlistfile = $VIMRPLUGIN_TMPDIR . "/GlobalEnvList"

" Use Conque Shell plugin by default... 
if exists("g:ConqueTerm_Loaded") && !exists("g:vimrplugin_conqueplugin")
  if has("python")
    let g:vimrplugin_conqueplugin = 1
    " ... unless explicitly told otherwise in the vimrc
    if exists("g:vimrplugin_screenplugin") && g:vimrplugin_screenplugin == 1
      let g:vimrplugin_conqueplugin = 0
    endif
  else
    call RWarningMsg("Python interface must be enabled to run Vim-R-Plugin with Conque Shell.")
    let g:vimrplugin_conqueplugin = 0
    sleep 2
  endif
endif
if exists("g:vimrplugin_conqueplugin") && g:vimrplugin_conqueplugin == 1
  if !exists("g:ConqueTerm_Version") || (exists("g:ConqueTerm_Version") && g:ConqueTerm_Version < 120)
    let g:vimrplugin_conqueplugin = 0
    call RWarningMsg("Vim-R-plugin requires Conque Shell plugin >= 1.2")
    call input("Press <Enter> to continue. ")
  endif
endif

if !exists("g:vimrplugin_conqueplugin")
  let g:vimrplugin_conqueplugin = 0
endif

if g:vimrplugin_conqueplugin == 1
  let g:vimrplugin_screenplugin = 0
endif

if !exists("g:vimrplugin_screenplugin") && exists("g:ScreenImpl")
  let g:vimrplugin_screenplugin = 1
endif

" The screen.vim plugin only works on terminal emulators
if !exists("g:vimrplugin_screenplugin") || has('gui_running')
  let g:vimrplugin_screenplugin = 0
endif

" Check again if screen is installed
if !has("gui_win32") && g:vimrplugin_conqueplugin == 0 && g:vimrplugin_screenplugin == 0 && !executable("screen")
  if has("python") && !exists("g:ConqueTerm_Version")
    call RWarningMsg("Please, install either the 'screen' application or the 'Conque Shell' plugin to enable the Vim-R-plugin.")
  else
    call RWarningMsg("Please, install the 'screen' application to enable the Vim-R-plugin.")
  endif
  call input("Press <Enter> to continue. ")
  finish
endif

" Make the file name of files to be sourced
let b:bname = expand("%:t")
let b:bname = substitute(b:bname, " ", "",  "g")
if exists("*getpid") " getpid() was introduced in Vim 7.1.142
  let b:rsource = $VIMRPLUGIN_TMPDIR . "/Rsource-" . getpid() . "-" . b:bname
else
  let b:randnbr = system("echo $RANDOM")
  let b:randnbr = substitute(b:randnbr, "\n", "", "")
  if strlen(b:randnbr) == 0
    let b:randnbr = "NoRandom"
  endif
  let b:rsource = $VIMRPLUGIN_TMPDIR . "/Rsource-" . b:randnbr . "-" . b:bname
  unlet b:randnbr
endif
unlet b:bname

" Replace 'underline' with '<-'
if g:vimrplugin_underscore == 1
  imap <buffer> _ <Esc>:call ReplaceUnderS()<CR>a
endif

" Are we in a Debian package? Is the plugin being running for the first time?
" Create r-plugin directory if it doesn't exist yet:
if !isdirectory(b:user_vimfiles . "/r-plugin")
  call mkdir(b:user_vimfiles . "/r-plugin", "p")
endif

" If there is no functions.vim, copy the default one
if !filereadable(b:user_vimfiles . "/r-plugin/functions.vim")
  if filereadable("/usr/share/vim/addons/r-plugin/functions.vim")
    let x = readfile("/usr/share/vim/addons/r-plugin/functions.vim")
    call writefile(x, b:user_vimfiles . "/r-plugin/functions.vim")
  endif
endif

" If there is no omnilist, copy the default one
let b:libs_omni_filename = b:user_vimfiles . "/r-plugin/omnilist"
if !filereadable(b:libs_omni_filename)
  if filereadable("/usr/share/vim/addons/r-plugin/omnilist")
    let x = readfile("/usr/share/vim/addons/r-plugin/omnilist")
    call writefile(x, b:libs_omni_filename)
  else
    if filereadable(b:r_plugin_home . "/r-plugin/omnilist")
      let x = readfile(b:r_plugin_home . "/r-plugin/omnilist")
      call writefile(x, b:libs_omni_filename)
    else
      call writefile([], b:libs_omni_filename)
    endif
  endif
endif

" Keeps the libraries object list in memory to avoid the need of reading the file
" repeatedly:
let b:flines1 = readfile(b:libs_omni_filename)


" Control the menu 'R' and the tool bar buttons
if !exists("g:rplugin_hasmenu")
  let g:rplugin_hasmenu = 0
endif

" Special screenrc file
let b:scrfile = " "

" List of marks that the plugin seeks to find the block to be sent to R
let s:all_marks = "abcdefghijklmnopqrstuvwxyz"

" The current buffer number
if !exists("g:rplugin_curbuf") && (&filetype == "r" || &filetype == "rnoweb")
  let g:rplugin_curbuf = bufname("%")
endif

" Create an empty file to avoid errors if the user do Ctrl-X Ctrl-O before
" starting R:
call writefile([], b:globalenvlistfile)

" Choose a terminal (code adapted from screen.vim)
if has("gui_win32")
  let g:vimrplugin_term = "xterm"
else
  let s:terminals = ['gnome-terminal', 'konsole', 'xfce4-terminal', 'iterm', 'Eterm', 'rxvt', 'aterm', 'xterm' ]
  if !exists("g:vimrplugin_term")
    for term in s:terminals
      if executable(term)
	let g:vimrplugin_term = term
	break
      endif
    endfor
    unlet term
  endif
  unlet s:terminals
endif

if !exists("g:vimrplugin_term") && !exists("g:vimrplugin_term_cmd")
  call RWarningMsg("Please, set the variable 'g:vimrplugin_term_cmd' in your .vimrc.\nRead the plugin documentation for details.")
  call input("Press <Enter> to continue. ")
  finish
endif

if g:vimrplugin_term == "gnome-terminal" || g:vimrplugin_term == "xfce4-terminal"
  " Cannot set icon: http://bugzilla.gnome.org/show_bug.cgi?id=126081
  let b:term_cmd = g:vimrplugin_term . " --working-directory='" . expand("%:p:h") . "' --title R -e"
endif

if g:vimrplugin_term == "konsole"
  let b:term_cmd = "konsole --workdir '" . expand("%:p:h") . "' --icon " . b:r_plugin_home . "/bitmaps/ricon.png -e"
endif

if g:vimrplugin_term == "Eterm"
  let b:term_cmd = "Eterm --icon " . b:r_plugin_home . "/bitmaps/ricon.png -e"
endif

if g:vimrplugin_term == "rxvt" || g:vimrplugin_term == "aterm"
  let b:term_cmd = g:vimrplugin_term . " -e"
endif

if g:vimrplugin_term == "xterm" || g:vimrplugin_term == "uxterm"
  let b:term_cmd = g:vimrplugin_term . " -xrm '*iconPixmap: " . b:r_plugin_home . "/bitmaps/ricon.xbm' -e"
endif

" Override default settings:
if exists("g:vimrplugin_term_cmd")
  let b:term_cmd = g:vimrplugin_term_cmd
endif

if g:vimrplugin_nosingler == 1
  " Make a random name for the screen session
  let b:screensname = "vimrplugin-" . s:userlogin . "-" . localtime()
else
  " Make a unique name for the screen session
  let b:screensname = "vimrplugin-" . s:userlogin
endif

" Make a unique name for the screen process for each Vim instance:
if g:vimrplugin_by_vim_instance == 1
  let sname = substitute(v:servername, " ", "-", "g")
  if sname == ""
    call RWarningMsg("The option vimrplugin_by_vim_instance requires a servername. Please read the documentation.")
    sleep 2
  else
    " For screen GVIM and GVIM1 are the same string.
    let sname = substitute(sname, "GVIM$", "GVIM0", "g")
    let b:screensname = "vimrplugin-" . s:userlogin . "-" . sname
  endif
endif

function! ReplaceUnderS()
  let j = col(".")
  let s = getline(".")
  if j > 3 && s[j-3] == "<" && s[j-2] == "-" && s[j-1] == " "
    execute "normal! 3h3xr_"
    return
  endif
  let isString = 0
  let i = 0
  while i < j
    if s[i] == '"'
      if isString == 0
	let isString = 1
      else
	let isString = 0
      endif
    endif
    let i += 1
  endwhile
  if isString == 0
    execute "normal! a <- "
  else
    execute "normal! a_"
  endif
endfunction

" Count braces
function! CountBraces(line)
  let line2 = substitute(a:line, "{", "", "g")
  let line3 = substitute(a:line, "}", "", "g")
  let result = strlen(line3) - strlen(line2)
  return result
endfunction

" Skip empty lines and lines whose first non blank char is '#'
function! GoDown()
  let lastLine = line("$")
  if &filetype == "rnoweb"
    let i = line(".")
    let curline = getline(".")
    let fc = curline[0]
    if fc == '@'
      while i < lastLine && curline !~ "^<<.*$"
        let i = i + 1
        call cursor(i, 1)
        let curline = getline(i)
      endwhile
    endif
  endif
  let i = line(".") + 1
  call cursor(i, 1)
  let curline = substitute(getline("."), '^\s*', "", "")
  let fc = curline[0]
  while i < lastLine && (fc == '#' || strlen(curline) == 0)
    let i = i + 1
    call cursor(i, 1)
    let curline = substitute(getline("."), '^\s*', "", "")
    let fc = curline[0]
  endwhile
endfunction

function! RWriteScreenRC()
  let b:scrfile = $VIMRPLUGIN_TMPDIR . "/" . b:screensname . ".screenrc"
  if g:vimrplugin_nosingler == 1
    let scrtitle = 'hardstatus string "' . expand("%:t") . '"'
  else
    let scrtitle = "hardstatus string R"
  endif
  let scrtxt = ["msgwait 1", "hardstatus lastline", scrtitle,
	\ "caption splitonly", 'caption string "Vim-R-plugin"',
	\ "termcapinfo xterm* 'ti@:te@'", 'vbell off']
  call writefile(scrtxt, b:scrfile)
  let scrrc = "-c " . b:scrfile
  return scrrc
endfunction

" Start R
function! StartR(whatr)
  if a:whatr =~ "vanilla"
    let b:r_args = "--vanilla"
  else
    if a:whatr =~ "custom"
      call inputsave()
      let b:r_args = input('Enter parameters for R: ')
      call inputrestore()
    else
      let b:r_args = g:vimrplugin_r_args
    endif
  endif

  if has("gui_win32")
    call StartRPy()
    return
  endif

  if b:r_args == " "
    let rcmd = b:R
  else
    let rcmd = b:R . " " . b:r_args
  endif

  if g:vimrplugin_screenplugin
    exec 'ScreenShell ' . rcmd
  elseif g:vimrplugin_conqueplugin
    let savesb = &switchbuf
    set switchbuf=useopen,usetab
    if g:vimrplugin_conquevsplit == 1
      let l:sr = &splitright
      set splitright
      " exec 'ConqueTermVSplit ' . rcmd
      let g:conquebuff = conque_term#open(rcmd, ['vsplit'], 0)
      let &splitright = l:sr
    else
      " exec 'ConqueTermSplit ' . rcmd
     let g:conquebuff = conque_term#open(rcmd, ['belowright split'], 0)
    endif
    execute "setlocal syntax=rout"
    exe "sb " . g:rplugin_curbuf
    exe "set switchbuf=" . savesb
  else
    if g:vimrplugin_noscreenrc == 1
      let scrrc = " "
    else
      let scrrc = RWriteScreenRC()
    endif
    " Some terminals want quotes (see screen.vim)
    if b:term_cmd =~ "gnome-terminal" || b:term_cmd =~ "xfce4-terminal" || b:term_cmd =~ "iterm"
      let opencmd = printf("%s 'screen %s -d -RR -S %s %s' &", b:term_cmd, scrrc, b:screensname, rcmd)
    else
      let opencmd = printf("%s screen %s -d -RR -S %s %s &", b:term_cmd, scrrc, b:screensname, rcmd)
    endif
    " Change to buffer's directory, run R, and go back to original directory:
    lcd %:p:h
    let rlog = system(opencmd)
    lcd -
    if v:shell_error
      call RWarningMsg(rlog)
      return
    endif
  endif
  echon
endfunction

" Open an object browser window
function! RObjBrowser()
  " Only opens the object browser if R is running
  if g:vimrplugin_screenplugin && !exists("g:ScreenShellSend")
    return
  endif
  if g:vimrplugin_conqueplugin
    if !exists("g:ConqueTerm_BufName")
      return
    endif
  endif

  " R builds the Object_Browser contents.
  let lockfile = $VIMRPLUGIN_TMPDIR . "/objbrowser" . "lock"
  call writefile(["Wait!"], lockfile)
  call SendCmdToScreen("source('" . b:r_plugin_home . "/r-plugin/vimbrowser.R')", 1)
  sleep 50m
  let i = 0 
  while filereadable(lockfile)
    let i = i + 1
    sleep 50m
    if i == 40
      call delete(lockfile)
      call RWarningMsg("No longer waiting for Object_Browser to finish...")
      if exists("g:rplugin_r_ouput")
	echo g:rplugin_r_ouput
      endif
      sleep 2
      return
    endif
  endwhile

  " Either load or reload the object browser
  let g:rplugin_curbuf = bufname("%")
  let savesb = &switchbuf
  set switchbuf=useopen,usetab
  if bufloaded("Object_Browser")
    exe "sb Object_Browser"
  else
    let l:sr = &splitright
    set splitright
    40vsplit Object_Browser
    let &splitright = l:sr
    set ft=rbrowser
  endif

  let objbr = $VIMRPLUGIN_TMPDIR . "/objbrowser"
  let i = 1
  while !filereadable(objbr)
    sleep 100m
    if i == 20
      return
    endif
  endwhile
  let curline = line(".")
  let curcol = col(".")
  normal! ggdG
  exe "source " . objbr
  call RBrowserFill()
  setlocal nomodified
  call cursor(curline, curcol)
  redraw
  exe "sb " . g:rplugin_curbuf
  exe "set switchbuf=" . savesb
endfunction

function! RObjBrowserClose()
  if bufloaded("Object_Browser")
    bunload Object_Browser
  endif
endfunction

" Scroll conque term buffer (called by CursorHold event)
function! RScrollTerm()
  "call RSetTimer()
  if &ft != "r" && &ft != "rnoweb" && &ft != "rhelp" && &ft != "rdoc"
    return
  endif
  if !exists("g:ConqueTerm_BufName")
    return
  endif

  let savesb = &switchbuf
  set switchbuf=useopen,usetab
  exe "sil noautocmd sb " . g:ConqueTerm_BufName

  normal! G

  exe "sil noautocmd sb " . g:rplugin_curbuf
  exe "set switchbuf=" . savesb
endfunction

" Function to send commands
function! SendCmdToScreen(cmd, quiet)
  if has("gui_win32")
    call SendToRPy(a:cmd . "\n")
    silent exe '!start WScript "' . b:vimjspath . '" "' . expand("%") . '"'
    " call RestoreClipboardPy()
    return 1
  endif
  if g:vimrplugin_screenplugin
    if !exists("g:ScreenShellSend")
      call RWarningMsg("Did you already start R?")
      return 0
    endif
    call g:ScreenShellSend(a:cmd)
    return 1
  elseif g:vimrplugin_conqueplugin
    let g:rplugin_curbuf = bufname("%")

    " Code provided by Nico Raffo
    " use an agressive sb option
    let savesb = &switchbuf
    set switchbuf=useopen,usetab

    " jump to terminal buffer
    exe "sil noautocmd sb " . g:ConqueTerm_BufName

    " write variable content to terminal
    call g:conquebuff.writeln(a:cmd)
    if a:quiet
      let g:rplugin_r_ouput = g:conquebuff.read(100, 0)
    else
      call g:conquebuff.read(100, 1)
    endif

    " jump back to code buffer
    exe "sil noautocmd sb " . g:rplugin_curbuf
    exe "set switchbuf=" . savesb
    return 1
  endif
  let str = substitute(a:cmd, "'", "'\\\\''", "g")
  let scmd = 'screen -S ' . b:screensname . " -X stuff '" . str . "\<C-M>'"
  let rlog = system(scmd)
  if v:shell_error
    let rlog = substitute(rlog, '\n', ' ', 'g')
    let rlog = substitute(rlog, '\r', ' ', 'g')
    call RWarningMsg(rlog)
    return 0
  endif
  return 1
endfunction

" Quit R
function! RQuit(how)
  if a:how == "save"
    call SendCmdToScreen('quit(save = "yes")', 0)
  else
    call SendCmdToScreen('quit(save = "no")', 0)
  endif
  if g:vimrplugin_screenplugin && exists(':ScreenQuit')
      ScreenQuit
  elseif g:vimrplugin_conqueplugin
    sleep 100m
    let savesb = &switchbuf
    set switchbuf=useopen,usetab

    " jump to terminal buffer
    exe "sil noautocmd sb " . g:ConqueTerm_BufName

    q
    " jump back to code buffer
    exe "sil noautocmd sb " . g:rplugin_curbuf
    exe "set switchbuf=" . savesb
  endif
  echon
endfunction

" Get the word either under or after the cursor.
" Works for word(| where | is the cursor position.
function! RGetKeyWord()
  " Go back some columns if character under cursor is not valid
  let save_cursor = getpos(".")
  let curline = line(".")
  let line = getline(curline)
  " line index starts in 0; cursor index starts in 1:
  let i = col(".") - 1
  while i > 0 && "({[ " =~ line[i]
    call setpos(".", [0, line("."), i])
    let i -= 1
  endwhile
  let save_keyword = &iskeyword
  setlocal iskeyword=@,48-57,_,.,$
  let rkeyword = expand("<cword>")
  exe "setlocal iskeyword=" . save_keyword
  call setpos(".", save_cursor)
  return rkeyword
endfunction

" Send sources to R
function! RSourceLines(lines, e)
  call writefile(a:lines, b:rsource)
  if a:e == "echo"
    if exists("g:vimrplugin_maxdeparse")
      let rcmd = 'source("' . b:rsource . '", echo=TRUE, max.deparse=' . g:vimrplugin_maxdeparse . ')'
    else
      let rcmd = 'source("' . b:rsource . '", echo=TRUE)'
    endif
  else
    let rcmd = 'source("' . b:rsource . '")'
  endif
  let ok = SendCmdToScreen(rcmd, 0)
  return ok
endfunction

" Send file to R
function! SendFileToR(e)
  echon
  let b:needsnewomnilist = 1
  let lines = getline("1", line("$"))
  let ok = RSourceLines(lines, a:e)
  if  ok == 0
    return
  endif
endfunction

" Send block to R
" Adapted of the plugin marksbrowser
" Function to get the marks which the cursor is between
function! SendMBlockToR(e, m)
  let b:needsnewomnilist = 1
  let curline = line(".")
  let lineA = -1
  let lineB = line("$") + 1
  let maxmarks = strlen(s:all_marks)
  let n = 0
  while n < maxmarks
    let c = strpart(s:all_marks, n, 1)
    let lnum = line("'" . c)
    if lnum != 0
      if lnum <= curline && lnum > lineA
        let lineA = lnum
      elseif lnum > curline && lnum < lineB
        let lineB = lnum
      endif
    endif
    let n = n + 1
  endwhile
  if lineA == -1 || lineB == (line("$") + 1)
    call RWarningMsg("The cursor is not between two marks!")
    return
  endif
  let lines = getline(lineA, lineB)
  let ok = RSourceLines(lines, a:e)
  if ok == 0
    return
  endif
  if a:m == "down" && lineB != line("$")
    call cursor(lineB, 1)
    call GoDown()
  endif  
  echon
endfunction

" Send functions to R
function! SendFunctionToR(e, m)
  echon
  let b:needsnewomnilist = 1
  let line = getline(".")
  let i = line(".")
  while i > 0 && line !~ "function"
    let i -= 1
    let line = getline(i)
  endwhile
  if i == 0
    return
  endif
  let functionline = i
  while i > 0 && line !~ "<-"
    let i -= 1
    let line = getline(i)
  endwhile
  if i == 0
    return
  endif
  let firstline = i
  let i = functionline
  let line = getline(i)
  let tt = line("$")
  while i < tt && line !~ "{"
    let i += 1
    let line = getline(i)
  endwhile
  if i == tt
    return
  endif
  let nb = CountBraces(line)
  while i < tt && nb > 0
    let i += 1
    let line = getline(i)
    let nb += CountBraces(line)
  endwhile
  if nb != 0
    return
  endif
  let lastline = i
  let lines = getline(firstline, lastline)
  let ok = RSourceLines(lines, a:e)
  if  ok == 0
    return
  endif
  if a:m == "down"
    call cursor(lastline, 1)
    call GoDown()
  endif
  echon
endfunction

" Send selection to R
function! SendSelectionToR(e, m)
  echon
  let b:needsnewomnilist = 1
  if line("'<") == line("'>")
    let i = col("'<") - 1
    let j = col("'>") - i
    let l = getline("'<")
    let line = strpart(l, i, j)
    let ok = SendCmdToScreen(line, 0)
    if ok && a:m =~ "down"
      call GoDown()
    endif
    return
  endif
  let lines = getline("'<", "'>")
  let ok = RSourceLines(lines, a:e)
  if ok == 0
    return
  endif
  if a:m == "down"
    call GoDown()
  else
    normal! gv
  endif
endfunction

" Send paragraph to R
function! SendParagraphToR(e, m)
  let b:needsnewomnilist = 1
  let i = line(".")
  let c = col(".")
  let max = line("$")
  let j = i
  let gotempty = 0
  while j < max
    let j = j + 1
    let line = getline(j)
    if line =~ "^\s*$"
      break
    endif
  endwhile
  let lines = getline(i, j)
  let ok = RSourceLines(lines, a:e)
  if ok == 0
    return
  endif
  if j < max
    call cursor(j, 1)
  else
    call cursor(max, 1)
  endif
  if a:m == "down"
    call GoDown()
  else
    call cursor(i, c)
  endif
  echon
endfunction

" Send current line to R. Don't go down if called by <S-Enter>.
function! SendLineToR(godown)
  echon
  let b:needsnewomnilist = 1
  let line = getline(".")
  if &filetype == "rnoweb" && line =~ "^@$"
    if a:godown =~ "down"
      call GoDown()
    endif
    return
  endif
  let ok = SendCmdToScreen(line, 0)
  if ok && a:godown =~ "down"
    call GoDown()
  endif
endfunction

" Clear the console screen
function! RClearConsole()
  if has("gui_win32")
    call RClearConsolePy()
    silent exe '!start WScript "' . b:vimjspath . '" "' . expand("%") . '"'
  else
    call SendCmdToScreen("", 0)
  endif
endfunction

" Remove all objects
function! RClearAll()
  let ok = SendCmdToScreen("rm(list=ls())", 0)
  sleep 500m
  call RClearConsole()
endfunction

"Set working directory to the path of current buffer
function! RSetWD()
  let wdcmd = 'setwd("' . expand("%:p:h") . '")'
  if has("gui_win32")
    let wdcmd = substitute(wdcmd, "\\", "/", "g")
  endif
  let ok = SendCmdToScreen(wdcmd, 0)
  if ok == 0
    return
  endif
  echon
endfunction

" Sweave the current buffer content
function! RSweave()
  update
  call RSetWD()
  call SendCmdToScreen('Sweave("' . expand("%:t") . '")', 0)
  echon
endfunction

" Sweave and compile the current buffer content
function! RMakePDF()
  update
  call RSetWD()
  if exists("g:vimrplugin_sweaveargs")
    let pdfcmd = ".Sresult <- Sweave('" . expand("%:t") . "', " . g:vimrplugin_sweaveargs . ");"
  else
    let pdfcmd = ".Sresult <- Sweave('" . expand("%:t") . "');"
  endif
  let pdfcmd =  pdfcmd . " if(exists('.Sresult')){system(paste('" . g:vimrplugin_latexcmd . "', .Sresult)); rm(.Sresult)}"
  let ok = SendCmdToScreen(pdfcmd, 0)
  if ok == 0
    return
  endif
  echon
endfunction  

" Tell R to create a list of objects file (/tmp/.R-omnilist-user-time) listing all currently
" available objects in its environment. The file is necessary for omni completion.
function! BuildROmniList(env)
  if a:env =~ "GlobalEnv"
    let rtf = b:globalenvlistfile
    let b:needsnewomnilist = 0
  else
    let rtf = b:libs_omni_filename
  endif
  let omnilistcmd = printf(".vimomnilistfile <- \"%s\"", rtf)
  let ok = SendCmdToScreen(omnilistcmd, 1)
  if ok == 0
    return
  endif
  let lockfile = rtf . ".locked"
  call writefile(["Wait!"], lockfile)
  let omnilistcmd = 'source("' . b:r_plugin_home . '/r-plugin/build_omni_list.R")'
  call SendCmdToScreen(omnilistcmd, 1)
  " Wait while R is writing the list of objects into the file
  sleep 50m
  let i = 0 
  let s = 0
  while filereadable(lockfile)
    let s = s + 1
    if s == 4 && a:env !~ "GlobalEnv"
      let s = 0
      let i = i + 1
      let k = g:vimrplugin_buildwait - i
      let themsg = "\rPlease, wait! [" . i . ":" . k . "]"
      echon themsg
    endif
    sleep 250m
    if i == g:vimrplugin_buildwait
      call delete(lockfile)
      call RWarningMsg("No longer waiting. See  :h vimrplugin_buildwait  for details.")
      return
    endif
  endwhile

  if a:env == "GlobalEnv"
    let g:rplugin_globalenvlines = readfile(b:globalenvlistfile)
  endif
  if i > 2
    echon "\rFinished in " . i . " seconds."
  endif
endfunction

function! RBuildSyntaxFile()
  call BuildROmniList("libraries")
  sleep 1
  let b:flines1 = readfile(b:libs_omni_filename)
  let res = []
  for line in b:flines1
    if line =~ ':function:\|:standardGeneric:'
      let line = substitute(line, ':.*', "", "")
      let line = "syn keyword rFunction " . line
      call add(res, line)
    endif
  endfor
  call writefile(res, b:user_vimfiles . "/r-plugin/functions.vim")
  unlet b:current_syntax
  exe "runtime syntax/r.vim"
endfunction

" Run R CMD BATCH on current file and load the resulting .Rout in a split
" window
function! ShowRout()
  let routfile = expand("%:r") . ".Rout"
  if bufloaded(routfile)
    exe "bunload " . routfile
  endif
  call delete(routfile)
  " if not silent, the user will have to type <Enter>
  silent update
  if has("gui_win32")
    let rcmd = 'Rcmd.exe BATCH "' . expand("%") . '"'
  else
    let rcmd = b:R . " CMD BATCH '" . expand("%") . "'"
  endif
  echo "Please wait for: " . rcmd
  let rlog = system(rcmd)
  if v:shell_error
    call RWarningMsg('Error: "' . rlog . '"')
    sleep 1
  endif
  if filereadable(routfile)
    if g:vimrplugin_routnotab == 1
      exe "split " . routfile
    else
      exe "tabnew " . routfile
    endif
  endif
endfunction

command! RUpdateObjList :call RBuildSyntaxFile()

" For each noremap we need a vnoremap including <Esc> before the :call,
" otherwise vim will call the function as many times as the number of selected
" lines. If we put the <Esc> in the noremap, vim will bell.
" RCreateMaps Args:
"   type : modes to which create maps (normal, visual and insert) and whether
"          the cursor have to go the beginning of the line
"   plug : the <Plug>Name
"   combo: the combination of letter that make the shortcut
"   target: the command or function to be called
function! s:RCreateMaps(type, plug, combo, target)
  if a:type =~ '0'
    let tg = a:target . '<CR>0'
    let il = 'i'
  else
    let tg = a:target . '<CR>'
    let il = 'a'
  endif
  if a:type =~ "n"
    if hasmapto(a:plug, "n")
      exec 'noremap <buffer> ' . a:plug . ' ' . tg
    else
      exec 'noremap <buffer> <LocalLeader>' . a:combo . ' ' . tg
    endif
  endif
  if a:type =~ "v"
    if hasmapto(a:plug, "v")
      exec 'vnoremap <buffer> ' . a:plug . ' <Esc>' . tg
    else
      exec 'vnoremap <buffer> <LocalLeader>' . a:combo . ' <Esc>' . tg
    endif
  endif
  if a:type =~ "i"
    if hasmapto(a:plug, "i")
      exec 'inoremap <buffer> ' . a:plug . ' <Esc>' . tg . il
    else
      exec 'inoremap <buffer> <LocalLeader>' . a:combo . ' <Esc>' . tg . il
    endif
  endif
endfunction

"----------------------------------------------------------------------------
" ***Start/Close***
"----------------------------------------------------------------------------
" Start
"-------------------------------------
call s:RCreateMaps("nvi", '<Plug>RStart',        'rf', ':call StartR("R")')
call s:RCreateMaps("nvi", '<Plug>RVanillaStart', 'rv', ':call StartR("vanilla")')
call s:RCreateMaps("nvi", '<Plug>RCustomStart',  'rc', ':call StartR("custom")')

" Close
"-------------------------------------
call s:RCreateMaps("nvi", '<Plug>RClose',        'rq', ":call RQuit('nosave')")
call s:RCreateMaps("nvi", '<Plug>RSaveClose',    'rw', ":call RQuit('save')")

"----------------------------------------------------------------------------
" ***Send*** (e=echo, d=down, a=all)
"----------------------------------------------------------------------------
" File
"-------------------------------------
call s:RCreateMaps("ni", '<Plug>RSendFile',      'aa', ':call SendFileToR("silent")')
call s:RCreateMaps("ni", '<Plug>RESendFile',     'ae', ':call SendFileToR("echo")')
call s:RCreateMaps("ni", '<Plug>RShowRout',     'ao', ':call ShowRout()')

" Block
"-------------------------------------
call s:RCreateMaps("ni", '<Plug>RSendMBlock',     'bb', ':call SendMBlockToR("silent", "stay")')
call s:RCreateMaps("ni", '<Plug>RESendMBlock',    'be', ':call SendMBlockToR("echo", "stay")')
call s:RCreateMaps("ni", '<Plug>RDSendMBlock',    'bd', ':call SendMBlockToR("silent", "down")')
call s:RCreateMaps("ni", '<Plug>REDSendMBlock',   'ba', ':call SendMBlockToR("echo", "down")')

" Function
"-------------------------------------
call s:RCreateMaps("nvi", '<Plug>RSendFunction',  'ff', ':call SendFunctionToR("silent", "stay")')
call s:RCreateMaps("nvi", '<Plug>RDSendFunction', 'fe', ':call SendFunctionToR("echo", "stay")')
call s:RCreateMaps("nvi", '<Plug>RDSendFunction', 'fd', ':call SendFunctionToR("silent", "down")')
call s:RCreateMaps("nvi", '<Plug>RDSendFunction', 'fa', ':call SendFunctionToR("echo", "down")')

" Selection
"-------------------------------------
call s:RCreateMaps("v0", '<Plug>RSendSelection',   'ss', ':call SendSelectionToR("silent", "stay")')
call s:RCreateMaps("v0", '<Plug>RESendSelection',  'se', ':call SendSelectionToR("echo", "stay")')
call s:RCreateMaps("v0", '<Plug>RDSendSelection',  'sd', ':call SendSelectionToR("silent", "down")')
call s:RCreateMaps("v0", '<Plug>REDSendSelection', 'sa', ':call SendSelectionToR("echo", "down")')

" Paragraph
"-------------------------------------
call s:RCreateMaps("ni", '<Plug>RSendParagraph',   'pp', ':call SendParagraphToR("silent", "stay")')
call s:RCreateMaps("ni", '<Plug>RESendParagraph',  'pe', ':call SendParagraphToR("echo", "stay")')
call s:RCreateMaps("ni", '<Plug>RDSendParagraph',  'pd', ':call SendParagraphToR("silent", "down")')
call s:RCreateMaps("ni", '<Plug>REDSendParagraph', 'pa', ':call SendParagraphToR("echo", "down")')

" *Line*
"-------------------------------------
call s:RCreateMaps("ni0", '<Plug>RSendLine', 'l', ':call SendLineToR("stay")')
call s:RCreateMaps('ni0', '<Plug>RDSendLine', 'd', ':call SendLineToR("down")')

" We can't call RCreateMaps because of the 'o' command at the end of the map:
if hasmapto('<Plug>RSendLAndOpenNewOne', 'i')
  inoremap <buffer> <Plug>RSendLAndOpenNewOne <Esc>:call SendLineToR("stay")<CR>o
else
  inoremap <buffer> <LocalLeader>q <Esc>:call SendLineToR("stay")<CR>o
endif

" For compatibility with Johannes Ranke's plugin
if g:vimrplugin_map_r == 1
  vnoremap <buffer> r <Esc>:call SendSelectionToR("silent", "down")<CR>
endif

"----------------------------------------------------------------------------
" ***Control***
"----------------------------------------------------------------------------
" List space, clear console, clear all
"-------------------------------------
call s:RCreateMaps("nvi", '<Plug>RListSpace',    'rl', ':call SendCmdToScreen("ls()", 0)<CR>:echon')
call s:RCreateMaps("nvi", '<Plug>RClearConsole', 'rr', ':call RClearConsole()')
call s:RCreateMaps("nvi", '<Plug>RClearAll',     'rm', ':call RClearAll()')

" Print, names, structure
"-------------------------------------
call s:RCreateMaps("nvi", '<Plug>RObjectPr',     'rp', ':call rplugin#RAction("print")')
call s:RCreateMaps("nvi", '<Plug>RObjectNames',  'rn', ':call rplugin#RAction("names")')
call s:RCreateMaps("nvi", '<Plug>RObjectStr',    'rt', ':call rplugin#RAction("str")')

" Arguments, example, help
"-------------------------------------
call s:RCreateMaps("nvi", '<Plug>RShowArgs',     'ra', ':call rplugin#RAction("args")')
call s:RCreateMaps("nvi", '<Plug>RShowEx',       're', ':call rplugin#RAction("example")')
call s:RCreateMaps("nvi", '<Plug>RHelp',         'rh', ':call rplugin#RAction("help")')

" Summary, plot, both
"-------------------------------------
call s:RCreateMaps("nvi", '<Plug>RSummary',      'rs', ':call rplugin#RAction("summary")')
call s:RCreateMaps("nvi", '<Plug>RPlot',         'rg', ':call rplugin#RAction("plot")')
call s:RCreateMaps("nvi", '<Plug>RSPlot',        'rb', ':call rplugin#RAction("plot")<CR>:call rplugin#RAction("summary")')

" Set working directory
"-------------------------------------
call s:RCreateMaps("nvi", '<Plug>RSetwd',        'rd', ':call RSetWD()')

" Sweave (cur file)
"-------------------------------------
call s:RCreateMaps("nvi", '<Plug>RSweave',       'sw', ':call RSweave()')
call s:RCreateMaps("nvi", '<Plug>RMakePDF',      'sp', ':call RMakePDF()')

" Build list of objects for omni completion
"-------------------------------------
call s:RCreateMaps("nvi", '<Plug>RUpdateObjBrowser',    'ro', ':call RObjBrowser()')

"----------------------------------------------------------------------------
" ***Debug***
"----------------------------------------------------------------------------
" Start debugging
"-------------------------------------
"call s:RCreateMaps("nvi", '<Plug>RDebug', 'dd', ':call RStartDebug()')

redir => b:ikblist
silent imap
redir END
redir => b:nkblist
silent nmap
redir END
redir => b:vkblist
silent vmap
redir END
let b:iskblist = split(b:ikblist, "\n")
let b:nskblist = split(b:nkblist, "\n")
let b:vskblist = split(b:vkblist, "\n")
let b:imaplist = []
let b:vmaplist = []
let b:nmaplist = []
for i in b:iskblist
  let si = split(i)
  if len(si) == 3 && si[2] =~ "<Plug>R"
      call add(b:imaplist, [si[1], si[2]])
  endif
endfor
for i in b:nskblist
  let si = split(i)
  if len(si) == 3 && si[2] =~ "<Plug>R"
      call add(b:nmaplist, [si[1], si[2]])
  endif
endfor
for i in b:vskblist
  let si = split(i)
  if len(si) == 3 && si[2] =~ "<Plug>R"
      call add(b:vmaplist, [si[1], si[2]])
  endif
endfor
unlet b:ikblist
unlet b:nkblist
unlet b:vkblist
unlet b:iskblist
unlet b:nskblist
unlet b:vskblist
unlet i
unlet si

function! RNMapCmd(plug)
  for [el1, el2] in b:nmaplist
    if el2 == a:plug
      return el1
    endif
  endfor
endfunction

function! RIMapCmd(plug)
  for [el1, el2] in b:imaplist
    if el2 == a:plug
      return el1
    endif
  endfor
endfunction

function! RVMapCmd(plug)
  for [el1, el2] in b:vmaplist
    if el2 == a:plug
      return el1
    endif
  endfor
endfunction

if exists('g:maplocalleader')
  let b:tll = '<Tab>' . g:maplocalleader
else
  let b:tll = '<Tab>\\'
endif

function! s:RCreateMenuItem(type, label, plug, combo, target)
  if a:type =~ '0'
    let tg = a:target . '<CR>0'
    let il = 'i'
  else
    let tg = a:target . '<CR>'
    let il = 'a'
  endif
  if a:type =~ "n"
    if hasmapto(a:plug, "n")
      let boundkey = RNMapCmd(a:plug)
      exec 'nmenu &R.' . a:label . '<Tab>' . boundkey . ' ' . tg
    else
      exec 'nmenu &R.' . a:label . b:tll . a:combo . ' ' . tg
    endif
  endif
  if a:type =~ "v"
    if hasmapto(a:plug, "v")
      let boundkey = RVMapCmd(a:plug)
      exec 'vmenu &R.' . a:label . '<Tab>' . boundkey . ' ' . tg
    else
      exec 'vmenu &R.' . a:label . b:tll . a:combo . ' ' . '<Esc>' . tg
    endif
  endif
  if a:type =~ "i"
    if hasmapto(a:plug, "i")
      let boundkey = RIMapCmd(a:plug)
      exec 'imenu &R.' . a:label . '<Tab>' . boundkey . ' ' . tg
    else
      exec 'imenu &R.' . a:label . b:tll . a:combo . ' ' . '<Esc>' . tg . il
    endif
  endif
endfunction

" Menu R
function! MakeRMenu()
  if g:rplugin_hasmenu == 1
    return
  endif
  " Do not translate "File":
  menutranslate clear

  "----------------------------------------------------------------------------
  " Start/Close
  "----------------------------------------------------------------------------
  call s:RCreateMenuItem("nvi", 'Start/Close.Start\ R\ (default)', '<Plug>RStart', 'rf', ':call StartR("R")')
  call s:RCreateMenuItem("nvi", 'Start/Close.Start\ R\ --vanilla', '<Plug>RVanillaStart', 'rv', ':call StartR("vanilla")')
  call s:RCreateMenuItem("nvi", 'Start/Close.Start\ R\ (custom)', '<Plug>RCustomStart', 'rc', ':call StartR("custom")')
  "-------------------------------
  menu R.Start/Close.-Sep1- <nul>
  call s:RCreateMenuItem("nvi", 'Start/Close.Close\ R\ (no\ save)', '<Plug>RClose', 'rq', ":call SendCmdToScreen('quit(save = \"no\")', 0)")
  call s:RCreateMenuItem("nvi", 'Start/Close.Close\ R\ (save\ workspace)', '<Plug>RSaveClose', 'rw', ":call SendCmdToScreen('quit(save = \"yes\")', 0)")

  "----------------------------------------------------------------------------
  " Send
  "----------------------------------------------------------------------------
  call s:RCreateMenuItem("ni", 'Send.File', '<Plug>RSendFile', 'aa', ':call SendFileToR("silent")')
  call s:RCreateMenuItem("ni", 'Send.File\ (echo)', '<Plug>RESendFile', 'ae', ':call SendFileToR("echo")')
  call s:RCreateMenuItem("ni", 'Send.File\ (open\ \.Rout)', '<Plug>RShowRout', 'ao', ':call ShowRout()')
  "-------------------------------
  menu R.Send.-Sep1- <nul>
  call s:RCreateMenuItem("ni", 'Send.Block\ (cur)', '<Plug>RSendMBlock', 'bb', ':call SendMBlockToR("silent", "stay")')
  call s:RCreateMenuItem("ni", 'Send.Block\ (cur,\ echo)', '<Plug>RESendMBlock', 'be', ':call SendMBlockToR("echo", "stay")')
  call s:RCreateMenuItem("ni", 'Send.Block\ (cur,\ down)', '<Plug>RDSendMBlock', 'bd', ':call SendMBlockToR("silent", "down")')
  call s:RCreateMenuItem("ni", 'Send.Block\ (cur,\ echo\ and\ down)', '<Plug>REDSendMBlock', 'ba', ':call SendMBlockToR("echo", "down")')
  "-------------------------------
  menu R.Send.-Sep2- <nul>
  call s:RCreateMenuItem("ni", 'Send.Function\ (cur)', '<Plug>RSendFunction', 'ff', ':call SendFunctionToR("silent", "stay")')
  call s:RCreateMenuItem("ni", 'Send.Function\ (cur,\ echo)', '<Plug>RESendFunction', 'fe', ':call SendFunctionToR("echo", "stay")')
  call s:RCreateMenuItem("ni", 'Send.Function\ (cur\ and\ down)', '<Plug>RDSendFunction', 'fd', ':call SendFunctionToR("silent", "down")')
  call s:RCreateMenuItem("ni", 'Send.Function\ (cur,\ echo\ and\ down)', '<Plug>REDSendFunction', 'fa', ':call SendFunctionToR("echo", "down")')
  "-------------------------------
  menu R.Send.-Sep3- <nul>
  call s:RCreateMenuItem("v0", 'Send.Selection', '<Plug>RSendSelection', 'ss', ':call SendSelectionToR("silent", "stay")')
  call s:RCreateMenuItem("v0", 'Send.Selection\ (echo)', '<Plug>RESendSelection', 'se', ':call SendSelectionToR("echo", "stay")')
  call s:RCreateMenuItem("v0", 'Send.Selection\ (and\ down)', '<Plug>RDSendSelection', 'sd', ':call SendSelectionToR("silent", "down")')
  call s:RCreateMenuItem("v0", 'Send.Selection\ (echo\ and\ down)', '<Plug>REDSendSelection', 'sa', ':call SendSelectionToR("echo", "down")')
  "-------------------------------
  menu R.Send.-Sep4- <nul>
  call s:RCreateMenuItem("ni", 'Send.Paragraph', '<Plug>RSendParagraph', 'pp', ':call SendParagraphToR("silent", "stay")')
  call s:RCreateMenuItem("ni", 'Send.Paragraph\ (echo)', '<Plug>RESendParagraph', 'pe', ':call SendParagraphToR("echo", "stay")')
  call s:RCreateMenuItem("ni", 'Send.Paragraph\ (and\ down)', '<Plug>RDSendParagraph', 'pd', ':call SendParagraphToR("silent", "down")')
  call s:RCreateMenuItem("ni", 'Send.Paragraph\ (echo\ and\ down)', '<Plug>REDSendParagraph', 'pa', ':call SendParagraphToR("echo", "down")')
  "-------------------------------
  menu R.Send.-Sep5- <nul>
  call s:RCreateMenuItem("ni0", 'Send.Line', '<Plug>RSendLine', 'l', ':call SendLineToR("stay")')
  call s:RCreateMenuItem("ni0", 'Send.Line\ (and\ down)', '<Plug>RDSendLine', 'd', ':call SendLineToR("down")')

  " We can't call RCreateMenuItem because of the 'o' command at the end of the map:
  if hasmapto('<Plug>RSendLAndOpenNewOne')
    imenu R.Send.Line\ (and\ new\ one) <Plug>RSendLAndOpenNewOne <Esc>:call SendLineToR("stay")<CR>o
  else
    exe "imenu R.Send.Line\\ (and\\ new\\ one)" . b:tll . 'q <Esc>:call SendLineToR("stay")<CR>o'
  endif

  "----------------------------------------------------------------------------
  " Control
  "----------------------------------------------------------------------------
  call s:RCreateMenuItem("nvi", 'Control.List\ space', '<Plug>RListSpace', 'rl', ':call SendCmdToScreen("ls()", 0)')
  call s:RCreateMenuItem("nvi", 'Control.Clear\ console\ screen', '<Plug>RClearConsole', 'rr', ':call RClearConsole()')
  call s:RCreateMenuItem("nvi", 'Control.Clear\ all', '<Plug>RClearAll', 'rm', ':call RClearAll()')
  "-------------------------------
  menu R.Control.-Sep1- <nul>
  call s:RCreateMenuItem("nvi", 'Control.Object\ (print)', '<Plug>RObjectPr', 'rp', ':call rplugin#RAction("print")')
  call s:RCreateMenuItem("nvi", 'Control.Object\ (names)', '<Plug>RObjectNames', 'rn', ':call rplugin#RAction("names")')
  call s:RCreateMenuItem("nvi", 'Control.Object\ (str)', '<Plug>RObjectStr', 'rt', ':call rplugin#RAction("str")')
  "-------------------------------
  menu R.Control.-Sep2- <nul>
  call s:RCreateMenuItem("nvi", 'Control.Arguments\ (cur)', '<Plug>RShowArgs', 'ra', ':call rplugin#RAction("args")')
  call s:RCreateMenuItem("nvi", 'Control.Example\ (cur)', '<Plug>RShowEx', 're', ':call rplugin#RAction("example")')
  call s:RCreateMenuItem("nvi", 'Control.Help\ (cur)', '<Plug>RHelp', 'rh', ':call rplugin#RAction("help")')
  "-------------------------------
  menu R.Control.-Sep3- <nul>
  call s:RCreateMenuItem("nvi", 'Control.Summary\ (cur)', '<Plug>RSummary', 'rs', ':call rplugin#RAction("summary")')
  call s:RCreateMenuItem("nvi", 'Control.Plot\ (cur)', '<Plug>RPlot', 'rg', ':call rplugin#RAction("plot")')
  call s:RCreateMenuItem("nvi", 'Control.Plot\ and\ summary\ (cur)', '<Plug>RSPlot', 'rb', ':call rplugin#RAction("plot")<CR>:call rplugin#RAction("summary")')
  "-------------------------------
  menu R.Control.-Sep4- <nul>
  call s:RCreateMenuItem("nvi", 'Control.Set\ working\ directory\ (cur\ file\ path)', '<Plug>RSetwd', 'rd', ':call RSetWD()')
  "-------------------------------
  menu R.Control.-Sep5- <nul>
  call s:RCreateMenuItem("nvi", 'Control.Sweave\ (cur\ file)', '<Plug>RSweave', 'sw', ':call RSweave()')
  call s:RCreateMenuItem("nvi", 'Control.Sweave\ and\ PDF\ (cur\ file)', '<Plug>RMakePDF', 'sp', ':call RMakePDF()')
  "-------------------------------
  menu R.Control.-Sep6- <nul>
  call s:RCreateMenuItem("nvi", 'Control.Update\ object\ browser', '<Plug>RUpdateObjBrowser', 'ro', ':call RObjBrowser()')
  "-------------------------------
  menu R.-Sep7- <nul>

  "----------------------------------------------------------------------------
  " Help
  "----------------------------------------------------------------------------
  amenu R.r-plugin\ Help :help vim-r-plugin<CR>
  amenu R.R\ Help :call SendCmdToScreen("help.start()", 0)<CR>

  "----------------------------------------------------------------------------
  " ToolBar
  "----------------------------------------------------------------------------
  " Buttons
  amenu ToolBar.RStart :call StartR("R")<CR>
  amenu ToolBar.RClose :call SendCmdToScreen('quit(save = "no")', 0)<CR>
  "---------------------------
  amenu ToolBar.RSendFile :call SendFileToR("echo")<CR>
  amenu ToolBar.RSendBlock :call SendMBlockToR("echo", "down")<CR>
  amenu ToolBar.RSendFunction :call SendFunctionToR("echo", "down")<CR>
  vmenu ToolBar.RSendSelection <ESC>:call SendSelectionToR("echo", "down")<CR>
  amenu ToolBar.RSendParagraph <ESC>:call SendParagraphToR("echo", "down")<CR>
  amenu ToolBar.RSendLine :call SendLineToR("down")<CR>
  "---------------------------
  amenu ToolBar.RListSpace :call SendCmdToScreen("ls()", 0)<CR>
  amenu ToolBar.RClear :call RClearConsole()<CR>
  amenu ToolBar.RClearAll :call RClearAll()<CR>

  " Hints
  tmenu ToolBar.RStart Start R (default)
  tmenu ToolBar.RClose Close R (no save)
  tmenu ToolBar.RSendFile Send file (echo)
  tmenu ToolBar.RSendBlock Send block (cur, echo and down)
  tmenu ToolBar.RSendFunction Send function (cur, echo and down)
  tmenu ToolBar.RSendSelection Send selection (cur, echo and down)
  tmenu ToolBar.RSendParagraph Send paragraph (cur, echo and down)
  tmenu ToolBar.RSendLine Send line (cur and down)
  tmenu ToolBar.RListSpace List objects
  tmenu ToolBar.RClear Clear the console screen
  tmenu ToolBar.RClearAll Remove objects from workspace and clear the console screen
  let g:rplugin_hasmenu = 1
endfunction

function! DeleteScreenRC()
  if filereadable(b:scrfile)
    call delete(b:scrfile)
  endif
endfunction

function! UnMakeRMenu()
  call DeleteScreenRC()
  if exists("g:rplugin_hasmenu") && g:rplugin_hasmenu == 0
    return
  endif
  if g:vimrplugin_never_unmake_menu == 1
    return
  endif
  if &previewwindow			" don't do this in the preview window
    return
  endif
  aunmenu R
  aunmenu ToolBar.RClearAll
  aunmenu ToolBar.RClear
  aunmenu ToolBar.RListSpace
  aunmenu ToolBar.RSendLine
  aunmenu ToolBar.RSendSelection
  aunmenu ToolBar.RSendParagraph
  aunmenu ToolBar.RSendFunction
  aunmenu ToolBar.RSendBlock
  aunmenu ToolBar.RSendFile
  aunmenu ToolBar.RClose
  aunmenu ToolBar.RStart
  let g:rplugin_hasmenu = 0
endfunction

" Activate the menu and toolbar buttons if the user sets the file type as 'r':
call MakeRMenu()

augroup VimRPlugin
  au FileType * if &filetype == "r" || &filetype == "rnoweb" || &filetype == "rhelp" | call MakeRMenu() | endif
  au BufEnter * if &filetype == "r" || &filetype == "rnoweb" || &filetype == "rhelp" | call MakeRMenu() | endif
  au BufLeave * if &filetype == "r" || &filetype == "rnoweb" || &filetype == "rhelp" | call UnMakeRMenu() | endif
augroup END

