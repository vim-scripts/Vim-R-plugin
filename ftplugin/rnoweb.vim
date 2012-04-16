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
" Last Change: Mon Apr 16, 2012  12:08AM
"==========================================================================

" Only do this when not yet done for this buffer
if exists("b:did_rnoweb_ftplugin") || exists("disable_r_ftplugin")
    finish
endif

" Don't load another plugin for this buffer
let b:did_rnoweb_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

" Enables Vim-Latex-Suite if it is installed
runtime ftplugin/tex_latexSuite.vim

" Enable syntax highlight of LaTeX errors in R Console (if using Conque
" Shell)
let syn_rout_latex = 1

" Source scripts common to R, Rnoweb, Rhelp and Rdoc:
runtime r-plugin/common_global.vim
if exists("g:rplugin_failed")
    finish
endif

" Some buffer variables common to R, Rnoweb, Rhelp and Rdoc need to be defined
" after the global ones:
runtime r-plugin/common_buffer.vim

setlocal iskeyword=@,48-57,_,.

function! RWriteChunk()
    if getline(".") =~ "^\\s*$" && RnwIsInRCode() == 0
        call setline(line("."), "<<>>=")
        exe "normal! o@"
        exe "normal! 0kl"
    else
        exe "normal! a<"
    endif
endfunction

function! RnwIsInRCode()
    let chunkline = search("^<<", "bncW")
    let docline = search("^@", "bncW")
    if chunkline > docline
        return 1
    else
        return 0
    endif
endfunction

function! RnwPreviousChunk() range
    let rg = range(a:firstline, a:lastline)
    let chunk = len(rg)
    for var in range(1, chunk)
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
            return
        else
            call cursor(i+1, 1)
        endif
    endfor
    return
endfunction

function! RnwNextChunk() range
    let rg = range(a:firstline, a:lastline)
    let chunk = len(rg)
    for var in range(1, chunk)
        let i = search("^<<.*$", "nW")
        if i == 0
            call RWarningMsg("There is no next R code chunk to go.")
            return
        else
            call cursor(i+1, 1)
        endif
    endfor
    return
endfunction

" Sweave and compile the current buffer content
function! RMakePDF(bibtex, knit)
    update
    call RSetWD()
    let pdfcmd = "vim.interlace('" . expand("%:t") . "'"

    if a:knit
        let pdfcmd = "require(knitr); " . pdfcmd . ', knit = TRUE'
    endif

    if g:vimrplugin_latexcmd != "pdflatex"
        let pdfcmd = pdfcmd . ", latexcmd = '" . g:vimrplugin_latexcmd . "'"
    endif

    if a:bibtex == "bibtex"
        let pdfcmd = pdfcmd . ", bibtex = TRUE"
    endif

    if a:knit
        if exists("g:vimrplugin_knitargs")
            let pdfcmd = pdfcmd . ", " . g:vimrplugin_knitargs
        endif
    else
        if exists("g:vimrplugin_sweaveargs")
            let pdfcmd = pdfcmd . ", " . g:vimrplugin_sweaveargs
        endif
    endif

    let pdfcmd = pdfcmd . ")"
    let b:needsnewomnilist = 1
    let ok = SendCmdToR(pdfcmd)
    if ok == 0
        return
    endif
endfunction  

" Send Sweave chunk to R
function! SendChunkToR(e, m)
    if RnwIsInRCode() == 0
        call RWarningMsg("Not inside an R code chunk.")
        return
    endif
    let chunkline = search("^<<", "bncW") + 1
    let docline = search("^@", "ncW") - 1
    let lines = getline(chunkline, docline)
    let ok = RSourceLines(lines, a:e)
    if ok == 0
        return
    endif
    if a:m == "down"
        call RnwNextChunk()
    endif  
endfunction

" Sweave the current buffer content
function! RSweave(knit)
    update
    let b:needsnewomnilist = 1
    call RSetWD()
    if a:knit
        call SendCmdToR('require(knitr); knit("' . expand("%:t") . '")')
    else
        call SendCmdToR('Sweave("' . expand("%:t") . '")')
    endif
endfunction

if g:vimrplugin_rnowebchunk == 1
    " Write code chunk in rnoweb files
    imap <buffer><silent> < <Esc>:call RWriteChunk()<CR>a
endif

"==========================================================================
" Key bindings and menu items

call RCreateStartMaps()
call RCreateEditMaps()
call RCreateSendMaps()
call RControlMaps()
call RCreateMaps("nvi", '<Plug>RSetwd',        'rd', ':call RSetWD()')

" Only .Rnw files use these functions:
call RCreateMaps("nvi", '<Plug>RSweave',      'sw', ':call RSweave(0)')
call RCreateMaps("nvi", '<Plug>RMakePDF',     'sp', ':call RMakePDF("nobib", 0)')
call RCreateMaps("nvi", '<Plug>RBibTeX',      'sb', ':call RMakePDF("bibtex", 0)')
call RCreateMaps("nvi", '<Plug>RKnit',        'kn', ':call RSweave(1)')
call RCreateMaps("nvi", '<Plug>RMakePDFK',    'kp', ':call RMakePDF("nobib", 1)')
call RCreateMaps("nvi", '<Plug>RBibTeXK',     'kb', ':call RMakePDF("bibtex", 1)')
call RCreateMaps("nvi", '<Plug>RIndent',      'si', ':call RnwToggleIndentSty()')
call RCreateMaps("ni",  '<Plug>RSendChunk',   'cc', ':call SendChunkToR("silent", "stay")')
call RCreateMaps("ni",  '<Plug>RESendChunk',  'ce', ':call SendChunkToR("echo", "stay")')
call RCreateMaps("ni",  '<Plug>RDSendChunk',  'cd', ':call SendChunkToR("silent", "down")')
call RCreateMaps("ni",  '<Plug>REDSendChunk', 'ca', ':call SendChunkToR("echo", "down")')
nmap <buffer><silent> gn :call RnwNextChunk()<CR>
nmap <buffer><silent> gN :call RnwPreviousChunk()<CR>

" Menu R
if has("gui_running")
    call MakeRMenu()
endif

let &cpo = s:cpo_save
unlet s:cpo_save

