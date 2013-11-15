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

" Only do this when not yet done for this buffer
if exists("b:did_rdoc_ftplugin") || exists("disable_r_ftplugin")
    finish
endif

" Don't load another plugin for this buffer
let b:did_rdoc_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

" Source scripts common to R, Rnoweb, Rhelp and rdoc files:
runtime r-plugin/common_global.vim

" Some buffer variables common to R, Rnoweb, Rhelp and rdoc file need be
" defined after the global ones:
runtime r-plugin/common_buffer.vim

setlocal iskeyword=@,48-57,_,.

" Prepare R documentation output to be displayed by Vim
function! FixRdoc()
    let lnr = line("$")
    for i in range(1, lnr)
        call setline(i, substitute(getline(i), "_\010", "", "g"))
        " A space after 'Arguments:' is necessary for correct syntax highlight
        " of the first argument
        call setline(i, substitute(getline(i), "^Arguments:", "Arguments: ", ""))
    endfor
    let has_ex = search("^Examples:$")
    if has_ex
        let lnr = line("$") + 1
        call setline(lnr, '###')
    endif
    normal! gg

    " Clear undo history
    let old_undolevels = &undolevels
    set undolevels=-1
    exe "normal a \<BS>\<Esc>"
    let &undolevels = old_undolevels
    unlet old_undolevels
endfunction

function! RdocIsInRCode(vrb)
    let exline = search("^Examples:$", "bncW")
    if exline > 0 && line(".") > exline
        return 1
    else
        if a:vrb
            call RWarningMsg('Not in the "Examples" section.')
        endif
        return 0
    endif
endfunction

"==========================================================================
" Key bindings and menu items

let b:IsInRCode = function("RdocIsInRCode")

call RCreateSendMaps()
call RControlMaps()

" Menu R
if has("gui_running")
    call MakeRMenu()
endif

call RSourceOtherScripts()

setlocal bufhidden=wipe
setlocal noswapfile
set buftype=nofile
autocmd VimResized <buffer> let g:vimrplugin_newsize = 1
call FixRdoc()
autocmd FileType rdoc call FixRdoc()

let &cpo = s:cpo_save
unlet s:cpo_save

