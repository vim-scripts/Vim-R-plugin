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
" ftplugin for Rmd files
"
" Authors: Jakson Alves de Aquino <jalvesaq@gmail.com>
"          Jose Claudio Faria
"          Alex Zvoleff (adjusting for rmd by Michel Kuhlmann)
"
"==========================================================================

" Only do this when not yet done for this buffer
if exists("b:did_rmd_ftplugin") || exists("disable_r_ftplugin") || exists("b:did_ftplugin")
    finish
endif

" Don't load another plugin for this buffer
let b:did_rmd_ftplugin = 1

runtime! ftplugin/html.vim ftplugin/html_*.vim ftplugin/html/*.vim
unlet! b:did_ftplugin

setlocal comments=fb:*,fb:-,fb:+,n:> commentstring=>\ %s
setlocal formatoptions+=tcqln
setlocal formatlistpat=^\\s*\\d\\+\\.\\s\\+\\\|^\\s*[-*+]\\s\\+
setlocal iskeyword=@,48-57,_,.

let s:cpo_save = &cpo
set cpo&vim

" Enables pandoc if it is installed
runtime ftplugin/pandoc.vim

" Source scripts common to R, Rrst, Rnoweb, Rhelp and Rdoc:
runtime r-plugin/common_global.vim
if exists("g:rplugin_failed")
    finish
endif

" Some buffer variables common to R, Rmd, Rrst, Rnoweb, Rhelp and Rdoc need to
" be defined after the global ones:
runtime r-plugin/common_buffer.vim

function! RmdIsInRCode()
    let curline = line(".")
    let chunkline = search("^```[ ]*{r", "bncW")
    call cursor(chunkline)
    let docline = search("^```$", "ncW")
    call cursor(curline)
    if 0 < chunkline && chunkline < curline && curline < docline
        return 1
    else
        return 0
    endif
endfunction

function! RmdPreviousChunk() range
    let rg = range(a:firstline, a:lastline)
    let chunk = len(rg)
    for var in range(1, chunk)
        let curline = line(".")
        if RmdIsInRCode()
            let i = search("^```[ ]*{r", "bnW")
            if i != 0
                call cursor(i-1, 1)
            endif
        endif
        let i = search("^```[ ]*{r", "bnW")
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

function! RmdNextChunk() range
    let rg = range(a:firstline, a:lastline)
    let chunk = len(rg)
    for var in range(1, chunk)
        let i = search("^```[ ]*{r", "nW")
        if i == 0
            call RWarningMsg("There is no next R code chunk to go.")
            return
        else
            call cursor(i+1, 1)
        endif
    endfor
    return
endfunction

function! RMakeHTMLrmd(t)
    call RSetWD()
    update
    let rcmd = 'require(knitr); knit2html("' . expand("%:t") . '", options = "")'
    if a:t == "odt"
        if g:rplugin_has_soffice == 0
            if has("win32") || has("win64")
                let soffbin = "soffice.exe"
            else
                let soffbin = "soffice"
            endif
            if executable(soffbin)
                let g:rplugin_has_soffice = 1
            else
                call RWarningMsg("Is Libre Office installed? Cannot convert into ODT: '" . soffbin . "' not found.")
            endif
        endif
        let rcmd = rcmd . '; system("' . soffbin . ' --invisible --convert-to odt ' . expand("%:r:t") . '.html")'
    endif
    if g:vimrplugin_openhtml && a:t == "html"
        let rcmd = rcmd . '; browseURL("' . expand("%:r:t") . '.html")'
    endif
    call SendCmdToR(rcmd)
endfunction

function! RMakePDFrmd(t)
    if g:rplugin_vimcomport == 0
        exe "Py DiscoverVimComPort()"
        if g:rplugin_vimcomport == 0
            return
        endif
    endif
    if g:rplugin_has_pandoc == 0
        if executable("pandoc")
            let g:rplugin_has_pandoc = 1
        else
            call RWarningMsg("Cannot convert into PDF: 'pandoc' not found.")
            return
        endif
    endif
    call RSetWD()
    update
    let pdfcmd = "vim.interlace.rmd('" . expand("%:t") . "'"
    let pdfcmd = pdfcmd . ", pdfout = '" . a:t  . "'"
    if exists("g:vimrplugin_rmdcompiler")
        let pdfcmd = pdfcmd . ", compiler='" . g:vimrplugin_rmdcompiler . "'"
    endif
    if exists("g:vimrplugin_knitargs")
        let pdfcmd = pdfcmd . ", " . g:vimrplugin_knitargs
    endif
    if exists("g:vimrplugin_rmd2pdfpath")
        pdfcmd = pdfcmd . ", rmd2pdfpath='" . g:vimrplugin_rmd2pdf_path . "'"
    endif
    if exists("g:vimrplugin_pandoc_args")
        let pdfcmd = pdfcmd . ", pandoc_args = '" . g:vimrplugin_pandoc_args . "'"
    endif
    let pdfcmd = pdfcmd . ")"
    let b:needsnewomnilist = 1
    call SendCmdToR(pdfcmd)
endfunction  

" Send Rmd chunk to R
function! SendRmdChunkToR(e, m)
    if RmdIsInRCode() == 0
        call RWarningMsg("Not inside an R code chunk.")
        return
    endif
    let chunkline = search("^```[ ]*{r", "bncW") + 1
    let docline = search("^```", "ncW") - 1
    let lines = getline(chunkline, docline)
    let b:needsnewomnilist = 1
    let ok = RSourceLines(lines, a:e)
    if ok == 0
        return
    endif
    if a:m == "down"
        call RmdNextChunk()
    endif  
endfunction

"==========================================================================
" Key bindings and menu items

call RCreateStartMaps()
call RCreateEditMaps()
call RCreateSendMaps()
call RControlMaps()
call RCreateMaps("nvi", '<Plug>RSetwd',        'rd', ':call RSetWD()')

" Only .Rmd files use these functions:
call RCreateMaps("nvi", '<Plug>RKnit',        'kn', ':call RKnit()')
call RCreateMaps("nvi", '<Plug>RMakePDFK',    'kp', ':call RMakePDFrmd("latex")')
call RCreateMaps("nvi", '<Plug>RMakePDFK',    'kl', ':call RMakePDFrmd("beamer")')
call RCreateMaps("nvi", '<Plug>RMakeHTML',    'kh', ':call RMakeHTMLrmd("html")')
call RCreateMaps("nvi", '<Plug>RMakeODT',     'ko', ':call RMakeHTMLrmd("odt")')
call RCreateMaps("ni",  '<Plug>RSendChunk',   'cc', ':call SendRmdChunkToR("silent", "stay")')
call RCreateMaps("ni",  '<Plug>RESendChunk',  'ce', ':call SendRmdChunkToR("echo", "stay")')
call RCreateMaps("ni",  '<Plug>RDSendChunk',  'cd', ':call SendRmdChunkToR("silent", "down")')
call RCreateMaps("ni",  '<Plug>REDSendChunk', 'ca', ':call SendRmdChunkToR("echo", "down")')
nmap <buffer><silent> gn :call RmdNextChunk()<CR>
nmap <buffer><silent> gN :call RmdPreviousChunk()<CR>

" Menu R
if has("gui_running")
    call MakeRMenu()
endif

let g:rplugin_has_pandoc = 0
let g:rplugin_has_soffice = 0

let &cpo = s:cpo_save
unlet s:cpo_save

if exists('b:undo_ftplugin')
  let b:undo_ftplugin .= "|setl cms< com< fo< flp<"
else
  let b:undo_ftplugin = "setl cms< com< fo< flp<"
endif

