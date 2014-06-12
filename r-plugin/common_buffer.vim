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
" Please see doc/r-plugin.txt for usage details.
"==========================================================================


" Set completion with CTRL-X CTRL-O to autoloaded function.
if exists('&ofu')
    if &filetype == "r" || &filetype == "rnoweb" || &filetype == "rdoc" || &filetype == "rhelp" || &filetype == "rrst" || &filetype == "rmd"
        setlocal omnifunc=rcomplete#CompleteR
    endif
endif

" This isn't the Object Browser running externally
let b:rplugin_extern_ob = 0

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

if exists("g:rplugin_firstbuffer") && g:rplugin_firstbuffer == ""
    " The file global_r_plugin.vim was copied to ~/.vim/plugin
    let g:rplugin_firstbuffer = expand("%:p")
endif

let g:rplugin_lastft = &filetype

if !exists("g:SendCmdToR")
    let g:SendCmdToR = function('SendCmdToR_fake')
endif

if !has("neovim")
    if &filetype != "rbrowser"
        if v:servername == "" || has("gui_macvim")
            autocmd CursorHold <buffer> call RCheckLibListFile()
        else
            if &filetype != "r"
                autocmd CursorMoved <buffer> call RCheckLibList()
                if g:vimrplugin_insert_mode_cmds == 1
                    autocmd CursorMovedI <buffer> call RCheckLibList()
                endif
            endif
        endif
    endif
endif



