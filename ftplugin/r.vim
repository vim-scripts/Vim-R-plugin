"==========================================================================
" ftplugin for R files
"
" Authors: Jakson Alves de Aquino <jalvesaq@gmail.com>
"          and
"          José Cláudio Faria <joseclaudio.faria@gmail.com>
"          
"          Based on previous work by Johannes Ranke <jranke@uni-bremen.de>
"
" Last Change: 2009/10/04
"
" Please see doc/r-plugin.txt for usage details.
"==========================================================================

" This plugin does not work on Windows
if has("gui_win32")
  finish
endif

" Only do this when not yet done for this buffer
if exists("b:did_ftplugin")
  finish
endif

" Don't load another plugin for this buffer
let b:did_ftplugin = 1

let b:hasrmenu = 0

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

" Automatically rebuild the 'tags' file for omni completion if the user press
" <C-X><C-O> and we know that the file either was not created yet or is
" outdated.
let b:needsnewtags = 1

" Automatically call R's function help.start() the first time <C-H> is pressed:
let b:needshstart = 0
if exists("g:vimrplugin_hstart")
  if g:vimrplugin_hstart == 1
    let b:needshstart = 1
  endif
endif

if exists("g:vimrplugin_browser_time") == 0
  let g:vimrplugin_browser_time = 4
endif

let b:replace_us = 1
if exists("g:vimrplugin_underscore")
  if g:vimrplugin_underscore != 0
    let b:replace_us = 0
  endif
endif

function! RWarningMsg(wmsg)
  echohl WarningMsg
  echo a:wmsg
  echohl Normal
endfunction

if !executable('screen')
  call RWarningMsg("Please, install 'screen' to run vim-r-plugin")
  sleep 2
  finish
endif

" Special screenrc file
let b:scrfile = " "

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
  let b:term_cmd = g:vimrplugin_term . " --working-directory='" . expand("%:p:h") . "' -e"
endif

if g:vimrplugin_term == "konsole"
  let b:term_cmd = "konsole --workdir '" . expand("%:p:h") . "' --icon ~/.vim/bitmaps/ricon.png -e"
endif

if g:vimrplugin_term == "Eterm"
  let b:term_cmd = "Eterm --icon ~/.vim/bitmaps/ricon.png -e"
endif

if g:vimrplugin_term == "rxvt" || g:vimrplugin_term == "aterm"
  let b:term_cmd = g:vimrplugin_term . " -e"
endif

if g:vimrplugin_term == "xterm" || g:vimrplugin_term == "uxterm"
  let b:term_cmd = g:vimrplugin_term . " -xrm '*iconPixmap: " . expand("~") . "/.vim/bitmaps/ricon.xbm' -e"
endif

" Override default settings:
if exists("g:vimrplugin_term_cmd")
  let b:term_cmd = g:vimrplugin_term_cmd
endif

" Automatically source the script tools/rargs.R the first time <S-F1> is pressed:
let b:needsrargs = 1

" Make the file name of files to be sourced
let b:rsource = printf("/tmp/.Rsource-%s", userlogin)

" Make the R 'tags' file name
let b:rtagsfile = printf("/tmp/.Rtags-%s", userlogin)

if exists("g:vimrplugin_nosingler")
  " Make a random name for the screen session
  let b:screensname = printf("vimrplugin-%s-%s", userlogin, localtime())
else
  " Make a unique name for the screen session
  let b:screensname = printf("vimrplugin-%s", userlogin)
endif

" Set completion with CTRL-X CTRL-O to autoloaded function.
if exists('&ofu')
  setlocal ofu=rcomplete#CompleteR
endif

function! SendCmdToScreen(cmd)
  if a:cmd =~ "library"
    let b:needsnewtags = 1
  endif
  if &filetype == "rnoweb"
    let line = getline(".")
    if line =~ "^@$"
      return 1
    endif
  endif
  let str = substitute(a:cmd, "'", "'\\\\''", "g")
  let scmd = 'screen -S ' . b:screensname . " -X stuff '" . str . "\<C-M>'"
  let rlog = system(scmd)
  if v:shell_error
    let rlog = substitute(rlog, '\n', '', 'g')
    call RWarningMsg(rlog)
    return 0
  endif
  return 1
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

" Send current line to R. Don't go down if called by <S-Enter>.
function! SendLineToR(godown)
  echon
  let line = getline(".")
  let ok = SendCmdToScreen(line)
  if ok && a:godown =~ "down"
    call GoDown()
  endif
endfunction

" Send selected lines.
function! SendSelectionToR(t, e, m)
  echon
  if a:t == "v"
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
  else
    let lines = getline("'a", "'b")
  endif

  let ok = RSourceLines(lines, a:e)
  if ok == 0
    return
  endif
  if a:m == "down"
    call GoDown()
  else
    if a:t == "v"
      normal! gv
    endif
  endif
endfunction

function! CountBraces(line)
  let line2 = substitute(a:line, "{", "", "g")
  let line3 = substitute(a:line, "}", "", "g")
  let result = strlen(line3) - strlen(line2)
  return result
endfunction

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

function! SendFunctionToR(m)
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
  let ok = RSourceLines(lines, "silent")
  if  ok == 0
    return
  endif
  if a:m == "down"
    call cursor(lastline, 1)
    call GoDown()
  endif
  echon
endfunction

function! SendFileToR(e)
  echon
  let lines = getline("1", line("$"))
  let ok = RSourceLines(lines, a:e)
  if  ok == 0
    return
  endif
endfunction

" Call R funtions for the word under cursor
function! RAction(type)
  echon
  " Go back some columns if character under cursor is not valid
  let curline = line(".")
  let line = getline(curline)
  " line index starts in 0; cursor index starts in 1:
  let i = col(".") - 1
  while i > 0 && (line[i] == ' ' || line[i] == '(')
    let i -= 1
  endwhile
  " Go back until the begining of the word:
  let wentback = 0
  while i >= 0 && line[i] != ' ' && line[i] != '(' && line[i] != '[' && line[i] != '{' && line[i] != ','
    let i -= 1
    let wentback = 1
  endwhile
  let llen = strlen(line)
  if wentback == 1
    let i += 1
  endif
  let kstart = i
  while i < llen && line[i] != ' ' && line[i] != '(' && line[i] != '[' && line[i] != '{' && line[i] != ','
    let i += 1
  endwhile
  if (line[i-1] == ' ' || line[i-1] == ')' || line[i-1] == ']' || line[i-1] == '}' || line[i-1] == ',')
    let i -= 1
  endif
  let rkeyword = strpart(line, kstart, i - kstart)
  if strlen(rkeyword) > 0
    if a:type == "help"
      if b:needshstart == 1
        let b:needshstart = 0
        let ok = SendCmdToScreen("help.start()")
        if ok == 0
          return
        endif
        let wt = g:vimrplugin_browser_time
        while wt > 0
          sleep
          let wt -= 1
        endwhile
      endif
      let rhelpcmd = printf("help('%s')", rkeyword)
    elseif a:type == "args"
      let rhelpcmd = printf("args('%s')", rkeyword)
    elseif a:type == "example"
      let rhelpcmd = printf("example('%s')", rkeyword)
    elseif a:type == "summary"
      let rhelpcmd = printf("summary(%s)", rkeyword)
    elseif a:type == "plot"
      let rhelpcmd = printf("plot(%s)", rkeyword)
    elseif a:type == "plot&summary"
      let rhelpcmd = printf("plot(%s); summary(%s)", rkeyword, rkeyword)
    elseif a:type == "print"
      let rhelpcmd = printf("print(%s)", rkeyword)
    elseif a:type == "str"
      let rhelpcmd = printf("str(%s)", rkeyword)
    elseif a:type == "names"
      let rhelpcmd = printf("names(%s)", rkeyword)  
    endif

    let ok = SendCmdToScreen(rhelpcmd)
    if ok == 0
      return
    endif
  endif
endfunction

" Tell R to create a 'tags' file (/tmp/.Rtags-user-time) listing all currently
" available objects in its environment. The file is necessary omni completion.
function! BuildRTags()
  let tagscmd = printf(".vimtagsfile <- \"%s\"", b:rtagsfile)
  let ok = SendCmdToScreen(tagscmd)
  if ok == 0
    return
  endif
  let tagscmd = "source(\"~/.vim/tools/rtags.R\")"
  let b:needsnewtags = 0
  call SendCmdToScreen(tagscmd)
  " Wait while R is writing the tags file
  sleep
  let i = 1
  while 1
    if filereadable(b:rtagsfile)
      " the tags file may not finished yet
      sleep
      break
    endif
    let i += 1
    sleep
    if i == 10
      break
    endif
  endwhile
  echon
endfunction

function! StartR(whatr)
  if a:whatr =~ "vanilla"
    let rcmd = "R --vanilla"
  else
    if a:whatr =~ "R"
      let rcmd = "R"
    else
      if a:whatr =~ "custom"
        call inputsave()
        let rargs = input('Enter parameters for R: ')
        call inputrestore()
        let rcmd = "R " . rargs
      endif
    endif
  endif
  if exists("g:vimrplugin_noscreenrc")
    let scrrc = " "
  else
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

  if !exists("g:vimrplugin_hstart")
    let b:needshstart = 0
  endif
  if exists("g:vimrplugin_hstart")
    if g:vimrplugin_hstart == 1
      let b:needshstart = 1
    else
      let b:needshstart = 0
    endif
  endif
  let b:needsrargs = 1
  echon
endfunction

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

function! RClearAll()
  let ok = SendCmdToScreen("rm(list=ls())")
  sleep 500m
  if ok
    call SendCmdToScreen("")
  endif
endfunction

function! RSetWD()
  let ok = SendCmdToScreen('setwd("' . expand("%:p:h") . '")')
  if ok == 0
    return
  endif
  echon
endfunction

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

function! RSweave()
  update
  call RSetWD()
  call SendCmdToScreen('Sweave("' . expand("%:t") . '")')
  echon
endfunction

" List of marks that the plugin seeks to find the block to be sent to R
let s:all_marks = "abcdefghijklmnopqrstuvwxyz"

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
endfunction

" Replace 'underline' with '<-'
if b:replace_us
  imap <buffer> _ <Esc>:call ReplaceUnderS()<CR>a
endif

" For each noremap we need a vnoremap including <Esc> before the :call,
" otherwise vim will call the function as many times as the number of selected
" lines. If we put the <Esc> in the noremap, vim will bell.
"
"----------------------------------------------------------------------------
" ***Start/Close***
"----------------------------------------------------------------------------
" *Start*
" ---------------------------
" Start R 
if hasmapto('<Plug>RStart')
  noremap <buffer> <Plug>RStart :call StartR("R")<CR>
  vnoremap <buffer> <Plug>RStart <Esc>:call StartR("R")<CR>
  inoremap <buffer> <Plug>RStart <Esc>:call StartR("R")<CR>a
else
  noremap <buffer> <Leader>rf :call StartR("R")<CR>
  vnoremap <buffer> <Leader>rf <Esc>:call StartR("R")<CR>
  inoremap <buffer> <Leader>rf <Esc>:call StartR("R")<CR>a
endif

" Start R --vannila
if hasmapto('<Plug>RvanillaStart')
  noremap <buffer> <Plug>RvanillaStart :call StartR("vanilla")<CR>
  vnoremap <buffer> <Plug>RvanillaStart <Esc>:call StartR("vanilla")<CR>
  inoremap <buffer> <Plug>RvanillaStart <Esc>:call StartR("vanilla")<CR>a
else
  noremap <buffer> <Leader>rv :call StartR("vanilla")<CR>
  vnoremap <buffer> <Leader>rv <Esc>:call StartR("vanilla")<CR>
  inoremap <buffer> <Leader>rv <Esc>:call StartR("vanilla")<CR>a
endif

" Start R (custom) 
if hasmapto('<Plug>RCustomStart')
  noremap <buffer> <Plug>RCustomStart :call StartR("custom")<CR>
  vnoremap <buffer> <Plug>RCustomStart <Esc>:call StartR("custom")<CR>
  inoremap <buffer> <Plug>RCustomStart <Esc>:call StartR("custom")<CR>a
else
  noremap <buffer> <Leader>rc :call StartR("custom")<CR>
  vnoremap <buffer> <Leader>rc <Esc>:call StartR("custom")<CR>
  inoremap <buffer> <Leader>rc <Esc>:call StartR("custom")<CR>a
endif

" *Close*
" ---------------------------
" Close R (no save)
if hasmapto('<Plug>RClose')
  noremap <buffer> <Plug>RClose :call SendCmdToScreen('quit(save = "no")')<CR>
  vnoremap <buffer> <Plug>RClose <Esc>:call SendCmdToScreen('quit(save = "no")')<CR>
  inoremap <buffer> <Plug>RClose <Esc>:call SendCmdToScreen('quit(save = "no")')<CR>a
else
  noremap <buffer> <Leader>rq :call SendCmdToScreen('quit(save = "no")')<CR>
  vnoremap <buffer> <Leader>rq <Esc>:call SendCmdToScreen('quit(save = "no")')<CR>
  inoremap <buffer> <Leader>rq <Esc>:call SendCmdToScreen('quit(save = "no")')<CR>a
endif

" Close R (save workspace)
if hasmapto('<Plug>RSaveClose')
  noremap <buffer> <Plug>RSaveClose :call SendCmdToScreen('quit(save = "yes")')<CR>
  vnoremap <buffer> <Plug>RSaveClose <Esc>:call SendCmdToScreen('quit(save = "yes")')<CR>
  inoremap <buffer> <Plug>RSaveClose <Esc>:call SendCmdToScreen('quit(save = "yes")')<CR>a
else
  noremap <buffer> <Leader>rw :call SendCmdToScreen('quit(save = "yes")')<CR>
  vnoremap <buffer> <Leader>rw <Esc>:call SendCmdToScreen('quit(save = "yes")')<CR>
  inoremap <buffer> <Leader>rw <Esc>:call SendCmdToScreen('quit(save = "yes")')<CR>a
endif

"----------------------------------------------------------------------------
" ***Send***
"----------------------------------------------------------------------------
" *File*
" ---------------------------
" File 
if hasmapto('<Plug>RSendFile')
  noremap <buffer> <Plug>RSendFile :call SendFileToR("silent")<CR>
  vnoremap <buffer> <Plug>RSendFile <Esc>:call SendFileToR("silent")<CR>
  inoremap <buffer> <Plug>RSendFile <Esc>:call SendFileToR("silent")<CR>a
else
  noremap <buffer> <F5> :call SendFileToR("silent")<CR>
  vnoremap <buffer> <F5> <Esc>:call SendFileToR("silent")<CR>
  inoremap <buffer> <F5> <Esc>:call SendFileToR("silent")<CR>a
endif

" File (echo)
if hasmapto('<Plug>RESendFile')
  noremap <buffer> <Plug>RESendFile :call SendFileToR("echo")<CR>
  vnoremap <buffer> <Plug>RESendFile <Esc>:call SendFileToR("echo")<CR>
  inoremap <buffer> <Plug>RESendFile <Esc>:call SendFileToR("echo")<CR>a
else
  noremap <buffer> <S-F5> :call SendFileToR("echo")<CR>
  vnoremap <buffer> <S-F5> <Esc>:call SendFileToR("echo")<CR>
  inoremap <buffer> <S-F5> <Esc>:call SendFileToR("echo")<CR>a
endif

" *Block*
" ---------------------------
" Block (cur)
if hasmapto('<Plug>RSendMBlock')
  noremap <buffer> <Plug>RSendMBlock :call SendMBlockToR("silent", "stay")<CR>
  inoremap <buffer> <Plug>RSendMBlock <Esc>:call SendMBlockToR("silent", "stay")<CR>i
else
  noremap <buffer> <F6> :call SendMBlockToR("silent", "stay")<CR>
  inoremap <buffer> <F6> <Esc>:call SendMBlockToR("silent", "stay")<CR>i
endif

" Block (cur, echo)
if hasmapto('<Plug>RESendMBlock')
  noremap <buffer> <Plug>RESendMBlock :call SendMBlockToR("echo", "stay")<CR>
  inoremap <buffer> <Plug>RESendMBlock <Esc>:call SendMBlockToR("echo, "stay"")<CR>i
else
  noremap <buffer> <S-F6> :call SendMBlockToR("echo", "stay")<CR>
  inoremap <buffer> <S-F6> <Esc>:call SendMBlockToR("echo", "stay")<CR>i
endif

" Block (cur, echo and down)
if hasmapto('<Plug>REDSendMBlock')
  noremap <buffer> <Plug>REDSendMBlock :call SendMBlockToR("echo" "down")<CR>
  inoremap <buffer> <Plug>REDSendMBlock <Esc>:call SendMBlockToR("echo" "down")<CR>i
else
  noremap <buffer> <C-S-F6> :call SendMBlockToR("echo", "down")<CR>
  inoremap <buffer> <C-S-F6> <Esc>:call SendMBlockToR("echo", "down")<CR>
  inoremap <buffer> <C-S-F6> <Esc>:call SendMBlockToR("echo", "down")<CR>i
endif

" *Function*
" ---------------------------
" Function (cur)
if hasmapto('<Plug>RSendFunction')
  noremap <buffer> <Plug>RSendFunction :call SendFunctionToR("stay")<CR>
  vnoremap <buffer> <Plug>RSendFunction <Esc>:call SendFunctionToR("stay")<CR>
  inoremap <buffer> <Plug>RSendFunction <Esc>:call SendFunctionToR("stay")<CR>i
else
  noremap <buffer> <F7> :call SendFunctionToR("stay")<CR>
  vnoremap <buffer> <F7> <Esc>:call SendFunctionToR("stay")<CR>
  inoremap <buffer> <F7> <Esc>:call SendFunctionToR("stay")<CR>i
endif

" Function (cur and down)
if hasmapto('<Plug>RDSendFunction')
  noremap <buffer> <Plug>RDSendFunction :call SendFunctionToR("down")<CR>
  vnoremap <buffer> <Plug>RDSendFunction <Esc>:call SendFunctionToR("down")<CR>
  inoremap <buffer> <Plug>RDSendFunction <Esc>:call SendFunctionToR("down")<CR>i
else
  noremap <buffer> <S-F7> :call SendFunctionToR("down")<CR>
  vnoremap <buffer> <S-F7> <Esc>:call SendFunctionToR("down")<CR>
  inoremap <buffer> <S-F7> <Esc>:call SendFunctionToR("down")<CR>i
endif

" 'Send line' must become before 'Send selection' because they share the same
" shortcut. Otherwise, 'Send selection' will send the selection as many times as
" are the number of selected lines.
" *Line*
" ---------------------------
" Line
if hasmapto('<Plug>RSendLine')
  noremap <buffer> <Plug>RSendLine :call SendLineToR("stay")<CR>0
  inoremap <buffer> <Plug>RSendLine <Esc>:call SendLineToR("stay")<CR>0i
else
  noremap <buffer> <F8> :call SendLineToR("stay")<CR>0
  inoremap <buffer> <F8> <Esc>:call SendLineToR("stay")<CR>0i
endif

"Line (and down)
if hasmapto('<Plug>RDSendLine')
  noremap <buffer> <Plug>RDSendLine :call SendLineToR("down")<CR>0
  inoremap <buffer> <Plug>RDSendLine <Esc>:call SendLineToR("down")<CR>0i
else
  noremap <buffer> <F9> :call SendLineToR("down")<CR>0
  inoremap <buffer> <F9> <Esc>:call SendLineToR("down")<CR>0i
endif

" Line (and new one)
if hasmapto('<Plug>RSendLAndOpenNewOne')
  inoremap <buffer> <Plug>RSendLAndOpenNewOne <Esc>:call SendLineToR("stay")<CR>o
else
  inoremap <buffer> \q <Esc>:call SendLineToR("stay")<CR>o
endif

" For compatibility with Johannes Ranke's plugin
if exists("g:vimrplugin_map_r")
  vnoremap <buffer> r <Esc>:call SendSelectionToR("v", "silent", "down")<CR>
endif

" 'Send line' must become before 'Send selection' because they share the same
" shortcut. Otherwise, 'Send selection' will send the selection as many times as
" are the number of selected lines.
" *Selection*
" ---------------------------
" Selection
if hasmapto('<Plug>RSendSelection')
  vnoremap <buffer> <Plug>RSendSelection <Esc>:call SendSelectionToR("v", "silent", "stay")<CR>
else
  vnoremap <buffer> <F8> <Esc>:call SendSelectionToR("v", "silent", "stay")<CR>0
endif

" Selection (echo)
if hasmapto('<Plug>RESendSelection')
  vnoremap <buffer> <Plug>RESendSelection <Esc>:call SendSelectionToR("v", "echo", "stay")<CR>
else
  vnoremap <buffer> <S-F8> <Esc>:call SendSelectionToR("v", "echo", "stay")<CR>0
endif

" Selection (and down)
if hasmapto('<Plug>RDSendSelection')
  vnoremap <buffer> <Plug>RSendSelection <Esc>:call SendSelectionToR("v", "silent", "down")<CR>
else
  vnoremap <buffer> <F9> <Esc>:call SendSelectionToR("v", "silent", "down")<CR>0
endif

" Send selection to R (echo, down)
if hasmapto('<Plug>REDSendSelection')
  vnoremap <buffer> <Plug>RESendSelection <Esc>:call SendSelectionToR("v", "echo", "down")<CR>
else
  vnoremap <buffer> <S-F9> <Esc>:call SendSelectionToR("v", "echo", "down")<CR>0
endif

"----------------------------------------------------------------------------
" Control
"----------------------------------------------------------------------------
" List space
if hasmapto('<Plug>RListSpace')
  noremap <buffer> <Plug>RListSpace :call SendCmdToScreen("ls()")<CR>
  vnoremap <buffer> <Plug>RListSpace <Esc>:call SendCmdToScreen("ls()")<CR>
  inoremap <buffer> <Plug>RListSpace <Esc>:call SendCmdToScreen("ls()")<CR>
else
  noremap <buffer> <Leader>rl :call SendCmdToScreen("ls()")<CR>
  vnoremap <buffer> <Leader>rl <Esc>:call SendCmdToScreen("ls()")<CR>
  inoremap <buffer> <Leader>rl <Esc>:call SendCmdToScreen("ls()")<CR>i
endif

" Clear console
if hasmapto('<Plug>RClearConsole')
  noremap <buffer> <Plug>RClearConsole :call SendCmdToScreen("")<CR>
  vnoremap <buffer> <Plug>RClearConsole <Esc>:call SendCmdToScreen("")<CR>
  inoremap <buffer> <Plug>RClearConsole <Esc>:call SendCmdToScreen("")<CR>i
else
  noremap <buffer> <Leader>rr :call SendCmdToScreen("")<CR>
  vnoremap <buffer> <Leader>rr <Esc>:call SendCmdToScreen("")<CR>
  inoremap <buffer> <Leader>rr <Esc>:call SendCmdToScreen("")<CR>i
endif

" Clear all
if hasmapto('<Plug>RClearAll')
  noremap <buffer> <Plug>RClearAll :call RClearAll()<CR>
  vnoremap <buffer> <Plug>RClearAll <Esc>:call RClearAll()<CR>
  inoremap <buffer> <Plug>RClearAll <Esc>:call RClearAll()<CR>i
else
  noremap <buffer> <Leader>rm :call RClearAll()<CR>
  vnoremap <buffer> <Leader>rm <Esc>:call RClearAll()<CR>
  inoremap <buffer> <Leader>rm <Esc>:call RClearAll()<CR>i
endif

" ---------------------------
" Object (print)
if hasmapto('<Plug>RObjectPr')
  noremap <buffer> <Plug>RObjectPr :call RAction("print")<CR>
  vnoremap <buffer> <Plug>RObjectPr <Esc>:call RAction("print")<CR>
  inoremap <buffer> <Plug>RObjectPr <Esc>:call RAction("print")<CR>a
else
  noremap <buffer> <Leader>rp :call RAction("print")<CR>
  vnoremap <buffer> <Leader>rp <Esc>:call RAction("print")<CR>
  inoremap <buffer> <Leader>rp <Esc>:call RAction("print")<CR>a
endif

" Object (names)
if hasmapto('<Plug>RObjectNames')
  noremap <buffer> <Plug>RObjectNames :call RAction("names")<CR>
  vnoremap <buffer> <Plug>RObjectNames <Esc>:call RAction("names")<CR>
  inoremap <buffer> <Plug>RObjectNames <Esc>:call RAction("names")<CR>a
else
  noremap <buffer> <Leader>rn :call RAction("names")<CR>
  vnoremap <buffer> <Leader>rn <Esc>:call RAction("names")<CR>
  inoremap <buffer> <Leader>rn <Esc>:call RAction("names")<CR>a
endif

" Object (str)
if hasmapto('<Plug>RObjectStr')
  noremap <buffer> <Plug>RObjectStr :call RAction("str")<CR>
  vnoremap <buffer> <Plug>RObjectStr <Esc>:call RAction("str")<CR>
  inoremap <buffer> <Plug>RObjectStr <Esc>:call RAction("str")<CR>a
else
  noremap <buffer> <Leader>rt :call RAction("str")<CR>
  vnoremap <buffer> <Leader>rt <Esc>:call RAction("str")<CR>
  inoremap <buffer> <Leader>rt <Esc>:call RAction("str")<CR>a
endif

" ---------------------------
" Arguments (cur)
if hasmapto('<Plug>RShowArgs')
  noremap <buffer> <Plug>RShowArgs :call RAction("args")<CR>
  vnoremap <buffer> <Plug>RShowArgs <Esc>:call RAction("args")<CR>
  inoremap <buffer> <Plug>RShowArgs <Esc>:call RAction("args")<CR>a
else
  noremap <buffer> <Leader>ra :call RAction("args")<CR>
  vnoremap <buffer> <Leader>ra <Esc>:call RAction("args")<CR>
  inoremap <buffer> <Leader>ra <Esc>:call RAction("args")<CR>a
endif

" Example (cur)
if hasmapto('<Plug>RShowEx')
  noremap <buffer> <Plug>RShowEx :call RAction("example")<CR>
  vnoremap <buffer> <Plug>RShowEx <Esc>:call RAction("example")<CR>
  inoremap <buffer> <Plug>RShowEx <Esc>:call RAction("example")<CR>a
else
  noremap <buffer> <Leader>re :call RAction("example")<CR>
  vnoremap <buffer> <Leader>re <Esc>:call RAction("example")<CR>
  inoremap <buffer> <Leader>re <Esc>:call RAction("example")<CR>a
endif

" Help (cur)
if hasmapto('<Plug>RHelp')
  noremap <buffer> <Plug>RHelp :call RAction("help")<CR>
  vnoremap <buffer> <Plug>RHelp <Esc>:call RAction("help")<CR>
  inoremap <buffer> <Plug>RHelp <Esc>:call RAction("help")<CR>a
else
  noremap <buffer> <Leader>rh :call RAction("help")<CR>
  vnoremap <buffer> <Leader>rh <Esc>:call RAction("help")<CR>
  inoremap <buffer> <Leader>rh <Esc>:call RAction("help")<CR>a
endif

" ---------------------------
" Summary (cur)
if hasmapto('<Plug>RSummary')
  noremap <buffer> <Plug>RSummary :call RAction("summary")<CR>
  vnoremap <buffer> <Plug>RSummary <Esc>:call RAction("sumary")<CR>
  inoremap <buffer> <Plug>RSummary <Esc>:call RAction("summary")<CR>a
else
  noremap <buffer> <Leader>rs :call RAction("summary")<CR>
  vnoremap <buffer> <Leader>rs <Esc>:call RAction("summary")<CR>
  inoremap <buffer> <Leader>rs <Esc>:call RAction("summary")<CR>a
endif

" Plot (cur)
if hasmapto('<Plug>RPlot')
  noremap <buffer> <Plug>RPlot :call RAction("plot")<CR>
  vnoremap <buffer> <Plug>RPlot <Esc>:call RAction("plot")<CR>
  inoremap <buffer> <Plug>RPlot <Esc>:call RAction("plot")<CR>a
else
  noremap <buffer> <Leader>rg :call RAction("plot")<CR>
  vnoremap <buffer> <Leader>rg <Esc>:call RAction("plot")<CR>
  inoremap <buffer> <Leader>rg <Esc>:call RAction("plot")<CR>a
endif

" Plot and summary (cur)
if hasmapto('<Plug>RSPlot')
  noremap <buffer> <Plug>RSPlot :call RAction("plot&summary")<CR>
  vnoremap <buffer> <Plug>RSPlot <Esc>:call RAction("plot&summary")<CR>
  inoremap <buffer> <Plug>RSPlot <Esc>:call RAction("plot&summary")<CR>a
else
  noremap <buffer> <Leader>rb :call RAction("plot&summary")<CR>
  vnoremap <buffer> <Leader>rb <Esc>:call RAction("plot&summary")<CR>
  inoremap <buffer> <Leader>rb <Esc>:call RAction("plot&summary")<CR>a
endif

" ---------------------------
" Set working directory
if hasmapto('<Plug>RSetwd')
  noremap <buffer> <Plug>RSetwd :call RSetWD()<CR>
  vnoremap <buffer> <Plug>RSetwd <Esc>:call RSetWD()<CR>
  inoremap <buffer> <Plug>RSetwd <Esc>:call RSetWD()<CR>a
else
  noremap <buffer> <Leader>rd :call RSetWD()<CR>
  vnoremap <buffer> <Leader>rd <Esc>:call RSetWD()<CR>
  inoremap <buffer> <Leader>rd <Esc>:call RSetWD()<CR>a
endif

" ---------------------------
" Sweave (cur file)
if &filetype == "rnoweb"
  if hasmapto('<Plug>RSweave')
    noremap <buffer> <Plug>RSweave :call RSweave()<CR>
    vnoremap <buffer> <Plug>RSweave <Esc>:call RSweave()<CR>
    inoremap <buffer> <Plug>RSweave <Esc>:call RSweave()<CR>a
  else
    noremap <buffer> \sw :call RSweave()<CR>
    vnoremap <buffer> \sw <Esc>:call RSweave()<CR>
    inoremap <buffer> \sw <Esc>:call RSweave()<CR>a
  endif
endif

" Sweave and PDF (cur file)
if &filetype == "rnoweb"
  if hasmapto('<Plug>RMakePDF')
    noremap <buffer> <Plug>RMakePDF :call RMakePDF()<CR>
    vnoremap <buffer> <Plug>RMakePDF <Esc>:call RMakePDF()<CR>
    inoremap <buffer> <Plug>RMakePDF <Esc>:call RMakePDF()<CR>a
  else
    noremap <buffer> \sp :call RMakePDF()<CR>
    vnoremap <buffer> \sp <Esc>:call RMakePDF()<CR>
    inoremap <buffer> \sp <Esc>:call RMakePDF()<CR>a
  endif
endif

" ---------------------------
" Build tags file for omni completion
if hasmapto('<Plug>RBuildTags')
  noremap <buffer> <Plug>RBuildTags :call BuildRTags()<CR>
  vnoremap <buffer> <Plug>RBuildTags <Esc>:call BuildRTags()<CR>
  inoremap <buffer> <Plug>RBuildTags <Esc>:call BuildRTags()<CR>i
else
  noremap <buffer> <Leader>ro :call BuildRTags()<CR>
  vnoremap <buffer> <Leader>ro <Esc>:call BuildRTags()<CR>
  inoremap <buffer> <Leader>ro <Esc>:call BuildRTags()<CR>i
endif

" Stop R
"if hasmapto('<Plug>RStop')
"  noremap <buffer> <Plug>RStop :call SendCmdToScreen('cat("not implemented yet\n")')<CR>
"  vnoremap <buffer> <Plug>RStop <Esc>:call SendCmdToScreen('cat("not implemented yet\n")')<CR>
"  inoremap <buffer> <Plug>RStop <Esc>:call SendCmdToScreen('cat("not implemented yet\n")')<CR>i
"else
"  noremap <buffer> <C-S-F4> :call SendCmdToScreen('cat("not implemented yet\n")')<CR>
"  vnoremap <buffer> <C-S-F4> <Esc>:call SendCmdToScreen('cat("not implemented yet\n")')<CR>
"  inoremap <buffer> <C-S-F4> <Esc>:call SendCmdToScreen('cat("not implemented yet\n")')<CR>i
"endif


" Menu R
function! MakeRMenu()
  if b:hasrmenu == 1
    return
  endif
  "----------------------------------------------------------------------------
  " Start/Close
  "----------------------------------------------------------------------------
  " Start R
  if hasmapto('<Plug>RStart')
    amenu &R.Start/Close.Start\ R\ (default) :call StartR("R")<CR>
  else
    amenu &R.Start/Close.Start\ R\ (default)<Tab>\\rf :call StartR("R")<CR>
  endif

  " Start R --vannila
  if hasmapto('<Plug>RvanillaStart')
    amenu R.Start/Close.Start\ R\ --vanilla :call StartR("vanilla")<CR>
  else
    amenu R.Start/Close.Start\ R\ --vanilla<Tab>\\rv :call StartR("Rvanilla")<CR>
  endif

  " Start R (custom)
  if hasmapto('<Plug>RCustomStart')
    amenu R.Start/Close.Start\ R\ (custom) :call StartR("custom")<CR>
  else
    amenu R.Start/Close.Start\ R\ (custom)<Tab>\\rc :call StartR("custom")<CR>
  endif

  "-------------------------------
  menu R.Start/Close.-Sep1- <nul>

  " Close R (no save)
  if hasmapto('<Plug>RClose')
    amenu R.Start/Close.Close\ R\ (no\ save) :call SendCmdToScreen('quit(save = "no")')<CR>
  else
    amenu R.Start/Close.Close\ R\ (no\ save)<Tab>\\rq :call SendCmdToScreen('quit(save = "no")')<CR>
  endif

  " Close R (save workspace)
  if hasmapto('<Plug>RSaveClose')
    amenu R.Start/Close.Close\ R\ (save\ workspace) :call SendCmdToScreen('quit(save = "yes")')<CR>
  else
    amenu R.Start/Close.Close\ R\ (save\ workspace)<Tab>\\rw :call SendCmdToScreen('quit(save = "yes")')<CR>
  endif

  "----------------------------------------------------------------------------
  " Send
  "----------------------------------------------------------------------------
  " File
  if hasmapto('<Plug>RSendFile')
    amenu R.Send.File :call SendFileToR("silent")<CR>
  else
    amenu R.Send.File<Tab>f5 :call SendFileToR("silent")<CR>
  endif

  " File (echo)
  if hasmapto('<Plug>RESendFile')
    amenu R.Send.File\ (echo) :call SendFileToR("echo")<CR>
  else
    amenu R.Send.File\ (echo)<Tab>F5 :call SendFileToR("echo")<CR>
  endif

  "-------------------------------
  menu R.Send.-Sep1- <nul>

  " Block (cur)
  if hasmapto('<Plug>RSendMBlock')
    amenu R.Send.Block\ (cur) :call SendMBlockToR("silent", "stay")<CR>
  else
    amenu R.Send.Block\ (cur)<Tab>f6 :call SendMBlockToR("silent", "stay")<CR>
  endif

  " Block (cur, echo)
  if hasmapto('<Plug>RESendMBlock')
    amenu R.Send.Block\ (cur,\ echo) :call SendMBlockToR("echo", "stay")<CR>
  else
    amenu R.Send.Block\ (cur,\ echo)<Tab>F6 :call SendMBlockToR("echo", "stay")<CR>
  endif

  " Block (cur, echo and down)
  if hasmapto('<Plug>REDSendMBlock')
    amenu R.Send.Block\ (cur,\ echo\ and\ down) :call SendMBlockToR("echo", "down")<CR>
  else
    amenu R.Send.Block\ (cur,\ echo\ and\ down)<Tab>^F6 :call SendMBlockToR("echo", "down")<CR>
  endif
  
  "-------------------------------
  menu R.Send.-Sep2- <nul>

  " Function (cur)
  if hasmapto('<Plug>RSendFunction')
    amenu R.Send.Function\ (cur) :call SendFunctionToR("stay")<CR>
    imenu R.Send.Function\ (cur) <Esc> :call SendFunctionToR("stay")<CR>
  else
    amenu R.Send.Function\ (cur)<Tab>f7 :call SendFunctionToR("stay")<CR>
    imenu R.Send.Function\ (cur)<Tab>f7 <Esc> :call SendFunctionToR("stay")<CR>
  endif

  " Function (cur and down)
  if hasmapto('<Plug>RDSendFunction')
    amenu R.Send.Function\ (cur\ and\ down) :call SendFunctionToR("down")<CR>
    imenu R.Send.Function\ (cur\ and\ down) <Esc> :call SendFunctionToR("down")<CR>
  else
    amenu R.Send.Function\ (cur\ and\ down)<Tab>F7 :call SendFunctionToR("down")<CR>
    imenu R.Send.Function\ (cur\ and\ down)<Tab>F7 <Esc> :call SendFunctionToR("down")<CR>
  endif

  "-------------------------------
  menu R.Send.-Sep3- <nul>

  " Selection
  if hasmapto('<Plug>RSendSelection')
    vmenu R.Send.Selection<Esc> :call SendSelectionToR("v", "silent", "stay")<CR>0
  else
    vmenu R.Send.Selection<Tab>f8 <Esc> :call SendSelectionToR("v", "silent", "stay")<CR>0
  endif

  " Selection (echo)
  if hasmapto('<Plug>RESendSelection')
    vmenu R.Send.Selection\ (echo)<Esc> :call SendSelectionToR("v", "echo", "stay")<CR>0
  else
    vmenu R.Send.Selection\ (echo)<Tab>F8 <Esc> :call SendSelectionToR("v", "echo", "stay")<CR>0
  endif

  " Selection (and down)
  if hasmapto('<Plug>RDSendSelection')
    vmenu R.Send.Selection\ (and\ down)<Esc> :call SendSelectionToR("v", "silent", "down")<CR>0
  else
    vmenu R.Send.Selection\ (and\ down)<Tab>f9 <Esc> :call SendSelectionToR("v", "silent", "down")<CR>0
  endif

  " Selection (echo and down)
  if hasmapto('<Plug>REDSendSelection')
    vmenu R.Send.Selection\ (echo\ and\ down) <Esc> :call SendSelectionToR("v", "echo", "down")<CR>0
  else
    vmenu R.Send.Selection\ (echo\ and\ down)<Tab>F9 <Esc> :call SendSelectionToR("v", "echo", "down")<CR>0
  endif

  "-------------------------------
  menu R.Send.-Sep4- <nul>

  " Line
  if hasmapto('<Plug>RSendLine')
    amenu R.Send.Line :call SendLineToR("stay")<CR>0
    imenu R.Send.Line <Esc> :call SendLineToR("stay")<CR>0a
  else
    amenu R.Send.Line<Tab>f8 :call SendLineToR("stay")<CR>0
    imenu R.Send.Line<Tab>f8 <Esc> :call SendLineToR("stay")<CR>0a
  endif

  "Line (and down)
  if hasmapto('<Plug>RDSendLine')
    amenu R.Send.Line\ (and\ down) :call SendLineToR("down")<CR>0
    imenu R.Send.Line\ (and\ down) <Esc> :call SendLineToR("down")<CR>0a
  else
    amenu R.Send.Line\ (and\ down)<Tab>f9 :call SendLineToR("down")<CR>0
    imenu R.Send.Line\ (and\ down)<Tab>f9 <Esc> :call SendLineToR("down")<CR>0a
  endif

  " Line (and new one)
  if hasmapto('<Plug>RSendLAndOpenNewOne')
    imenu R.Send.Line\ (and\ new\ one) <Esc> :call SendLineToR("stay")<CR>o
  else
    imenu R.Send.Line\ (and\ new\ one)<Tab>\\q <Esc> :call SendLineToR("stay")<CR>o
  endif

  "----------------------------------------------------------------------------
  " Control
  "----------------------------------------------------------------------------
  " List space
  if hasmapto('<Plug>RListSpace')
    amenu R.Control.List\ space :call SendCmdToScreen("ls()")<CR>
  else
    amenu R.Control.List\ space<Tab>\\rl :call SendCmdToScreen("ls()")<CR>
  endif

  " Clear console
  if hasmapto('<Plug>RClearConsole')
    amenu R.Control.Clear\ console\ screen :call SendCmdToScreen("")<CR>
  else
    amenu R.Control.Clear\ console\ screen<Tab>\\rr :call SendCmdToScreen("")<CR>
  endif

  " Clear all
  if hasmapto('<Plug>RClearAll')
    amenu R.Control.Clear\ all :call RClearAll()<CR>
  else
    amenu R.Control.Remove\ all<Tab>\\rm :call RClearAll()<CR>
  endif

  "-------------------------------
  menu R.Control.-Sep1- <nul>

  " Object (print)
  if hasmapto('<Plug>RObjectPr')
    amenu R.Control.Object\ (print) :call RAction("print")<CR>
  else
    amenu R.Control.Object\ (print)<Tab>\\rp :call RAction("print")<CR>
  endif

  " Object (names)
  if hasmapto('<Plug>RObjectNames')
    amenu R.Control.Object\ (names) :call RAction("names")<CR>
  else
    amenu R.Control.Object\ (names)<Tab>\\rn :call RAction("names")<CR>
  endif
  
  " Object (str)
  if hasmapto('<Plug>RObjectStr')
    amenu R.Control.Object\ (str) :call RAction("str")<CR>
  else
    amenu R.Control.Object\ (str)<Tab>\\rt :call RAction("str")<CR>
  endif

  "-------------------------------
  menu R.Control.-Sep2- <nul>

  " Arguments (cur)
  if hasmapto('<Plug>RShowArgs')
    amenu R.Control.Arguments\ (cur) :call RAction("args")<CR>
  else
    amenu R.Control.Arguments\ (cur)<Tab>\\ra :call RAction("args")<CR>
  endif

  " Example (cur)
  if hasmapto('<Plug>RShowEx')
    amenu R.Control.Example\ (cur) :call RAction("example")<CR>
  else
    amenu R.Control.Example\ (cur)<Tab>\\re :call RAction("example")<CR>
  endif

  " Help (cur)
  if hasmapto('<Plug>RHelp')
    amenu R.Control.Help\ (cur) :call RAction("help")<CR>
  else
    amenu R.Control.Help\ (cur)<Tab>\\rh :call RAction("help")<CR>
  endif

  "-------------------------------
  menu R.Control.-Sep3- <nul>
  
  " Summary (cur)
  if hasmapto('<Plug>RSummary')
    amenu R.Control.Summary\ (cur) :call RAction("summary")<CR>
  else
    amenu R.Control.Summary\ (cur)<Tab>\\rs :call RAction("summary")<CR>
  endif

  " Plot (cur)
  if hasmapto('<Plug>RPlot')
    amenu R.Control.Plot\ (cur) :call RAction("plot")<CR>
  else
    amenu R.Control.Plot\ (cur)<Tab>\\rg :call RAction("plot")<CR>
  endif

  " Plot and summary (cur)
  if hasmapto('<Plug>RSPlot')
    amenu R.Control.Plot\ and\ summary\ (cur) :call RAction("plot&summary")<CR>
  else
    amenu R.Control.Plot\ and\ summary\ (cur)<Tab>\\rb :call RAction("plot&summary")<CR>
  endif

  "-------------------------------
  menu R.Control.-Sep4- <nul>

  " Set working directory
  if hasmapto('<Plug>RSetwd')
    amenu R.Control.Set\ working\ directory\ (cur\ file\ path) <Esc>:call RSetWD()<CR>
  else
    amenu R.Control.Set\ working\ directory\ (cur\ file\ path)<Tab>\\rd <Esc>:call RSetWD()<CR>
  endif

  "-------------------------------
  if &filetype == "rnoweb"
    menu R.Control.-Sep5- <nul>
  endif  

  " Sweave (cur file)
  if &filetype == "rnoweb"
    if hasmapto('<Plug>RSweave')
      amenu R.Control.Sweave\ (cur\ file) :call RSweave()<CR>
    else
      amenu R.Control.Sweave\ (cur\ file)<Tab>\\sw :call RSweave()<CR>
    endif
  endif

  " Sweave and PDF (cur file)
  if &filetype == "rnoweb"
    if hasmapto('<Plug>RMakePDF')
      amenu R.Control.Sweave\ and\ PDF\ (cur\ file) :call RMakePDF()<CR>
    else
      amenu R.Control.Sweave\ and\ PDF\ (cur\ file)<Tab>\\sp :call RMakePDF()<CR>
    endif
  endif

  "-------------------------------
  menu R.Control.-Sep6- <nul>

  " Rebuild list of objects
  if hasmapto('<Plug>RBuildTags')
    amenu R.Control.Rebuild\ list\ of\ objects :call BuildRTags()<CR>
  else
    amenu R.Control.Rebuild\ list\ of\ objects<Tab>\\ro :call BuildRTags()<CR>
  endif

  " Stop (process)
"  if hasmapto('<Plug>RStop')
"    amenu R.Control.Stop\ (process) :call SendCmdToScreen('cat("not implemented yet\n")')<CR>
"  else
"    amenu R.Control.Stop\ (process)<Tab><C-S-F4> :call SendCmdToScreen('cat("not implemented yet\n")')<CR>
"  endif

  "-------------------------------
  menu R.-Sep7- <nul>
  
  "----------------------------------------------------------------------------
  " About
  "----------------------------------------------------------------------------
  amenu R.About\ the\ plugin :help vim-r-plugin<CR>

  "----------------------------------------------------------------------------
  " ToolBar
  "----------------------------------------------------------------------------
  " Buttons
  amenu icon=r-start ToolBar.RStart :call StartR("R")<CR>
  amenu icon=r-close ToolBar.RClose :call SendCmdToScreen('quit(save = "no")')<CR>
  "---------------------------
  amenu icon=r-send-file ToolBar.RSendFile :call SendFileToR("echo")<CR>
  amenu icon=r-send-block ToolBar.RSendBlock :call SendMBlockToR("echo", "down")<CR>
  amenu icon=r-send-function ToolBar.RSendFunction :call SendFunctionToR("down")<CR>
  vmenu icon=r-send-selection ToolBar.RSendSelection <ESC> :call SendSelectionToR("v", "echo", "down")<CR>
  amenu icon=r-send-line ToolBar.RSendLine :call SendLineToR("down")<CR>
  "---------------------------
  amenu icon=r-control-listspace ToolBar.RListSpace :call SendCmdToScreen("ls()")<CR>
  amenu icon=r-control-clear ToolBar.RClear :call SendCmdToScreen("")<CR>
  amenu icon=r-control-clearall ToolBar.RClearAll :call RClearAll()<CR>

  "Hints
  tmenu ToolBar.RStart Start R
  tmenu ToolBar.RClose Close R (no save)
  tmenu ToolBar.RSendFile Send file (echo)
  tmenu ToolBar.RSendBlock Send current block and go down (echo)
  tmenu ToolBar.RSendFunction Send current function and go down
  tmenu ToolBar.RSendSelection Send selection and go down (echo)
  tmenu ToolBar.RSendLine Send current line and go down
  tmenu ToolBar.RListSpace List objects
  tmenu ToolBar.RClear Clear the console screen
  tmenu ToolBar.RClearAll Remove objects from workspace and clear the console screen

  let b:hasrmenu = 1
endfunction

function! DeleteScreenRC()
  if filereadable(b:scrfile)
    call delete(b:scrfile)
  endif
endfunction

function! UnMakeRMenu()
  call DeleteScreenRC()
  if b:hasrmenu == 0
    return
  endif
  aunmenu R
  aunmenu ToolBar.RClearAll
  aunmenu ToolBar.RClear
  aunmenu ToolBar.RListSpace
  aunmenu ToolBar.RSendLine
  aunmenu ToolBar.RSendSelection
  aunmenu ToolBar.RSendFunction
  aunmenu ToolBar.RSendBlock
  aunmenu ToolBar.RSendFile
  aunmenu ToolBar.RClose
  aunmenu ToolBar.RStart

  let b:hasrmenu = 0
endfunction

augroup VimRPlugin
  au BufEnter * if (&filetype == "r" || &filetype == "rnoweb" || &filetype == "rhelp") | call MakeRMenu() | endif
  au BufLeave * if (&filetype == "r" || &filetype == "rnoweb" || &filetype == "rhelp") | call UnMakeRMenu() | endif
  au VimLeave * if (&filetype == "r" || &filetype == "rnoweb" || &filetype == "rhelp") | call DeleteScreenRC() | endif
augroup END

