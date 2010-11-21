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
" Authors: Jakson Alves de Aquino <jalvesaq@gmail.com>
"          Jose Claudio Faria
"          
"          Based on previous work by Johannes Ranke
"
" Last Change: Sat Nov 20, 2010  09:23PM
"
" Purposes of this file: Create all functions and commands and Set the
" value of all global variables  and some buffer variables.for r,
" rnoweb, rhelp, rdoc, and rbrowser files
"
" Why not an autoload script? Because autoload was designed to store
" functions that are only occasionally used. The Vim-R-plugin has
" global variables and functions that are common to five file types
" and most of these functions will be used every time the plugin is
" used.
"==========================================================================


" Do this only once
if exists("g:rplugin_did_global_stuff")
  finish
endif
let g:rplugin_did_global_stuff = 1

"==========================================================================
" Functions that are common to r, rnoweb, rhelp and rdoc
"==========================================================================

function RWarningMsg(wmsg)
  echohl WarningMsg
  echomsg a:wmsg
  echohl Normal
endfunction

" Set default value of some variables:
function RSetDefaultValue(var, val)
  if !exists(a:var)
    exe "let " . a:var . " = " . a:val
  endif
endfunction

function ReplaceUnderS()
  if &filetype == "rnoweb" && RnwIsInRCode() == 0
    let isString = 1
  else
    let j = col(".")
    let s = getline(".")
    if j > 3 && s[j-3] == "<" && s[j-2] == "-" && s[j-1] == " "
      exe "normal! 3h3xr_"
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
  endif
  if isString == 0
    exe "normal! a <- "
  else
    exe "normal! a_"
  endif
endfunction

" Count braces
function CountBraces(line)
  let line2 = substitute(a:line, "{", "", "g")
  let line3 = substitute(a:line, "}", "", "g")
  let result = strlen(line3) - strlen(line2)
  return result
endfunction

function RnwPreviousChunk()
  echon
  let curline = line(".")
  if RnwIsInRCode()
    let i = search("^<<.*$", "bnW")
    if i != 0
      call cursor(i-1, 1)
    endif
  endif

  let i = search("^<<.*$", "bnW")
  if i == 0
    call cursor(curline, 1)
    call RWarningMsg("There is no previous R code chunk to go.")
  else
    call cursor(i+1, 1)
  endif
  return
endfunction

function RnwNextChunk()
  echon
  let i = search("^<<.*$", "nW")
  if i == 0
    call RWarningMsg("There is no next R code chunk to go.")
  else
    call cursor(i+1, 1)
  endif
  return
endfunction

function RnwOldNextChunk()
  let i = line(".")
  let lastLine = line("$")
  let curline = getline(".")
  while i < lastLine && curline !~ "^<<.*$"
    let i = i + 1
    let curline = getline(i)
  endwhile
  if i == lastLine
    call RWarningMsg("There is no next R code chunk to go.")
  else
    call cursor(i, 1)
  endif
endfunction

" Skip empty lines and lines whose first non blank char is '#'
function GoDown()
  if &filetype == "rnoweb"
    let curline = getline(".")
    let fc = curline[0]
    if fc == '@'
      call RnwNextChunk()
    endif
  endif

  let i = line(".") + 1
  call cursor(i, 1)
  let curline = substitute(getline("."), '^\s*', "", "")
  let fc = curline[0]
  let lastLine = line("$")
  while i < lastLine && (fc == '#' || strlen(curline) == 0)
    let i = i + 1
    call cursor(i, 1)
    let curline = substitute(getline("."), '^\s*', "", "")
    let fc = curline[0]
  endwhile
endfunction

function RWriteScreenRC()
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
function StartR(whatr)
  if a:whatr =~ "vanilla"
    let g:rplugin_r_args = "--vanilla"
  else
    if a:whatr =~ "custom"
      call inputsave()
      let g:rplugin_r_args = input('Enter parameters for R: ')
      call inputrestore()
    else
      let g:rplugin_r_args = g:vimrplugin_r_args
    endif
  endif

  if has("gui_win32")
    if g:vimrplugin_conqueplugin == 0
      exe s:py . " StartRPy()"
      return
    else
      let g:rplugin_R = "Rterm.exe"
    endif
  endif

  if g:rplugin_r_args == " "
    let rcmd = g:rplugin_R
  else
    let rcmd = g:rplugin_R . " " . g:rplugin_r_args
  endif

  if g:vimrplugin_screenplugin
    if g:vimrplugin_screenvsplit
      if exists(":ScreenShellVertical") == 2
	exec 'ScreenShellVertical ' . rcmd
      else
	call RWarningMsg("The screen plugin version >= 1.1 is required to split the window vertically.")
	call input("Press <Enter> to continue. ")
	exec 'ScreenShell ' . rcmd
      endif
    else
      exec 'ScreenShell ' . rcmd
    endif
  elseif g:vimrplugin_conqueplugin
    if exists("b:conque_bufname")
      if bufloaded(substitute(b:conque_bufname, "\\", "", "g"))
        call RWarningMsg("This buffer already has a Conque Shell.")
        return
      endif
    endif

    if g:vimrplugin_by_vim_instance == 1 && exists("g:ConqueTerm_BufName") && bufloaded(substitute(g:ConqueTerm_BufName, "\\", "", "g"))
      call RWarningMsg("This Vim instance already has a Conque Shell.")
      return
    endif

    let savesb = &switchbuf
    set switchbuf=useopen,usetab
    if g:vimrplugin_conquevsplit == 1
      let l:sr = &splitright
      set splitright
      let b:conqueshell = conque_term#open(rcmd, ['vsplit'], 1)
      let &splitright = l:sr
    else
     let b:conqueshell = conque_term#open(rcmd, ['belowright split'], 1)
    endif

    if b:conqueshell['idx'] == 1
      let b:objbrtitle = "Object_Browser"
    else
      let b:objbrtitle = "Object_Browser" . b:conqueshell['idx']
    endif
    let b:conque_bufname = g:ConqueTerm_BufName

    " Copy the values of some local variables that will be inherited
    let g:tmp_conqueshell = b:conqueshell
    let g:tmp_conque_bufname = b:conque_bufname
    let g:tmp_objbrtitle = b:objbrtitle

    exe "sil noautocmd sb " . b:conque_bufname

    " Inheritance of some local variables
    let b:conqueshell = g:tmp_conqueshell
    let b:conque_bufname = g:tmp_conque_bufname
    let b:objbrtitle = g:tmp_objbrtitle

    if g:vimrplugin_by_vim_instance == 1
      let g:rplugin_conqueshell = b:conqueshell
      let g:rplugin_conque_bufname = b:conque_bufname
      let g:rplugin_objbrtitle = b:objbrtitle
    endif

    unlet g:tmp_conqueshell
    unlet g:tmp_conque_bufname
    unlet g:tmp_objbrtitle

    exe "setlocal syntax=rout"
    exe "sil noautocmd sb " . g:rplugin_curbuf
    exe "set switchbuf=" . savesb
  else
    if g:vimrplugin_noscreenrc == 1
      let scrrc = " "
    else
      let scrrc = RWriteScreenRC()
    endif
    " Some terminals want quotes (see screen.vim)
    if g:rplugin_termcmd =~ "gnome-terminal" || g:rplugin_termcmd =~ "xfce4-terminal" || g:rplugin_termcmd =~ "iterm"
      let opencmd = printf("%s 'screen %s -d -RR -S %s %s' &", g:rplugin_termcmd, scrrc, b:screensname, rcmd)
    else
      let opencmd = printf("%s screen %s -d -RR -S %s %s &", g:rplugin_termcmd, scrrc, b:screensname, rcmd)
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

" Open an Object Browser window
function RObjBrowser()
  " Only opens the Object Browser if R is running
  if g:vimrplugin_screenplugin && !exists("g:ScreenShellSend")
    return
  endif
  if g:vimrplugin_conqueplugin && !exists("b:conque_bufname")
    return
  endif

  " R builds the Object Browser contents.
  let lockfile = $VIMRPLUGIN_TMPDIR . "/objbrowser" . "lock"
  call writefile(["Wait!"], lockfile)
  if g:vimrplugin_allnames == 1
    call SendCmdToScreen("source('" . g:rplugin_home . "/r-plugin/vimbrowser.R') ; .vim.browser(TRUE)")
  else
    call SendCmdToScreen("source('" . g:rplugin_home . "/r-plugin/vimbrowser.R') ; .vim.browser()")
  endif
  sleep 50m
  let i = 0 
  while filereadable(lockfile)
    let i = i + 1
    sleep 50m
    if i == 40
      call delete(lockfile)
      call RWarningMsg("No longer waiting for Object Browser to finish...")
      if exists("g:rplugin_r_output")
	echo g:rplugin_r_output
      endif
      sleep 2
      return
    endif
  endwhile

  let g:rplugin_origbuf = bufname("%")

  " Either load or reload the Object Browser
  let savesb = &switchbuf
  set switchbuf=useopen,usetab
  if bufloaded(b:objbrtitle)
    exe "sb " . b:objbrtitle
  else
    " Copy the values of some local variables that will be inherited
    let g:tmp_objbrtitle = b:objbrtitle
    let g:tmp_screensname = b:screensname
    let g:tmp_curbufname = bufname("%")

    if g:vimrplugin_conqueplugin == 1
      " Copy the values of some local variables that will be inherited
      let g:tmp_conqueshell = b:conqueshell
      let g:tmp_conque_bufname = b:conque_bufname

      if g:vimrplugin_objbr_place =~ "console"
	exe "sil sb " . b:conque_bufname
	normal! G0
      endif
    endif

    let l:sr = &splitright
    if g:vimrplugin_objbr_place =~ "right"
      set splitright
    else
      set nosplitright
    endif
    exe "vsplit " . b:objbrtitle
    let &splitright = l:sr
    exe "vertical resize " . g:vimrplugin_objbr_w
    set filetype=rbrowser

    " Inheritance of some local variables
    if g:vimrplugin_conqueplugin == 1
      let b:conqueshell = g:tmp_conqueshell
      let b:conque_bufname = g:tmp_conque_bufname
      unlet g:tmp_conqueshell
      unlet g:tmp_conque_bufname
    endif
    let b:screensname = g:tmp_screensname
    let b:objbrtitle = g:tmp_objbrtitle
    let b:rscript_buffer = g:tmp_curbufname
    unlet g:tmp_objbrtitle
    unlet g:tmp_screensname
    unlet g:tmp_curbufname

  endif


  let objbr = $VIMRPLUGIN_TMPDIR . "/objbrowser"
  let i = 1
  while !filereadable(objbr)
    sleep 100m
    if i == 20
      exe "sb " . g:rplugin_origbuf
      exe "set switchbuf=" . savesb
      return
    endif
  endwhile
  setlocal modifiable
  let curline = line(".")
  let curcol = col(".")
  normal! ggdG
  exe "source " . objbr
  if exists("b:libdict")
    unlet b:libdict
  endif
  call RBrowserFill(0)
  setlocal nomodified
  call cursor(curline, curcol)
  redraw
  exe "sb " . g:rplugin_origbuf
  exe "set switchbuf=" . savesb
endfunction

" Scroll conque term buffer (called by CursorHold event)
function RScrollTerm()
  if &ft != "r" && &ft != "rnoweb" && &ft != "rhelp" && &ft != "rdoc"
    return
  endif
  if !exists("b:conque_bufname")
    return
  endif

  let savesb = &switchbuf
  set switchbuf=useopen,usetab
  exe "sil noautocmd sb " . b:conque_bufname

  call b:conqueshell.read(50)
  normal! G0

  exe "sil noautocmd sb " . g:rplugin_curbuf
  exe "set switchbuf=" . savesb
endfunction

" Function to send commands
" return 0 on failure and 1 on success
function SendCmdToScreen(cmd)
  if has("gui_win32") && g:vimrplugin_conqueplugin == 0
    let cmd = a:cmd . "\n"
    let slen = len(cmd)
    let str = ""
    for i in range(0, slen)
      let str = str . printf("\\x%02X", char2nr(cmd[i]))
    endfor
    exe s:py . " SendToRPy(b'" . str . "')"
    silent exe '!start WScript "' . g:rplugin_jspath . '" "' . expand("%") . '"'
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
    if !exists("b:conque_bufname")
      if g:vimrplugin_by_vim_instance
	if exists("g:rplugin_conqueshell")
	  let b:conqueshell = g:rplugin_conqueshell
	  let b:conque_bufname = g:rplugin_conque_bufname
	  let b:objbrtitle = g:rplugin_objbrtitle
	else
	  call RWarningMsg("This buffer does not have a Conque Shell yet.")
	  return 0
	endif
      else
	call RWarningMsg("Did you already start R?")
	return 0
      endif
    endif

    " Is the Conque buffer hidden or deleted?
    if !bufloaded(substitute(b:conque_bufname, "\\", "", "g"))
      call RWarningMsg("Could not find Conque Shell buffer.")
      return 0
    endif
      
    " Code provided by Nico Raffo: use an aggressive sb option
    let savesb = &switchbuf
    set switchbuf=useopen,usetab

    " jump to terminal buffer
    if bufwinnr(substitute(b:conque_bufname, "\\", "", "g")) < 0
      " The buffer either was hidden by the user with the  :q  command or is
      " in another tab
      exe "sil noautocmd belowright split " . b:conque_bufname
    else
      exe "sil noautocmd sb " . b:conque_bufname
    endif

    " write variable content to terminal
    call b:conqueshell.writeln(a:cmd)
    exe "sleep " . g:vimrplugin_conquesleep . "m"
    call b:conqueshell.read(50)
    normal! G0

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

" Get the word either under or after the cursor.
" Works for word(| where | is the cursor position.
function RGetKeyWord()
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
function RSourceLines(lines, e)
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
  let ok = SendCmdToScreen(rcmd)
  return ok
endfunction

" Send file to R
function SendFileToR(e)
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
function SendMBlockToR(e, m)
  if &filetype == "rnoweb" && RnwIsInRCode() == 0
    call RWarningMsg("Not inside a R code chunk.")
    return
  endif
  if &filetype == "rdoc" && search("^Examples:$", "bncW") == 0
    call RWarningMsg('Not in the "Examples" section.')
    return
  endif

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
function SendFunctionToR(e, m)
  echon
  if &filetype == "rnoweb" && RnwIsInRCode() == 0
    call RWarningMsg("Not inside a R code chunk.")
    return
  endif
  if &filetype == "rdoc" && search("^Examples:$", "bncW") == 0
    call RWarningMsg('Not in the "Examples" section.')
    return
  endif

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
function SendSelectionToR(e, m)
  echon
  if &filetype == "rnoweb" && RnwIsInRCode() == 0
    call RWarningMsg("Not inside a R code chunk.")
    return
  endif
  if &filetype == "rdoc" && search("^Examples:$", "bncW") == 0
    call RWarningMsg('Not in the "Examples" section.')
    return
  endif

  let b:needsnewomnilist = 1
  if line("'<") == line("'>")
    let i = col("'<") - 1
    let j = col("'>") - i
    let l = getline("'<")
    let line = strpart(l, i, j)
    let ok = SendCmdToScreen(line)
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
function SendParagraphToR(e, m)
  if &filetype == "rnoweb" && RnwIsInRCode() == 0
    call RWarningMsg("Not inside a R code chunk.")
    return
  endif
  if &filetype == "rdoc" && search("^Examples:$", "bncW") == 0
    call RWarningMsg('Not in the "Examples" section.')
    return
  endif

  let b:needsnewomnilist = 1
  let i = line(".")
  let c = col(".")
  let max = line("$")
  let j = i
  let gotempty = 0
  while j < max
    let j = j + 1
    let line = getline(j)
    if line =~ '^\s*$'
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
function SendLineToR(godown)
  echon
  let line = getline(".")

  if &filetype == "rnoweb"
    if line =~ "^@$"
      if a:godown =~ "down"
	call GoDown()
      endif
      return
    endif
    if RnwIsInRCode() == 0
      call RWarningMsg("Not inside a R code chunk.")
      return
    endif
  endif

  if &filetype == "rdoc" && search("^Examples:$", "bncW") == 0
    call RWarningMsg('Not in the "Examples" section.')
    return
  endif

  let b:needsnewomnilist = 1
  let ok = SendCmdToScreen(line)
  if ok && a:godown =~ "down"
    call GoDown()
  endif
endfunction

" Clear the console screen
function RClearConsole()
  if has("gui_win32") && g:vimrplugin_conqueplugin == 0
    exe s:py . " RClearConsolePy()"
    silent exe '!start WScript "' . g:rplugin_jspath . '" "' . expand("%") . '"'
  else
    call SendCmdToScreen("\014")
  endif
endfunction

" Remove all objects
function RClearAll()
  let ok = SendCmdToScreen("rm(list=ls())")
  sleep 500m
  call RClearConsole()
endfunction

"Set working directory to the path of current buffer
function RSetWD()
  let wdcmd = 'setwd("' . expand("%:p:h") . '")'
  if has("gui_win32")
    let wdcmd = substitute(wdcmd, "\\", "/", "g")
  endif
  let ok = SendCmdToScreen(wdcmd)
  if ok == 0
    return
  endif
  echon
endfunction

" Quit R
function RQuit(how)
  if a:how == "save"
    call SendCmdToScreen('quit(save = "yes")')
  else
    call SendCmdToScreen('quit(save = "no")')
  endif
  if g:vimrplugin_screenplugin && exists(':ScreenQuit')
      ScreenQuit
  elseif g:vimrplugin_conqueplugin
    sleep 200m
    exe "sil bdelete " . b:conque_bufname
    unlet b:conque_bufname
    unlet b:conqueshell
  endif

  if exists("g:rplugin_objbrtitle")
    unlet g:rplugin_objbrtitle
    if exists("g:rplugin_conqueshell")
      unlet g:rplugin_conqueshell
      unlet g:rplugin_conque_bufname
    endif
  endif

  if bufloaded(b:objbrtitle)
    exe "bunload! " . b:objbrtitle
  endif
  echon
endfunction

" Tell R to create a list of objects file listing all currently available
" objects in its environment. The file is necessary for omni completion.
function BuildROmniList(env, what)
  if a:env =~ "GlobalEnv"
    let rtf = g:rplugin_globalenvfname
    let b:needsnewomnilist = 0
  else
    let rtf = g:rplugin_omnifname
  endif
  let lockfile = rtf . ".locked"
  call writefile(["Wait!"], lockfile)
  let omnilistcmd = 'source("' . g:rplugin_home . '/r-plugin/build_omniList.R") ; .vim.bol("' . rtf . '"'
  if a:env == "libraries" && a:what == "installed"
    let omnilistcmd = omnilistcmd . ', what = "installed"'
  endif
  if g:vimrplugin_allnames == 1
    let omnilistcmd = omnilistcmd . ', allnames = TRUE'
  endif
  let omnilistcmd = omnilistcmd . ')'
  let ok = SendCmdToScreen(omnilistcmd)
  if ok == 0
    return
  endif

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
    let g:rplugin_globalenvlines = readfile(g:rplugin_globalenvfname)
  endif
  if i > 2
    echon "\rFinished in " . i . " seconds."
  endif
endfunction

function RBuildSyntaxFile(what)
  call BuildROmniList("libraries", a:what)
  sleep 1
  let g:rplugin_liblist = readfile(g:rplugin_omnifname)
  let res = []
  let nf = 0
  let funlist = ""
  for line in g:rplugin_liblist
    let obj = split(line, ";")
    if obj[2] == "function"
      if obj[0] !~ '[[:punct:]]' || (obj[0] =~ '\.[a-zA-Z]' && obj[0] !~ '[[:punct:]][[:punct:]]')
	let nf += 1
	let funlist = funlist . " " . obj[0]
	if nf == 7
	  let line = "syn keyword rFunction " . funlist
	  call add(res, line)
	  let nf = 0
	  let funlist = ""
	endif
      endif
    endif
  endfor
  if nf > 0
    let line = "syn keyword rFunction " . funlist
    call add(res, line)
  endif
  call writefile(res, g:rplugin_uservimfiles . "/r-plugin/functions.vim")
  if &filetype == "rbrowser"
    let savesb = &switchbuf
    set switchbuf=useopen,usetab
    exe "sb " . b:rscript_buffer
    unlet b:current_syntax
    exe "runtime syntax/r.vim"
    exe "sb " . b:objbrtitle
    exe "set switchbuf=" . savesb
    if g:rplugin_curview == "libraries"
      unlet b:libdict
      call RBrowserShowLibs(0)
    endif
  else
    unlet b:current_syntax
    exe "runtime syntax/r.vim"
  endif
endfunction

function SetRTextWidth()
  if !bufloaded(s:rdoctitle) || g:vimrplugin_newsize == 1
    " Bug fix for Vim < 7.2.318
    if !has("gui_win32")
      let curlang = v:lang
      language C
    endif

    let g:vimrplugin_newsize = 0

    " s:vimpager is used to calculate the width of the R help documentation
    " and to decide whether to obey vimrplugin_vimpager = 'vertical'
    let s:vimpager = g:vimrplugin_vimpager

    let wwidth = winwidth(0)
    if wwidth <= (g:vimrplugin_help_w + g:vimrplugin_editor_w)
      let s:vimpager = "horizontal"
    endif

    if g:vimrplugin_vimpager == "tab" || g:vimrplugin_vimpager == "tabnew"
      let s:vimpager = "horizontal"
    endif

    if s:vimpager != "vertical"
      "Default help_text_width:
      let htwf = (wwidth > 80) ? 88.1 : ((wwidth - 1) / 0.9)
    else
      " Not enough room to split vertically

      let min_e = (g:vimrplugin_editor_w > 80) ? g:vimrplugin_editor_w : 80
      let min_h = (g:vimrplugin_help_w > 73) ? g:vimrplugin_help_w : 73

      if wwidth > (min_e + min_h)
	" The editor window is large enough to be splitted as either >80+73 or
	" the user defined minimum values
	let s:hwidth = min_h
      elseif wwidth > (min_e + g:vimrplugin_help_w)
	" The help window must have less than min_h columns
	let s:hwidth = wwidth - min_e
      else
	" The help window must have the minimum value
	let s:hwidth = g:vimrplugin_help_w
      endif
      let htwf = (s:hwidth - 1) / 0.9
    endif
    let htw = printf("%f", htwf)
    let g:rplugin_htw = substitute(htw, "\\..*", "", "")
    if !has("gui_win32")
      exe "language " . curlang
    endif
  endif
endfunction

" Show R's help doc in Vim's buffer
" (based  on pydoc plugin)
function ShowRDoc(rkeyword)
  if filewritable(g:rplugin_docfile)
    call delete(g:rplugin_docfile)
  endif

  if bufname("%") =~ "Object_Browser"
    let savesb = &switchbuf
    set switchbuf=useopen,usetab
    exe "sb " . b:rscript_buffer
    exe "set switchbuf=" . savesb
  endif

  if g:vimrplugin_vimpager == "tabnew"
    let s:rdoctitle = a:rkeyword . "\\ -\\ help" 
  else
    let s:tnr = tabpagenr()
    if g:vimrplugin_vimpager != "tab" && s:tnr > 1
      let s:rdoctitle = "R_doc" . s:tnr
    else
      let s:rdoctitle = "R_doc"
    endif
    unlet s:tnr
  endif

  call SetRTextWidth()

  call writefile(['Wait...'], g:rplugin_docfile . "lock")
  call SendCmdToScreen("source('" . g:rplugin_home . "/r-plugin/vimhelp.R') ; .vim.help('" . a:rkeyword . "', " . g:rplugin_htw . "L)")
  sleep 50m

  let i = 0
  while filereadable(g:rplugin_docfile . "lock") && i < 40
    sleep 50m
    let i += 1
  endwhile
  if i == 40
    echohl WarningMsg
    echomsg "Waited too much time..."
    echohl Normal
    return
  endif

  " Local variables that must be inherited by the rdoc buffer
  let g:tmp_screensname = b:screensname
  let g:tmp_objbrtitle = b:objbrtitle
  if g:vimrplugin_conqueplugin == 1
    let g:tmp_conqueshell = b:conqueshell
    let g:tmp_conque_bufname = b:conque_bufname
  endif

  if bufloaded(s:rdoctitle)
    let savesb = &switchbuf
    set switchbuf=useopen,usetab
    exe "sb ". s:rdoctitle
    exe "set switchbuf=" . savesb
  else
    if g:vimrplugin_vimpager == "tab" || g:vimrplugin_vimpager == "tabnew"
      exe 'tabnew ' . s:rdoctitle
    elseif s:vimpager == "vertical"
      let l:sr = &splitright
      set splitright
      exe s:hwidth . 'vsplit ' . s:rdoctitle
      let &splitright = l:sr
    elseif s:vimpager == "horizontal"
      exe 'split ' . s:rdoctitle
      if winheight(0) < 20
	resize 20
      endif
    else
      echohl WarningMsg
      echomsg "Invalid vimrplugin_vimpager value: '" . g:vimrplugin_vimpager . "'"
      echohl Normal
      return
    endif
  endif

  set filetype=rdoc
  setlocal modifiable
  let g:rplugin_curbuf = bufname("%")

  " Inheritance of local variables from the script buffer
  let b:objbrtitle = g:tmp_objbrtitle
  let b:screensname = g:tmp_screensname
  unlet g:tmp_objbrtitle
  if g:vimrplugin_conqueplugin == 1
    let b:conqueshell = g:tmp_conqueshell
    let b:conque_bufname = g:tmp_conque_bufname
    unlet g:tmp_conqueshell
    unlet g:tmp_conque_bufname
  endif

  normal! ggdG
  exe "read " . g:rplugin_docfile
  let lnr = line("$")
  for i in range(1, lnr)
    call setline(i, substitute(getline(i), "_\010", "", "g"))
  endfor
  let has_ex = search("^Examples:$")
  if has_ex
    let lnr = line("$") + 1
    call setline(lnr, '###')
  endif
  normal! ggdd
  setlocal nomodified
  setlocal nomodifiable

endfunction

" Call R functions for the word under cursor
function RAction(rcmd)
  echon
  if &filetype == "rbrowser"
    let rkeyword = RBrowserGetName()
  else
    let rkeyword = RGetKeyWord()
  endif
  if strlen(rkeyword) > 0
    if a:rcmd == "help"
      if g:vimrplugin_vimpager != "no"
	call ShowRDoc(rkeyword)
      else
	call SendCmdToScreen("help(" . rkeyword . ")")
      endif
      return
    endif
    let rfun = a:rcmd
    if a:rcmd == "args" && g:vimrplugin_listmethods == 1
      let rfun = "source('" . g:rplugin_home . "/r-plugin/specialfuns.R') ; .vim.list.args"
    endif
    if a:rcmd == "plot" && g:vimrplugin_specialplot == 1
      let rfun = "source('" . g:rplugin_home . "/r-plugin/specialfuns.R') ; .vim.plot"
    endif
    let raction = rfun . "(" . rkeyword . ")"
    let ok = SendCmdToScreen(raction)
    if ok == 0
      return
    endif
  endif
endfunction

if exists('g:maplocalleader')
  let s:tll = '<Tab>' . g:maplocalleader
else
  let s:tll = '<Tab>\\'
endif

redir => s:ikblist
silent imap
redir END
redir => s:nkblist
silent nmap
redir END
redir => s:vkblist
silent vmap
redir END
let s:iskblist = split(s:ikblist, "\n")
let s:nskblist = split(s:nkblist, "\n")
let s:vskblist = split(s:vkblist, "\n")
let s:imaplist = []
let s:vmaplist = []
let s:nmaplist = []
for i in s:iskblist
  let si = split(i)
  if len(si) == 3 && si[2] =~ "<Plug>R"
      call add(s:imaplist, [si[1], si[2]])
  endif
endfor
for i in s:nskblist
  let si = split(i)
  if len(si) == 3 && si[2] =~ "<Plug>R"
      call add(s:nmaplist, [si[1], si[2]])
  endif
endfor
for i in s:vskblist
  let si = split(i)
  if len(si) == 3 && si[2] =~ "<Plug>R"
      call add(s:vmaplist, [si[1], si[2]])
  endif
endfor
unlet s:ikblist
unlet s:nkblist
unlet s:vkblist
unlet s:iskblist
unlet s:nskblist
unlet s:vskblist
unlet i
unlet si

function RNMapCmd(plug)
  for [el1, el2] in s:nmaplist
    if el2 == a:plug
      return el1
    endif
  endfor
endfunction

function RIMapCmd(plug)
  for [el1, el2] in s:imaplist
    if el2 == a:plug
      return el1
    endif
  endfor
endfunction

function RVMapCmd(plug)
  for [el1, el2] in s:vmaplist
    if el2 == a:plug
      return el1
    endif
  endfor
endfunction

function RCreateMenuItem(type, label, plug, combo, target)
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
      exec 'nmenu &R.' . a:label . s:tll . a:combo . ' ' . tg
    endif
  endif
  if a:type =~ "v"
    if hasmapto(a:plug, "v")
      let boundkey = RVMapCmd(a:plug)
      exec 'vmenu &R.' . a:label . '<Tab>' . boundkey . ' ' . tg
    else
      exec 'vmenu &R.' . a:label . s:tll . a:combo . ' ' . '<Esc>' . tg
    endif
  endif
  if a:type =~ "i"
    if hasmapto(a:plug, "i")
      let boundkey = RIMapCmd(a:plug)
      exec 'imenu &R.' . a:label . '<Tab>' . boundkey . ' ' . tg
    else
      exec 'imenu &R.' . a:label . s:tll . a:combo . ' ' . '<Esc>' . tg . il
    endif
  endif
endfunction

function RControlMenu()
  call RCreateMenuItem("nvi", 'Control.List\ space', '<Plug>RListSpace', 'rl', ':call SendCmdToScreen("ls()")')
  call RCreateMenuItem("nvi", 'Control.Clear\ console\ screen', '<Plug>RClearConsole', 'rr', ':call RClearConsole()')
  call RCreateMenuItem("nvi", 'Control.Clear\ all', '<Plug>RClearAll', 'rm', ':call RClearAll()')
  "-------------------------------
  menu R.Control.-Sep1- <nul>
  call RCreateMenuItem("nvi", 'Control.Object\ (print)', '<Plug>RObjectPr', 'rp', ':call RAction("print")')
  call RCreateMenuItem("nvi", 'Control.Object\ (names)', '<Plug>RObjectNames', 'rn', ':call RAction("names")')
  call RCreateMenuItem("nvi", 'Control.Object\ (str)', '<Plug>RObjectStr', 'rt', ':call RAction("str")')
  "-------------------------------
  menu R.Control.-Sep2- <nul>
  call RCreateMenuItem("nvi", 'Control.Arguments\ (cur)', '<Plug>RShowArgs', 'ra', ':call RAction("args")')
  call RCreateMenuItem("nvi", 'Control.Example\ (cur)', '<Plug>RShowEx', 're', ':call RAction("example")')
  call RCreateMenuItem("nvi", 'Control.Help\ (cur)', '<Plug>RHelp', 'rh', ':call RAction("help")')
  "-------------------------------
  menu R.Control.-Sep3- <nul>
  call RCreateMenuItem("nvi", 'Control.Summary\ (cur)', '<Plug>RSummary', 'rs', ':call RAction("summary")')
  call RCreateMenuItem("nvi", 'Control.Plot\ (cur)', '<Plug>RPlot', 'rg', ':call RAction("plot")')
  call RCreateMenuItem("nvi", 'Control.Plot\ and\ summary\ (cur)', '<Plug>RSPlot', 'rb', ':call RAction("plot")<CR>:call RAction("summary")')
  "-------------------------------
  menu R.Control.-Sep4- <nul>
  call RCreateMenuItem("nvi", 'Control.Update\ Object\ Browser', '<Plug>RUpdateObjBrowser', 'ro', ':call RObjBrowser()')
  let g:rplugin_hasmenu = 1
endfunction

function RControlMaps()
  " List space, clear console, clear all
  "-------------------------------------
  call RCreateMaps("nvi", '<Plug>RListSpace',    'rl', ':call SendCmdToScreen("ls()")<CR>:echon')
  call RCreateMaps("nvi", '<Plug>RClearConsole', 'rr', ':call RClearConsole()')
  call RCreateMaps("nvi", '<Plug>RClearAll',     'rm', ':call RClearAll()')

  " Print, names, structure
  "-------------------------------------
  call RCreateMaps("nvi", '<Plug>RObjectPr',     'rp', ':call RAction("print")')
  call RCreateMaps("nvi", '<Plug>RObjectNames',  'rn', ':call RAction("names")')
  call RCreateMaps("nvi", '<Plug>RObjectStr',    'rt', ':call RAction("str")')

  " Arguments, example, help
  "-------------------------------------
  call RCreateMaps("nvi", '<Plug>RShowArgs',     'ra', ':call RAction("args")')
  call RCreateMaps("nvi", '<Plug>RShowEx',       're', ':call RAction("example")')
  call RCreateMaps("nvi", '<Plug>RHelp',         'rh', ':call RAction("help")')

  " Summary, plot, both
  "-------------------------------------
  call RCreateMaps("nvi", '<Plug>RSummary',      'rs', ':call RAction("summary")')
  call RCreateMaps("nvi", '<Plug>RPlot',         'rg', ':call RAction("plot")')
  call RCreateMaps("nvi", '<Plug>RSPlot',        'rb', ':call RAction("plot")<CR>:call RAction("summary")')

  " Build list of objects for omni completion
  "-------------------------------------
  call RCreateMaps("nvi", '<Plug>RUpdateObjBrowser',    'ro', ':call RObjBrowser()')
endfunction


" For each noremap we need a vnoremap including <Esc> before the :call,
" otherwise vim will call the function as many times as the number of selected
" lines. If we put the <Esc> in the noremap, vim will bell.
" RCreateMaps Args:
"   type : modes to which create maps (normal, visual and insert) and whether
"          the cursor have to go the beginning of the line
"   plug : the <Plug>Name
"   combo: the combination of letter that make the shortcut
"   target: the command or function to be called
function RCreateMaps(type, plug, combo, target)
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

function MakeRMenu()
  if g:rplugin_hasmenu == 1 || !has("gui_running")
    return
  endif

  " Do not translate "File":
  menutranslate clear

  "----------------------------------------------------------------------------
  " Start/Close
  "----------------------------------------------------------------------------
  if &filetype != "rdoc"
    call RCreateMenuItem("nvi", 'Start/Close.Start\ R\ (default)', '<Plug>RStart', 'rf', ':call StartR("R")')
    call RCreateMenuItem("nvi", 'Start/Close.Start\ R\ --vanilla', '<Plug>RVanillaStart', 'rv', ':call StartR("vanilla")')
    call RCreateMenuItem("nvi", 'Start/Close.Start\ R\ (custom)', '<Plug>RCustomStart', 'rc', ':call StartR("custom")')
    "-------------------------------
    menu R.Start/Close.-Sep1- <nul>
    call RCreateMenuItem("nvi", 'Start/Close.Close\ R\ (no\ save)', '<Plug>RClose', 'rq', ":call SendCmdToScreen('quit(save = \"no\")')")
    call RCreateMenuItem("nvi", 'Start/Close.Close\ R\ (save\ workspace)', '<Plug>RSaveClose', 'rw', ":call SendCmdToScreen('quit(save = \"yes\")')")
  endif

  "----------------------------------------------------------------------------
  " Send
  "----------------------------------------------------------------------------
  if &filetype == "r" || g:vimrplugin_never_unmake_menu
    call RCreateMenuItem("ni", 'Send.File', '<Plug>RSendFile', 'aa', ':call SendFileToR("silent")')
    call RCreateMenuItem("ni", 'Send.File\ (echo)', '<Plug>RESendFile', 'ae', ':call SendFileToR("echo")')
    call RCreateMenuItem("ni", 'Send.File\ (open\ \.Rout)', '<Plug>RShowRout', 'ao', ':call ShowRout()')
  endif
  "-------------------------------
  menu R.Send.-Sep1- <nul>
  call RCreateMenuItem("ni", 'Send.Block\ (cur)', '<Plug>RSendMBlock', 'bb', ':call SendMBlockToR("silent", "stay")')
  call RCreateMenuItem("ni", 'Send.Block\ (cur,\ echo)', '<Plug>RESendMBlock', 'be', ':call SendMBlockToR("echo", "stay")')
  call RCreateMenuItem("ni", 'Send.Block\ (cur,\ down)', '<Plug>RDSendMBlock', 'bd', ':call SendMBlockToR("silent", "down")')
  call RCreateMenuItem("ni", 'Send.Block\ (cur,\ echo\ and\ down)', '<Plug>REDSendMBlock', 'ba', ':call SendMBlockToR("echo", "down")')
  "-------------------------------
  menu R.Send.-Sep2- <nul>
  call RCreateMenuItem("ni", 'Send.Function\ (cur)', '<Plug>RSendFunction', 'ff', ':call SendFunctionToR("silent", "stay")')
  call RCreateMenuItem("ni", 'Send.Function\ (cur,\ echo)', '<Plug>RESendFunction', 'fe', ':call SendFunctionToR("echo", "stay")')
  call RCreateMenuItem("ni", 'Send.Function\ (cur\ and\ down)', '<Plug>RDSendFunction', 'fd', ':call SendFunctionToR("silent", "down")')
  call RCreateMenuItem("ni", 'Send.Function\ (cur,\ echo\ and\ down)', '<Plug>REDSendFunction', 'fa', ':call SendFunctionToR("echo", "down")')
  "-------------------------------
  menu R.Send.-Sep3- <nul>
  call RCreateMenuItem("v0", 'Send.Selection', '<Plug>RSendSelection', 'ss', ':call SendSelectionToR("silent", "stay")')
  call RCreateMenuItem("v0", 'Send.Selection\ (echo)', '<Plug>RESendSelection', 'se', ':call SendSelectionToR("echo", "stay")')
  call RCreateMenuItem("v0", 'Send.Selection\ (and\ down)', '<Plug>RDSendSelection', 'sd', ':call SendSelectionToR("silent", "down")')
  call RCreateMenuItem("v0", 'Send.Selection\ (echo\ and\ down)', '<Plug>REDSendSelection', 'sa', ':call SendSelectionToR("echo", "down")')
  "-------------------------------
  menu R.Send.-Sep4- <nul>
  call RCreateMenuItem("ni", 'Send.Paragraph', '<Plug>RSendParagraph', 'pp', ':call SendParagraphToR("silent", "stay")')
  call RCreateMenuItem("ni", 'Send.Paragraph\ (echo)', '<Plug>RESendParagraph', 'pe', ':call SendParagraphToR("echo", "stay")')
  call RCreateMenuItem("ni", 'Send.Paragraph\ (and\ down)', '<Plug>RDSendParagraph', 'pd', ':call SendParagraphToR("silent", "down")')
  call RCreateMenuItem("ni", 'Send.Paragraph\ (echo\ and\ down)', '<Plug>REDSendParagraph', 'pa', ':call SendParagraphToR("echo", "down")')
  "-------------------------------
  menu R.Send.-Sep5- <nul>
  call RCreateMenuItem("ni0", 'Send.Line', '<Plug>RSendLine', 'l', ':call SendLineToR("stay")')
  call RCreateMenuItem("ni0", 'Send.Line\ (and\ down)', '<Plug>RDSendLine', 'd', ':call SendLineToR("down")')

  " We can't call RCreateMenuItem because of the 'o' command at the end of the map:
  if hasmapto('<Plug>RSendLAndOpenNewOne')
    imenu R.Send.Line\ (and\ new\ one) <Plug>RSendLAndOpenNewOne <Esc>:call SendLineToR("stay")<CR>o
  else
    if exists('g:maplocalleader')
      exe "imenu R.Send.Line\\ (and\\ new\\ one)<Tab>". g:maplocalleader . 'q <Esc>:call SendLineToR("stay")<CR>o'
    else
      exe 'imenu R.Send.Line\ (and\ new\ one)<Tab>\\q <Esc>:call SendLineToR("stay")<CR>o'
    endif
  endif

  "----------------------------------------------------------------------------
  " Control
  "----------------------------------------------------------------------------
  call RControlMenu()
  "-------------------------------
  menu R.Control.-Sep5- <nul>
  if &filetype != "rdoc"
    call RCreateMenuItem("nvi", 'Control.Set\ working\ directory\ (cur\ file\ path)', '<Plug>RSetwd', 'rd', ':call RSetWD()')
  endif
  if &filetype == "r" || &filetype == "rnoweb" || g:vimrplugin_never_unmake_menu
    nmenu R.Control.Build\ R\ tags\ file<Tab>:RBuildTags :call SendCmdToScreen('rtags(ofile = "TAGS")')<CR>
    imenu R.Control.Build\ R\ tags\ file<Tab>:RBuildTags <Esc>:call SendCmdToScreen('rtags(ofile = "TAGS")')<CR>a
  endif
  nmenu R.Control.Build\ omniList\ (loaded)<Tab>:RUpdateObjList :call RBuildSyntaxFile("loaded")<CR>
  imenu R.Control.Build\ omniList\ (loaded)<Tab>:RUpdateObjList <Esc>:call RBuildSyntaxFile("loaded")<CR>a
  nmenu R.Control.Build\ omniList\ (installed)<Tab>:RUpdateObjListAll :call RBuildSyntaxFile("installed")<CR>
  imenu R.Control.Build\ omniList\ (installed)<Tab>:RUpdateObjListAll <Esc>:call RBuildSyntaxFile("installed")<CR>a
  "-------------------------------
  if &filetype == "rnoweb" || g:vimrplugin_never_unmake_menu
    menu R.Control.-Sep6- <nul>
    call RCreateMenuItem("nvi", 'Control.Sweave\ (cur\ file)', '<Plug>RSweave', 'sw', ':call RSweave()')
    call RCreateMenuItem("nvi", 'Control.Sweave\ and\ PDF\ (cur\ file)', '<Plug>RMakePDF', 'sp', ':call RMakePDF()')
    nmenu R.Control.Go\ to\ next\ R\ chunk<Tab>gn :call RnwNextChunk()<CR>
    nmenu R.Control.Go\ to\ previous\ R\ chunk<Tab>gN :call RnwPreviousChunk()<CR>
  endif
  "-------------------------------
  menu R.-Sep7- <nul>

  "----------------------------------------------------------------------------
  " Help
  "----------------------------------------------------------------------------
  amenu R.r-plugin\ Help.Overview :help r-plugin-overview<CR>
  amenu R.r-plugin\ Help.Main\ features :help r-plugin-features<CR>
  amenu R.r-plugin\ Help.Installation :help r-plugin-installation<CR>
  amenu R.r-plugin\ Help.Use :help r-plugin-use<CR>
  amenu R.r-plugin\ Help.How\ the\ plugin\ works :help r-plugin-functioning<CR>
  amenu R.r-plugin\ Help.Known\ bugs\ and\ workarounds :help r-plugin-known-bugs<CR>

  amenu R.r-plugin\ Help.Options.Underscore\ and\ Rnoweb\ code :help vimrplugin_underscore<CR>
  amenu R.r-plugin\ Help.Options.Object\ Browser :help vimrplugin_objbr_place<CR>
  if !has("gui_win32")
    amenu R.r-plugin\ Help.Options.Terminal\ emulator :help vimrplugin_term<CR>
    amenu R.r-plugin\ Help.Options.Vim\ as\ pager\ for\ R\ help :help vimrplugin_vimpager<CR>
    amenu R.r-plugin\ Help.Options.Number\ of\ R\ processes :help vimrplugin_nosingler<CR>
    amenu R.r-plugin\ Help.Options.Screen\ configuration :help vimrplugin_noscreenrc<CR>
    amenu R.r-plugin\ Help.Options.Screen\ plugin :help vimrplugin_screenplugin<CR>
  endif
  amenu R.r-plugin\ Help.Options.Conque\ Shell\ plugin :help vimrplugin_conqueplugin<CR>
  if has("gui_win32")
    amenu R.r-plugin\ Help.Options.Use\ 32\ bit\ version\ of\ R :help vimrplugin_i386<CR>
    amenu R.r-plugin\ Help.Options.Sleep\ time :help vimrplugin_sleeptime<CR>
  endif
  amenu R.r-plugin\ Help.Options.R\ path :help vimrplugin_r_path<CR>
  amenu R.r-plugin\ Help.Options.Arguments\ to\ R :help vimrplugin_r_args<CR>
  amenu R.r-plugin\ Help.Options.Time\ building\ omniList :help vimrplugin_buildwait<CR>
  amenu R.r-plugin\ Help.Options.Syntax\ highlighting\ of\ \.Rout\ files :help vimrplugin_routmorecolors<CR>
  amenu R.r-plugin\ Help.Options.Automatically\ open\ the\ \.Rout\ file :help vimrplugin_routnotab<CR>
  amenu R.r-plugin\ Help.Options.Special\ R\ functions :help vimrplugin_listmethods<CR>
  amenu R.r-plugin\ Help.Options.maxdeparse :help vimrplugin_maxdeparse<CR>
  amenu R.r-plugin\ Help.Options.LaTeX\ command :help vimrplugin_latexcmd<CR>
  amenu R.r-plugin\ Help.Options.Never\ unmake\ the\ R\ menu :help vimrplugin_never_unmake_menu<CR>

  amenu R.r-plugin\ Help.Custom\ key\ bindings :help r-plugin-key-bindings<CR>
  amenu R.r-plugin\ Help.Files :help r-plugin-files<CR>
  amenu R.r-plugin\ Help.FAQ\ and\ tips :help r-plugin-tips<CR>
  amenu R.r-plugin\ Help.News :help r-plugin-news<CR>

  amenu R.R\ Help :call SendCmdToScreen("help.start()")<CR>

  "----------------------------------------------------------------------------
  " ToolBar
  "----------------------------------------------------------------------------
  " Buttons
  if &filetype != "rdoc"
    amenu ToolBar.RStart :call StartR("R")<CR>
    amenu ToolBar.RClose :call SendCmdToScreen('quit(save = "no")')<CR>
  endif
  "---------------------------
  if &filetype == "r" || g:vimrplugin_never_unmake_menu
    nmenu ToolBar.RSendFile :call SendFileToR("echo")<CR>
    imenu ToolBar.RSendFile <Esc>:call SendFileToR("echo")<CR>
  endif
  nmenu ToolBar.RSendBlock :call SendMBlockToR("echo", "down")<CR>
  imenu ToolBar.RSendBlock <Esc>:call SendMBlockToR("echo", "down")<CR>
  nmenu ToolBar.RSendFunction :call SendFunctionToR("echo", "down")<CR>
  imenu ToolBar.RSendFunction <Esc>:call SendFunctionToR("echo", "down")<CR>
  vmenu ToolBar.RSendSelection <ESC>:call SendSelectionToR("echo", "down")<CR>
  nmenu ToolBar.RSendParagraph :call SendParagraphToR("echo", "down")<CR>
  imenu ToolBar.RSendParagraph <Esc>:call SendParagraphToR("echo", "down")<CR>
  nmenu ToolBar.RSendLine :call SendLineToR("down")<CR>
  imenu ToolBar.RSendLine <Esc>:call SendLineToR("down")<CR>
  "---------------------------
  nmenu ToolBar.RListSpace :call SendCmdToScreen("ls()")<CR>
  imenu ToolBar.RListSpace <Esc>:call SendCmdToScreen("ls()")<CR>
  nmenu ToolBar.RClear :call RClearConsole()<CR>
  imenu ToolBar.RClear <Esc>:call RClearConsole()<CR>
  nmenu ToolBar.RClearAll :call RClearAll()<CR>
  imenu ToolBar.RClearAll <Esc>:call RClearAll()<CR>

  " Hints
  if &filetype != "rdoc"
    tmenu ToolBar.RStart Start R (default)
    tmenu ToolBar.RClose Close R (no save)
  endif
  if &filetype == "r" || g:vimrplugin_never_unmake_menu
    tmenu ToolBar.RSendFile Send file (echo)
  endif
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

function UnMakeRMenu()
  if !has("gui_running") || g:rplugin_hasmenu == 0 || g:vimrplugin_never_unmake_menu == 1 || &previewwindow
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
  if &filetype == "r"
    aunmenu ToolBar.RSendFile
  endif
  if &filetype != "rdoc"
    aunmenu ToolBar.RClose
    aunmenu ToolBar.RStart
  endif
  let g:rplugin_hasmenu = 0
endfunction


function ROpenGraphicsDevice()
  call SendCmdToScreen('x11(title = "Vim-R-plugin Graphics", width = 3.5, height = 3.5, pointsize = 9, xpos = -1, ypos = 0)')
  let savesb = &switchbuf
  set switchbuf=useopen,usetab
  let l:sr = &splitright
  set splitright
  37vsplit Space_for_Graphics
  set nomodifiable
  setlocal noswapfile
  set buftype=nofile
  set nowrap
  set winfixwidth
  exe "sb " . g:rplugin_curbuf
  let &splitright = l:sr
  exe "set switchbuf=" . savesb
endfunction

function RCreateStartMaps()
  " Start
  "-------------------------------------
  call RCreateMaps("nvi", '<Plug>RStart',        'rf', ':call StartR("R")')
  call RCreateMaps("nvi", '<Plug>RVanillaStart', 'rv', ':call StartR("vanilla")')
  call RCreateMaps("nvi", '<Plug>RCustomStart',  'rc', ':call StartR("custom")')

  " Close
  "-------------------------------------
  call RCreateMaps("nvi", '<Plug>RClose',        'rq', ":call RQuit('nosave')")
  call RCreateMaps("nvi", '<Plug>RSaveClose',    'rw', ":call RQuit('save')")
endfunction

function RCreateSendMaps()
  " Block
  "-------------------------------------
  call RCreateMaps("ni", '<Plug>RSendMBlock',     'bb', ':call SendMBlockToR("silent", "stay")')
  call RCreateMaps("ni", '<Plug>RESendMBlock',    'be', ':call SendMBlockToR("echo", "stay")')
  call RCreateMaps("ni", '<Plug>RDSendMBlock',    'bd', ':call SendMBlockToR("silent", "down")')
  call RCreateMaps("ni", '<Plug>REDSendMBlock',   'ba', ':call SendMBlockToR("echo", "down")')

  " Function
  "-------------------------------------
  call RCreateMaps("nvi", '<Plug>RSendFunction',  'ff', ':call SendFunctionToR("silent", "stay")')
  call RCreateMaps("nvi", '<Plug>RDSendFunction', 'fe', ':call SendFunctionToR("echo", "stay")')
  call RCreateMaps("nvi", '<Plug>RDSendFunction', 'fd', ':call SendFunctionToR("silent", "down")')
  call RCreateMaps("nvi", '<Plug>RDSendFunction', 'fa', ':call SendFunctionToR("echo", "down")')

  " Selection
  "-------------------------------------
  call RCreateMaps("v0", '<Plug>RSendSelection',   'ss', ':call SendSelectionToR("silent", "stay")')
  call RCreateMaps("v0", '<Plug>RESendSelection',  'se', ':call SendSelectionToR("echo", "stay")')
  call RCreateMaps("v0", '<Plug>RDSendSelection',  'sd', ':call SendSelectionToR("silent", "down")')
  call RCreateMaps("v0", '<Plug>REDSendSelection', 'sa', ':call SendSelectionToR("echo", "down")')

  " Paragraph
  "-------------------------------------
  call RCreateMaps("ni", '<Plug>RSendParagraph',   'pp', ':call SendParagraphToR("silent", "stay")')
  call RCreateMaps("ni", '<Plug>RESendParagraph',  'pe', ':call SendParagraphToR("echo", "stay")')
  call RCreateMaps("ni", '<Plug>RDSendParagraph',  'pd', ':call SendParagraphToR("silent", "down")')
  call RCreateMaps("ni", '<Plug>REDSendParagraph', 'pa', ':call SendParagraphToR("echo", "down")')

  " *Line*
  "-------------------------------------
  call RCreateMaps("ni0", '<Plug>RSendLine', 'l', ':call SendLineToR("stay")')
  call RCreateMaps('ni0', '<Plug>RDSendLine', 'd', ':call SendLineToR("down")')

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
endfunction

function RBufEnter()
  call MakeRMenu()
  let g:rplugin_curbuf = bufname("%")
endfunction

function RBufLeave()
  call UnMakeRMenu()
endfunction

command RUpdateObjList :call RBuildSyntaxFile("loaded")
command RUpdateObjListAll :call RBuildSyntaxFile("installed")
command RBuildTags :call SendCmdToScreen('rtags(ofile = "TAGS")')

"==========================================================================
" Global variables
" Convention: vimrplugin_ for user options
"             rplugin_    for internal parameters
"==========================================================================

" Variables whose default value is fixed
call RSetDefaultValue("g:vimrplugin_map_r",             0)
call RSetDefaultValue("g:vimrplugin_open_df",           1)
call RSetDefaultValue("g:vimrplugin_open_list",         0)
call RSetDefaultValue("g:vimrplugin_allnames",          0)
call RSetDefaultValue("g:vimrplugin_underscore",        1)
call RSetDefaultValue("g:vimrplugin_rnowebchunk",       1)
call RSetDefaultValue("g:vimrplugin_screenvsplit",      0)
call RSetDefaultValue("g:vimrplugin_conquevsplit",      0)
call RSetDefaultValue("g:vimrplugin_listmethods",       0)
call RSetDefaultValue("g:vimrplugin_specialplot",       0)
call RSetDefaultValue("g:vimrplugin_nosingler",         0)
call RSetDefaultValue("g:vimrplugin_noscreenrc",        0)
call RSetDefaultValue("g:vimrplugin_routnotab",         0) 
call RSetDefaultValue("g:vimrplugin_editor_w",         66)
call RSetDefaultValue("g:vimrplugin_help_w",           46)
call RSetDefaultValue("g:vimrplugin_objbr_w",          40)
call RSetDefaultValue("g:vimrplugin_buildwait",       120)
call RSetDefaultValue("g:vimrplugin_by_vim_instance",   0)
call RSetDefaultValue("g:vimrplugin_never_unmake_menu", 0)
call RSetDefaultValue("g:vimrplugin_vimpager",       "'vertical'")
call RSetDefaultValue("g:vimrplugin_latexcmd", "'pdflatex'")
call RSetDefaultValue("g:vimrplugin_objbr_place", "'console,right'")

if has("gui_win32")
  call RSetDefaultValue("g:vimrplugin_conquesleep",     200)
else
  call RSetDefaultValue("g:vimrplugin_conquesleep",     100)
endif

" g:rplugin_home should be the directory where the r-plugin files are.  For
" users following the installation instructions it will be at ~/.vim or
" ~/vimfiles, that is, the same value of g:rplugin_uservimfiles. However the
" variables will have different values if the plugin is installed somewhere
" else in the runtimepath.
let g:rplugin_home = expand("<sfile>:h:h")

" g:rplugin_uservimfiles must be a writable directory. It will be g:rplugin_home
" unless it's not writable. Then it wil be ~/.vim or ~/vimfiles.
if filewritable(g:rplugin_home) == 2
  let g:rplugin_uservimfiles = g:rplugin_home
else
  let g:rplugin_uservimfiles = split(&runtimepath, ",")[0]
endif

" Start with an empty list of objects in the workspace
let g:rplugin_globalenvlines = []

" From changelog.vim, with bug fixed by "Si" ("i5ivem")
" Windows logins can include domain, e.g: 'DOMAIN\Username', need to remove
" the backslash from this as otherwise cause file path problems.
let g:rplugin_userlogin = substitute(system('whoami'), "\\", "-", "")

if v:shell_error
  let g:rplugin_userlogin = 'unknown'
else
  let newuline = stridx(g:rplugin_userlogin, "\n")
  if newuline != -1
    let g:rplugin_userlogin = strpart(g:rplugin_userlogin, 0, newuline)
  endif
  unlet newuline
endif

if has("gui_win32")
  " python has priority over python3, unless ConqueTerm_PyVersion == 3
  if has("python")
    let s:py = "py"
  else
    if has("python3")
      let s:py = "py3"
    else
      let s:py = ""
    endif
  endif
  if has("python3") && exists("g:ConqueTerm_PyVersion") && g:ConqueTerm_PyVersion == 3
    let s:py = "py3"
  endif

  if s:py == ""
    call RWarningMsg("Python interface must be enabled to run Vim-R-Plugin.")
    call RWarningMsg("Please do  ':h r-plugin-installation'  for details.")
    call input("Press <Enter> to continue. ")
    let g:rplugin_failed = 1
    finish
  endif
  exe s:py . "file " . substitute(g:rplugin_home, " ", '\ ', "g") . '\r-plugin\windows.py' 
  let g:rplugin_jspath = g:rplugin_home . "\\r-plugin\\vimActivate.js"
  let g:rplugin_home = substitute(g:rplugin_home, "\\", "/", "g")
  let g:rplugin_uservimfiles = substitute(g:rplugin_uservimfiles, "\\", "/", "g")
  if !exists("g:rplugin_rpathadded")
    if exists("g:vimrplugin_r_path")
      let $PATH = g:vimrplugin_r_path . ";" . $PATH
      let g:rplugin_Rgui = g:vimrplugin_r_path . "\\Rgui.exe"
    else
      exe s:py . " GetRPathPy()"
      if s:rinstallpath == "Not found"
	call RWarningMsg('Could not find R path in Windows Registry.')
	call input("Press <Enter> to continue. ")
	let g:rplugin_failed = 1
	finish
      endif
      if isdirectory(s:rinstallpath . '\bin\i386')
	if !exists("g:vimrplugin_i386")
	  let g:vimrplugin_i386 = 0
	endif
	if !isdirectory(s:rinstallpath . '\bin\x64')
	  let g:vimrplugin_i386 = 1
	endif
	if g:vimrplugin_i386
	  let $PATH = s:rinstallpath . '\bin\i386;' . $PATH
	  let g:rplugin_Rgui = s:rinstallpath . '\bin\i386\Rgui.exe'
	else
	  let $PATH = s:rinstallpath . '\bin\x64;' . $PATH
	  let g:rplugin_Rgui = s:rinstallpath . '\bin\x64\Rgui.exe'
	endif
      else
	let $PATH = s:rinstallpath . '\bin;' . $PATH
	let g:rplugin_Rgui = s:rinstallpath . '\bin\Rgui.exe'
      endif
      unlet s:rinstallpath
    endif
    let g:rplugin_rpathadded = 1
  endif
  let g:rplugin_R = "Rgui.exe"
  let g:vimrplugin_term_cmd = "none"
  let g:vimrplugin_term = "none"
  let g:vimrplugin_noscreenrc = 1
  if !exists("g:vimrplugin_r_args")
    let g:vimrplugin_r_args = "--sdi"
  endif
  if !exists("g:vimrplugin_sleeptime")
    let g:vimrplugin_sleeptime = 0.02
  endif
else
  if !executable('screen') && !exists("g:ConqueTerm_Version")
    if has("python") || has("python3")
      call RWarningMsg("Please, install either the 'screen' application or the 'Conque Shell' plugin to enable the Vim-R-plugin.")
    else
      call RWarningMsg("Please, install the 'screen' application to enable the Vim-R-plugin.")
    endif
    call input("Press <Enter> to continue. ")
    let g:rplugin_failed = 1
    finish
  endif
  if exists("g:vimrplugin_r_path")
    let g:rplugin_R = g:vimrplugin_r_path . "/R"
  else
    let g:rplugin_R = "R"
  endif
  if !exists("g:vimrplugin_r_args")
    let g:vimrplugin_r_args = " "
  endif
endif

if isdirectory("/tmp")
  let $VIMRPLUGIN_TMPDIR = "/tmp/r-plugin-" . g:rplugin_userlogin
else
  let $VIMRPLUGIN_TMPDIR = g:rplugin_uservimfiles . "/r-plugin"
endif

if !isdirectory($VIMRPLUGIN_TMPDIR)
  call mkdir($VIMRPLUGIN_TMPDIR, "p", 0700)
endif

let g:rplugin_docfile = $VIMRPLUGIN_TMPDIR . "/Rdoc"
let g:rplugin_globalenvfname = $VIMRPLUGIN_TMPDIR . "/GlobalEnvList"

" Use Conque Shell plugin by default... 
if exists("g:ConqueTerm_Loaded") && !exists("g:vimrplugin_conqueplugin")
  if has("python") || has("python3")
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

if !exists("g:vimrplugin_screenplugin")
  if exists("g:ScreenVersion")
    let g:vimrplugin_screenplugin = 1
  else
    let g:vimrplugin_screenplugin = 0
  endif
endif

if !exists("g:ScreenVersion")
  " g:ScreenVersion was introduced in screen plugin 1.3
  if g:vimrplugin_screenplugin == 1
    call RWarningMsg("Vim-R-plugin requires Screen plugin >= 1.3")
    call input("Press <Enter> to continue. ")
  endif
  let g:vimrplugin_screenplugin = 0
endif

" The screen.vim plugin only works on terminal emulators
if !exists("g:vimrplugin_screenplugin") || has('gui_running')
  let g:vimrplugin_screenplugin = 0
endif

" Check again if screen is installed
if !has("gui_win32") && g:vimrplugin_conqueplugin == 0 && g:vimrplugin_screenplugin == 0 && !executable("screen")
  if (has("python") || has("python3")) && !exists("g:ConqueTerm_Version")
    call RWarningMsg("Please, install either the 'screen' application or the 'Conque Shell' plugin to enable the Vim-R-plugin.")
  else
    call RWarningMsg("Please, install the 'screen' application to enable the Vim-R-plugin.")
  endif
  call input("Press <Enter> to continue. ")
  let g:rplugin_failed = 1
  finish
endif

" Are we in a Debian package? Is the plugin being running for the first time?
let g:rplugin_omnifname = g:rplugin_uservimfiles . "/r-plugin/omniList"
if g:rplugin_home != g:rplugin_uservimfiles
  " Create r-plugin directory if it doesn't exist yet:
  if !isdirectory(g:rplugin_uservimfiles . "/r-plugin")
    call mkdir(g:rplugin_uservimfiles . "/r-plugin", "p")
  endif

  " If there is no functions.vim, copy the default one
  if !filereadable(g:rplugin_uservimfiles . "/r-plugin/functions.vim")
    if filereadable("/usr/share/vim/addons/r-plugin/functions.vim")
      let ffile = readfile("/usr/share/vim/addons/r-plugin/functions.vim")
      call writefile(ffile, g:rplugin_uservimfiles . "/r-plugin/functions.vim")
      unlet ffile
    endif
  endif

  " If there is no omniList, copy the default one
  if !filereadable(g:rplugin_omnifname)
    if filereadable("/usr/share/vim/addons/r-plugin/omniList")
      let omnilines = readfile("/usr/share/vim/addons/r-plugin/omniList")
    else
      if filereadable(g:rplugin_home . "/r-plugin/omniList")
	let omnilines = readfile(g:rplugin_home . "/r-plugin/omniList")
      else
	let omnilines = []
      endif
    endif
    call writefile(omnilines, g:rplugin_omnifname)
    unlet omnilines
  endif
endif

" Minimum width for the Object Browser
if g:vimrplugin_objbr_w < 9
 let g:vimrplugin_objbr_w = 9
endif

" Keeps the libraries object list in memory to avoid the need of reading the file
" repeatedly:
let g:rplugin_liblist = readfile(g:rplugin_omnifname)


" Control the menu 'R' and the tool bar buttons
if !exists("g:rplugin_hasmenu")
  let g:rplugin_hasmenu = 0
endif

" List of marks that the plugin seeks to find the block to be sent to R
let s:all_marks = "abcdefghijklmnopqrstuvwxyz"


" Create an empty file to avoid errors if the user do Ctrl-X Ctrl-O before
" starting R:
call writefile([], g:rplugin_globalenvfname)

" Choose a terminal (code adapted from screen.vim)
if has("gui_win32") || g:vimrplugin_conqueplugin == 1
  " No external terminal emulator will be called, so any value is good
  let g:vimrplugin_term = "xterm"
else
  let s:terminals = ['gnome-terminal', 'konsole', 'xfce4-terminal', 'Eterm', 'rxvt', 'aterm', 'xterm']
  if has('mac')
    let s:terminals = ['iTerm', 'Terminal.app'] + s:terminals
  endif
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
  let g:rplugin_failed = 1
  finish
endif

if g:vimrplugin_term == "gnome-terminal" || g:vimrplugin_term == "xfce4-terminal"
  " Cannot set icon: http://bugzilla.gnome.org/show_bug.cgi?id=126081
  let g:rplugin_termcmd = g:vimrplugin_term . " --working-directory='" . expand("%:p:h") . "' --title R -e"
endif

if g:vimrplugin_term == "konsole"
  let g:rplugin_termcmd = "konsole --workdir '" . expand("%:p:h") . "' --icon " . g:rplugin_home . "/bitmaps/ricon.png -e"
endif

if g:vimrplugin_term == "Eterm"
  let g:rplugin_termcmd = "Eterm --icon " . g:rplugin_home . "/bitmaps/ricon.png -e"
endif

if g:vimrplugin_term == "rxvt" || g:vimrplugin_term == "aterm"
  let g:rplugin_termcmd = g:vimrplugin_term . " -e"
endif

if g:vimrplugin_term == "xterm" || g:vimrplugin_term == "uxterm"
  let g:rplugin_termcmd = g:vimrplugin_term . " -xrm '*iconPixmap: " . g:rplugin_home . "/bitmaps/ricon.xbm' -e"
endif

" Override default settings:
if exists("g:vimrplugin_term_cmd")
  let g:rplugin_termcmd = g:vimrplugin_term_cmd
endif

