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

let g:rplugin_lastft = &filetype

if !exists("g:SendCmdToR")
    let g:SendCmdToR = function('SendCmdToR_fake')
endif

" Were new libraries loaded by R?
if !exists("b:rplugin_new_libs")
    let b:rplugin_new_libs = 0
endif
" When using as a global plugin for non R files, RCheckLibList will not exist
if exists("*RCheckLibList")
    autocmd BufEnter <buffer> call RCheckLibList()
endif

