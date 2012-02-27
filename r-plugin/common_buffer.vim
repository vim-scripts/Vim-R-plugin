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
" Last Change: Mon Feb 27, 2012  12:45PM
"
" Please see doc/r-plugin.txt for usage details.
"==========================================================================


" Set completion with CTRL-X CTRL-O to autoloaded function.
if exists('&ofu')
  setlocal ofu=rcomplete#CompleteR
endif

" Automatically rebuild the file listing .GlobalEnv objects for omni
" completion if the user press <C-X><C-O> and we know that the file either was
" not created yet or is outdated.
let b:needsnewomnilist = 0

" Set the name of the Object Browser caption if not set yet
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
if (g:vimrplugin_by_vim_instance || g:vimrplugin_nosingler == 0) && exists("g:rplugin_objbrtitle")
  if g:vimrplugin_conqueplugin
    let b:conqueshell = g:rplugin_conqueshell
    let b:conque_bufname = g:rplugin_conque_bufname
  endif
  let b:objbrtitle = g:rplugin_objbrtitle
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

" Special screenrc file
let b:scrfile = " "

if g:vimrplugin_nosingler == 1
  " Make a random name for the screen session
  let b:screensname = "vimrplugin-" . g:rplugin_userlogin . "-" . localtime()
else
  " Make a unique name for the screen session
  let b:screensname = "vimrplugin-" . g:rplugin_userlogin
endif

" Make a unique name for the screen process for each Vim instance:
if g:vimrplugin_by_vim_instance == 1
  let s:sname = substitute(v:servername, " ", "-", "g")
  if s:sname == "" && g:vimrplugin_conqueplugin == 0
    call RWarningMsg("The option vimrplugin_by_vim_instance requires a servername. Please read the documentation.")
    let g:vimrplugin_by_vim_instance = 0
    sleep 2
  else
    " For screen GVIM and GVIM1 are the same string.
    let s:sname = substitute(s:sname, "GVIM$", "GVIM0", "g")
    let b:screensname = "vimrplugin-" . g:rplugin_userlogin . "-" . s:sname
  endif
  unlet s:sname
endif

if g:rplugin_firstbuffer == ""
    " The file global_r_plugin.vim was copied to ~/.vim/plugin
    let g:rplugin_firstbuffer = expand("%:p")
endif

if g:vimrplugin_screenplugin
    let s:uniquename = b:screensname . g:rplugin_firstbuffer
else
    let s:uniquename = b:screensname
endif
let s:uniquename = substitute(s:uniquename, '\W', '', 'g')
let $VIMINSTANCEID = $VIMRPLUGIN_TMPDIR . "/" . s:uniquename . "-port"
unlet s:uniquename

let g:rplugin_lastft = &filetype

