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
"          José Cláudio Faria
"          
"          Based on previous work by Johannes Ranke
"
" Last Change: Tue Aug 24, 2010  01:25PM
"
" Please see doc/r-plugin.txt for usage details.
"==========================================================================

" Only do this when not yet done for this buffer
if exists("b:did_ftplugin")
  finish
endif

" Don't load another plugin for this buffer
let b:did_ftplugin = 1

let b:replace_us = 1
if exists("g:vimrplugin_underscore")
  if g:vimrplugin_underscore != 0
    let b:replace_us = 0
  endif
endif

function! RWarningMsg(wmsg)
  echohl WarningMsg
  echomsg a:wmsg
  echohl Normal
endfunction

" Set completion with CTRL-X CTRL-O to autoloaded function.
if exists('&ofu')
  setlocal ofu=rcomplete#CompleteR
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

" Replace 'underline' with '<-'
if b:replace_us
  imap <buffer> _ <Esc>:call ReplaceUnderS()<CR>a
endif

" Save r plugin home - necessary to make vim-r-plugin2 work with pathogen
let b:r_plugin_home = expand("<sfile>:h:h")

" Save user_vimfiles
let b:user_vimfiles = split(&runtimepath, ",")[0]


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
if !filereadable(b:user_vimfiles . "/r-plugin/omnilist")
  if filereadable("/usr/share/vim/addons/r-plugin/omnilist")
    let x = readfile("/usr/share/vim/addons/r-plugin/omnilist")
    call writefile(x, b:user_vimfiles . "/r-plugin/omnilist")
  endif
endif

" Keeps the libraries object list in memory to avoid the need of reading the file
" repeatedly:
let b:local_omni_filename = b:user_vimfiles . "/r-plugin/omnilist"
let b:flines1 = readfile(b:local_omni_filename)

if exists("g:vimrplugin_screenplugin") && !has('gui_running')
  let b:usescreenplugin = 1
else
  let b:usescreenplugin = 0
endif

if exists("g:vimrplugin_r_path")
  let b:rpath = g:vimrplugin_r_path
else
  let b:rpath = "R"
endif

" Automatically rebuild the file listing .GlobalEnv objects for omni
" completion if the user press <C-X><C-O> and we know that the file either was
" not created yet or is outdated.
let b:needsnewomnilist = 1

"==========================================================================
" The remaining of the script needs screen which doesn't work on MS Windows
"==========================================================================
if has("gui_win32")
  let b:usescreenplugin = 0
  let b:needsnewomnilist = 0
  finish
endif
"==========================================================================
" This is the end for Windows users.
"==========================================================================


" How much time must wait for R to build the list of objects:
if !exists("g:vimrplugin_buildwait")
  let g:vimrplugin_buildwait = 120
endif

" Control the menu 'R' and the tool bar buttons
if !exists("g:hasrmenu")
  let g:hasrmenu = 0
endif

" Special screenrc file
let b:scrfile = " "

" List of marks that the plugin seeks to find the block to be sent to R
let s:all_marks = "abcdefghijklmnopqrstuvwxyz"

" From changelog.vim
let userlogin = system('whoami')
if v:shell_error
  let userlogin = 'unknown'
else
  let newline = stridx(userlogin, "\n")
  if newline != -1
    let userlogin = strpart(userlogin, 0, newline)
  endif
endif

" Make the R list of objects file name
let b:romnilistfile = "/tmp/.R-omnilist-" . userlogin

" Create an empty file to avoid errors if the users do Ctrl-X Ctrl-O before
" starting R:
call writefile([], b:romnilistfile)

" Make the file name of files to be sourced
let b:bname = expand("%:t")
let b:bname = substitute(b:bname, " ", "",  "g")
let b:rsource = "/tmp/.Rsource-" . userlogin . "-" . getpid() . "-" . b:bname
unlet b:bname

if !executable('screen')
  call RWarningMsg("Please, install 'screen' to run vim-r-plugin")
  sleep 2
  finish
endif

" Choose a terminal (code adapted from screen.vim)
let s:terminals = ['gnome-terminal', 'konsole', 'xfce4-terminal', 'Eterm', 'rxvt', 'aterm', 'xterm' ]
if !exists("g:vimrplugin_term")
  for term in s:terminals
    if executable(term)
      let g:vimrplugin_term = term
      break
    endif
  endfor
endif

if !exists("g:vimrplugin_term") && !exists("g:vimrplugin_term_cmd")
  call RWarningMsg("Please, set the variable 'g:vimrplugin_term_cmd' in your .vimrc.\nRead the plugin documentation for details.")
  sleep 3
  finish
endif

if g:vimrplugin_term == "gnome-terminal" || g:vimrplugin_term == "xfce4-terminal"
  " Cannot set icon: http://bugzilla.gnome.org/show_bug.cgi?id=126081
  let b:term_cmd = g:vimrplugin_term . " --working-directory='" . expand("%:p:h") . "' --title R -e"
endif

if g:vimrplugin_term == "konsole"
  let b:term_cmd = "konsole --workdir '" . expand("%:p:h") . "' --icon ~/.vim/bitmaps/ricon.png -e"
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

if exists("g:vimrplugin_nosingler")
  " Make a random name for the screen session
  let b:screensname = "vimrplugin-" . userlogin . "-" . localtime()
else
  " Make a unique name for the screen session
  let b:screensname = "vimrplugin-" . userlogin
endif

" Make a unique name for the screen process for each Vim instance:
if exists("g:vimrplugin_by_vim_instance")
  let sname = substitute(v:servername, " ", "-", "g")
  if sname == ""
    call RWarningMsg("The option vimrplugin_by_vim_instance requires a servername. Please read the documentation.")
    sleep 2
  else
    " For screen GVIM and GVIM1 are the same string.
    let sname = substitute(sname, "GVIM$", "GVIM0", "g")
    let b:screensname = "vimrplugin-" . userlogin . "-" . sname
  endif
endif

" Count braces
function! CountBraces(line)
  let line2 = substitute(a:line, "{", "", "g")
  let line3 = substitute(a:line, "}", "", "g")
  let result = strlen(line3) - strlen(line2)
  return result
endfunction

" Get first non blank character
function! GetFirstChar(lin)
  let j = 0
  while a:lin[j] == ' '
    let j = j + 1
  endwhile
  return a:lin[j]
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
  let curline = getline(".")
  let fc = GetFirstChar(curline)
  while i < lastLine && (fc == '#' || strlen(curline) == 0)
    let i = i + 1
    call cursor(i, 1)
    let curline = getline(i)
    let fc = GetFirstChar(curline)
  endwhile
endfunction

function! RWriteScreenRC()
  let b:scrfile = "/tmp/." . b:screensname . ".screenrc"
  if exists("g:vimrplugin_nosingler")
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
    let rcmd = b:rpath . " --vanilla"
  else
    if a:whatr =~ "R"
      let rcmd = b:rpath
    else
      if a:whatr =~ "custom"
        call inputsave()
        let rargs = input('Enter parameters for R: ')
        call inputrestore()
        let rcmd = b:rpath . " " . rargs
      endif
    endif
  endif
  if b:usescreenplugin
    exec 'ScreenShell ' . rcmd
  else
    if exists("g:vimrplugin_noscreenrc")
      let scrrc = " "
    else
      let scrrc = RWriteScreenRC()
    endif
    " Some terminals want quotes (see screen.vim)
    if b:term_cmd =~ "gnome-terminal" || b:term_cmd =~ "xfce4-terminal"
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

" Function to send commands
function! SendCmdToScreen(cmd)
  if b:usescreenplugin
    if !exists("g:ScreenShellSend")
      call RWarningMsg("Did you already start R?")
      return 0
    endif
    call g:ScreenShellSend(a:cmd)
    return 1
  end
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
    call SendCmdToScreen('quit(save = "yes")')
  else
    call SendCmdToScreen('quit(save = "no")')
  endif
  if b:usescreenplugin && exists(':ScreenQuit')
      ScreenQuit
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

" Call R functions for the word under cursor
function! RAction(rcmd)
  echon
  let rkeyword = RGetKeyWord()
  if strlen(rkeyword) > 0
    if a:rcmd == "help"
      call SendCmdToScreen("help(" . rkeyword . ")")
      return
    endif
    let rfun = a:rcmd
    if a:rcmd == "args" && exists('g:vimrplugin_listmethods') && g:vimrplugin_listmethods == 1
      let rfun = ".vim.list.args"
    endif
    if a:rcmd == "plot" && exists('g:vimrplugin_specialplot') && g:vimrplugin_specialplot == 1
      let rfun = ".vim.plot"
    endif
    let raction = rfun . "(" . rkeyword . ")"
    let ok = SendCmdToScreen(raction)
    if ok == 0
      return
    endif
  endif
endfunction

" Send sources to R
function! RSourceLines(lines, e)
  call writefile(a:lines, b:rsource)
  if a:e == "echo"
    if exists("g:vimrplugin_maxdeparse")
      let rcmd = "source('" . b:rsource . "', echo=TRUE, max.deparse=" . g:vimrplugin_maxdeparse .")"
    else
      let rcmd = "source('" . b:rsource . "', echo=TRUE)"
    endif
  else
    let rcmd = "source('" . b:rsource . "')"
  endif
  let ok = SendCmdToScreen(rcmd)
  return ok
endfunction

" Send file to R
function! SendFileToR(e)
  echon
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
function! SendParagraphToR(e, m)
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
  let line = getline(".")
  if line =~ "<-"
    let b:needsnewomnilist = 1
  endif
  if &filetype == "rnoweb" && line =~ "^@$"
    if a:godown =~ "down"
      call GoDown()
    endif
    return
  endif
  let ok = SendCmdToScreen(line)
  if ok && a:godown =~ "down"
    call GoDown()
  endif
endfunction

" Clear the console screen
function! RClearAll()
  let ok = SendCmdToScreen("rm(list=ls())")
  sleep 500m
  if ok
    call SendCmdToScreen("")
  endif
endfunction

"Set working directory to the path of current buffer
function! RSetWD()
  let ok = SendCmdToScreen('setwd("' . expand("%:p:h") . '")')
  if ok == 0
    return
  endif
  echon
endfunction

" Sweave the current buffer content
function! RSweave()
  update
  call RSetWD()
  call SendCmdToScreen('Sweave("' . expand("%:t") . '")')
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
  let pdfcmd =  pdfcmd . " if(exists('.Sresult')){"
  if exists("g:vimrplugin_latexcmd")
    let pdfcmd = pdfcmd . "system(paste('" . g:vimrplugin_latexcmd . "', .Sresult));"
  else
    let pdfcmd = pdfcmd . "system(paste('pdflatex', .Sresult));"
  endif
  let pdfcmd = pdfcmd . " rm(.Sresult)}"
  let ok = SendCmdToScreen(pdfcmd)
  if ok == 0
    return
  endif
  echon
endfunction  

" Tell R to create a list of objects file (/tmp/.R-omnilist-user-time) listing all currently
" available objects in its environment. The file is necessary for omni completion.
function! BuildROmniList(env)
  if a:env =~ "GlobalEnv"
    let rtf = b:romnilistfile
    let b:needsnewomnilist = 0
  else
    let rtf = b:local_omni_filename
  endif
  let omnilistcmd = printf(".vimomnilistfile <- \"%s\"", rtf)
  let ok = SendCmdToScreen(omnilistcmd)
  if ok == 0
    return
  endif
  let lockomnilistfile = rtf . ".locked"
  call writefile(["Wait!"], lockomnilistfile)
  let omnilistcmd = "source(\"" . b:r_plugin_home . "/r-plugin/build_omni_list.R\")"
  call SendCmdToScreen(omnilistcmd)
  " Wait while R is writing the list of object into the file
  sleep 70m
  let i = 0 
  let s = 0
  while filereadable(lockomnilistfile)
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
      call delete(lockomnilistfile)
      call RWarningMsg("No longer waiting. See  :h vimrplugin_buildwait  for details.")
      return
    endif
  endwhile
  if i > 2
    echon "\rFinished in " . i . " seconds."
  endif
endfunction

function! RBuildSyntaxFile()
  call BuildROmniList("libraries")
  sleep 1
  let b:flines1 = readfile(b:local_omni_filename)
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
  " if not silent, the user will have to type <Enter>
  silent update
  let rcmd = b:rpath " CMD BATCH '" . expand("%") . "'"
  echo "Please wait for: " . rcmd
  let rlog = system(rcmd)
  if v:shell_error
    call RWarningMsg(rlog)
    return
  endif
  if exists("g:vimrplugin_routnotab") && g:vimrplugin_routnotab == 1
    exe "split " . routfile
  else
    exe "tabnew " . routfile
  endif
endfunction


" Integration with Norm Matloff's edtdbg package.
function! RStartDebug()
  if exists("g:vimrplugin_isdebugging") && g:vimrplugin_isdebugging == 1
    "call SendCmdToScreen("editclose()")
    let g:vimrplugin_isdebugging = 0
  endif
  let fname = RGetKeyWord()
  if strlen(fname) == 0
    call RWarningMsg("No valid name under cursor.")
    return
  endif
  if exists("g:vimrplugin_noscreenrc")
    let scrrc = " "
  else
    let scrrc = RWriteScreenRC()
  endif
  if b:term_cmd =~ "gnome-terminal" || b:term_cmd =~ "xfce4-terminal"
    let opencmd = b:term_cmd . " 'screen " . scrrc . " -d -RR -S VimRdebug " . b:rpath . "' &"
  else
    let opencmd = b:term_cmd . " screen " . scrrc . " -d -RR -S VimRdebug " . b:rpath . " &"
  endif
  let rlog = system(opencmd)
  if v:shell_error
    call RWarningMsg(rlog)
    return
  endif
  call SendCmdToScreen('source("' . b:user_vimfiles . '/r-plugin/Clnt.r")')
  let curline = line(".")
  let scmd = "screen -S VimRdebug -X stuff 'source(\"" . b:user_vimfiles . "/r-plugin/Srvr.r\") ; editsrvr(vimserver=\"" . v:servername . "\") ; quit(\"no\")" . "\<C-M>'"
  sleep 3
  let rlog = system(scmd)
  if v:shell_error
    let rlog = substitute(rlog, '\n', '', 'g')
    call RWarningMsg(rlog)
    return
  endif
  "call SendCmdToScreen('editclnt(firstline=' . curline . ')')
  call SendCmdToScreen('editclnt()')
  call SendCmdToScreen('debug(' . fname . ')')
  " Detach the VimRdebug screen session to run the R server in the background:
"  sleep 1
"  let rlog = system('screen -d -S VimRdebug')
"  if v:shell_error
"    let rlog = substitute(rlog, '\n', '', 'g')
"    call RWarningMsg(rlog)
"    return
"  endif
  let g:vimrplugin_isdebugging = 1
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
if exists("g:vimrplugin_map_r")
  vnoremap <buffer> r <Esc>:call SendSelectionToR("silent", "down")<CR>
endif

"----------------------------------------------------------------------------
" ***Control***
"----------------------------------------------------------------------------
" List space, clear console, clear all
"-------------------------------------
call s:RCreateMaps("nvi", '<Plug>RListSpace',    'rl', ':call SendCmdToScreen("ls()")<CR>:echon')
call s:RCreateMaps("nvi", '<Plug>RClearConsole', 'rr', ':call SendCmdToScreen("")<CR>:echon')
call s:RCreateMaps("nvi", '<Plug>RClearAll',     'rm', ':call RClearAll()')

" Print, names, structure
"-------------------------------------
call s:RCreateMaps("nvi", '<Plug>RObjectPr',     'rp', ':call RAction("print")')
call s:RCreateMaps("nvi", '<Plug>RObjectNames',  'rn', ':call RAction("names")')
call s:RCreateMaps("nvi", '<Plug>RObjectStr',    'rt', ':call RAction("str")')

" Arguments, example, help
"-------------------------------------
call s:RCreateMaps("nvi", '<Plug>RShowArgs',     'ra', ':call RAction("args")')
call s:RCreateMaps("nvi", '<Plug>RShowEx',       're', ':call RAction("example")')
call s:RCreateMaps("nvi", '<Plug>RHelp',         'rh', ':call RAction("help")')

" Summary, plot, both
"-------------------------------------
call s:RCreateMaps("nvi", '<Plug>RSummary',      'rs', ':call RAction("summary")')
call s:RCreateMaps("nvi", '<Plug>RPlot',         'rg', ':call RAction("plot")')
call s:RCreateMaps("nvi", '<Plug>RSPlot',        'rb', ':call RAction("plot")<CR>:call RAction("summary")')

" Set working directory
"-------------------------------------
call s:RCreateMaps("nvi", '<Plug>RSetwd',        'rd', ':call RSetWD()')

" Sweave (cur file)
"-------------------------------------
call s:RCreateMaps("nvi", '<Plug>RSweave',       'sw', ':call RSweave()')
call s:RCreateMaps("nvi", '<Plug>RMakePDF',      'sp', ':call RMakePDF()')

" Build list of objects for omni completion
"-------------------------------------
call s:RCreateMaps("nvi", '<Plug>RBuildOmniList',    'ro', ':call BuildROmniList("GlobalEnv")')

"----------------------------------------------------------------------------
" ***Debug***
"----------------------------------------------------------------------------
" Start debugging
"-------------------------------------
"call s:RCreateMaps("nvi", '<Plug>RDebug', 'dd', ':call RStartDebug()')

redir => b:kblist
silent imap
silent vmap
silent nmap
redir END
let b:kblist2 = split(b:kblist, "\n")
unlet b:kblist
let b:imaplist = []
let b:vmaplist = []
let b:nmaplist = []
for i in b:kblist2
  if i =~ "<Plug>R"
    let si = split(i)
    if len(si) == 3
      if si[0] =~ "v"
	call add(b:vmaplist, si)
      endif
      if si[0] =~ "i"
	call add(b:imaplist, si)
      endif
      if si[0] =~ "n"
	call add(b:nmaplist, si)
      endif
    else
      if len(si) == 2
	call add(b:nmaplist, si)
      endif
    endif
  endif
endfor
unlet b:kblist2

function! RNMapCmd(plug)
  for [el1, el2] in b:nmaplist
    if el2 == a:plug
      return el1
    endif
  endfor
endfunction

function! RIMapCmd(plug)
  for [el1, el2, el3] in b:imaplist
    if el3 == a:plug
      return el2
    endif
  endfor
endfunction

function! RVMapCmd(plug)
  for [el1, el2, el3] in b:vmaplist
    if el3 == a:plug
      return el2
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
  if g:hasrmenu == 1
    return
  endif

  "----------------------------------------------------------------------------
  " Start/Close
  "----------------------------------------------------------------------------
  call s:RCreateMenuItem("nvi", 'Start/Close.Start\ R\ (default)', '<Plug>RStart', 'rf', ':call StartR("R")')
  call s:RCreateMenuItem("nvi", 'Start/Close.Start\ R\ --vanilla', '<Plug>RVanillaStart', 'rv', ':call StartR("vanilla")')
  call s:RCreateMenuItem("nvi", 'Start/Close.Start\ R\ (custom)', '<Plug>RCustomStart', 'rc', ':call StartR("custom")')
  "-------------------------------
  menu R.Start/Close.-Sep1- <nul>
  call s:RCreateMenuItem("nvi", 'Start/Close.Close\ R\ (no\ save)', '<Plug>RClose', 'rq', ":call SendCmdToScreen('quit(save = \"no\")')")
  call s:RCreateMenuItem("nvi", 'Start/Close.Close\ R\ (save\ workspace)', '<Plug>RSaveClose', 'rw', ":call SendCmdToScreen('quit(save = \"yes\")')")

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
  call s:RCreateMenuItem("nvi", 'Control.List\ space', '<Plug>RListSpace', 'rl', ':call SendCmdToScreen("ls()")')
  call s:RCreateMenuItem("nvi", 'Control.Clear\ console\ screen', '<Plug>RClearConsole', 'rr', ':call SendCmdToScreen("")')
  call s:RCreateMenuItem("nvi", 'Control.Clear\ all', '<Plug>RClearAll', 'rm', ':call RClearAll()')
  "-------------------------------
  menu R.Control.-Sep1- <nul>
  call s:RCreateMenuItem("nvi", 'Control.Object\ (print)', '<Plug>RObjectPr', 'rp', ':call RAction("print")')
  call s:RCreateMenuItem("nvi", 'Control.Object\ (names)', '<Plug>RObjectNames', 'rn', ':call RAction("names")')
  call s:RCreateMenuItem("nvi", 'Control.Object\ (str)', '<Plug>RObjectStr', 'rt', ':call RAction("str")')
  "-------------------------------
  menu R.Control.-Sep2- <nul>
  call s:RCreateMenuItem("nvi", 'Control.Arguments\ (cur)', '<Plug>RShowArgs', 'ra', ':call RAction("args")')
  call s:RCreateMenuItem("nvi", 'Control.Example\ (cur)', '<Plug>RShowEx', 're', ':call RAction("example")')
  call s:RCreateMenuItem("nvi", 'Control.Help\ (cur)', '<Plug>RHelp', 'rh', ':call RAction("help")')
  "-------------------------------
  menu R.Control.-Sep3- <nul>
  call s:RCreateMenuItem("nvi", 'Control.Summary\ (cur)', '<Plug>RSummary', 'rs', ':call RAction("summary")')
  call s:RCreateMenuItem("nvi", 'Control.Plot\ (cur)', '<Plug>RPlot', 'rg', ':call RAction("plot")')
  call s:RCreateMenuItem("nvi", 'Control.Plot\ and\ summary\ (cur)', '<Plug>RSPlot', 'rb', ':call RAction("plot")<CR>:call RAction("summary")')
  "-------------------------------
  menu R.Control.-Sep4- <nul>
  call s:RCreateMenuItem("nvi", 'Control.Set\ working\ directory\ (cur\ file\ path)', '<Plug>RSetwd', 'rd', ':call RSetWD()')
  "-------------------------------
  menu R.Control.-Sep5- <nul>
  call s:RCreateMenuItem("nvi", 'Control.Sweave\ (cur\ file)', '<Plug>RSweave', 'sw', ':call RSweave()')
  call s:RCreateMenuItem("nvi", 'Control.Sweave\ and\ PDF\ (cur\ file)', '<Plug>RMakePDF', 'sp', ':call RMakePDF()')
  "-------------------------------
  menu R.Control.-Sep6- <nul>
  call s:RCreateMenuItem("nvi", 'Control.Rebuild\ list\ of\ objects', '<Plug>RBuildOmniList', 'ro', ':call BuildROmniList("GlobalEnv")')
  "-------------------------------
  menu R.-Sep7- <nul>

  "----------------------------------------------------------------------------
  " Help
  "----------------------------------------------------------------------------
  amenu R.r-plugin\ Help :help vim-r-plugin<CR>
  amenu R.R\ Help :call SendCmdToScreen("help.start()")<CR>

  "----------------------------------------------------------------------------
  " ToolBar
  "----------------------------------------------------------------------------
  " Buttons
  amenu icon=r-start ToolBar.RStart :call StartR("R")<CR>
  amenu icon=r-close ToolBar.RClose :call SendCmdToScreen('quit(save = "no")')<CR>
  "---------------------------
  amenu icon=r-send-file ToolBar.RSendFile :call SendFileToR("echo")<CR>
  amenu icon=r-send-block ToolBar.RSendBlock :call SendMBlockToR("echo", "down")<CR>
  amenu icon=r-send-function ToolBar.RSendFunction :call SendFunctionToR("echo", "down")<CR>
  vmenu icon=r-send-selection ToolBar.RSendSelection <ESC>:call SendSelectionToR("echo", "down")<CR>
  amenu icon=r-send-paragraph ToolBar.RSendParagraph <ESC>:call SendParagraphToR("echo", "down")<CR>
  amenu icon=r-send-line ToolBar.RSendLine :call SendLineToR("down")<CR>
  "---------------------------
  amenu icon=r-control-listspace ToolBar.RListSpace :call SendCmdToScreen("ls()")<CR>
  amenu icon=r-control-clear ToolBar.RClear :call SendCmdToScreen("")<CR>
  amenu icon=r-control-clearall ToolBar.RClearAll :call RClearAll()<CR>

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
  let g:hasrmenu = 1
endfunction

function! DeleteScreenRC()
  if filereadable(b:scrfile)
    call delete(b:scrfile)
  endif
endfunction

function! UnMakeRMenu()
  call DeleteScreenRC()
  if exists("g:hasrmenu") && g:hasrmenu == 0
    return
  endif
  if exists("g:vimrplugin_never_unmake_menu") && g:vimrplugin_never_unmake_menu == 1
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
  let g:hasrmenu = 0
endfunction

" Activate the menu and toolbar buttons if the user sets the file type as 'r':
call MakeRMenu()

augroup VimRPlugin
  au FileType * if &filetype == "r" || &filetype == "rnoweb" || &filetype == "rhelp" | call MakeRMenu() | endif
  au BufEnter * if &filetype == "r" || &filetype == "rnoweb" || &filetype == "rhelp" | call MakeRMenu() | endif
  au BufLeave * if &filetype == "r" || &filetype == "rnoweb" || &filetype == "rhelp" | call UnMakeRMenu() | endif
augroup END

