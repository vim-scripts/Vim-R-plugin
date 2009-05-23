" ftplugin for R files
"
" Author: Iago Mosqueira <i.mosqueira@ic.ac.uk>
" Author: Johannes Ranke <jranke@uni-bremen.de>
" Author: Fernando Henrique Ferraz Pereira da Rosa <feferraz@ime.usp.br>
" Author: Johannes Ranke <jranke@uni-bremen.de>
" Maintainer: Jakson Alves de Aquino <jalvesaq@gmail.com>
" Last Change: 2009 May
"
" Functions added by Jakson Alves de Aquino:
"   CheckRpipe(), GetFirstChar(), GoDown(), SendLineToR(), SendBlockToR(),
"   SendFileToR(), SendFunctionToR(), RHelp(), BuildRTags(), StartR(),
"   SignalToR(), ReplaceUnderS(), MakeRMenu() and UnMakeRMenu().
"
" Code written in vim is sent to R through a perl pipe [funnel.pl, by Larry
" Clapp <vim@theclapp.org> (modifiedy by Jakson Aquino and renamed to
" rfunnel.pl)], as individual lines, blocks, or the whole file.
"
" Please see doc/r-plugin.txt for usage details.


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
let b:hastoolbarkill = 0

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
let b:needshstart = 1
if exists("g:vimrplugin_nohstart")
  let b:needshstart = 0
endif
if exists("g:vimrplugin_browser_time") == 0
  let g:vimrplugin_browser_time = 4
endif

" What terminal is preferred:
if exists("g:vimrplugin_term_cmd")
  let b:term_cmd = g:vimrplugin_term_cmd
else
  let b:term_cmd = "uxterm -T 'R' -e"
endif

" Automatically source the script tools/rargs.R the first time <S-F1> is
" pressed:
let b:needsrargs = 1

" Make the R 'tags' file name
let b:rtagsfile = printf("/tmp/.Rtags-%s", userlogin)

" Make a random name for the pipe
let b:pipefname = printf("/tmp/.r-pipe-%s-%s", userlogin, localtime())
let b:rpidfile = b:pipefname . ".Rpid"

" Set completion with CTRL-X CTRL-O to autoloaded function.
if exists('&ofu')
  setlocal ofu=rcomplete#CompleteR
endif

" Disable backup for r-pipe
setl backupskip=/tmp/.r-pipe*

" Set tabstop so it is compatible with the emacs edited code. Personally, I
" prefer shiftwidth=2, which I have in my .vimrc anyway
set expandtab
set shiftwidth=4
set tabstop=8

function! SignalToR(signal)
  if filereadable(b:rpidfile)
    let tmp = readfile(b:rpidfile)
    let rparent = tmp[0]
    let awkprog = "{if(\$2 == " . rparent . ") print \$1}"
    let getpid = printf("ps -eo pid,ppid,comm | grep %s | awk '%s'", rparent, awkprog)
    let rpid = system(getpid)
    let killcmd = "kill -s " . a:signal . " " . rpid
    call system(killcmd)
  endif
endfunction

function! RWarningMsg(wmsg)
  echohl WarningMsg
  echo a:wmsg
  echohl Normal
endfunction

function! CheckRpipe()
  if filewritable(b:pipefname) == 0
    call RWarningMsg(b:pipefname . " not found!")
    return 1
  endif
  return 0
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
  let i = line(".") + 1
  call cursor(i, 1)
  let lastLine = line("$")
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
  if CheckRpipe()
    return
  endif
  echon
  let line = getline(".")
  if line =~ "library"
    let b:needsnewtags = 1
  endif
  call writefile([line], b:pipefname)
  if a:godown
    call GoDown()
  endif
endfunction

" Big chunks of text might obstruct the pipe.
function! CheckBlockSize(lines, type)
  let nbytes = len(a:lines)
  for str in a:lines
    let nbytes += strlen(str)
    if a:type == "block" && str =~ "library"
      let b:needsnewtags = 1
    endif
  endfor
  if nbytes > 4000
    call RWarningMsg("We can send to R at most 4000 bytes at once, but this " . a:type . " has " . nbytes . " bytes.")
    return 1
  endif
  return 0
endfunction

" Send visually selected lines.
function! SendBlockToR()
  if CheckRpipe()
    return
  endif
  echon
  if line("'<") == line("'>")
    call RWarningMsg("No block selected.")
    return
  endif
  let lines = getline("'<", "'>")
  if CheckBlockSize(lines, "block") == 0
    call writefile(lines, b:pipefname)
    call GoDown()
  endif
endfunction

function! CountBraces(line)
  let line2 = substitute(a:line, "{", "", "g")
  let line3 = substitute(a:line, "}", "", "g")
  let result = strlen(line3) - strlen(line2)
  return result
endfunction

function! SendFunctionToR()
  if CheckRpipe()
    return
  endif
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
  if CheckBlockSize(lines, "function") == 0
    call writefile(lines, b:pipefname)
  endif
endfunction

function! SendFileToR()
  if CheckRpipe()
    return
  endif
  echon
  let lines = getline("1", line("$"))
  if CheckBlockSize(lines, "file") == 0
    call writefile(lines, b:pipefname)
  endif
endfunction

" Call args() for the word under cursor
function! RHelp(type)
  if CheckRpipe()
    return
  endif
  echon
  " Go back some columns if character under cursor is not valid
  let curcol = col(".")
  let curline = line(".")
  let line = getline(curline)
  let i = curcol - 1
  while i > 1 && (line[i] == ' ' || line[i] == '(')
    let i -= 1
    call cursor(curline, i)
  endwhile
  let rkeyword = expand("<cWORD>")
  let rkeyword = substitute(rkeyword, "(.*", "", "g")
  " Put the cursor back into its original position and run the R command
  call cursor(curline, curcol)
  if strlen(rkeyword) > 0
    if a:type == "a"
      if b:needsrargs
        let b:needsrargs = 0
        call writefile(["source(\"~/.vim/tools/rargs.R\")"], b:pipefname)
      endif
      let rhelpcmd = printf("vim.list.args('%s')", rkeyword)
    else
      if b:needshstart == 1
	let b:needshstart = 0
        call writefile(["help.start()"], b:pipefname)
        let wt = g:vimrplugin_browser_time
        while wt > 0
          sleep
	  let wt -= 1
        endwhile
      endif
      let rhelpcmd = printf("help('%s')", rkeyword)
    endif
    call writefile([rhelpcmd], b:pipefname)
  endif
endfunction

" Tell R to create a 'tags' file (/tmp/.Rtags-user-time) listing all currently
" available objects in its environment. The file is necessary omni completion.
function! BuildRTags()
  if CheckRpipe()
    return
  endif
  let tagscmd = printf(".vimtagsfile <- \"%s\"", b:rtagsfile)
  call writefile([tagscmd], b:pipefname)
  let tagscmd = "source(\"~/.vim/tools/rtags.R\")"
  let b:needsnewtags = 0
  call writefile([tagscmd], b:pipefname)
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

function! StartR(whatr, kbdclk)
  let rcmd = printf("\:%s", a:whatr)
  " Truncate the string if there is an empty space
  let spchar = stridx(rcmd, " ")
  if spchar != -1
    let rcmd = strpart(rcmd, 0, spchar)
  endif
  " Check whether the R executable exists
  if exists(rcmd) == 0
    if a:kbdclk == "click"
      let msg = printf("Cannot start \"%s\": command not found.", a:whatr)
      call confirm(msg, "&OK", "Warning")
    else
      call RWarningMsg(a:whatr . " not found.")
    endif
    return
  endif
  " Check whether the pipe was already open
  if filewritable(b:pipefname) == 1
    if a:kbdclk == "click"
      let msg = printf("The fifo %s already exists. I'll not open it again.", b:pipefname)
      call confirm(msg, "&OK", "Warning")
    else
      call RWarningMsg(b:pipefname . " already exists")
    endif
    return
  endif
  " Run R
  let opencmd = printf("%s ~/.vim/tools/rfunnel.pl %s \"%s && echo -e 'Interpreter has finished. Exiting. Goodbye.'\"&", b:term_cmd, b:pipefname, a:whatr)
  let rlog = system(opencmd)
  if rlog != ""
    call RWarningMsg(rlog)
    return
  endif
  amenu icon=rstop ToolBar.RStop :call SignalToR("INT")<CR>
  amenu icon=rkill ToolBar.RKill :call SignalToR("TERM")<CR>
  tmenu ToolBar.RStop Stop R process
  tmenu ToolBar.RKill Kill R process
  let b:hastoolbarkill = 1
  echon
endfunction


function! ReplaceUnderS()
  let j = col(".")
  let s = getline(".")
  if j > 3 && s[j-3] == "<" && s[j-2] == "-" && s[j-1] == " "
    let i = line(".")
    call cursor(i, j-3)
    put = '_'
    execute 'normal! kJ4h4xl'
    return
  endif
  let isString = 0
  while j > 0
    if s[j] == " "
      break
    endif
    if s[j] == '"'
      let isString = 1
      break
    endif
    let j = j - 1
  endwhile
  if isString == 0
    execute "normal! a <- "
  else
    put = '_'
    execute 'normal! kgJ'
  endif
endfunction

" For each noremap we need a vnoremap including <Esc> before the :call,
" otherwise vim will call the function as many times as the number of selected
" lines. If we put the <Esc> in the noremap, vim will bell.

" Start a listening R interpreter in new xterm
if hasmapto('<Plug>RStart')
  noremap <buffer> <Plug>RStart :call StartR("R", "kbd")<CR>
  vnoremap <buffer> <Plug>RStart <Esc>:call StartR("R", "kbd")<CR>
  inoremap <buffer> <Plug>RStart <Esc>:call StartR("R", "kbd")<CR>a
else
  noremap <buffer> <F2> :call StartR("R", "kbd")<CR>
  vnoremap <buffer> <F2> <Esc>:call StartR("R", "kbd")<CR>
  inoremap <buffer> <F2> <Esc>:call StartR("R", "kbd")<CR>a
endif

" Start a listening R-devel interpreter in new xterm
if hasmapto('<Plug>RStart-dev')
  noremap <buffer> <Plug>RStart-dev :call StartR("R-devel", "kbd")<CR>
  vnoremap <buffer> <Plug>RStart-dev <Esc>:call StartR("R-devel", "kbd")<CR>
  inoremap <buffer> <Plug>RStart-dev <Esc>:call StartR("R-devel", "kbd")<CR>a
else
  noremap <buffer> <F3> :call StartR("R-devel", "kbd")<CR>
  vnoremap <buffer> <F3> <Esc>:call StartR("R-devel", "kbd")<CR>
  inoremap <buffer> <F3> <Esc>:call StartR("R-devel", "kbd")<CR>a
endif

" Start a listening R --vanilla interpreter in new xterm
if hasmapto('<Plug>RStart-vanilla')
  noremap <buffer> <Plug>RStart-vanilla :call StartR("R --vanilla", "kbd")<CR>
  vnoremap <buffer> <Plug>RStart-vanilla <Esc>:call StartR("R --vanilla", "kbd")<CR>
  inoremap <buffer> <Plug>RStart-vanilla <Esc>:call StartR("R --vanilla", "kbd")<CR>a
else
  noremap <buffer> <F4> :call StartR("R --vanilla", "kbd")<CR>
  vnoremap <buffer> <F4> <Esc>:call StartR("R --vanilla", "kbd")<CR>
  inoremap <buffer> <F4> <Esc>:call StartR("R --vanilla", "kbd")<CR>a
endif

" Build tags file for omni completion
if hasmapto('<Plug>RBuildTags')
  noremap <buffer> <Plug>RBuildTags :call BuildRTags()<CR>
  vnoremap <buffer> <Plug>RBuildTags <Esc>:call BuildRTags()<CR>
  inoremap <buffer> <Plug>RBuildTags <Esc>:call BuildRTags()<CR>i
else
  noremap <buffer> <F8> :call BuildRTags()<CR>
  vnoremap <buffer> <F8> <Esc>:call BuildRTags()<CR>
  inoremap <buffer> <F8> <Esc>:call BuildRTags()<CR>i
endif

" Stop R process
if hasmapto('<Plug>RStop')
  noremap <buffer> <Plug>RStop :call SignalToR("INT")<CR>
  vnoremap <buffer> <Plug>RStop <Esc>:call SignalToR("INT")<CR>
  inoremap <buffer> <Plug>RStop <Esc>:call SignalToR("INT")<CR>i
else
  noremap <buffer> <F6> :call SignalToR("INT")<CR>
  vnoremap <buffer> <F6> <Esc>:call SignalToR("INT")<CR>
  inoremap <buffer> <F6> <Esc>:call SignalToR("INT")<CR>i
endif

" Kill R process
if hasmapto('<Plug>RKill')
  noremap <buffer> <Plug>RKill :call SignalToR("TERM")<CR>
  vnoremap <buffer> <Plug>RKill <Esc>:call SignalToR("TERM")<CR>
  inoremap <buffer> <Plug>RKill <Esc>:call SignalToR("TERM")<CR>i
else
  noremap <buffer> <F7> :call SignalToR("TERM")<CR>
  vnoremap <buffer> <F7> <Esc>:call SignalToR("TERM")<CR>
  inoremap <buffer> <F7> <Esc>:call SignalToR("TERM")<CR>i
endif

" Send line under cursor to R
if hasmapto('<Plug>RSendLine')
  noremap <buffer> <Plug>RSendLine :call SendLineToR(1)<CR>0
  vnoremap <buffer> <Plug>RSendLine <Esc>:call SendLineToR(1)<CR>0
  inoremap <buffer> <Plug>RSendLine <Esc>:call SendLineToR(1)<CR>0i
else
  noremap <buffer> <F9> :call SendLineToR(1)<CR>0
  inoremap <buffer> <F9> <Esc>:call SendLineToR(1)<CR>0i
endif

" Send block of lines to R
if hasmapto('<Plug>RSendBlock')
  vnoremap <buffer> <Plug>RSendBlock <Esc>:call SendBlockToR()<CR>
else
  vnoremap <buffer> <F9> <Esc>:call SendBlockToR()<CR>0
endif

" For compatibility with original plugin
if exists("g:vimrplugin_map_r")
  vnoremap <buffer> r <Esc>:call SendBlockToR()<CR>
endif


" Send function which the cursor is in
if hasmapto('<Plug>RSendFunction')
  noremap <buffer> <Plug>RSendFunction :call SendFunctionToR()<CR>
  vnoremap <buffer> <Plug>RSendFunction <Esc>:call SendFunctionToR()<CR>
  inoremap <buffer> <Plug>RSendFunction <Esc>:call SendFunctionToR()<CR>i
else
  noremap <buffer> <C-F9> :call SendFunctionToR()<CR>
  vnoremap <buffer> <C-F9> <Esc>:call SendFunctionToR()<CR>
  inoremap <buffer> <C-F9> <Esc>:call SendFunctionToR()<CR>i
endif

" Write and process mode (somehow mapping <C-Enter> does not work)
if hasmapto('<Plug>RSendLineAndOpenNewOne')
  inoremap <buffer> <Plug>RSendLineAndOpenNewOne <Esc>:call SendLineToR(0)<CR>o
else
  inoremap <buffer> <S-Enter> <Esc>:call SendLineToR(0)<CR>o
endif

" Send current file to R
if hasmapto('<Plug>RSendFile')
  noremap <buffer> <Plug>RSendFile :call SendFileToR()<CR>
  vnoremap <buffer> <Plug>RSendFile <Esc>:call SendFileToR()<CR>
  inoremap <buffer> <Plug>RSendFile <Esc>:call SendFileToR()<CR>a
else
  noremap <buffer> <F5> :call SendFileToR()<CR>
  vnoremap <buffer> <F5> <Esc>:call SendFileToR()<CR>
  inoremap <buffer> <F5> <Esc>:call SendFileToR()<CR>a
endif

" Call R function args()
if hasmapto('<Plug>RShowArgs')
  noremap <buffer> <Plug>RShowArgs :call RHelp("a")<CR>
  vnoremap <buffer> <Plug>RShowArgs <Esc>:call RHelp("a")<CR>
  inoremap <buffer> <Plug>RShowArgs <Esc>:call RHelp("a")<CR>a
else
  noremap <buffer> <S-F1> :call RHelp("a")<CR>
  vnoremap <buffer> <S-F1> <Esc>:call RHelp("a")<CR>
  inoremap <buffer> <S-F1> <Esc>:call RHelp("a")<CR>a
endif

" Call R function help()
if hasmapto('<Plug>RHelp')
  noremap <buffer> <Plug>RHelp :call RHelp("h")<CR>
  vnoremap <buffer> <Plug>RHelp <Esc>:call RHelp("h")<CR>
  inoremap <buffer> <Plug>RHelp <Esc>:call RHelp("h")<CR>a
else
  noremap <buffer> <C-H> :call RHelp("h")<CR>
  vnoremap <buffer> <C-H> <Esc>:call RHelp("h")<CR>
  inoremap <buffer> <C-H> <Esc>:call RHelp("h")<CR>a
endif

" Replace "underline" with " <- "
imap <buffer> _ <Esc>:call ReplaceUnderS()<CR>a

function! MakeRMenu()
  if b:hasrmenu == 1
    return
  endif
  if hasmapto('<Plug>RStart')
    amenu &R.Start\ &R :call StartR("R", "click")<CR>
  else
    amenu &R.Start\ &R<Tab><F2> :call StartR("R", "click")<CR>
  endif
  if hasmapto('<Plug>RStart-dev')
    amenu R.Start\ R-&devel :call StartR("R-devel", "click")<CR>
  else
    amenu R.Start\ R-&devel<Tab><F3> :call StartR("R-devel", "click")<CR>
  endif
  if hasmapto('<Plug>RStart-vanilla')
    amenu R.Start\ R\ --&vanilla :call StartR("R --vanilla", "click")<CR>
  else
    amenu R.Start\ R\ --&vanilla<Tab><F4> :call StartR("R --vanilla", "click")<CR>
  endif
  menu R.-Sep1- <nul>
  if hasmapto('<Plug>RSendLine')
    amenu R.Send\ &line :call SendLineToR(1)<CR>0
    imenu R.Send\ &line <Esc>:call SendLineToR(1)<CR>0a
  else
    amenu R.Send\ &line<Tab><F9> :call SendLineToR(1)<CR>0
    imenu R.Send\ &line<Tab><F9> <Esc>:call SendLineToR(1)<CR>0a
  endif
  if hasmapto('<Plug>RSendBlock')
    vmenu R.Send\ &selected\ lines :call SendBlockToR()<CR>0
  else
    vmenu R.Send\ &selected\ lines<Tab><F9> :call SendBlockToR()<CR>0
  endif
  if hasmapto('<Plug>RSendFunction')
    amenu R.Send\ current\ &function :call SendFunctionToR()<CR>
    imenu R.Send\ current\ &function <Esc>:call SendFunctionToR()<CR>
  else
    amenu R.Send\ current\ &function<Tab><C-F9> :call SendFunctionToR()<CR>
    imenu R.Send\ current\ &function<Tab><C-F9> <Esc>:call SendFunctionToR()<CR>
  endif
  if hasmapto('<Plug>RSendLineAndOpenNewOne')
    imenu R.Send\ line\ and\ &open\ a\ new\ one <Esc>:call SendLineToR(0)<CR>o
  else
    imenu R.Send\ line\ and\ &open\ a\ new\ one<Tab><S-Enter> <Esc>:call SendLineToR(0)<CR>o
  endif
  if hasmapto('<Plug>RSendFile')
    amenu R.Send\ &file :call SendFileToR()<CR>
  else
    amenu R.Send\ &file<Tab><F5> :call SendFileToR()<CR>
  endif
  menu R.-Sep2- <nul>
  if hasmapto('<Plug>RShowArgs')
    amenu R.Run\ &args() :call RHelp("a")<CR>
  else
    amenu R.Run\ &args()<Tab><S-F1> :call RHelp("a")<CR>
  endif
  if hasmapto('<Plug>RHelp')
    amenu R.Run\ &help() :call RHelp("h")<CR>
  else
    amenu R.Run\ &help()<Tab><C-H> :call RHelp("h")<CR>
  endif
  if hasmapto('<Plug>RBuildTags')
    amenu R.Rebuild\ list\ of\ objects :call BuildRTags()<CR>
  else
    amenu R.Rebuild\ list\ of\ objects<Tab><F8> :call BuildRTags()<CR>
  endif
  amenu R.About\ the\ plugin :help vim-r-plugin<CR>
  menu R.-Sep3- <nul>
  if hasmapto('<Plug>RStop')
    amenu R.Stop\ R :call SignalToR("INT")<CR>
  else
    amenu R.Stop\ R<Tab><F6> :call SignalToR("INT")<CR>
  endif
  if hasmapto('<Plug>RKill')
    amenu R.Kill\ R :call SignalToR("TERM")<CR>
  else
    amenu R.Kill\ R<Tab><F7> :call SignalToR("TERM")<CR>
  endif
  amenu icon=rstart ToolBar.RStart :call StartR("R", "click")<CR>
  amenu icon=rline ToolBar.RLine :call SendLineToR(1)<CR>
  amenu icon=rregion ToolBar.RRegion :call SendBlockToR()<CR>
  amenu icon=rfunction ToolBar.RFunction :call SendFunctionToR()<CR>
  amenu icon=rcomplete ToolBar.RTags :call BuildRTags()<CR>
  tmenu ToolBar.RStart Start R
  tmenu ToolBar.RLine Send current line to R
  tmenu ToolBar.RRegion Send selected lines to R
  tmenu ToolBar.RFunction Send current function to R
  tmenu ToolBar.RTags Rebuild list of objects
  if b:hastoolbarkill
    amenu icon=rstop ToolBar.RStop :call SignalToR("INT")<CR>
    amenu icon=rkill ToolBar.RKill :call SignalToR("TERM")<CR>
    tmenu ToolBar.RStop Stop R process
    tmenu ToolBar.RKill Kill R process
  endif
  let b:hasrmenu = 1
endfunction

function! UnMakeRMenu()
  if b:hasrmenu == 0
    return
  endif
  aunmenu R
  if b:hastoolbarkill
    aunmenu ToolBar.RKill
    aunmenu ToolBar.RStop
  endif
  aunmenu ToolBar.RTags
  aunmenu ToolBar.RRegion
  aunmenu ToolBar.RFunction
  aunmenu ToolBar.RLine
  aunmenu ToolBar.RStart
  let b:hasrmenu = 0
endfunction

augroup RStatMenu
  au BufEnter * if &filetype == "r" | call MakeRMenu() | endif
  au BufLeave * if &filetype == "r" | call UnMakeRMenu() | endif
augroup END

