" ftplugin for R files
"
" Author: Iago Mosqueira <i.mosqueira@ic.ac.uk>
" Author: Johannes Ranke <jranke@uni-bremen.de>
" Author: Fernando Henrique Ferraz Pereira da Rosa <feferraz@ime.usp.br>
" Author: Johannes Ranke <jranke@uni-bremen.de>
" Maintainer: Jakson Alves de Aquino <jalvesaq@gmail.com>
" Last Change: 2009 Aug
"
" Functions added by Jakson Alves de Aquino:
"   GetFirstChar(), GoDown(), SendLineToR(), SendBlockToR(),
"   SendFileToR(), SendFunctionToR(), RHelp(), BuildRTags(), StartR(),
"   ReplaceUnderS(), MakeRMenu() and UnMakeRMenu().
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
  sleep 3
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
  sleep 4
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

" Automatically source the script tools/rargs.R the first time <S-F1> is
" pressed:
let b:needsrargs = 1

" Make the R 'tags' file name
let b:rtagsfile = printf("/tmp/.Rtags-%s", userlogin)

if exists("g:vimrplugin_single_r")
  " Make a unique name for the screen session
  let b:screensname = printf("vimrplugin-%s", userlogin)
else
  " Make a random name for the screen session
  let b:screensname = printf("vimrplugin-%s-%s", userlogin, localtime())
endif

" Set completion with CTRL-X CTRL-O to autoloaded function.
if exists('&ofu')
  setlocal ofu=rcomplete#CompleteR
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" From the original plugin:
" Set tabstop so it is compatible with the emacs edited code. Personally, I
" prefer shiftwidth=2, which I have in my .vimrc anyway
" set expandtab
" set shiftwidth=4
" set tabstop=8
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! SendCmdToScreen(cmd)
  if a:cmd =~ "library"
    let b:needsnewtags = 1
  endif
  let str = substitute(a:cmd, "'", "'\\\\''", "g")
  let scmd = 'screen -S ' . b:screensname . " -X stuff '" . str . "'"
  let rlog = system(scmd)
  if rlog != ""
    call RWarningMsg(rlog)
    return
  endif
endfunction

function! SendLinesToScreen(lines)
  for str in a:lines
    call SendCmdToScreen(str)
  endfor
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
  echon
  let line = getline(".")
  call SendCmdToScreen(line)
  if a:godown
    call GoDown()
  endif
endfunction


" Send visually selected lines.
function! SendBlockToR()
  echon
  if line("'<") == line("'>")
    call RWarningMsg("No block selected.")
    return
  endif
  let lines = getline("'<", "'>")
  call SendLinesToScreen(lines)
  call GoDown()
endfunction

function! CountBraces(line)
  let line2 = substitute(a:line, "{", "", "g")
  let line3 = substitute(a:line, "}", "", "g")
  let result = strlen(line3) - strlen(line2)
  return result
endfunction

function! SendFunctionToR()
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
  call SendLinesToScreen(lines)
endfunction

function! SendFileToR()
  echon
  let lines = getline("1", line("$"))
  call SendLinesToScreen(lines)
endfunction

" Call args() for the word under cursor
function! RHelp(type)
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
  while i > 0 && line[i] != ' ' && line[i] != '('
    let i -= 1
  endwhile
  let llen = strlen(line)
  if i < (llen - 1) && (line[i] == ' ' || line[i] == '(')
    let i += 1
  endif
  let kstart = i
  while i < llen && line[i] != ' ' && line[i] != '('
    let i += 1
  endwhile
  let rkeyword = strpart(line, kstart, i - kstart)
  if strlen(rkeyword) > 0
    if a:type == "a"
      if b:needsrargs
        let b:needsrargs = 0
        call SendCmdToScreen('source("~/.vim/tools/rargs.R")')
      endif
      let rhelpcmd = printf("vim.list.args('%s')", rkeyword)
    else
      if b:needshstart == 1
	let b:needshstart = 0
        call SendCmdToScreen("help.start()")
        let wt = g:vimrplugin_browser_time
        while wt > 0
          sleep
	  let wt -= 1
        endwhile
      endif
      let rhelpcmd = printf("help('%s')", rkeyword)
    endif
    call SendCmdToScreen(rhelpcmd)
  endif
endfunction

" Tell R to create a 'tags' file (/tmp/.Rtags-user-time) listing all currently
" available objects in its environment. The file is necessary omni completion.
function! BuildRTags()
  let tagscmd = printf(".vimtagsfile <- \"%s\"", b:rtagsfile)
  call SendCmdToScreen(tagscmd)
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

function! StartR(whatr, kbdclk)
  if exists("g:vimrplugin_noscreenrc")
    let srcfile = " "
  else
    let scrfile = "/tmp/." . b:screensname . ".screenrc"
    if exists("g:vimrplugin_single_r")
      let scrtitle = "hardstatus string R"
    else
      let scrtitle = 'hardstatus string "' . expand("%:t") . '"'
    endif
    let scrtxt = ["hardstatus lastline", scrtitle, "caption splitonly", 'caption string "Vim-R-plugin"', "termcapinfo xterm* 'ti@:te@'"]
    call writefile(scrtxt, scrfile)
    let scrfile = "-c " . scrfile
  endif
  " Some terminals want quotes (see screen.vim)
  if b:term_cmd =~ "gnome-terminal" || b:term_cmd =~ "xfce4-terminal"
    let opencmd = printf("%s 'screen %s -d -RR -S %s %s' &", b:term_cmd, scrfile, b:screensname, a:whatr)
  else
    let opencmd = printf("%s screen %s -d -RR -S %s %s &", b:term_cmd, scrfile, b:screensname, a:whatr)
  endif

  " Change to buffer's directory, run R, and go back to original directory:
  lcd %:p:h
  let rlog = system(opencmd)
  lcd -

  if rlog != ""
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

" Start a listening R --vanilla interpreter in new xterm
if hasmapto('<Plug>RvanillaStart')
  noremap <buffer> <Plug>RvanillaStart :call StartR("R --vanilla", "kbd")<CR>
  vnoremap <buffer> <Plug>RvanillaStart <Esc>:call StartR("R --vanilla", "kbd")<CR>
  inoremap <buffer> <Plug>RvanillaStart <Esc>:call StartR("R --vanilla", "kbd")<CR>a
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
if hasmapto('<Plug>RSendLAndOpenNewOne')
  inoremap <buffer> <Plug>RSendLAndOpenNewOne <Esc>:call SendLineToR(0)<CR>o
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
if b:replace_us
  imap <buffer> _ <Esc>:call ReplaceUnderS()<CR>a
endif


function! MakeRMenu()
  if b:hasrmenu == 1
    return
  endif
  if hasmapto('<Plug>RStart')
    amenu &R.Start\ &R :call StartR("R", "click")<CR>
  else
    amenu &R.Start\ &R<Tab><F2> :call StartR("R", "click")<CR>
  endif
  if hasmapto('<Plug>RvanillaStart')
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
  if hasmapto('<Plug>RSendLAndOpenNewOne')
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
  let b:hasrmenu = 1
endfunction

function! UnMakeRMenu()
  if b:hasrmenu == 0
    return
  endif
  aunmenu R
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

