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
" Last Change: Fri Feb 17, 2012  08:38AM
"
" Please see doc/r-plugin.txt for usage details.
"==========================================================================

" Only do this when not yet done for this buffer
if exists("b:did_r_ftplugin") || exists("disable_r_ftplugin")
    finish
endif

" Don't load another plugin for this buffer
let b:did_r_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

" Don't do this if called by ../r-plugin/global_r_plugin.vim
if &filetype == "r"
    setlocal commentstring=#%s
    setlocal comments=b:#,b:##,b:###
endif

" Source scripts common to R, Rnoweb, Rhelp and rdoc files:
runtime r-plugin/common_global.vim
if exists("g:rplugin_failed")
    finish
endif

" Some buffer variables common to R, Rnoweb, Rhelp and rdoc files need be
" defined after the global ones:
runtime r-plugin/common_buffer.vim

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
    if has("win32") | has("win64")
        let rcmd = 'Rcmd.exe BATCH --no-restore --no-save "' . expand("%") . '" "' . routfile . '"'
    else
        let rcmd = b:rplugin_R . " CMD BATCH --no-restore --no-save '" . expand("%") . "' '" . routfile . "'"
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


"==========================================================================
" Key bindings and menu items

call RCreateStartMaps()
call RCreateEditMaps()

" Only .R files are sent to R
call RCreateMaps("ni", '<Plug>RSendFile',     'aa', ':call SendFileToR("silent")')
call RCreateMaps("ni", '<Plug>RESendFile',    'ae', ':call SendFileToR("echo")')
call RCreateMaps("ni", '<Plug>RShowRout',     'ao', ':call ShowRout()')

call RCreateSendMaps()
call RControlMaps()
call RCreateMaps("nvi", '<Plug>RSetwd',        'rd', ':call RSetWD()')

" Sweave (cur file)
"-------------------------------------
if &filetype == "rnoweb"
    call RCreateMaps("nvi", '<Plug>RSweave',      'sw', ':call RSweave()')
    call RCreateMaps("nvi", '<Plug>RMakePDF',     'sp', ':call RMakePDF("nobib")')
    call RCreateMaps("nvi", '<Plug>RIndent',      'si', ':call RnwToggleIndentSty()')
endif


" Menu R
if has("gui_running")
    call MakeRMenu()
endif

let &cpo = s:cpo_save
unlet s:cpo_save

