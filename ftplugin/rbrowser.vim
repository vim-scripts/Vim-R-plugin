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
" ftplugin for RBrowser files (created by the Vim-R-plugin)
"
" Author: Jakson Alves de Aquino <jalvesaq@gmail.com>
"          
" Last Change: Mon Apr 30, 2012  12:39PM
"==========================================================================

" Only do this when not yet done for this buffer
if exists("b:did_ftplugin")
    finish
endif


" Don't load another plugin for this buffer
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

" Source scripts common to R, Rnoweb, Rhelp and rdoc files:
runtime r-plugin/common_global.vim

" Some buffer variables common to R, Rnoweb, Rhelp and rdoc file need be
" defined after the global ones:
runtime r-plugin/common_buffer.vim

setlocal noswapfile
setlocal buftype=nofile
setlocal nowrap
if g:vimrplugin_tmux && g:vimrplugin_screenplugin
    let showmarks_enable = 0
endif

if !exists("g:rplugin_hasmenu")
    let g:rplugin_hasmenu = 0
endif

" Popup menu
if !exists("g:rplugin_hasbrowsermenu")
    let g:rplugin_hasbrowsermenu = 0
endif

" Current view of the object browser: .GlobalEnv X loaded libraries
let g:rplugin_curview = "GlobalEnv"


function! UpdateOB(what)
    if g:rplugin_curview != a:what
        return
    endif
    if g:rplugin_ob_busy
        return
    endif
    redir => s:bufl
    silent buffers
    redir END
    if exists("g:rplugin_curbuf") && g:rplugin_curbuf != "Object_Browser" && g:rplugin_editor_port == 0 && s:bufl =~ "Object_Browser"
        let savesb = &switchbuf
        set switchbuf=useopen,usetab
        sil noautocmd sb Object_Browser
        let g:rplugin_switchedbuf = 1
    else
        let g:rplugin_switchedbuf = 0
    endif
    set modifiable
    let curline = line(".")
    let curcol = col(".")
    if !exists("curline")
        let curline = 3
    endif
    if !exists("curcol")
        let curcol = 1
    endif
    sil normal! ggdG
    if a:what == "GlobalEnv"
        call setline(1, ".GlobalEnv | Libraries")
        exe "silent read " . $VIMRPLUGIN_TMPDIR . "/object_browser"
    else
        call setline(1, "Libraries | .GlobalEnv")
        exe "silent read " . $VIMRPLUGIN_TMPDIR . "/liblist"
    endif
    call cursor(curline, curcol)
    set nomodifiable
    redraw
    if g:rplugin_switchedbuf
        exe "sil noautocmd sb " . g:rplugin_curbuf
        exe "set switchbuf=" . savesb
    endif
endfunction

function! RBrowserDoubleClick()
    " Toggle view: Objects in the workspace X List of libraries
    if line(".") == 1
        if g:rplugin_curview == "libraries"
            let g:rplugin_curview = "GlobalEnv"
            call UpdateOB("GlobalEnv")
        else
            let g:rplugin_curview = "libraries"
            call UpdateOB("libraries")
        endif
        return
    endif

    " Toggle state of list or data.frame: open X closed
    let key = RBrowserGetName(1, line("."))
    if g:rplugin_curview == "GlobalEnv"
        exe 'Py SendToR("' . "\005" . '-' . substitute(key, '\$', '-', "g") . '")'
        call UpdateOB("GlobalEnv")
    else
        let key = substitute(key, '\$', '-', "g") 
        let key = substitute(key, '`', '', "g") 
        if key !~ "^package:"
            let key = "package:" . RBGetPkgName() . '-' . key
        endif
        exe 'Py SendToR("' . "\005" . key . '")'
        call UpdateOB("libraries")
    endif
endfunction

function! RBrowserRightClick()
    if line(".") == 1
        return
    endif

    let key = RBrowserGetName(1, line("."))
    if key == ""
        return
    endif

    let line = getline(".")
    if line =~ "^   ##"
        return
    endif
    let isfunction = 0
    if line =~ "(#.*\t"
        let isfunction = 1
    endif

    if g:rplugin_hasbrowsermenu == 1
        aunmenu ]RBrowser
    endif
    let key = substitute(key, '\.', '\\.', "g")
    let key = substitute(key, ' ', '\\ ', "g")

    exe 'amenu ]RBrowser.summary('. key . ') :call RAction("summary")<CR>'
    exe 'amenu ]RBrowser.str('. key . ') :call RAction("str")<CR>'
    exe 'amenu ]RBrowser.names('. key . ') :call RAction("names")<CR>'
    exe 'amenu ]RBrowser.plot('. key . ') :call RAction("plot")<CR>'
    exe 'amenu ]RBrowser.print(' . key . ') :call RAction("print")<CR>'
    amenu ]RBrowser.-sep01- <nul>
    exe 'amenu ]RBrowser.example('. key . ') :call RAction("example")<CR>'
    exe 'amenu ]RBrowser.help('. key . ') :call RAction("help")<CR>'
    if isfunction
        exe 'amenu ]RBrowser.args('. key . ') :call RAction("args")<CR>'
    endif
    popup ]RBrowser
    let g:rplugin_hasbrowsermenu = 1
endfunction

function! RBGetPkgName()
    let lnum = line(".")
    while lnum > 0
        let line = getline(lnum)
        if line =~ '.*##[0-9a-zA-Z\.]*\t'
            let line = substitute(line, '.*##\(.*\)\t', '\1', "")
            return line
        endif
        let lnum -= 1
    endwhile
    return ""
endfunction

function! RBrowserFindParent(word, curline, curpos)
    let curline = a:curline
    let curpos = a:curpos
    while curline > 1 && curpos >= a:curpos
        let curline -= 1
        let line = substitute(getline(curline), "	.*", "", "")
        let curpos = stridx(line, '[#')
        if curpos == -1
            let curpos = a:curpos
        endif
    endwhile

    if g:rplugin_curview == "GlobalEnv"
        let spacelimit = 3
    else
        if s:isutf8
            let spacelimit = 10
        else
            let spacelimit = 6
        endif
    endif
    if curline > 1
        let word = substitute(line, '.*[#', "", "") . '$' . a:word
        if curpos != spacelimit
            let word = RBrowserFindParent(word, line("."), curpos)
        endif
        return word
    else
        " Didn't find the parent: should never happen.
        let msg = "R-plugin Error: " . a:word . ":" . curline
        echoerr msg
    endif
    return ""
endfunction

function! RBrowserGetName(complete, lnum)
    let curpos = col(".")

    let line = getline(a:lnum)
    if line =~ "^$"
        return
    endif

    " Is the object a top level one (curpos == 2)?
    if g:rplugin_curview == "libraries"
        let delim = ['##', '{#', '[#', '(#', '"#', "'#", '%#', '<#', '=#']
    else
        let delim = ['{#', '[#', '(#', '"#', "'#", '%#', '<#', '=#']
    endif
    let word = substitute(line, '^\W*#\{-1,}\(.*\)\t.*', '\1', "")

    if word =~ ' ' || word =~ '^[0-9]'
        let word = '`' . word . '`'
    endif

    if a:complete == 0
        return word
    endif

    for i in delim
        let curpos = stridx(line, i)
        if curpos != -1
            break
        endif
    endfor
    if curpos == -1
        return ""
    endif


    if curpos == 3
        " top level object
        if g:rplugin_curview == "libraries"
            return "package:" . word
        else
            return word
        endif
    else
        if g:rplugin_curview == "libraries"
            if s:isutf8
                if curpos == 10
                    return word
                endif
            elseif curpos == 6
                return word
            endif
        endif
        if curpos > 3
            " Find the parent data.frame or list
            let word = RBrowserFindParent(word, line("."), curpos)
            " Unnamed objects of lists
            if word =~ '\$\[\[[0-9]*\]\]'
                let word = substitute(word, '\$\[\[\([0-9]*\)\]\]', '-[[\1]]', "g")
            endif
            return word
        else
            " Wrong object name delimiter: should never happen.
            let msg = "R-plugin Error: (curpos = " . curpos . ") " . word
            echoerr msg
            return ""
        endif
    endif
endfunction

function! MakeRBrowserMenu()
    let g:rplugin_curbuf = bufname("%")
    if g:rplugin_hasmenu == 1
        return
    endif
    menutranslate clear
    call RControlMenu()
    call RBrowserMenu()
endfunction

function! ObBrBufUnload()
    Py StopServer()
    call delete($VIMRPLUGIN_TMPDIR . "/object_browser")
    call delete($VIMRPLUGIN_TMPDIR . "/liblist")
    if g:rplugin_editor_port
        call system("tmux select-pane -t " . g:rplugin_edpane)
    endif
endfunction

function! SourceObjBrLines()
    exe "source " . $VIMRPLUGIN_TMPDIR . "/objbrowserInit"
endfunction

function! OBGetDeleteCmd(lnum)
    let obj = RBrowserGetName(1, a:lnum)
    if g:rplugin_curview == "GlobalEnv"
        if obj =~ '\$'
            let cmd = obj . ' <- NULL'
        elseif obj =~ '-\[\[[0-9]*\]\]'
            let obj = substitute(obj, '-\(\[\[[0-9]*\]\]\)', '\1', '')
            let cmd = obj . ' <- NULL'
        else
            let cmd = 'rm(' . obj . ')'
        endif
    else
        if obj =~ "^package:"
            let cmd = 'detach("' . obj . '", unload = TRUE, character.only = TRUE)'
        else
            return ""
        endif
    endif
    return cmd
endfunction

function! OBSendDeleteCmd(cmd)
    let g:rplugin_ob_busy = 1
    call RBrSendToR(a:cmd)
    sleep 250m
    let g:rplugin_ob_busy = 0
    call UpdateOB(g:rplugin_curview)
    sleep 10m
endfunction

function! OBDelete()
    if g:rplugin_ob_busy || line(".") < 3 || g:rplugin_myport == 0
        return
    endif
    let cmd = OBGetDeleteCmd(line("."))
    call OBSendDeleteCmd(cmd)
endfunction

function! OBMultiDelete()
    if g:rplugin_ob_busy || g:rplugin_myport == 0
        return
    endif
    let fline = line("'<")
    let eline = line("'>")
    if fline < 3
        return
    endif
    let nl= 0
    let cmd = ""
    for ii in range(fline, eline)
        let nl+= 1
        if nl > 1
            let cmd = cmd . "; "
        endif
        let cmd = cmd . OBGetDeleteCmd(ii)
        if g:rplugin_curview == "GlobalEnv"
            let cmd = substitute(cmd, "); rm(", ", ", "")
        endif
    endfor
    call OBSendDeleteCmd(cmd)
endfunction

nmap <buffer><silent> <CR> :call RBrowserDoubleClick()<CR>
nmap <buffer><silent> <2-LeftMouse> :call RBrowserDoubleClick()<CR>
nmap <buffer><silent> <RightMouse> :call RBrowserRightClick()<CR>

call RControlMaps()

setlocal winfixwidth
setlocal bufhidden=wipe

if has("gui_running")
    call RControlMenu()
    call RBrowserMenu()
endif

call writefile([], $VIMRPLUGIN_TMPDIR . "/object_browser")
call writefile([], $VIMRPLUGIN_TMPDIR . "/liblist")

au BufUnload <buffer> call ObBrBufUnload()

function! RKeepRunning()
    if g:rplugin_myport == 0
        Py StopServer()
        sleep 250m
        Py RunServer()
        echon
    endif
endfunction

if $TMUX_PANE != ""
    set updatetime=3200
    autocmd CursorHold <buffer> call RKeepRunning()
    nmap <buffer><silent> d :call OBDelete()<CR>
    vmap <buffer><silent> d <Esc>:call OBMultiDelete()<CR>
endif

let s:envstring = tolower($LC_MESSAGES . $LC_ALL . $LANG)
if s:envstring =~ "utf-8" || s:envstring =~ "utf8"
    let s:isutf8 = 1
else
    let s:isutf8 = 0
endif
unlet s:envstring

let &cpo = s:cpo_save
unlet s:cpo_save

