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
" Last Change: Sun Nov 07, 2010  11:52AM
"
" Please see doc/r-plugin.txt for usage details.
"==========================================================================

" Only do this when not yet done for this buffer
if exists("b:did_r_ftplugin") || exists("disable_r_ftplugin")
  finish
endif

" Don't load another plugin for this buffer
let b:did_r_ftplugin = 1

function! RWarningMsg(wmsg)
  echohl WarningMsg
  echomsg a:wmsg
  echohl Normal
endfunction

" Set completion with CTRL-X CTRL-O to autoloaded function.
if exists('&ofu')
  setlocal ofu=rcomplete#CompleteR
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

" Automatically rebuild the file listing .GlobalEnv objects for omni
" completion if the user press <C-X><C-O> and we know that the file either was
" not created yet or is outdated.
let b:needsnewomnilist = 0
let g:rplugin_globalenvlines = []

" From changelog.vim
let s:userlogin = system('whoami')
if v:shell_error
  let s:userlogin = 'unknown'
else
  let newuline = stridx(s:userlogin, "\n")
  if newuline != -1
    let s:userlogin = strpart(s:userlogin, 0, newuline)
  endif
  unlet newuline
endif

if has("gui_win32")
  let g:rplugin_jspath = g:rplugin_home . "\\r-plugin\\vimActivate.js"
  let g:rplugin_home = substitute(g:rplugin_home, "\\", "/", "g")
  let g:rplugin_uservimfiles = substitute(g:rplugin_uservimfiles, "\\", "/", "g")
  if !has("python")
    call RWarningMsg("Python interface must be enabled to run Vim-R-Plugin.")
    call RWarningMsg("Please do  ':h r-plugin-installation'  for details.")
    call input("Press <Enter> to continue. ")
    finish
  endif
  exe "source " . g:rplugin_home . "/r-plugin/rpython.vim"
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
      if isdirectory(b:rinstallpath . '\bin\i386')
	if !exists("g:vimrplugin_i386")
	  let g:vimrplugin_i386 = 0
	endif
	if !isdirectory(b:rinstallpath . '\bin\x64')
	  let g:vimrplugin_i386 = 1
	endif
	if g:vimrplugin_i386
	  let $PATH = b:rinstallpath . '\bin\i386;' . $PATH
	  let b:Rgui = b:rinstallpath . '\bin\i386\Rgui.exe'
	else
	  let $PATH = b:rinstallpath . '\bin\x64;' . $PATH
	  let b:Rgui = b:rinstallpath . '\bin\x64\Rgui.exe'
	endif
      else
	let $PATH = b:rinstallpath . '\bin;' . $PATH
	let b:Rgui = b:rinstallpath . '\bin\Rgui.exe'
      endif
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
call RSetDefaultValue("g:vimrplugin_rnowebchunk",  1)
call RSetDefaultValue("g:vimrplugin_screenvsplit", 0)
call RSetDefaultValue("g:vimrplugin_conquevsplit", 0)
call RSetDefaultValue("g:vimrplugin_listmethods",  0)
call RSetDefaultValue("g:vimrplugin_specialplot",  0)
call RSetDefaultValue("g:vimrplugin_nosingler",    0)
call RSetDefaultValue("g:vimrplugin_noscreenrc",   0)
call RSetDefaultValue("g:vimrplugin_routnotab",    0) 
call RSetDefaultValue("g:vimrplugin_editor_w",    66)
call RSetDefaultValue("g:vimrplugin_help_w",      46)
call RSetDefaultValue("g:vimrplugin_objbr_w",     40)
call RSetDefaultValue("g:vimrplugin_buildwait",  120)
call RSetDefaultValue("g:vimrplugin_by_vim_instance", 0)
call RSetDefaultValue("g:vimrplugin_never_unmake_menu", 0)
call RSetDefaultValue("g:vimrplugin_vimpager",       "'vertical'")
call RSetDefaultValue("g:vimrplugin_latexcmd", "'pdflatex'")
call RSetDefaultValue("g:vimrplugin_objbr_place", "'console,right'")

if isdirectory("/tmp")
  let $VIMRPLUGIN_TMPDIR = "/tmp/r-plugin-" . s:userlogin
else
  let $VIMRPLUGIN_TMPDIR = g:rplugin_uservimfiles . "/r-plugin"
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
  if has("python") && !exists("g:ConqueTerm_Version")
    call RWarningMsg("Please, install either the 'screen' application or the 'Conque Shell' plugin to enable the Vim-R-plugin.")
  else
    call RWarningMsg("Please, install the 'screen' application to enable the Vim-R-plugin.")
  endif
  call input("Press <Enter> to continue. ")
  finish
endif

let s:tnr = tabpagenr()
if !exists("b:objbrtitle")
  if s:tnr == 1
    let b:objbrtitle = "Object_Browser"
  else
    let b:objbrtitle = "Object_Browser" . s:tnr
  endif
  unlet s:tnr
endif

" Initialize some local variables if Conque shell was already started
if (vimrplugin_by_vim_instance || vimrplugin_nosingler == 0) && exists("g:the_objbrtitle")
  if g:vimrplugin_conqueplugin
    let b:conqueshell = g:the_conqueshell
    let b:conque_bufname = g:the_conque_bufname
  endif
  let b:objbrtitle = g:the_objbrtitle
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

if &filetype == "rnoweb"
  nmap <buffer> gn :call RnwNextChunk()<CR>
  nmap <buffer> gN :call RnwPreviousChunk()<CR>

  if g:vimrplugin_rnowebchunk == 1
    " Write code chunck in rnoweb files
    imap <buffer> < <Esc>:call RWriteChunk()<CR>a
  endif
endif

set commentstring=#%s

" Are we in a Debian package? Is the plugin being running for the first time?
let g:rplugin_omnifname = g:rplugin_uservimfiles . "/r-plugin/omni_list"
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

  " If there is no omni_list, copy the default one
  if !filereadable(g:rplugin_omnifname)
    if filereadable("/usr/share/vim/addons/r-plugin/omni_list")
      let omnilines = readfile("/usr/share/vim/addons/r-plugin/omni_list")
    else
      if filereadable(g:rplugin_home . "/r-plugin/omni_list")
	let omnilines = readfile(g:rplugin_home . "/r-plugin/omni_list")
      else
	let omnilines = []
      endif
    endif
    call writefile(omnilines, g:rplugin_omnifname)
    unlet omnilines
  endif
endif

" Minimum width for the object browser
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

" Special screenrc file
let b:scrfile = " "

" List of marks that the plugin seeks to find the block to be sent to R
let s:all_marks = "abcdefghijklmnopqrstuvwxyz"

" Create an empty file to avoid errors if the user do Ctrl-X Ctrl-O before
" starting R:
call writefile([], b:globalenvlistfile)

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
  finish
endif

if g:vimrplugin_term == "gnome-terminal" || g:vimrplugin_term == "xfce4-terminal"
  " Cannot set icon: http://bugzilla.gnome.org/show_bug.cgi?id=126081
  let b:term_cmd = g:vimrplugin_term . " --working-directory='" . expand("%:p:h") . "' --title R -e"
endif

if g:vimrplugin_term == "konsole"
  let b:term_cmd = "konsole --workdir '" . expand("%:p:h") . "' --icon " . g:rplugin_home . "/bitmaps/ricon.png -e"
endif

if g:vimrplugin_term == "Eterm"
  let b:term_cmd = "Eterm --icon " . g:rplugin_home . "/bitmaps/ricon.png -e"
endif

if g:vimrplugin_term == "rxvt" || g:vimrplugin_term == "aterm"
  let b:term_cmd = g:vimrplugin_term . " -e"
endif

if g:vimrplugin_term == "xterm" || g:vimrplugin_term == "uxterm"
  let b:term_cmd = g:vimrplugin_term . " -xrm '*iconPixmap: " . g:rplugin_home . "/bitmaps/ricon.xbm' -e"
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
  let s:sname = substitute(v:servername, " ", "-", "g")
  if s:sname == ""
    call RWarningMsg("The option vimrplugin_by_vim_instance requires a servername. Please read the documentation.")
    let g:vimrplugin_by_vim_instance = 0
    sleep 2
  else
    " For screen GVIM and GVIM1 are the same string.
    let s:sname = substitute(s:sname, "GVIM$", "GVIM0", "g")
    let b:screensname = "vimrplugin-" . s:userlogin . "-" . s:sname
  endif
  unlet s:sname
endif

function! RnwIsInRCode()
  let chunkline = search("^<<", "bncW")
  let docline = search("^@", "bncW")
  if chunkline > docline
    return 1
  else
    return 0
  endif
endif
endfunction

function! RWriteChunk()
  let line = getline(".")
  if line == "" && RnwIsInRCode() == 0
    exe "normal! i<<>>="
    exe "normal! o@"
    exe "normal! 0kl"
  else
    exe "normal! a<"
  endif
endfunction

function! ReplaceUnderS()
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
function! CountBraces(line)
  let line2 = substitute(a:line, "{", "", "g")
  let line3 = substitute(a:line, "}", "", "g")
  let result = strlen(line3) - strlen(line2)
  return result
endfunction

function! RnwPreviousChunk()
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

function! RnwNextChunk()
  echon
  let i = search("^<<.*$", "nW")
  if i == 0
    call RWarningMsg("There is no next R code chunk to go.")
  else
    call cursor(i+1, 1)
  endif
  return
endfunction

function! RnwOldNextChunk()
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
function! GoDown()
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
    if g:vimrplugin_conqueplugin == 0
      call StartRPy()
      return
    else
      let b:R = "Rterm.exe"
    endif
  endif

  if b:r_args == " "
    let rcmd = b:R
  else
    let rcmd = b:R . " " . b:r_args
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
      let g:the_conqueshell = b:conqueshell
      let g:the_conque_bufname = b:conque_bufname
      let g:the_objbrtitle = b:objbrtitle
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
  if g:vimrplugin_conqueplugin && !exists("b:conque_bufname")
    return
  endif

  " R builds the Object Browser contents.
  let lockfile = $VIMRPLUGIN_TMPDIR . "/objbrowser" . "lock"
  call writefile(["Wait!"], lockfile)
  call SendCmdToScreen("source('" . g:rplugin_home . "/r-plugin/vimbrowser.R')", 1)
  sleep 50m
  let i = 0 
  while filereadable(lockfile)
    let i = i + 1
    sleep 50m
    if i == 40
      call delete(lockfile)
      call RWarningMsg("No longer waiting for Object Browser to finish...")
      if exists("g:rplugin_r_ouput")
	echo g:rplugin_r_ouput
      endif
      sleep 2
      return
    endif
  endwhile

  let g:rplugin_origbuf = bufname("%")

  " Either load or reload the object browser
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
    setlocal winfixwidth

    set ft=rbrowser

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

function! RObjBrowserClose()
  if bufloaded(b:objbrtitle)
    exe "bunload " . b:objbrtitle
  endif
endfunction

" Scroll conque term buffer (called by CursorHold event)
function! RScrollTerm()
  "call RSetTimer()
  if &ft != "r" && &ft != "rnoweb" && &ft != "rhelp" && &ft != "rdoc"
    return
  endif
  if !exists("b:conque_bufname")
    return
  endif

  let savesb = &switchbuf
  set switchbuf=useopen,usetab
  exe "sil noautocmd sb " . b:conque_bufname

  normal! G0

  exe "sil noautocmd sb " . g:rplugin_curbuf
  exe "set switchbuf=" . savesb
endfunction

" Function to send commands
" return 0 on failure and 1 on success
function! SendCmdToScreen(cmd, quiet)
  if has("gui_win32") && g:vimrplugin_conqueplugin == 0
    call SendToRPy(a:cmd . "\n")
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

    " Code provided by Nico Raffo
    " use an aggressive sb option
    let savesb = &switchbuf
    set switchbuf=useopen,usetab

    " Is the Conque buffer hidden?
    if !bufloaded(substitute(b:conque_bufname, "\\", "", "g"))
      exe "set switchbuf=" . savesb
      call RWarningMsg("Could not find Conque Shell buffer.")
      return 0
    endif
      
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
    if a:quiet
      let g:rplugin_r_ouput = b:conqueshell.read(100, 0)
    else
      call b:conqueshell.read(100, 1)
    endif
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
    sleep 200m
    exe "sil bdelete " . b:conque_bufname
    unlet b:conque_bufname
    unlet b:conqueshell
  endif
  if bufloaded(b:objbrtitle)
    exe "bunload! " . b:objbrtitle
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
function! SendFunctionToR(e, m)
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
function! SendSelectionToR(e, m)
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
function! SendLineToR(godown)
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
  let ok = SendCmdToScreen(line, 0)
  if ok && a:godown =~ "down"
    call GoDown()
  endif
endfunction

" Clear the console screen
function! RClearConsole()
  if has("gui_win32") && g:vimrplugin_conqueplugin == 0
    call RClearConsolePy()
    silent exe '!start WScript "' . g:rplugin_jspath . '" "' . expand("%") . '"'
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

" Tell R to create a list of objects file listing all currently available
" objects in its environment. The file is necessary for omni completion.
function! BuildROmniList(env)
  if a:env =~ "GlobalEnv"
    let rtf = b:globalenvlistfile
    let b:needsnewomnilist = 0
  else
    let rtf = g:rplugin_omnifname
  endif
  let omnilistcmd = printf(".vimomnilistfile <- \"%s\"", rtf)
  let lockfile = rtf . ".locked"
  call writefile(["Wait!"], lockfile)
  let omnilistcmd = omnilistcmd . " ; " . 'source("' . g:rplugin_home . '/r-plugin/build_omni_list.R")'
  let ok = SendCmdToScreen(omnilistcmd, 1)
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
    let g:rplugin_globalenvlines = readfile(b:globalenvlistfile)
  endif
  if i > 2
    echon "\rFinished in " . i . " seconds."
  endif
endfunction

function! RBuildSyntaxFile()
  call BuildROmniList("libraries")
  sleep 1
  let g:rplugin_liblist = readfile(g:rplugin_omnifname)
  let res = []
  for line in g:rplugin_liblist
    if line =~ ':function:\|:standardGeneric:'
      let line = substitute(line, ':.*', "", "")
      let line = "syn keyword rFunction " . line
      call add(res, line)
    endif
  endfor
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

" Run R CMD BATCH on current file and load the resulting .Rout in a split
" window
function! ShowRout()
  let routfile = expand("%:r") . ".Rout"
  if bufloaded(routfile)
    exe "bunload " . routfile
    call delete(routfile)
  endif

  " if not silent, the user will have to type <Enter>
  silent update
  if has("gui_win32")
    let rcmd = 'Rcmd.exe BATCH --no-restore --no-save "' . expand("%") . '" "' . routfile . '"'
  else
    let rcmd = b:R . " CMD BATCH --no-restore --no-save '" . expand("%") . "' '" . routfile . "'"
  endif
  echo "Please wait for: " . rcmd
  let rlog = system(rcmd)
  if v:shell_error && rlog != ""
    call RWarningMsg('Error: "' . rlog . '"')
    sleep 1
  endif

  if filereadable(routfile)
    if g:vimrplugin_routnotab == 1
      exe "split " . routfile
    else
      exe "tabnew " . routfile
    endif
  else
    call RWarningMsg("The file '" . routfile . "' is not readable.")
  endif
endfunction

command! RUpdateObjList :call RBuildSyntaxFile()
command! RBuildTags :call SendCmdToScreen('rtags(ofile = "TAGS")', 0)

"----------------------------------------------------------------------------
" ***Start/Close***
"----------------------------------------------------------------------------
if &filetype != "rdoc"
  " Start
  "-------------------------------------
  call rplugin#RCreateMaps("nvi", '<Plug>RStart',        'rf', ':call StartR("R")')
  call rplugin#RCreateMaps("nvi", '<Plug>RVanillaStart', 'rv', ':call StartR("vanilla")')
  call rplugin#RCreateMaps("nvi", '<Plug>RCustomStart',  'rc', ':call StartR("custom")')

  " Close
  "-------------------------------------
  call rplugin#RCreateMaps("nvi", '<Plug>RClose',        'rq', ":call RQuit('nosave')")
  call rplugin#RCreateMaps("nvi", '<Plug>RSaveClose',    'rw', ":call RQuit('save')")
endif

"----------------------------------------------------------------------------
" ***Send*** (e=echo, d=down, a=all)
"----------------------------------------------------------------------------
" File
"-------------------------------------
if &filetype == "r"
  call rplugin#RCreateMaps("ni", '<Plug>RSendFile',     'aa', ':call SendFileToR("silent")')
  call rplugin#RCreateMaps("ni", '<Plug>RESendFile',    'ae', ':call SendFileToR("echo")')
  call rplugin#RCreateMaps("ni", '<Plug>RShowRout',     'ao', ':call ShowRout()')
endif

" Block
"-------------------------------------
call rplugin#RCreateMaps("ni", '<Plug>RSendMBlock',     'bb', ':call SendMBlockToR("silent", "stay")')
call rplugin#RCreateMaps("ni", '<Plug>RESendMBlock',    'be', ':call SendMBlockToR("echo", "stay")')
call rplugin#RCreateMaps("ni", '<Plug>RDSendMBlock',    'bd', ':call SendMBlockToR("silent", "down")')
call rplugin#RCreateMaps("ni", '<Plug>REDSendMBlock',   'ba', ':call SendMBlockToR("echo", "down")')

" Function
"-------------------------------------
call rplugin#RCreateMaps("nvi", '<Plug>RSendFunction',  'ff', ':call SendFunctionToR("silent", "stay")')
call rplugin#RCreateMaps("nvi", '<Plug>RDSendFunction', 'fe', ':call SendFunctionToR("echo", "stay")')
call rplugin#RCreateMaps("nvi", '<Plug>RDSendFunction', 'fd', ':call SendFunctionToR("silent", "down")')
call rplugin#RCreateMaps("nvi", '<Plug>RDSendFunction', 'fa', ':call SendFunctionToR("echo", "down")')

" Selection
"-------------------------------------
call rplugin#RCreateMaps("v0", '<Plug>RSendSelection',   'ss', ':call SendSelectionToR("silent", "stay")')
call rplugin#RCreateMaps("v0", '<Plug>RESendSelection',  'se', ':call SendSelectionToR("echo", "stay")')
call rplugin#RCreateMaps("v0", '<Plug>RDSendSelection',  'sd', ':call SendSelectionToR("silent", "down")')
call rplugin#RCreateMaps("v0", '<Plug>REDSendSelection', 'sa', ':call SendSelectionToR("echo", "down")')

" Paragraph
"-------------------------------------
call rplugin#RCreateMaps("ni", '<Plug>RSendParagraph',   'pp', ':call SendParagraphToR("silent", "stay")')
call rplugin#RCreateMaps("ni", '<Plug>RESendParagraph',  'pe', ':call SendParagraphToR("echo", "stay")')
call rplugin#RCreateMaps("ni", '<Plug>RDSendParagraph',  'pd', ':call SendParagraphToR("silent", "down")')
call rplugin#RCreateMaps("ni", '<Plug>REDSendParagraph', 'pa', ':call SendParagraphToR("echo", "down")')

" *Line*
"-------------------------------------
call rplugin#RCreateMaps("ni0", '<Plug>RSendLine', 'l', ':call SendLineToR("stay")')
call rplugin#RCreateMaps('ni0', '<Plug>RDSendLine', 'd', ':call SendLineToR("down")')

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
call rplugin#ControlMaps()

" Set working directory
"-------------------------------------
call rplugin#RCreateMaps("nvi", '<Plug>RSetwd',        'rd', ':call RSetWD()')

" Sweave (cur file)
"-------------------------------------
if &filetype == "rnoweb"
  call rplugin#RCreateMaps("nvi", '<Plug>RSweave',      'sw', ':call RSweave()')
  call rplugin#RCreateMaps("nvi", '<Plug>RMakePDF',     'sp', ':call RMakePDF()')
  call rplugin#RCreateMaps("nvi", '<Plug>RIndent',      'si', ':call RnwToggleIndentSty()')
endif

"----------------------------------------------------------------------------
" ***Debug***
"----------------------------------------------------------------------------
" Start debugging
"-------------------------------------
"call rplugin#RCreateMaps("nvi", '<Plug>RDebug', 'dd', ':call RStartDebug()')

" Menu R
function! MakeRMenu()
  if g:rplugin_hasmenu == 1 || !has("gui_running")
    return
  endif

  " Do not translate "File":
  menutranslate clear

  "----------------------------------------------------------------------------
  " Start/Close
  "----------------------------------------------------------------------------
  if &filetype != "rdoc"
    call rplugin#RCreateMenuItem("nvi", 'Start/Close.Start\ R\ (default)', '<Plug>RStart', 'rf', ':call StartR("R")')
    call rplugin#RCreateMenuItem("nvi", 'Start/Close.Start\ R\ --vanilla', '<Plug>RVanillaStart', 'rv', ':call StartR("vanilla")')
    call rplugin#RCreateMenuItem("nvi", 'Start/Close.Start\ R\ (custom)', '<Plug>RCustomStart', 'rc', ':call StartR("custom")')
    "-------------------------------
    menu R.Start/Close.-Sep1- <nul>
    call rplugin#RCreateMenuItem("nvi", 'Start/Close.Close\ R\ (no\ save)', '<Plug>RClose', 'rq', ":call SendCmdToScreen('quit(save = \"no\")', 0)")
    call rplugin#RCreateMenuItem("nvi", 'Start/Close.Close\ R\ (save\ workspace)', '<Plug>RSaveClose', 'rw', ":call SendCmdToScreen('quit(save = \"yes\")', 0)")
  endif

  "----------------------------------------------------------------------------
  " Send
  "----------------------------------------------------------------------------
  if &filetype == "r" || g:vimrplugin_never_unmake_menu
    call rplugin#RCreateMenuItem("ni", 'Send.File', '<Plug>RSendFile', 'aa', ':call SendFileToR("silent")')
    call rplugin#RCreateMenuItem("ni", 'Send.File\ (echo)', '<Plug>RESendFile', 'ae', ':call SendFileToR("echo")')
    call rplugin#RCreateMenuItem("ni", 'Send.File\ (open\ \.Rout)', '<Plug>RShowRout', 'ao', ':call ShowRout()')
  endif
  "-------------------------------
  menu R.Send.-Sep1- <nul>
  call rplugin#RCreateMenuItem("ni", 'Send.Block\ (cur)', '<Plug>RSendMBlock', 'bb', ':call SendMBlockToR("silent", "stay")')
  call rplugin#RCreateMenuItem("ni", 'Send.Block\ (cur,\ echo)', '<Plug>RESendMBlock', 'be', ':call SendMBlockToR("echo", "stay")')
  call rplugin#RCreateMenuItem("ni", 'Send.Block\ (cur,\ down)', '<Plug>RDSendMBlock', 'bd', ':call SendMBlockToR("silent", "down")')
  call rplugin#RCreateMenuItem("ni", 'Send.Block\ (cur,\ echo\ and\ down)', '<Plug>REDSendMBlock', 'ba', ':call SendMBlockToR("echo", "down")')
  "-------------------------------
  menu R.Send.-Sep2- <nul>
  call rplugin#RCreateMenuItem("ni", 'Send.Function\ (cur)', '<Plug>RSendFunction', 'ff', ':call SendFunctionToR("silent", "stay")')
  call rplugin#RCreateMenuItem("ni", 'Send.Function\ (cur,\ echo)', '<Plug>RESendFunction', 'fe', ':call SendFunctionToR("echo", "stay")')
  call rplugin#RCreateMenuItem("ni", 'Send.Function\ (cur\ and\ down)', '<Plug>RDSendFunction', 'fd', ':call SendFunctionToR("silent", "down")')
  call rplugin#RCreateMenuItem("ni", 'Send.Function\ (cur,\ echo\ and\ down)', '<Plug>REDSendFunction', 'fa', ':call SendFunctionToR("echo", "down")')
  "-------------------------------
  menu R.Send.-Sep3- <nul>
  call rplugin#RCreateMenuItem("v0", 'Send.Selection', '<Plug>RSendSelection', 'ss', ':call SendSelectionToR("silent", "stay")')
  call rplugin#RCreateMenuItem("v0", 'Send.Selection\ (echo)', '<Plug>RESendSelection', 'se', ':call SendSelectionToR("echo", "stay")')
  call rplugin#RCreateMenuItem("v0", 'Send.Selection\ (and\ down)', '<Plug>RDSendSelection', 'sd', ':call SendSelectionToR("silent", "down")')
  call rplugin#RCreateMenuItem("v0", 'Send.Selection\ (echo\ and\ down)', '<Plug>REDSendSelection', 'sa', ':call SendSelectionToR("echo", "down")')
  "-------------------------------
  menu R.Send.-Sep4- <nul>
  call rplugin#RCreateMenuItem("ni", 'Send.Paragraph', '<Plug>RSendParagraph', 'pp', ':call SendParagraphToR("silent", "stay")')
  call rplugin#RCreateMenuItem("ni", 'Send.Paragraph\ (echo)', '<Plug>RESendParagraph', 'pe', ':call SendParagraphToR("echo", "stay")')
  call rplugin#RCreateMenuItem("ni", 'Send.Paragraph\ (and\ down)', '<Plug>RDSendParagraph', 'pd', ':call SendParagraphToR("silent", "down")')
  call rplugin#RCreateMenuItem("ni", 'Send.Paragraph\ (echo\ and\ down)', '<Plug>REDSendParagraph', 'pa', ':call SendParagraphToR("echo", "down")')
  "-------------------------------
  menu R.Send.-Sep5- <nul>
  call rplugin#RCreateMenuItem("ni0", 'Send.Line', '<Plug>RSendLine', 'l', ':call SendLineToR("stay")')
  call rplugin#RCreateMenuItem("ni0", 'Send.Line\ (and\ down)', '<Plug>RDSendLine', 'd', ':call SendLineToR("down")')

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
  call rplugin#ControlMenu()
  "-------------------------------
  menu R.Control.-Sep5- <nul>
  call rplugin#RCreateMenuItem("nvi", 'Control.Set\ working\ directory\ (cur\ file\ path)', '<Plug>RSetwd', 'rd', ':call RSetWD()')
  if &filetype == "r" || &filetype == "rnoweb" || g:vimrplugin_never_unmake_menu
    nmenu R.Control.Build\ R\ tags\ file<Tab>:RBuildTags :call SendCmdToScreen('rtags(ofile = "TAGS")', 0)<CR>
    imenu R.Control.Build\ R\ tags\ file<Tab>:RBuildTags <Esc>:call SendCmdToScreen('rtags(ofile = "TAGS")', 0)<CR>
  endif
  "-------------------------------
  if &filetype == "rnoweb" || g:vimrplugin_never_unmake_menu
    menu R.Control.-Sep6- <nul>
    call rplugin#RCreateMenuItem("nvi", 'Control.Sweave\ (cur\ file)', '<Plug>RSweave', 'sw', ':call RSweave()')
    call rplugin#RCreateMenuItem("nvi", 'Control.Sweave\ and\ PDF\ (cur\ file)', '<Plug>RMakePDF', 'sp', ':call RMakePDF()')
    " call rplugin#RCreateMenuItem("ni", 'Control.Toggle\ indent\ style\ (R/LaTeX)', '<Plug>RIndent', 'si', ':call RnwToggleIndentSty()')
    nmenu R.Control.Go\ to\ next\ R\ chunk<Tab>gn :call RnwNextChunk()<CR>
    nmenu R.Control.Go\ to\ previous\ R\ chunk<Tab>gN :call RnwPreviousChunk()<CR>
  endif
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
  if &filetype != "rdoc"
    amenu ToolBar.RStart :call StartR("R")<CR>
    amenu ToolBar.RClose :call SendCmdToScreen('quit(save = "no")', 0)<CR>
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
  nmenu ToolBar.RListSpace :call SendCmdToScreen("ls()", 0)<CR>
  imenu ToolBar.RListSpace <Esc>:call SendCmdToScreen("ls()", 0)<CR>
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

function! UnMakeRMenu()
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

call MakeRMenu()

function! ROpenGraphicsDevice()
  call SendCmdToScreen('x11(title = "Vim-R-plugin Graphics", width = 3.5, height = 3.5, pointsize = 9, xpos = -1, ypos = 0)', 1)
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

function! RBufEnter()
  call MakeRMenu()
  let g:rplugin_curbuf = bufname("%")
endfunction

function! RBufLeave()
  call UnMakeRMenu()
endfunction

augroup VimRPlugin
  au FileType * if &filetype == "r" || &filetype == "rdoc" || &filetype == "rnoweb" || &filetype == "rhelp" | call MakeRMenu() | endif
  au BufEnter * if &filetype == "r" || &filetype == "rdoc" || &filetype == "rnoweb" || &filetype == "rhelp" | call RBufEnter() | endif
  au BufLeave * if &filetype == "r" || &filetype == "rdoc" || &filetype == "rnoweb" || &filetype == "rhelp" | call RBufLeave() | endif
augroup END

