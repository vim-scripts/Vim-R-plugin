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
"   CheckRpipe(), GetFirstChar(lin), GoDown(), SendLinesToR(), SendBlockToR(),
"   SendFileToR(), RHelp(), BuildRTags(), StartR(whatr, kbdclk), SignalToR(),
"   ReplaceUnderS(), AboutRPlugin(), MakeRMenu() and UnMakeRMenu().
"
" Code written in vim is sent to R through a perl pipe [funnel.pl, by Larry
" Clapp <vim@theclapp.org> (modifiedy by Jakson Aquino and renamed to
" rfunnel.pl)], as individual lines, blocks, or the whole file.

" Press <F2> to open a new xterm with a new R interpreter listening
" to its standard input (you can type R commands into the xterm)
" as well as to code pasted from within vim.
"
" In insert mode, <S-Enter> sends the active line to R and moves to the next
" line (write and process mode).
"
" Maps:
"       <F1>       Run R args() with word under cursor as parameter
"       <F2>	   Start a listening R interpreter in new xterm
"       <F3>	   Start a listening R-devel interpreter in new xterm
"       <F4>	   Start a listening R --vanilla interpreter in new xterm
"       <F5>       Run current file
"       <F6>       Stop R
"       <F7>	   Kill R
"       <F8>	   Build tags file (/tmp/.Rtags-user) for <C-X><C-O>
"       <F9>       Run line under cursor or selected blocks and go to next line
"       	   of code
"       <S-Enter>  Write and process

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
  while i < lastLine && (fc == '#' || len(curline) == 0)
    let i = i + 1
    call cursor(i, 1)
    let curline = getline(i)
    let fc = GetFirstChar(curline)
  endwhile
endfunction

" Send current line or block of lines (the function is called recursively when
" more multiple line are selected and the mouse is not used)
" Don't go down if called by <S-Enter>.
function! SendLinesToR(godown)
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

" The above function doesn't work when using the mouse
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
  call writefile(lines, b:pipefname)
  call GoDown()
endfunction

function! SendFileToR()
  if CheckRpipe()
    return
  endif
  echon
  let thelines = getline("1", line("$"))
  call writefile(thelines, b:pipefname)
endfunction

" Call args() for the word under cursor
function! RHelp()
  if CheckRpipe()
    return
  endif
  echon
  let rkeyword = expand("<cword>")
  let rhelpcmd = printf("args('%s')", rkeyword)
  call writefile([rhelpcmd], b:pipefname)
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
  "let opencmd = printf("gnome-terminal -t R -x ~/.vim/tools/rfunnel.pl %s \"%s\"&", b:pipefname, a:whatr)
  let opencmd = printf("uxterm -T 'R' -e ~/.vim/tools/rfunnel.pl %s \"%s && echo -e 'Interpreter has finished. Exiting. Goodbye.'\"&", b:pipefname, a:whatr)
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
  let isString = 0
  while j >= 0
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
    execute "normal a <- "
  else
    put = '_'
    execute "normal kgJ"
  endif
endfunction

" Start a listening R interpreter in new xterm
noremap <buffer> <F2> :call StartR("R", "kbd")<CR>
inoremap <buffer> <F2> <Esc>:call StartR("R", "kbd")<CR>a
" Avoid that N terminal windows are opened when there are N lines selected:
vnoremap <buffer> <F2> <Esc>:call StartR("R", "kdb")<CR>

" Start a listening R-devel interpreter in new xterm
noremap <buffer> <F3> :call StartR("R-devel", "kbd")<CR>
inoremap <buffer> <F3> <Esc>:call StartR("R-devel", "kbd")<CR>a
vnoremap <buffer> <F3> <Esc>:call StartR("R-devel", "kbd")<CR>

" Start a listening R --vanilla interpreter in new xterm
noremap <buffer> <F4> :call StartR("R --vanilla", "kbd")<CR>
inoremap <buffer> <F4> <Esc>:call StartR("R --vanilla", "kbd")<CR>a
vnoremap <buffer> <F4> <Esc>:call StartR("R --vanilla", "kbd")<CR>

" Send line under cursor to R
noremap <buffer> <F8> :call BuildRTags()<CR>
inoremap <buffer> <F8> <Esc>:call BuildRTags()<CR>i

" Kill R process
noremap <buffer> <F6> :call SignalToR("INT")<CR>
inoremap <buffer> <F6> <Esc>:call SignalToR("INT")<CR>i

" Kill R process
noremap <buffer> <F7> :call SignalToR("TERM")<CR>
inoremap <buffer> <F7> <Esc>:call SignalToR("TERM")<CR>i

" Send line under cursor to R
noremap <buffer> <F9> :call SendLinesToR(1)<CR>0
inoremap <buffer> <F9> <Esc>:call SendLinesToR(1)<CR>0i
" vnoremap <buffer> <F9> :call SendBlockToR(1)<CR>0

" Write and process mode (somehow mapping <C-Enter> does not work)
inoremap <S-Enter> <Esc>:call SendLinesToR(0)<CR>o

" Send block of lines (for compatibility with original plugin)
if exists("g:vimrplugin_map_r")
  vnoremap <buffer> r :call SendBlockToR(1)<CR>
endif

" Send current file to R
noremap <buffer> <F5> :call SendFileToR()<CR>
inoremap <buffer> <F5> <Esc>:call SendFileToR()<CR>a

" Call R function args()
noremap <buffer> <F1> :call RHelp()<CR>
inoremap <buffer> <F1> <Esc>:call RHelp()<CR>a

" Replace "underline" with " <- "
imap <buffer> _ <Esc>:call ReplaceUnderS()<CR>a

function! AboutRPlugin()
  redraw
  echo "\nKnown bugs:\n\nIf you press <C-C> in the xterm window the terminal will close but R will not be killed.  If this happens or if you want to kill R because it is taking too much time to finish a process, would may try the button 'Kill R process' or press <F7>. If this does not work, you will have to find the PID of R and kill it manually."
endfunction

function! MakeRMenu()
  if b:hasrmenu == 1
    return
  endif
  amenu &R.Start\ &R<Tab><F2> :call StartR("R", "click")<CR>
  amenu R.Start\ R-&devel<Tab><F3> :call StartR("R-devel", "click")<CR>
  amenu R.Start\ R\ --&vanilla<Tab><F4> :call StartR("R --vanilla", "click")<CR>
  menu R.-Sep1- <nul>
  amenu R.Send\ &lines<Tab><F9> :call SendLinesToR(1)<CR>0
  imenu R.Send\ &lines<Tab><F9> <Esc>:call SendLinesToR(1)<CR>0a
  amenu R.Send\ &selected\ lines<Tab><F9> :call SendBlockToR()<CR>0
  imenu R.Send\ &selected\ lines<Tab><F9> <Esc>:call SendBlockToR()<CR>0
  imenu R.Send\ line\ and\ &open\ a\ new\ one<Tab><S-Enter> <Esc>:call SendLinesToR(0)<CR>o
  amenu R.Send\ &file<Tab><F5> :call SendFileToR()<CR>
  menu R.-Sep2- <nul>
  amenu R.Run\ &args()<Tab><F1> :call RHelp()<CR>
  amenu R.Rebuild\ list\ of\ objects<Tab><F8> :call BuildRTags()<CR>
  amenu R.About\ the\ plugin :call AboutRPlugin()<CR>
  menu R.-Sep3- <nul>
  amenu R.Stop\ R<Tab><F6> :call SignalToR("INT")<CR>
  amenu R.Kill\ R<Tab><F7> :call SignalToR("TERM")<CR>
  amenu icon=rstart ToolBar.RStart :call StartR("R", "click")<CR>
  amenu icon=rline ToolBar.RLine :call SendLinesToR(1)<CR>
  amenu icon=rregion ToolBar.RRegion :call SendBlockToR()<CR>
  "amenu icon=rbuffer ToolBar.RBuffer :call SendFileToR()<CR>
  amenu icon=rcomplete ToolBar.RTags :call BuildRTags()<CR>
  tmenu ToolBar.RStart Start R
  tmenu ToolBar.RLine Send current line to R
  tmenu ToolBar.RRegion Send selected lines to R
  "tmenu ToolBar.RBuffer Send file to R
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
  endif
  aunmenu ToolBar.RTags
  "aunmenu ToolBar.RBuffer
  aunmenu ToolBar.RRegion
  aunmenu ToolBar.RLine
  aunmenu ToolBar.RStart
  let b:hasrmenu = 0
endfunction

augroup RStatMenu
  au BufEnter * if &filetype == "r" | call MakeRMenu() | endif
  au BufLeave * if &filetype == "r" | call UnMakeRMenu() | endif
augroup END


