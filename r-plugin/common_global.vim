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
" Authors: Jakson Alves de Aquino <jalvesaq@gmail.com>
"          Jose Claudio Faria
"          
" Last Change: Wed May 02, 2012  10:10AM
"
" Purposes of this file: Create all functions and commands and set the
" value of all global variables and some buffer variables.for r,
" rnoweb, rhelp, rdoc, and rbrowser files
"
" Why not an autoload script? Because autoload was designed to store
" functions that are only occasionally used. The Vim-R-plugin has
" global variables and functions that are common to five file types
" and most of these functions will be used every time the plugin is
" used.
"==========================================================================


" Do this only once
if exists("g:rplugin_did_global_stuff")
    finish
endif
let g:rplugin_did_global_stuff = 1

"==========================================================================
" Functions that are common to r, rnoweb, rhelp and rdoc
"==========================================================================

function RWarningMsg(wmsg)
    echohl WarningMsg
    echomsg a:wmsg
    echohl Normal
endfunction

function RWarningMsgInp(wmsg)
    let savedlz = &lazyredraw
    if savedlz == 0
        set lazyredraw
    endif
    let savedsm = &shortmess
    set shortmess-=T
    echohl WarningMsg
    echomsg a:wmsg
    echohl Normal
    " The message disappears if starting to edit an empty buffer
    if line("$") == 1 && strlen(getline("$")) == 0
        sleep 2
    endif
    call input("[Press <Enter> to continue] ")
    if savedlz == 0
        set nolazyredraw
    endif
    let &shortmess = savedsm
endfunction

" Set default value of some variables:
function RSetDefaultValue(var, val)
    if !exists(a:var)
        exe "let " . a:var . " = " . a:val
    endif
endfunction

function ReplaceUnderS()
    if (&filetype == "rnoweb" || &filetype == "tex") && RnwIsInRCode() == 0
        let isString = 1
    else
        let j = col(".")
        let s = getline(".")
        if j > 3 && s[j-3] == "<" && s[j-2] == "-" && s[j-1] == " "
            exe "normal! 3h3xr_"
            return
        endif
        let isString = 0
        let synName = synIDattr(synID(line("."), j, 1), "name")
        if synName == "rSpecial"
            let isString = 1
        else
            if synName == "rString"
                let isString = 1
                if s[j-1] == '"' || s[j-1] == "'"
                    let synName = synIDattr(synID(line("."), j-2, 1), "name")
                    if synName == "rString" || synName == "rSpecial"
                        let isString = 0
                    endif
                endif
            endif
        endif
    endif
    if isString
        exe "normal! a_"
    else
        exe "normal! a <- "
    endif
endfunction

function RCompleteArgs()
    let lnum = line(".")
    let line = getline(".")
    let cpos = getpos(".")
    let idx = cpos[2] - 2
    let idx2 = cpos[2] - 2
    call cursor(lnum, cpos[2] - 1)
    if line[idx2] == ' ' || line[idx2] == ',' || line[idx2] == '('
        let idx2 = cpos[2]
        let argkey = ''
    else
        let argkey = RGetKeyWord()
        let idx2 = cpos[2] - strlen(argkey)
    endif
    if b:needsnewomnilist == 1
      call BuildROmniList("GlobalEnv", "none")
    endif
    let flines = g:rplugin_globalenvlines + g:rplugin_liblist
    let np = 1
    let nl = 0
    while np != 0 && nl < 10
        if line[idx] == '('
            let np -= 1
        elseif line[idx] == ')'
            let np += 1
        endif
        if np == 0
            call cursor(lnum, idx)
            let rkeyword0 = RGetKeyWord()
            let classfor = RGetClassFor(rkeyword0)
            let classfor = substitute(classfor, '"', '\\"', "g")
            let rkeyword = '^' . rkeyword0 . "\x06"
            call cursor(cpos[1], cpos[2])
            if classfor == ""
                exe 'Py SendToR("vimcom:::vim.args(' . "'" . rkeyword0 . "', '" . argkey . "')" . '")'
            else
                exe 'Py SendToR("vimcom:::vim.args(' . "'" . rkeyword0 . "', '" . argkey . "', classfor = " . classfor . ")" . '")'
            endif
            if g:rplugin_vimcomport > 0 && g:rplugin_lastrpl != "NOT_EXISTS" && g:rplugin_lastrpl != "NO_ARGS" && g:rplugin_lastrpl != "R is busy." && g:rplugin_lastrpl != "NOANSWER"
                let args = []
                let tmp0 = split(g:rplugin_lastrpl, "\x04")
                let tmp = split(tmp0[0], "\x09")
                if(len(tmp) > 0)
                    for id in range(len(tmp))
                        let tmp2 = split(tmp[id], "\x07")
                        if tmp2[0] == '...'
                            let tmp3 = tmp2[0]
                        else
                            let tmp3 = tmp2[0] . " = "
                        endif
                        if len(tmp2) > 1
                            call add(args,  {'word': tmp3, 'menu': tmp2[1]})
                        else
                            call add(args,  {'word': tmp3, 'menu': ' '})
                        endif
                    endfor
                    if len(args) > 0 && len(tmp0) > 1
                        call add(args, {'word': ' ', 'menu': tmp0[1]})
                    endif
                    call complete(idx2, args)
                endif
                return ''
            endif

            for omniL in flines
                if omniL =~ rkeyword && omniL =~ "\x06function\x06function\x06" 
                    let tmp1 = split(omniL, "\x06")
                    let info = tmp1[4]
                    let argsL = split(info, "\x09")
                    let args = []
                    for id in range(len(argsL))
                        let newkey = '^' . argkey
                        let tmp2 = split(argsL[id], "\x07")
                        if (argkey == '' || tmp2[0] =~ newkey) && tmp2[0] !~ "No arguments"
                            if tmp2[0] != '...'
                                let tmp2[0] = tmp2[0] . " = "
                            endif
                            if len(tmp2) == 2
                                let tmp3 = {'word': tmp2[0], 'menu': tmp2[1]}
                            else
                                let tmp3 = {'word': tmp2[0], 'menu': ''}
                            endif
                            call add(args, tmp3)
                        endif
                    endfor
                    call complete(idx2, args)
                    return ''
                endif
            endfor

            break
        endif
        let idx -= 1
        if idx <= 0
            let lnum -= 1
            if lnum == 0
                break
            endif
            let line = getline(lnum)
            let idx = strlen(line)
            let nl +=1
        endif
    endwhile
    call cursor(cpos[1], cpos[2])
    return ''
endfunction

function RCommentLine(lnum, ind, cmt)
    let line = getline(a:lnum)
    call cursor(a:lnum, 0)

    if line =~ '^\s*' . a:cmt
        let line = substitute(line, '^\s*' . a:cmt . '*', '', '')
        call setline(a:lnum, line)
        normal! ==
    else
        if g:vimrplugin_indent_commented
            while line =~ '^\s*\t'
                let line = substitute(line, '^\(\s*\)\t', '\1' . s:curtabstop, "")
            endwhile
            let line = strpart(line, a:ind)
        endif
        let line = a:cmt . ' ' . line
        call setline(a:lnum, line)
        if g:vimrplugin_indent_commented
            normal! ==
        endif
    endif
endfunction

function RComment(mode)
    let cpos = getpos(".")
    if a:mode == "selection"
        let fline = line("'<")
        let lline = line("'>")
    else
        let fline = line(".")
        let lline = fline
    endif

    " What comment string to use?
    call cursor(fline, 0)
    let isRcode = 1
    if &filetype == "rnoweb" && RnwIsInRCode() == 0
        let isRcode = 0
    endif
    if &filetype == "rhelp"
        let lastsection = search('^\\[a-z]*{', "bncW")
        let secname = getline(lastsection)
        if secname =~ '^\\usage{' || secname =~ '^\\examples{' || secname =~ '^\\dontshow{' || secname =~ '^\\dontrun{' || secname =~ '^\\donttest{' || secname =~ '^\\testonly{'
            let isRcode = 1
        else
            let isRcode = 0
        endif
    endif
    if isRcode == 0
        let cmt = '%'
    else
        if g:r_indent_ess_comments
            if g:vimrplugin_indent_commented
                let cmt = '##'
            else
                let cmt = '###'
            endif
        else
            let cmt = '#'
        endif
    endif

    let lnum = fline
    let ind = &tw
    while lnum <= lline
        let idx = indent(lnum)
        if idx < ind
            let ind = idx
        endif
        let lnum += 1
    endwhile

    let lnum = fline
    let s:curtabstop = repeat(' ', &tabstop)
    while lnum <= lline
        call RCommentLine(lnum, ind, cmt)
        let lnum += 1
    endwhile
    call cursor(cpos[1], cpos[2])
endfunction

function MovePosRCodeComment(mode)
    if a:mode == "selection"
        let fline = line("'<")
        let lline = line("'>")
    else
        let fline = line(".")
        let lline = fline
    endif

    let cpos = g:r_indent_comment_column
    let lnum = fline
    while lnum <= lline
        let line = getline(lnum)
        let cleanl = substitute(line, '\s*#.*', "", "")
        let llen = strlen(cleanl)
        if llen > (cpos - 2)
            let cpos = llen + 2
        endif
        let lnum += 1
    endwhile

    let lnum = fline
    while lnum <= lline
        call MovePosRLineComment(lnum, cpos)
        let lnum += 1
    endwhile
    call cursor(fline, cpos + 1)
    if a:mode == "insert"
        startinsert!
    endif
endfunction

function MovePosRLineComment(lnum, cpos)
    let line = getline(a:lnum)

    let ok = 1

    if &filetype == "rnoweb"
        if search("^<<", "bncW") > search("^@", "bncW")
            let ok = 1
        else
            let ok = 0
        endif
        if line =~ "^<<.*>>=$"
            let ok = 0
        endif
        if ok == 0
            call RWarningMsg("Not inside an R code chunk.")
            return
        endif
    endif

    if &filetype == "rhelp"
        let lastsection = search('^\\[a-z]*{', "bncW")
        let secname = getline(lastsection)
        if secname =~ '^\\usage{' || secname =~ '^\\examples{' || secname =~ '^\\dontshow{' || secname =~ '^\\dontrun{' || secname =~ '^\\donttest{' || secname =~ '^\\testonly{' || secname =~ '^\\method{.*}{.*}('
            let ok = 1
        else
            let ok = 0
        endif
        if ok == 0
            call RWarningMsg("Not inside an R code section.")
            return
        endif
    endif

    if line !~ '#'
        " Write the comment character
        let line = line . repeat(' ', a:cpos)
        let cmd = "let line = substitute(line, '^\\(.\\{" . (a:cpos - 1) . "}\\).*', '\\1# ', '')"
        exe cmd
        call setline(a:lnum, line)
    else
        " Align the comment character(s)
        let line = substitute(line, '\s*#', '#', "")
        let idx = stridx(line, '#')
        let str1 = strpart(line, 0, idx)
        let str2 = strpart(line, idx)
        let line = str1 . repeat(' ', a:cpos - idx - 1) . str2
        call setline(a:lnum, line)
    endif
endfunction

" Count braces
function CountBraces(line)
    let line2 = substitute(a:line, "{", "", "g")
    let line3 = substitute(a:line, "}", "", "g")
    let result = strlen(line3) - strlen(line2)
    return result
endfunction

function RnwPreviousChunk()
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

function RnwNextChunk()
    let linenr = search("^<<.*", "nW")
    if linenr == 0
        call RWarningMsg("There is no next R code chunk to go.")
    else
        let linenr += 1
        call cursor(linenr, 1)
    endif
    return
endfunction

" Skip empty lines and lines whose first non blank char is '#'
function GoDown()
    if &filetype == "rnoweb"
        let curline = getline(".")
        let fc = curline[0]
        if fc == '@'
            call RnwNextChunk()
            return
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

function RWriteScreenRC()
    if g:vimrplugin_noscreenrc
        return " "
    endif

    let scrcnf = $VIMRPLUGIN_TMPDIR . "/" . b:screensname . ".screenrc"

    if g:vimrplugin_screenplugin
        let cnflines = [
                    \ 'msgwait 0',
                    \ 'vbell off',
                    \ 'startup_message off',
                    \ 'bind a resize +1',
                    \ 'bind z resize -1',
                    \ "termcapinfo xterm* 'ti@:te@'"]
        if $DISPLAY != "" || $TERM =~ "xterm"
            let cnflines = cnflines + [
                        \ "terminfo rxvt-unicode 'Co#256:AB=\E[48;5;%dm:AF=\E[38;5;%dm'",
                        \ 'term screen-256color']
        endif
    else
        if g:vimrplugin_nosingler == 1
            let scrtitle = 'hardstatus string "' . expand("%:t") . '"'
        else
            let scrtitle = "hardstatus string R"
        endif

        let cnflines = ["msgwait 1",
                    \ "hardstatus lastline",
                    \ scrtitle,
                    \ "caption splitonly",
                    \ 'caption string "Vim-R-plugin"',
                    \ "termcapinfo xterm* 'ti@:te@'",
                    \ 'vbell off']
    endif

    call writefile(cnflines, scrcnf)
    return " -c " . scrcnf
endfunction

" Start R
function StartR(whatr)
    call writefile([], $VIMRPLUGIN_TMPDIR . "/object_browser")
    call writefile([], $VIMRPLUGIN_TMPDIR . "/liblist")

    if !exists("b:rplugin_R")
        call SetRPath()
    endif

    " Change to buffer's directory before starting R
    lcd %:p:h

    if a:whatr =~ "vanilla"
        let b:rplugin_r_args = "--vanilla"
    else
        if a:whatr =~ "custom"
            call inputsave()
            let b:rplugin_r_args = input('Enter parameters for R: ')
            call inputrestore()
        endif
    endif

    if g:vimrplugin_applescript && g:vimrplugin_screenplugin == 0 && g:vimrplugin_conqueplugin == 0
        if g:rplugin_r64app && g:vimrplugin_i386 == 0
            let rcmd = "/Applications/R64.app"
        else
            let rcmd = "/Applications/R.app"
        endif
        if b:rplugin_r_args != " "
            let rcmd = rcmd . " " . b:rplugin_r_args
        endif
        let rlog = system("open " . rcmd)
        if v:shell_error
            call RWarningMsg(rlog)
        endif
        lcd -
        return
    endif

    if has("win32") || has("win64")
        if g:vimrplugin_conqueplugin == 0
            Py StartRPy()
            lcd -
            return
        else
            let b:rplugin_R = "Rterm.exe"
        endif
    endif

    if b:rplugin_r_args == " "
        let rcmd = b:rplugin_R
    else
        let rcmd = b:rplugin_R . " " . b:rplugin_r_args
    endif

    if g:vimrplugin_screenplugin
        if $TERM =~ "screen"
            if g:vimrplugin_tmux
                call system("tmux set-environment VIMRPLUGIN_TMPDIR " . $VIMRPLUGIN_TMPDIR)
                call system("tmux set-environment VIMINSTANCEID " . $VIMINSTANCEID)
            else
                let rcmd = "VIMRPLUGIN_TMPDIR=" . $VIMRPLUGIN_TMPDIR . " " . rcmd
            endif
        endif
        if g:vimrplugin_tmux == 0 && g:vimrplugin_noscreenrc == 0 && exists("g:ScreenShellScreenInitArgs")
            let g:ScreenShellScreenInitArgs = RWriteScreenRC()
        endif
        if g:vimrplugin_screenvsplit
            if exists(":ScreenShellVertical") == 2
                exec 'ScreenShellVertical ' . rcmd
            else
                call RWarningMsgInp("Did you put \"let g:ScreenImpl = 'Tmux'\" in your vimrc?")
                exec 'ScreenShell ' . rcmd
            endif
        else
            exec 'ScreenShell ' . rcmd
        endif
    elseif g:vimrplugin_conqueplugin
        if exists("b:conque_bufname")
            if bufloaded(substitute(b:conque_bufname, "\\", "", "g"))
                call RWarningMsg("This buffer already has a Conque Shell.")
                lcd -
                return
            endif
        endif

        if g:vimrplugin_by_vim_instance == 1 && exists("g:ConqueTerm_BufName") && bufloaded(substitute(g:ConqueTerm_BufName, "\\", "", "g"))
            call RWarningMsg("This Vim instance already has a Conque Shell.")
            lcd -
            return
        endif

        let savesb = &switchbuf
        let savewd = &autochdir
        set noautochdir
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
            let g:rplugin_conqueshell = b:conqueshell
            let g:rplugin_conque_bufname = b:conque_bufname
            let g:rplugin_objbrtitle = b:objbrtitle
        endif

        unlet g:tmp_conqueshell
        unlet g:tmp_conque_bufname
        unlet g:tmp_objbrtitle

        setlocal syntax=rout
        exe "sil noautocmd sb " . g:rplugin_curbuf
        exe "set switchbuf=" . savesb
        if savewd
            set autochdir
        else
            set noautochdir
        endif
    else
        if g:vimrplugin_tmux
            if g:vimrplugin_notmuxconf
                let tmxcnf = " "
            else
                let tmxcnf = $VIMRPLUGIN_TMPDIR . "/tmux.conf"
                let cnflines = [
                            \ 'set-option -g prefix C-a',
                            \ 'unbind-key C-b',
                            \ 'bind-key C-a send-prefix',
                            \ 'set-window-option -g mode-keys vi',
                            \ 'set -g status off',
                            \ "set -g terminal-overrides 'xterm*:smcup@:rmcup@'"]
                if g:vimrplugin_external_ob
                    let cnflines = extend(cnflines, ['set -g mode-mouse on', 'set -g mouse-select-pane on', 'set -g mouse-resize-pane on'])
                endif
                call writefile(cnflines, tmxcnf)
                let tmxcnf = "-f " . tmxcnf
            endif
            call system("tmux has-session -t" . b:screensname)
            if v:shell_error
                if g:rplugin_termcmd =~ "gnome-terminal" || g:rplugin_termcmd =~ "xfce4-terminal" || g:rplugin_termcmd =~ "terminal" || g:rplugin_termcmd =~ "iterm"
                    let opencmd = printf("%s 'tmux -2 %s new-session -s %s \"%s\"' &", g:rplugin_termcmd, tmxcnf, b:screensname, rcmd)
                else
                    let opencmd = printf("%s tmux -2 %s new-session -s %s \"%s\" &", g:rplugin_termcmd, tmxcnf, b:screensname, rcmd)
                endif
            else
                if g:rplugin_termcmd =~ "gnome-terminal" || g:rplugin_termcmd =~ "xfce4-terminal" || g:rplugin_termcmd =~ "terminal" || g:rplugin_termcmd =~ "iterm"
                    let opencmd = printf("%s 'tmux -2 %s attach-session -d -t %s' &", g:rplugin_termcmd, tmxcnf, b:screensname)
                else
                    let opencmd = printf("%s tmux -2 %s attach-session -d -t %s &", g:rplugin_termcmd, tmxcnf, b:screensname)
                endif
            endif
        else
            let scrrc = RWriteScreenRC()
            " Some terminals want quotes (see screen.vim)
            if g:rplugin_termcmd =~ "gnome-terminal" || g:rplugin_termcmd =~ "xfce4-terminal" || g:rplugin_termcmd =~ "terminal" || g:rplugin_termcmd =~ "iterm"
                let opencmd = printf("%s 'screen %s -d -RR -S %s %s' &", g:rplugin_termcmd, scrrc, b:screensname, rcmd)
            else
                let opencmd = printf("%s screen %s -d -RR -S %s %s &", g:rplugin_termcmd, scrrc, b:screensname, rcmd)
            endif
        endif
        let rlog = system(opencmd)
        if v:shell_error
            call RWarningMsg(rlog)
            lcd -
            return
        endif
    endif

    " Go back to original directory:
    lcd -
    echon
endfunction

function StartObjectBrowser()
    if g:vimrplugin_tmux && (g:vimrplugin_screenplugin || g:vimrplugin_external_ob)

        if g:rplugin_editor_port
            " This is the Object Browser
            Py VimClient("EXPR call RObjBrowser()")
            let g:rplugin_running_objbr = 0
            return
        endif

        if g:rplugin_myport == 0
            let g:rplugin_myport1 = 6005
            let g:rplugin_myport2 = 6100
            Py RunServer()
            sleep 100m
            let ii = 0
            while ii < 10 && g:rplugin_myport == 0
                Py vim.command("let g:rplugin_myport = " + str(MyPort))
                let ii = ii + 1
                sleep 100m
            endwhile
        endif

        " Start the Object Browser if it doesn't exist yet
        if g:rplugin_objbr_port == 0
            let objbrowserfile = $VIMRPLUGIN_TMPDIR . "/objbrowserInit"
            if exists("g:ScreenShellSession")
                let tmxs = " -S " . g:ScreenShellSession . " "
            else
                let tmxs = " "
            endif

            if !exists("g:rplugin_edpane")
                let g:rplugin_edpane = $TMUX_PANE
                if strlen(g:rplugin_edpane) == 0
                    if g:vimrplugin_external_ob
                        let g:rplugin_edpane = "none"
                        let g:vimrplugin_objbr_place = substitute(g:vimrplugin_objbr_place, "script", "console", "g")
                    else
                        echoer "Could not find the environment variable TMUX_PANE."
                        return
                    endif
                endif
            endif

            call delete($VIMRPLUGIN_TMPDIR . "/rpane")
            Py SendToR("\001Tmux pane")
            let ii = 0
            while !filereadable($VIMRPLUGIN_TMPDIR . "/rpane") && ii < 20
                let ii = ii + 1
                sleep 50m
            endwhile
            if !filereadable($VIMRPLUGIN_TMPDIR . "/rpane")
                echoer "The number of the R Tmux pane is unknown."
                return
            endif
            let xx = readfile($VIMRPLUGIN_TMPDIR . "/rpane")
            let g:rplugin_rpane = xx[0]
            if g:rplugin_rpane !~ "%[0-9]"
                echoer 'The number of the R Tmux pane is invalid: "' . g:rplugin_rpane . '"'
                unlet g:rplugin_rpane
                return
            endif

            call writefile([
                        \ 'call writefile([$TMUX_PANE], $VIMRPLUGIN_TMPDIR . "/objbrpane")',
                        \ 'let b:this_is_ob = 1',
                        \ 'let g:rplugin_editor_port = ' . g:rplugin_myport ,
                        \ 'let g:rplugin_edpane = "' . g:rplugin_edpane . '"',
                        \ 'let g:rplugin_rpane = "' . g:rplugin_rpane . '"',
                        \ 'let b:objbrtitle = "' . b:objbrtitle . '"',
                        \ 'let b:screensname = "' . b:screensname . '"',
                        \ 'let b:rscript_buffer = "' . bufname("%") . '"',
                        \ 'set filetype=rbrowser',
                        \ 'let $VIMINSTANCEID="' . $VIMINSTANCEID . '"',
                        \ 'setlocal modifiable',
                        \ 'set shortmess=atI',
                        \ 'set rulerformat=%3(%l%)',
                        \ 'set noruler',
                        \ 'let curline = line(".")',
                        \ 'let curcol = col(".")',
                        \ 'normal! ggdG',
                        \ 'setlocal nomodified',
                        \ 'call cursor(curline, curcol)',
                        \ 'exe "PyFile " . g:rplugin_home . "/r-plugin/vimcom.py"',
                        \ 'Py OtherPort = ' . g:rplugin_myport ,
                        \ 'let g:rplugin_myport1 = 5005',
                        \ 'let g:rplugin_myport2 = 5100',
                        \ 'sleep 250m',
                        \ 'function! RBrSendToR(cmd)',
                        \ '    let scmd = "tmux set-buffer '. "'" . '" . a:cmd . "\<C-M>' . "'" . ' && tmux' . tmxs . 'paste-buffer -t ' . g:rplugin_rpane . '"',
                        \ '    let rlog = system(scmd)',
                        \ '    if v:shell_error',
                        \ '        let rlog = substitute(rlog, "\n", " ", "g")',
                        \ '        let rlog = substitute(rlog, "\r", " ", "g")',
                        \ '        call RWarningMsg(rlog)',
                        \ '        return 0',
                        \ '    endif',
                        \ 'endfunction',
                        \ 'Py RunServer()',
                        \ 'sleep 100m',
                        \ 'let ii = 0',
                        \ 'while ii < 10 && g:rplugin_myport == 0',
                        \ '  Py vim.command("let g:rplugin_myport = " + str(MyPort))',
                        \ '  let ii = ii + 1',
                        \ '  sleep 100m',
                        \ 'endwhile',
                        \ 'Py VimClient("EXPR let g:rplugin_objbr_port = " + str(MyPort))',
                        \ 'sleep 200m',
                        \ 'Py VimClient("EXPR Py OtherPort = " + str(MyPort))',
                        \ 'call UpdateOB("GlobalEnv")',
                        \ 'redraw'], objbrowserfile)

            if g:vimrplugin_objbr_place =~ "left"
                let panw = system("tmux list-panes | cat")
                if g:vimrplugin_objbr_place =~ "console"
                    " Get the R Console width:
                    let panw = substitute(panw, '.*\n1: \[\([0-9]*\)x.*', '\1', "")
                else
                    " Get the Vim with
                    let panw = substitute(panw, '.*0: \[\([0-9]*\)x.*', '\1', "")
                endif
                let panewidth = panw - g:vimrplugin_objbr_w
                " Just to be safe: If the above code doesn't work as expected
                " and we get a spurious value:
                if panewidth < 40 || panewidth > 180
                    let panewidth = 80
                endif
            else
                let panewidth = g:vimrplugin_objbr_w
            endif
            if g:vimrplugin_objbr_place =~ "console"
                let cmd = "tmux split-window -d -h -l " . panewidth . " -t " . g:rplugin_rpane . ' "vim -c ' . "'source " . objbrowserfile . "'" . '"'
            else
                let cmd = "tmux split-window -d -h -l " . panewidth . " -t " . g:rplugin_edpane . ' "vim -c ' . "'source " . objbrowserfile . "'" . '"'
            endif

            call delete($VIMRPLUGIN_TMPDIR . "/objbrpane")

            let rlog = system(cmd)
            if v:shell_error
                let rlog = substitute(rlog, '\n', ' ', 'g')
                let rlog = substitute(rlog, '\r', ' ', 'g')
                call RWarningMsg(rlog)
                let g:rplugin_running_objbr = 0
                return 0
            endif

            let ii = 0
            while !filereadable($VIMRPLUGIN_TMPDIR . "/objbrpane") && ii < 20
                let ii = ii + 1
                sleep 50m
            endwhile
            if !filereadable($VIMRPLUGIN_TMPDIR . "/objbrpane")
                echoer "The Tmux pane number of the Object Browser is unknown."
                return
            endif
            let xx = readfile($VIMRPLUGIN_TMPDIR . "/objbrpane")
            let g:rplugin_obpane = xx[0]
            if g:rplugin_obpane !~ "%[0-9]"
                echoer 'The number of the Object Browser Tmux pane is invalid: "' . g:rplugin_obpane . '"'
                unlet g:rplugin_obpane
                return
            endif

            if g:vimrplugin_objbr_place =~ "left"
                if g:vimrplugin_objbr_place =~ "console"
                    call system("tmux swap-pane -d -s " . g:rplugin_rpane . " -t " . g:rplugin_obpane)
                else
                    call system("tmux swap-pane -d -s " . g:rplugin_edpane . " -t " . g:rplugin_obpane)
                endif
            endif
            let ii = 0
            echohl WarningMsg
            echo "Please, wait..."
            echohl Normal
            while g:rplugin_objbr_port == 0 && ii < 10
                sleep 200m
                let ii = ii + 1
            endwhile
            echon "\r               "
        endif
        return
    endif

    " Either load or reload the Object Browser
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
        set filetype=rbrowser

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
        exe "PyFile " . g:rplugin_home . "/r-plugin/vimcom.py"
        Py SendToR("\003GlobalEnv")
        Py SendToR("\004Libraries")
        call UpdateOB("GlobalEnv")
    endif
endfunction

" Open an Object Browser window
function RObjBrowser()
    if !has("python") && !has("python3")
        call RWarningMsg("Python support is required to run the Object Browser.")
        return
    endif

    " Only opens the Object Browser if R is running
    if g:vimrplugin_screenplugin && !exists("g:ScreenShellSend")
        return
    endif
    if g:vimrplugin_conqueplugin && !exists("b:conque_bufname")
        return
    endif
    if g:rplugin_running_objbr == 1
        " Called twice due to BufEnter event
        return
    endif

    let g:rplugin_running_objbr = 1

    call StartObjectBrowser()
    Py SendToR("\003GlobalEnv")
    Py SendToR("\004Libraries")
    if exists("*UpdateOB")
        call UpdateOB("GlobalEnv")
        call UpdateOB("libraries")
    endif
    let g:rplugin_running_objbr = 0
    return
endfunction

function RBrowserOpenCloseLists(status)
    if g:vimrplugin_external_ob || (g:vimrplugin_screenplugin && !exists("b:this_is_ob"))
        let stt = a:status + 2
    else
        let stt = a:status
    endif

    let switchedbuf = 0
    if buflisted("Object_Browser") && g:rplugin_curbuf != "Object_Browser"
        let savesb = &switchbuf
        set switchbuf=useopen,usetab
        sil noautocmd sb Object_Browser
        let switchedbuf = 1
    endif

    exe 'Py SendToR("' . "\006" . stt . '")'

    if exists("g:rplugin_curview")
        if g:rplugin_curview == "GlobalEnv"
            call UpdateOB("GlobalEnv")
        else
            call UpdateOB("libraries")
        endif
    endif

    if switchedbuf
        exe "sil noautocmd sb " . g:rplugin_curbuf
        exe "set switchbuf=" . savesb
    endif
endfunction

" Scroll conque term buffer (called by CursorHold event)
function RScrollTerm()
    if &ft != "r" && &ft != "rnoweb" && &ft != "rhelp" && &ft != "rdoc"
        return
    endif
    if !exists("b:conque_bufname")
        return
    endif

    let savesb = &switchbuf
    set switchbuf=useopen,usetab
    exe "sil noautocmd sb " . b:conque_bufname

    call b:conqueshell.read(50)
    normal! G0

    exe "sil noautocmd sb " . g:rplugin_curbuf
    exe "set switchbuf=" . savesb
endfunction

" Called by the Object Browser when running remotely:
function RGetRemoteCmd(cmd)
    call RWarningMsg(a:cmd)
    call SendCmdToR(a:cmd)
    echon
endfunction

" Function to send commands
" return 0 on failure and 1 on success
function SendCmdToR(cmd)
    if g:vimrplugin_ca_ck
        let cmd = "\001" . "\013" . a:cmd
    else
        let cmd = a:cmd
    endif

    if (has("win32") || has("win64")) && g:vimrplugin_conqueplugin == 0
        let cmd = cmd . "\n"
        let slen = len(cmd)
        let str = ""
        for i in range(0, slen)
            let str = str . printf("\\x%02X", char2nr(cmd[i]))
        endfor
        exe "Py" . " SendToRPy(b'" . str . "')"
        silent exe '!start WScript "' . g:rplugin_jspath . '" "' . expand("%") . '"'
        " call RestoreClipboardPy()
        return 1
    endif

    if g:vimrplugin_screenplugin
        if !exists("g:ScreenShellSend") && !exists("*RBrSendToR")
            call RWarningMsg("Did you already start R?")
            return 0
        endif
        if exists("g:ScreenShellSend")
            call g:ScreenShellSend(cmd)
        else
            call RBrSendToR(cmd)
        endif
        return 1
    elseif g:vimrplugin_conqueplugin
        if !exists("b:conque_bufname")
            if g:vimrplugin_by_vim_instance
                if exists("g:rplugin_conqueshell")
                    let b:conqueshell = g:rplugin_conqueshell
                    let b:conque_bufname = g:rplugin_conque_bufname
                    let b:objbrtitle = g:rplugin_objbrtitle
                else
                    call RWarningMsg("This buffer does not have a Conque Shell yet.")
                    return 0
                endif
            else
                call RWarningMsg("Did you already start R?")
                return 0
            endif
        endif

        " Is the Conque buffer hidden or deleted?
        if !bufloaded(substitute(b:conque_bufname, "\\", "", "g"))
            call RWarningMsg("Could not find Conque Shell buffer.")
            return 0
        endif

        " Code provided by Nico Raffo: use an aggressive sb option
        let savesb = &switchbuf
        set switchbuf=useopen,usetab

        " jump to terminal buffer
        if bufwinnr(substitute(b:conque_bufname, "\\", "", "g")) < 0
            " The buffer either was hidden by the user with the  :q  command or is
            " in another tab
            exe "sil noautocmd belowright split " . b:conque_bufname
        else
            exe "sil noautocmd sb " . b:conque_bufname
        endif

        " write variable content to terminal
        call b:conqueshell.writeln(cmd)
        exe "sleep " . g:vimrplugin_conquesleep . "m"
        call b:conqueshell.read(50)
        normal! G0

        " jump back to code buffer
        exe "sil noautocmd sb " . g:rplugin_curbuf
        exe "set switchbuf=" . savesb
        return 1
    endif

    if g:vimrplugin_applescript && g:vimrplugin_screenplugin == 0 && g:vimrplugin_conqueplugin == 0
        if g:rplugin_r64app && g:vimrplugin_i386 == 0
            let rcmd = "R64"
        else
            let rcmd = "R"
        endif

        " for some reason it doesn't like "\025"
        let cmd = a:cmd
        let cmd = substitute(cmd, "\\", '\\\', 'g')
        let cmd = substitute(cmd, '"', '\\"', "g")
        let cmd = substitute(cmd, "'", "'\\\\''", "g")
        call system("osascript -e 'tell application \"".rcmd."\" to cmd \"" . cmd . "\"'")
        return 1
    endif

    " Send the command to R running in an external terminal emulator
    let str = substitute(cmd, "'", "'\\\\''", "g")
    if g:vimrplugin_tmux
        let scmd = "tmux set-buffer '" . str . "\<C-M>' && tmux paste-buffer -t " . b:screensname . '.0'
    else
        let scmd = 'screen -S ' . b:screensname . " -X stuff '" . str . "\<C-M>'"
    endif
    let rlog = system(scmd)
    if v:shell_error
        let rlog = substitute(rlog, '\n', ' ', 'g')
        let rlog = substitute(rlog, '\r', ' ', 'g')
        call RWarningMsg(rlog)
        return 0
    endif
    return 1
endfunction

" Get the word either under or after the cursor.
" Works for word(| where | is the cursor position.
function RGetKeyWord()
    " Go back some columns if character under cursor is not valid
    let save_cursor = getpos(".")
    let curline = line(".")
    let line = getline(curline)
    if strlen(line) == 0
        return ""
    endif
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
function RSourceLines(lines, e)
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
    let ok = SendCmdToR(rcmd)
    return ok
endfunction

" Send file to R
function SendFileToR(e)
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
function SendMBlockToR(e, m)
    if &filetype == "rnoweb" && RnwIsInRCode() == 0
        call RWarningMsg("Not inside an R code chunk.")
        return
    endif
    if &filetype == "rdoc" && search("^Examples:$", "bncW") == 0
        call RWarningMsg('Not in the "Examples" section.')
        return
    endif

    let b:needsnewomnilist = 1
    let curline = line(".")
    let lineA = 1
    let lineB = line("$")
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
    if lineA == 1 && lineB == (line("$"))
        call RWarningMsg("The file has no mark!")
        return
    endif
    if lineB < line("$")
        let lineB -= 1
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
endfunction

" Send functions to R
function SendFunctionToR(e, m)
    if &filetype == "rnoweb" && RnwIsInRCode() == 0
        call RWarningMsg("Not inside an R code chunk.")
        return
    endif
    if &filetype == "rdoc" && search("^Examples:$", "bncW") == 0
        call RWarningMsg('Not in the "Examples" section.')
        return
    endif

    let b:needsnewomnilist = 1
    let line = SanitizeRLine(getline("."))
    let i = line(".")
    while i > 0 && line !~ "function"
        let i -= 1
        let line = SanitizeRLine(getline(i))
    endwhile
    if i == 0
        return
    endif
    let functionline = i
    while i > 0 && line !~ "<-"
        let i -= 1
        let line = SanitizeRLine(getline(i))
    endwhile
    if i == 0
        return
    endif
    let firstline = i
    let i = functionline
    let line = SanitizeRLine(getline(i))
    let tt = line("$")
    while i < tt && line !~ "{"
        let i += 1
        let line = SanitizeRLine(getline(i))
    endwhile
    if i == tt
        return
    endif
    let nb = CountBraces(line)
    while i < tt && nb > 0
        let i += 1
        let line = SanitizeRLine(getline(i))
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
endfunction

" Send selection to R
function SendSelectionToR(e, m)
    if &filetype == "rnoweb" && RnwIsInRCode() == 0
        call RWarningMsg("Not inside an R code chunk.")
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
        let ok = SendCmdToR(line)
        if ok && a:m =~ "down"
            call GoDown()
        endif
        return
    endif

    let lines = getline("'<", "'>")

    if visualmode() == "\<C-V>"
        let lj = line("'<")
        let cj = col("'<")
        let lk = line("'>")
        let ck = col("'>")
        if cj > ck
            let bb = ck - 1
            let ee = cj - ck + 1
        else
            let bb = cj - 1
            let ee = ck - cj + 1
        endif
        if cj > len(getline(lj)) || ck > len(getline(lk))
            for idx in range(0, len(lines) - 1)
                let lines[idx] = strpart(lines[idx], bb)
            endfor
        else
            for idx in range(0, len(lines) - 1)
                let lines[idx] = strpart(lines[idx], bb, ee)
            endfor
        endif
    else
        let i = col("'<") - 1
        let j = col("'>")
        let lines[0] = strpart(lines[0], i)
        let llen = len(lines) - 1
        let lines[llen] = strpart(lines[llen], 0, j)
    endif

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
function SendParagraphToR(e, m)
    if &filetype == "rnoweb" && RnwIsInRCode() == 0
        call RWarningMsg("Not inside an R code chunk.")
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
        let j += 1
        let line = getline(j)
        if &filetype == "rnoweb" && line =~ "^@$"
            let j -= 1
            break
        endif
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
endfunction

" Send current line to R. Don't go down if called by <S-Enter>.
function SendLineToR(godown)
    let line = getline(".")
    if strlen(line) == 0
        if a:godown =~ "down"
            call GoDown()
        endif
        return
    endif

    if &filetype == "rnoweb"
        if line =~ "^@$"
            if a:godown =~ "down"
                call GoDown()
            endif
            return
        endif
        if RnwIsInRCode() == 0
            call RWarningMsg("Not inside an R code chunk.")
            return
        endif
    endif

    if &filetype == "rdoc"
        if getline(1) =~ '^The topic'
            let topic = substitute(line, '.*::', '', "")
            let package = substitute(line, '::.*', '', "")
            call ShowRDoc(topic, package, 1)
            return
        endif
        if search("^Examples:$", "bncW") == 0
            call RWarningMsg('Not in the "Examples" section.')
            return
        endif
    endif

    let b:needsnewomnilist = 1
    let ok = SendCmdToR(line)
    if ok
        if a:godown =~ "down"
            call GoDown()
        else
            if a:godown == "newline"
                normal! o
            endif
        endif
    endif
endfunction

function RSendPartOfLine(direction, correctpos)
    let lin = getline(".")
    let idx = col(".") - 1
    if a:correctpos
        call cursor(line("."), idx)
    endif
    if a:direction == "right"
        let rcmd = strpart(lin, idx)
    else
        let rcmd = strpart(lin, 0, idx)
    endif
    call SendCmdToR(rcmd)
endfunction

" Clear the console screen
function RClearConsole()
    if (has("win32") || has("win64")) && g:vimrplugin_conqueplugin == 0
        Py RClearConsolePy()
        silent exe '!start WScript "' . g:rplugin_jspath . '" "' . expand("%") . '"'
    else
        call SendCmdToR("\014")
    endif
endfunction

" Remove all objects
function RClearAll()
    let ok = SendCmdToR("rm(list=ls())")
    sleep 500m
    call RClearConsole()
endfunction

"Set working directory to the path of current buffer
function RSetWD()
    let wdcmd = 'setwd("' . expand("%:p:h") . '")'
    if has("win32") || has("win64")
        let wdcmd = substitute(wdcmd, "\\", "/", "g")
    endif
    let ok = SendCmdToR(wdcmd)
    if ok == 0
        return
    endif
endfunction

" Quit R
function RQuit(how)
    if g:rplugin_objbr_port
        Py VimClient("FINISH")
        sleep 200m
        Py OtherPort = 0
    endif
    if g:rplugin_myport
        Py StopServer()
        sleep 200m
    endif

    if bufloaded(b:objbrtitle)
        exe "bunload! " . b:objbrtitle
        sleep 150m
    endif

    if exists("b:quit_command")
        call SendCmdToR(b:quit_command)
    else
        if a:how == "save"
            call SendCmdToR('quit(save = "yes")')
            sleep 1
        else
            call SendCmdToR('quit(save = "no")')
        endif
    endif
    sleep 250m

    if g:rplugin_objbr_port
        " check if the pane still exists before trying to kill it because the
        " user may have already closed the Object Browser manually.
        let plst = system("tmux list-panes | cat")
        if plst =~ g:rplugin_obpane
            call system("tmux kill-pane -t " . g:rplugin_obpane)
        endif
        let g:rplugin_objbr_port = 0
        sleep 250m
    endif

    if g:vimrplugin_screenplugin
        if exists(':ScreenQuit')
            ScreenQuit
        endif
    elseif g:vimrplugin_conqueplugin
        sleep 200m
        exe "sil bdelete " . b:conque_bufname
        unlet b:conque_bufname
        unlet b:conqueshell
    endif

    if exists("g:rplugin_objbrtitle")
        unlet g:rplugin_objbrtitle
        if exists("g:rplugin_conqueshell")
            unlet g:rplugin_conqueshell
            unlet g:rplugin_conque_bufname
        endif
    endif

endfunction

" Tell R to create a list of objects file listing all currently available
" objects in its environment. The file is necessary for omni completion.
function BuildROmniList(env, what)
    if a:env =~ "GlobalEnv"
        let rtf = g:rplugin_globalenvfname
        let b:needsnewomnilist = 0
    else
        let rtf = g:rplugin_omnifname
    endif
    let omnilistcmd = 'vim.bol("' . rtf . '"'
    if a:env == "libraries" && a:what == "installed"
        let omnilistcmd = omnilistcmd . ', what = "installed"'
    endif
    if g:vimrplugin_allnames == 1
        let omnilistcmd = omnilistcmd . ', allnames = TRUE'
    endif
    let omnilistcmd = omnilistcmd . ')'

    call delete($VIMRPLUGIN_TMPDIR . "/vimbol_finished")
    if a:env =~ "GlobalEnv"
        exe "Py SendToR('" . omnilistcmd . "')"
        if g:rplugin_lastrpl == "R is busy."
            call RWarningMsg("R is busy.")
            let b:needsnewomnilist = 1
            sleep 800m
            return
        endif
        sleep 20m
    else
        echohl WarningMsg
        echo "Please, wait..."
        echohl Normal
        call SendCmdToR(omnilistcmd)
        sleep 2
    endif
    let ii = 0
    while !filereadable($VIMRPLUGIN_TMPDIR . "/vimbol_finished") && ii < g:vimrplugin_buildwait
        let ii += 1
        sleep
    endwhile
    echon "\r               "
    if ii == g:vimrplugin_buildwait
        call RWarningMsg("No longer waiting...")
        return
    endif

    if a:env == "GlobalEnv"
        let g:rplugin_globalenvlines = readfile(g:rplugin_globalenvfname)
    endif
    echon
endfunction

function RBuildSyntaxFile(what)
    call BuildROmniList("libraries", a:what)
    sleep 100m
    let g:rplugin_liblist = readfile(g:rplugin_omnifname)
    call BuildRHelpList()
    let res = []
    let nf = 0
    let funlist = ""
    for line in g:rplugin_liblist
        let obj = split(line, "\x06", 1)
        if obj[2] == "function"
            if obj[0] !~ '[[:punct:]]' || (obj[0] =~ '\.[a-zA-Z]' && obj[0] !~ '[[:punct:]][[:punct:]]')
                let nf += 1
                let funlist = funlist . " " . obj[0]
                if nf == 7
                    let line = "syn keyword rFunction " . funlist
                    call add(res, line)
                    let nf = 0
                    let funlist = ""
                endif
            endif
        endif
    endfor
    if nf > 0
        let line = "syn keyword rFunction " . funlist
        call add(res, line)
    endif
    call writefile(res, g:rplugin_uservimfiles . "/r-plugin/functions.vim")
    if &filetype == "rbrowser"
        let savesb = &switchbuf
        set switchbuf=useopen,usetab
        exe "sb " . b:rscript_buffer
        unlet b:current_syntax
        exe "runtime syntax/r.vim"
        exe "sb " . b:objbrtitle
        exe "set switchbuf=" . savesb
        call UpdateOB("libraries")
    else
        unlet b:current_syntax
        runtime syntax/r.vim
    endif
endfunction

function SetRTextWidth()
    if !bufloaded(s:rdoctitle) || g:vimrplugin_newsize == 1
        " Bug fix for Vim < 7.2.318
        if !(has("win32") || has("win64"))
            let curlang = v:lang
            language C
        endif

        let g:vimrplugin_newsize = 0

        " s:vimpager is used to calculate the width of the R help documentation
        " and to decide whether to obey vimrplugin_vimpager = 'vertical'
        let s:vimpager = g:vimrplugin_vimpager

        let wwidth = winwidth(0)

        " Not enough room to split vertically
        if g:vimrplugin_vimpager == "vertical" && wwidth <= (g:vimrplugin_help_w + g:vimrplugin_editor_w)
            let s:vimpager = "horizontal"
        endif

        if s:vimpager == "horizontal"
            " Use the window width (at most 80 columns)
            let htwf = (wwidth > 80) ? 88.1 : ((wwidth - 1) / 0.9)
        elseif g:vimrplugin_vimpager == "tab" || g:vimrplugin_vimpager == "tabnew"
            let wwidth = &columns
            let htwf = (wwidth > 80) ? 88.1 : ((wwidth - 1) / 0.9)
        else
            let min_e = (g:vimrplugin_editor_w > 80) ? g:vimrplugin_editor_w : 80
            let min_h = (g:vimrplugin_help_w > 73) ? g:vimrplugin_help_w : 73

            if wwidth > (min_e + min_h)
                " The editor window is large enough to be split as either >80+73 or
                " the user defined minimum values
                let s:hwidth = min_h
            elseif wwidth > (min_e + g:vimrplugin_help_w)
                " The help window must have less than min_h columns
                let s:hwidth = wwidth - min_e
            else
                " The help window must have the minimum value
                let s:hwidth = g:vimrplugin_help_w
            endif
            let htwf = (s:hwidth - 1) / 0.9
        endif
        let htw = printf("%f", htwf)
        let g:rplugin_htw = substitute(htw, "\\..*", "", "")
        if !(has("win32") || has("win64"))
            exe "language " . curlang
        endif
    endif
endfunction

function RGetClassFor(rkeyword)
    let classfor = ""
    let line = substitute(getline("."), '#.*', '', "")
    let begin = col(".")
    if strlen(line) > begin
        let piece = strpart(line, begin)
        while piece !~ '^' . a:rkeyword && begin >= 0
            let begin -= 1
            let piece = strpart(line, begin)
        endwhile
        let line = piece
        if line !~ '^\k*\s*('
            return classfor
        endif
        let begin = 1
        let linelen = strlen(line)
        while line[begin] != '(' && begin < linelen
            let begin += 1
        endwhile
        let begin += 1
        let line = strpart(line, begin)
        let line = substitute(line, '^\s*', '', "")
        if line =~ '^\k*\s*(' || line =~ '^\k*\s*=\s*\k*\s*('
            let idx = 0
            while line[idx] != '('
                let idx += 1
            endwhile
            let idx += 1
            let nparen = 1
            let len = strlen(line)
            let lnum = line(".")
            while nparen != 0
                if line[idx] == '('
                    let nparen += 1
                else
                    if line[idx] == ')'
                        let nparen -= 1
                    endif
                endif
                let idx += 1
                if idx == len
                    let lnum += 1
                    let line = line . substitute(getline(lnum), '#.*', '', "")
                    let len = strlen(line)
                endif
            endwhile
            let classfor = strpart(line, 0, idx)
        else
            let classfor = substitute(line, ').*', '', "")
            let classfor = substitute(classfor, ',.*', '', "")
            let classfor = substitute(classfor, ' .*', '', "")
        endif
    endif
    if classfor =~ "^'" && classfor =~ "'$"
        let classfor = substitute(classfor, "^'", '"', "")
        let classfor = substitute(classfor, "'$", '"', "")
    endif
    return classfor
endfunction

" Show R's help doc in Vim's buffer
" (based  on pydoc plugin)
function ShowRDoc(rkeyword, package, getclass)
    if !has("python") && !has("python3")
        call RWarningMsg("Python support is required to see R documentation on Vim.")
        return
    endif

    if filewritable(g:rplugin_docfile)
        call delete(g:rplugin_docfile)
    endif

    let classfor = ""
    if bufname("%") =~ "Object_Browser"
        let savesb = &switchbuf
        set switchbuf=useopen,usetab
        exe "sb " . b:rscript_buffer
        exe "set switchbuf=" . savesb
    else
        if a:getclass
            let classfor = RGetClassFor(a:rkeyword)
        endif
    endif

    if classfor =~ '='
        let classfor = "eval(expression(" . classfor . "))"
    endif

    if g:vimrplugin_vimpager == "tabnew"
        let s:rdoctitle = a:rkeyword . "\\ (help)" 
    else
        let s:tnr = tabpagenr()
        if g:vimrplugin_vimpager != "tab" && s:tnr > 1
            let s:rdoctitle = "R_doc" . s:tnr
        else
            let s:rdoctitle = "R_doc"
        endif
        unlet s:tnr
    endif

    call SetRTextWidth()

    let g:rplugin_lastrpl = "R did not reply."
    if classfor == "" && a:package == ""
        exe 'Py SendToR("vim.help(' . "'" . a:rkeyword . "', " . g:rplugin_htw . 'L)")'
    elseif a:package != ""
        exe 'Py SendToR("vim.help(' . "'" . a:rkeyword . "', " . g:rplugin_htw . "L, package='" . a:package  . "')". '")'
    else
        let classfor = substitute(classfor, '"', '\\"', "g")
        exe 'Py SendToR("vim.help(' . "'" . a:rkeyword . "', " . g:rplugin_htw . "L, '" . classfor . "')". '")'
    endif
    if g:rplugin_lastrpl != "VIMHELP"
        if g:rplugin_lastrpl =~ "^MULTILIB"
            echo "The topic '" . a:rkeyword . "' was found in more than one library:"
            let libs = split(g:rplugin_lastrpl)
            for idx in range(1, len(libs) - 1)
                echo idx . " : " . libs[idx]
            endfor
            let chn = input("Please, select one of them: ")
            if chn > 0 && chn < len(libs)
                exe 'Py SendToR("vim.help(' . "'" . a:rkeyword . "', " . g:rplugin_htw . "L, package='" . libs[chn] . "')" . '")'
            endif
        else
            call RWarningMsg(g:rplugin_lastrpl)
            return
        endif
    endif

    " Local variables that must be inherited by the rdoc buffer
    let g:tmp_screensname = b:screensname
    let g:tmp_objbrtitle = b:objbrtitle
    if g:vimrplugin_conqueplugin == 1
        let g:tmp_conqueshell = b:conqueshell
        let g:tmp_conque_bufname = b:conque_bufname
    endif

    let rdoccaption = substitute(s:rdoctitle, '\', '', "g")
    if bufloaded(rdoccaption)
        let curtabnr = tabpagenr()
        let savesb = &switchbuf
        set switchbuf=useopen,usetab
        exe "sb ". s:rdoctitle
        exe "set switchbuf=" . savesb
        if g:vimrplugin_vimpager == "tabnew"
            exe "tabmove " . curtabnr
        endif
    else
        if g:vimrplugin_vimpager == "tab" || g:vimrplugin_vimpager == "tabnew"
            exe 'tabnew ' . s:rdoctitle
        elseif s:vimpager == "vertical"
            let l:sr = &splitright
            set splitright
            exe s:hwidth . 'vsplit ' . s:rdoctitle
            let &splitright = l:sr
        elseif s:vimpager == "horizontal"
            exe 'split ' . s:rdoctitle
            if winheight(0) < 20
                resize 20
            endif
        else
            echohl WarningMsg
            echomsg "Invalid vimrplugin_vimpager value: '" . g:vimrplugin_vimpager . "'"
            echohl Normal
            return
        endif
    endif

    setlocal modifiable
    let g:rplugin_curbuf = bufname("%")

    " Inheritance of local variables from the script buffer
    let b:objbrtitle = g:tmp_objbrtitle
    let b:screensname = g:tmp_screensname
    unlet g:tmp_objbrtitle
    if g:vimrplugin_conqueplugin == 1
        let b:conqueshell = g:tmp_conqueshell
        let b:conque_bufname = g:tmp_conque_bufname
        unlet g:tmp_conqueshell
        unlet g:tmp_conque_bufname
    endif

    normal! ggdG
    exe "read " . g:rplugin_docfile
    set filetype=rdoc
    normal! ggdd
    setlocal nomodified
    setlocal nomodifiable
    redraw
endfunction

function BuildRHelpList()
    if !exists("s:list_of_objs")
        let s:list_of_objs = []
    endif
    for xx in g:rplugin_liblist
        let xxx = split(xx, "\x06")
        if xxx[0] !~ '\$'
            call add(s:list_of_objs, xxx[0])
        endif
    endfor
endfunction

function RLisObjs(arglead, cmdline, curpos)
    let lob = []
    let rkeyword = '^' . a:arglead
    for xx in s:list_of_objs
        if xx =~ rkeyword
            call add(lob, xx)
        endif
    endfor
    return lob
endfunction

function RSourceDirectory(...)
    if has("win32") || has("win64")
        let dir = substitute(a:1, '\\', '/', "g")
    else
        let dir = a:1
    endif
    if dir == ""
        call SendCmdToR("vim.srcdir()")
    else
        call SendCmdToR("vim.srcdir('" . dir . "')")
    endif
endfunction

function RAskHelp(...)
    if a:1 == ""
        call SendCmdToR("help.start()")
        return
    endif
    if g:vimrplugin_vimpager != "no"
        call ShowRDoc(a:1, "", 0)
    else
        call SendCmdToR("help(" . a:1. ")")
    endif
endfunction

function PrintRObject(rkeyword)
    if bufname("%") =~ "Object_Browser"
        let classfor = ""
    else
        let classfor = RGetClassFor(a:rkeyword)
    endif
    if classfor == ""
        call SendCmdToR("print(" . a:rkeyword . ")")
    else
        call SendCmdToR('vim.print("' . a:rkeyword . '", ' . classfor . ")")
    endif
endfunction

" Call R functions for the word under cursor
function RAction(rcmd)
    if &filetype == "rbrowser"
        let rkeyword = RBrowserGetName(1, line("."))
    else
        let rkeyword = RGetKeyWord()
    endif
    if strlen(rkeyword) > 0
        if a:rcmd == "help"
            if g:vimrplugin_vimpager == "no"
                call SendCmdToR("help(" . rkeyword . ")")
            else
                if bufname("%") =~ "Object_Browser" || exists("*RBrSendToR")
                    if g:rplugin_curview == "libraries"
                        let pkg = RBGetPkgName()
                    else
                        let pkg = ""
                    endif
                    if exists("b:this_is_ob")
                        if g:rplugin_edpane == "none"
                            call RWarningMsg("Cmd not available.")
                        else
                            let slog = system("tmux set-buffer '" . "\<Esc>" . ':call ShowRDoc("' . rkeyword . '", "' . pkg . '", 0)' . "\<C-M>' && tmux paste-buffer -t " . g:rplugin_edpane . " && tmux select-pane -t " . g:rplugin_edpane)
                            if v:shell_error
                                call RWarningMsg(slog)
                            endif
                        endif
                    else
                        call ShowRDoc(rkeyword, pkg, 0)
                    endif
                    return
                endif
                call ShowRDoc(rkeyword, "", 1)
            endif
            return
        endif
        if a:rcmd == "print"
            call PrintRObject(rkeyword)
            return
        endif
        let rfun = a:rcmd
        if a:rcmd == "args" && g:vimrplugin_listmethods == 1
            let rfun = "vim.list.args"
        endif
        if a:rcmd == "plot" && g:vimrplugin_specialplot == 1
            let rfun = "vim.plot"
        endif
        if a:rcmd == "plotsumm"
            if g:vimrplugin_specialplot == 1
                let raction = "vim.plot(" . rkeyword . "); summary(" . rkeyword . ")"
            else
                let raction = "plot(" . rkeyword . "); summary(" . rkeyword . ")"
            endif
            call SendCmdToR(raction)
            return
        endif

        let raction = rfun . "(" . rkeyword . ")"
        call SendCmdToR(raction)
    endif
endfunction

if exists('g:maplocalleader')
    let s:tll = '<Tab>' . g:maplocalleader
else
    let s:tll = '<Tab>\\'
endif

redir => s:ikblist
silent imap
redir END
redir => s:nkblist
silent nmap
redir END
redir => s:vkblist
silent vmap
redir END
let s:iskblist = split(s:ikblist, "\n")
let s:nskblist = split(s:nkblist, "\n")
let s:vskblist = split(s:vkblist, "\n")
let s:imaplist = []
let s:vmaplist = []
let s:nmaplist = []
for i in s:iskblist
    let si = split(i)
    if len(si) == 3 && si[2] =~ "<Plug>R"
        call add(s:imaplist, [si[1], si[2]])
    endif
endfor
for i in s:nskblist
    let si = split(i)
    if len(si) == 3 && si[2] =~ "<Plug>R"
        call add(s:nmaplist, [si[1], si[2]])
    endif
endfor
for i in s:vskblist
    let si = split(i)
    if len(si) == 3 && si[2] =~ "<Plug>R"
        call add(s:vmaplist, [si[1], si[2]])
    endif
endfor
unlet s:ikblist
unlet s:nkblist
unlet s:vkblist
unlet s:iskblist
unlet s:nskblist
unlet s:vskblist
unlet i
unlet si

function RNMapCmd(plug)
    for [el1, el2] in s:nmaplist
        if el2 == a:plug
            return el1
        endif
    endfor
endfunction

function RIMapCmd(plug)
    for [el1, el2] in s:imaplist
        if el2 == a:plug
            return el1
        endif
    endfor
endfunction

function RVMapCmd(plug)
    for [el1, el2] in s:vmaplist
        if el2 == a:plug
            return el1
        endif
    endfor
endfunction

function RCreateMenuItem(type, label, plug, combo, target)
    if a:type =~ '0'
        let tg = a:target . '<CR>0'
        let il = 'i'
    else
        let tg = a:target . '<CR>'
        let il = 'a'
    endif
    if a:type =~ "n"
        if hasmapto(a:plug, "n")
            let boundkey = RNMapCmd(a:plug)
            exec 'nmenu <silent> &R.' . a:label . '<Tab>' . boundkey . ' ' . tg
        else
            exec 'nmenu <silent> &R.' . a:label . s:tll . a:combo . ' ' . tg
        endif
    endif
    if a:type =~ "v"
        if hasmapto(a:plug, "v")
            let boundkey = RVMapCmd(a:plug)
            exec 'vmenu <silent> &R.' . a:label . '<Tab>' . boundkey . ' ' . '<Esc>' . tg
        else
            exec 'vmenu <silent> &R.' . a:label . s:tll . a:combo . ' ' . '<Esc>' . tg
        endif
    endif
    if a:type =~ "i"
        if hasmapto(a:plug, "i")
            let boundkey = RIMapCmd(a:plug)
            exec 'imenu <silent> &R.' . a:label . '<Tab>' . boundkey . ' ' . '<Esc>' . tg . il
        else
            exec 'imenu <silent> &R.' . a:label . s:tll . a:combo . ' ' . '<Esc>' . tg . il
        endif
    endif
endfunction

function RBrowserMenu()
    call RCreateMenuItem("nvi", 'Object\ browser.Show/Update', '<Plug>RUpdateObjBrowser', 'ro', ':call RObjBrowser()')
    call RCreateMenuItem("nvi", 'Object\ browser.Expand\ (all\ lists)', '<Plug>ROpenLists', 'r=', ':call RBrowserOpenCloseLists(1)')
    call RCreateMenuItem("nvi", 'Object\ browser.Collapse\ (all\ lists)', '<Plug>RCloseLists', 'r-', ':call RBrowserOpenCloseLists(0)')
    if &filetype == "rbrowser"
        imenu <silent> R.Object\ browser.Toggle\ (cur)<Tab>Enter <Esc>:call RBrowserDoubleClick()<CR>
        nmenu <silent> R.Object\ browser.Toggle\ (cur)<Tab>Enter :call RBrowserDoubleClick()<CR>
    endif
    let g:rplugin_hasmenu = 1
endfunction

function RControlMenu()
    call RCreateMenuItem("nvi", 'Command.List\ space', '<Plug>RListSpace', 'rl', ':call SendCmdToR("ls()")')
    call RCreateMenuItem("nvi", 'Command.Clear\ console\ screen', '<Plug>RClearConsole', 'rr', ':call RClearConsole()')
    call RCreateMenuItem("nvi", 'Command.Clear\ all', '<Plug>RClearAll', 'rm', ':call RClearAll()')
    "-------------------------------
    menu R.Command.-Sep1- <nul>
    call RCreateMenuItem("nvi", 'Command.Print\ (cur)', '<Plug>RObjectPr', 'rp', ':call RAction("print")')
    call RCreateMenuItem("nvi", 'Command.Names\ (cur)', '<Plug>RObjectNames', 'rn', ':call RAction("vim.names")')
    call RCreateMenuItem("nvi", 'Command.Structure\ (cur)', '<Plug>RObjectStr', 'rt', ':call RAction("str")')
    "-------------------------------
    menu R.Command.-Sep2- <nul>
    call RCreateMenuItem("nvi", 'Command.Arguments\ (cur)', '<Plug>RShowArgs', 'ra', ':call RAction("args")')
    call RCreateMenuItem("nvi", 'Command.Example\ (cur)', '<Plug>RShowEx', 're', ':call RAction("example")')
    call RCreateMenuItem("nvi", 'Command.Help\ (cur)', '<Plug>RHelp', 'rh', ':call RAction("help")')
    "-------------------------------
    menu R.Command.-Sep3- <nul>
    call RCreateMenuItem("nvi", 'Command.Summary\ (cur)', '<Plug>RSummary', 'rs', ':call RAction("summary")')
    call RCreateMenuItem("nvi", 'Command.Plot\ (cur)', '<Plug>RPlot', 'rg', ':call RAction("plot")')
    call RCreateMenuItem("nvi", 'Command.Plot\ and\ summary\ (cur)', '<Plug>RSPlot', 'rb', ':call RAction("plotsumm")')
    let g:rplugin_hasmenu = 1
endfunction

function RControlMaps()
    " List space, clear console, clear all
    "-------------------------------------
    call RCreateMaps("nvi", '<Plug>RListSpace',    'rl', ':call SendCmdToR("ls()")')
    call RCreateMaps("nvi", '<Plug>RClearConsole', 'rr', ':call RClearConsole()')
    call RCreateMaps("nvi", '<Plug>RClearAll',     'rm', ':call RClearAll()')

    " Print, names, structure
    "-------------------------------------
    call RCreateMaps("nvi", '<Plug>RObjectPr',     'rp', ':call RAction("print")')
    call RCreateMaps("nvi", '<Plug>RObjectNames',  'rn', ':call RAction("vim.names")')
    call RCreateMaps("nvi", '<Plug>RObjectStr',    'rt', ':call RAction("str")')

    " Arguments, example, help
    "-------------------------------------
    call RCreateMaps("nvi", '<Plug>RShowArgs',     'ra', ':call RAction("args")')
    call RCreateMaps("nvi", '<Plug>RShowEx',       're', ':call RAction("example")')
    call RCreateMaps("nvi", '<Plug>RHelp',         'rh', ':call RAction("help")')

    " Summary, plot, both
    "-------------------------------------
    call RCreateMaps("nvi", '<Plug>RSummary',      'rs', ':call RAction("summary")')
    call RCreateMaps("nvi", '<Plug>RPlot',         'rg', ':call RAction("plot")')
    call RCreateMaps("nvi", '<Plug>RSPlot',        'rb', ':call RAction("plotsumm")')

    " Build list of objects for omni completion
    "-------------------------------------
    call RCreateMaps("nvi", '<Plug>RUpdateObjBrowser', 'ro', ':call RObjBrowser()')
    call RCreateMaps("nvi", '<Plug>ROpenLists',        'r=', ':call RBrowserOpenCloseLists(1)')
    call RCreateMaps("nvi", '<Plug>RCloseLists',       'r-', ':call RBrowserOpenCloseLists(0)')
endfunction


" For each noremap we need a vnoremap including <Esc> before the :call,
" otherwise vim will call the function as many times as the number of selected
" lines. If we put the <Esc> in the noremap, vim will bell.
" RCreateMaps Args:
"   type : modes to which create maps (normal, visual and insert) and whether
"          the cursor have to go the beginning of the line
"   plug : the <Plug>Name
"   combo: the combination of letter that make the shortcut
"   target: the command or function to be called
function RCreateMaps(type, plug, combo, target)
    if a:type =~ '0'
        let tg = a:target . '<CR>0'
        let il = 'i'
    else
        let tg = a:target . '<CR>'
        let il = 'a'
    endif
    if a:type =~ "n"
        if hasmapto(a:plug, "n")
            exec 'noremap <buffer><silent> ' . a:plug . ' ' . tg
        else
            exec 'noremap <buffer><silent> <LocalLeader>' . a:combo . ' ' . tg
        endif
    endif
    if a:type =~ "v"
        if hasmapto(a:plug, "v")
            exec 'vnoremap <buffer><silent> ' . a:plug . ' <Esc>' . tg
        else
            exec 'vnoremap <buffer><silent> <LocalLeader>' . a:combo . ' <Esc>' . tg
        endif
    endif
    if a:type =~ "i"
        if hasmapto(a:plug, "i")
            exec 'inoremap <buffer><silent> ' . a:plug . ' <Esc>' . tg . il
        else
            exec 'inoremap <buffer><silent> <LocalLeader>' . a:combo . ' <Esc>' . tg . il
        endif
    endif
endfunction

function MakeRMenu()
    if g:rplugin_hasmenu == 1
        return
    endif

    " Do not translate "File":
    menutranslate clear

    "----------------------------------------------------------------------------
    " Start/Close
    "----------------------------------------------------------------------------
    call RCreateMenuItem("nvi", 'Start/Close.Start\ R\ (default)', '<Plug>RStart', 'rf', ':call StartR("R")')
    call RCreateMenuItem("nvi", 'Start/Close.Start\ R\ --vanilla', '<Plug>RVanillaStart', 'rv', ':call StartR("vanilla")')
    call RCreateMenuItem("nvi", 'Start/Close.Start\ R\ (custom)', '<Plug>RCustomStart', 'rc', ':call StartR("custom")')
    "-------------------------------
    menu R.Start/Close.-Sep1- <nul>
    call RCreateMenuItem("nvi", 'Start/Close.Close\ R\ (no\ save)', '<Plug>RClose', 'rq', ":call RQuit('no')")

    "----------------------------------------------------------------------------
    " Send
    "----------------------------------------------------------------------------
    if &filetype == "r" || g:vimrplugin_never_unmake_menu
        call RCreateMenuItem("ni", 'Send.File', '<Plug>RSendFile', 'aa', ':call SendFileToR("silent")')
        call RCreateMenuItem("ni", 'Send.File\ (echo)', '<Plug>RESendFile', 'ae', ':call SendFileToR("echo")')
        call RCreateMenuItem("ni", 'Send.File\ (open\ \.Rout)', '<Plug>RShowRout', 'ao', ':call ShowRout()')
    endif
    "-------------------------------
    menu R.Send.-Sep1- <nul>
    call RCreateMenuItem("ni", 'Send.Block\ (cur)', '<Plug>RSendMBlock', 'bb', ':call SendMBlockToR("silent", "stay")')
    call RCreateMenuItem("ni", 'Send.Block\ (cur,\ echo)', '<Plug>RESendMBlock', 'be', ':call SendMBlockToR("echo", "stay")')
    call RCreateMenuItem("ni", 'Send.Block\ (cur,\ down)', '<Plug>RDSendMBlock', 'bd', ':call SendMBlockToR("silent", "down")')
    call RCreateMenuItem("ni", 'Send.Block\ (cur,\ echo\ and\ down)', '<Plug>REDSendMBlock', 'ba', ':call SendMBlockToR("echo", "down")')
    "-------------------------------
    if &filetype == "rnoweb" || g:vimrplugin_never_unmake_menu
        menu R.Send.-Sep2- <nul>
        call RCreateMenuItem("ni", 'Send.Chunk\ (cur)', '<Plug>RSendChunk', 'cc', ':call SendChunkToR("silent", "stay")')
        call RCreateMenuItem("ni", 'Send.Chunk\ (cur,\ echo)', '<Plug>RESendChunk', 'ce', ':call SendChunkToR("echo", "stay")')
        call RCreateMenuItem("ni", 'Send.Chunk\ (cur,\ down)', '<Plug>RDSendChunk', 'cd', ':call SendChunkToR("silent", "down")')
        call RCreateMenuItem("ni", 'Send.Chunk\ (cur,\ echo\ and\ down)', '<Plug>REDSendChunk', 'ca', ':call SendChunkToR("echo", "down")')
    endif
    "-------------------------------
    menu R.Send.-Sep3- <nul>
    call RCreateMenuItem("ni", 'Send.Function\ (cur)', '<Plug>RSendFunction', 'ff', ':call SendFunctionToR("silent", "stay")')
    call RCreateMenuItem("ni", 'Send.Function\ (cur,\ echo)', '<Plug>RESendFunction', 'fe', ':call SendFunctionToR("echo", "stay")')
    call RCreateMenuItem("ni", 'Send.Function\ (cur\ and\ down)', '<Plug>RDSendFunction', 'fd', ':call SendFunctionToR("silent", "down")')
    call RCreateMenuItem("ni", 'Send.Function\ (cur,\ echo\ and\ down)', '<Plug>REDSendFunction', 'fa', ':call SendFunctionToR("echo", "down")')
    "-------------------------------
    menu R.Send.-Sep4- <nul>
    call RCreateMenuItem("v", 'Send.Selection', '<Plug>RSendSelection', 'ss', ':call SendSelectionToR("silent", "stay")')
    call RCreateMenuItem("v", 'Send.Selection\ (echo)', '<Plug>RESendSelection', 'se', ':call SendSelectionToR("echo", "stay")')
    call RCreateMenuItem("v", 'Send.Selection\ (and\ down)', '<Plug>RDSendSelection', 'sd', ':call SendSelectionToR("silent", "down")')
    call RCreateMenuItem("v", 'Send.Selection\ (echo\ and\ down)', '<Plug>REDSendSelection', 'sa', ':call SendSelectionToR("echo", "down")')
    "-------------------------------
    menu R.Send.-Sep5- <nul>
    call RCreateMenuItem("ni", 'Send.Paragraph', '<Plug>RSendParagraph', 'pp', ':call SendParagraphToR("silent", "stay")')
    call RCreateMenuItem("ni", 'Send.Paragraph\ (echo)', '<Plug>RESendParagraph', 'pe', ':call SendParagraphToR("echo", "stay")')
    call RCreateMenuItem("ni", 'Send.Paragraph\ (and\ down)', '<Plug>RDSendParagraph', 'pd', ':call SendParagraphToR("silent", "down")')
    call RCreateMenuItem("ni", 'Send.Paragraph\ (echo\ and\ down)', '<Plug>REDSendParagraph', 'pa', ':call SendParagraphToR("echo", "down")')
    "-------------------------------
    menu R.Send.-Sep6- <nul>
    call RCreateMenuItem("ni0", 'Send.Line', '<Plug>RSendLine', 'l', ':call SendLineToR("stay")')
    call RCreateMenuItem("ni0", 'Send.Line\ (and\ down)', '<Plug>RDSendLine', 'd', ':call SendLineToR("down")')
    call RCreateMenuItem("i", 'Send.Line\ (and\ new\ one)', '<Plug>RSendLAndOpenNewOne', 'q', ':call SendLineToR("newline")')
    call RCreateMenuItem("n", 'Send.Left\ part\ of\ line\ (cur)', '<Plug>RNLeftPart', 'r<Left>', ':call RSendPartOfLine("left", 0)')
    call RCreateMenuItem("n", 'Send.Right\ part\ of\ line\ (cur)', '<Plug>RNRightPart', 'r<Right>', ':call RSendPartOfLine("right", 0)')
    call RCreateMenuItem("i", 'Send.Left\ part\ of\ line\ (cur)', '<Plug>RILeftPart', 'r<Left>', 'l:call RSendPartOfLine("left", 1)')
    call RCreateMenuItem("i", 'Send.Right\ part\ of\ line\ (cur)', '<Plug>RIRightPart', 'r<Right>', 'l:call RSendPartOfLine("right", 1)')

    "----------------------------------------------------------------------------
    " Control
    "----------------------------------------------------------------------------
    call RControlMenu()
    "-------------------------------
    menu R.Command.-Sep4- <nul>
    if &filetype != "rdoc"
        call RCreateMenuItem("nvi", 'Command.Set\ working\ directory\ (cur\ file\ path)', '<Plug>RSetwd', 'rd', ':call RSetWD()')
    endif
    "-------------------------------
    if &filetype == "rnoweb" || g:vimrplugin_never_unmake_menu
        menu R.Command.-Sep5- <nul>
        call RCreateMenuItem("nvi", 'Command.Sweave\ (cur\ file)', '<Plug>RSweave', 'sw', ':call RSweave()')
        call RCreateMenuItem("nvi", 'Command.Sweave\ and\ PDF\ (cur\ file)', '<Plug>RMakePDF', 'sp', ':call RMakePDF("nobib")')
        call RCreateMenuItem("nvi", 'Command.Sweave,\ BibTeX\ and\ PDF\ (cur\ file)', '<Plug>RMakePDF', 'sb', ':call RMakePDF("bibtex")')
        menu R.Command.-Sep6- <nul>
        call RCreateMenuItem("nvi", 'Command.Knit\ (cur\ file)', '<Plug>RSweave', 'kn', ':call RSweave()')
        call RCreateMenuItem("nvi", 'Command.Knit\ and\ PDF\ (cur\ file)', '<Plug>RMakePDF', 'kp', ':call RMakePDF("nobib")')
        call RCreateMenuItem("nvi", 'Command.Knit,\ BibTeX\ and\ PDF\ (cur\ file)', '<Plug>RMakePDF', 'kb', ':call RMakePDF("bibtex")')
    endif
    "-------------------------------
    menu R.Command.-Sep7- <nul>
    if &filetype == "r" || &filetype == "rnoweb" || g:vimrplugin_never_unmake_menu
        nmenu <silent> R.Command.Build\ tags\ file\ (cur\ dir)<Tab>:RBuildTags :call SendCmdToR('rtags(ofile = "TAGS")')<CR>
        imenu <silent> R.Command.Build\ tags\ file\ (cur\ dir)<Tab>:RBuildTags <Esc>:call SendCmdToR('rtags(ofile = "TAGS")')<CR>a
    endif

    menu R.-Sep7- <nul>

    "----------------------------------------------------------------------------
    " Edit
    "----------------------------------------------------------------------------
    if &filetype == "r" || &filetype == "rnoweb" || &filetype == "rhelp" || g:vimrplugin_never_unmake_menu
        if g:vimrplugin_underscore == 1
            imenu <silent> R.Edit.Insert\ \"\ <-\ \"<Tab>_ <Esc>:call ReplaceUnderS()<CR>a
            imenu <silent> R.Edit.Complete\ object\ name<Tab>^X^O <C-X><C-O>
            if hasmapto("<Plug>RCompleteArgs", "i")
                let boundkey = RIMapCmd("<Plug>RCompleteArgs")
                exe "imenu <silent> R.Edit.Complete\\ function\\ arguments<Tab>" . boundkey . " " . boundkey
            else
                imenu <silent> R.Edit.Complete\ function\ arguments<Tab>^X^A <C-X><C-A>
            endif
        endif
        menu R.Edit.-Sep71- <nul>
        nmenu <silent> R.Edit.Indent\ (line)<Tab>== ==
        vmenu <silent> R.Edit.Indent\ (selected\ lines)<Tab>= =
        nmenu <silent> R.Edit.Indent\ (whole\ buffer)<Tab>gg=G gg=G
        menu R.Edit.-Sep72- <nul>
        call RCreateMenuItem("ni", 'Edit.Comment/Uncomment\ (line/sel)', '<Plug>RCommentLine', 'xx', ':call RComment("normal")')
        call RCreateMenuItem("v", 'Edit.Comment/Uncomment\ (line/sel)', '<Plug>RCommentLine', 'xx', ':call RComment("selection")')
        call RCreateMenuItem("ni", 'Edit.Add/Align\ right\ comment\ (line,\ sel)', '<Plug>RRightComment', ';', ':call MovePosRCodeComment("normal")')
        call RCreateMenuItem("v", 'Edit.Add/Align\ right\ comment\ (line,\ sel)', '<Plug>RRightComment', ';', ':call MovePosRCodeComment("selection")')
        if &filetype == "rnoweb" || g:vimrplugin_never_unmake_menu
            menu R.Edit.-Sep73- <nul>
            nmenu <silent> R.Edit.Go\ (next\ R\ chunk)<Tab>gn :call RnwNextChunk()<CR>
            nmenu <silent> R.Edit.Go\ (previous\ R\ chunk)<Tab>gN :call RnwPreviousChunk()<CR>
        endif
    endif

    "----------------------------------------------------------------------------
    " Object Browser
    "----------------------------------------------------------------------------
    call RBrowserMenu()

    "----------------------------------------------------------------------------
    " Syntax
    "----------------------------------------------------------------------------
    nmenu <silent> R.Syntax.Build\ omniList\ (loaded)<Tab>:RUpdateObjList :call RBuildSyntaxFile("loaded")<CR>
    imenu <silent> R.Syntax.Build\ omniList\ (loaded)<Tab>:RUpdateObjList <Esc>:call RBuildSyntaxFile("loaded")<CR>a

    "----------------------------------------------------------------------------
    " Help
    "----------------------------------------------------------------------------
    menu R.-Sep8- <nul>
    amenu R.Help\ (plugin).Overview :help r-plugin-overview<CR>
    amenu R.Help\ (plugin).Main\ features :help r-plugin-features<CR>
    amenu R.Help\ (plugin).Installation :help r-plugin-installation<CR>
    amenu R.Help\ (plugin).Use :help r-plugin-use<CR>
    amenu R.Help\ (plugin).How\ the\ plugin\ works :help r-plugin-functioning<CR>
    amenu R.Help\ (plugin).Known\ bugs\ and\ workarounds :help r-plugin-known-bugs<CR>

    amenu R.Help\ (plugin).Options.Underscore\ and\ Rnoweb\ code :help vimrplugin_underscore<CR>
    amenu R.Help\ (plugin).Options.Object\ Browser :help vimrplugin_objbr_place<CR>
    amenu R.Help\ (plugin).Options.Vim\ as\ pager\ for\ R\ help :help vimrplugin_vimpager<CR>
    if !has("gui_win32")
        amenu R.Help\ (plugin).Options.Terminal\ emulator :help vimrplugin_term<CR>
        amenu R.Help\ (plugin).Options.Number\ of\ R\ processes :help vimrplugin_nosingler<CR>
        amenu R.Help\ (plugin).Options.Screen\ configuration :help vimrplugin_noscreenrc<CR>
        amenu R.Help\ (plugin).Options.Screen\ plugin :help vimrplugin_screenplugin<CR>
    endif
    if has("gui_macvim") || has("gui_mac") || has("mac") || has("macunix")
        amenu R.Help\ (plugin).Options.Integration\ with\ Apple\ Script :help vimrplugin_applescript<CR>
    endif
    if has("gui_win32")
        amenu R.Help\ (plugin).Options.Use\ 32\ bit\ version\ of\ R :help vimrplugin_i386<CR>
        amenu R.Help\ (plugin).Options.Sleep\ time :help vimrplugin_sleeptime<CR>
    endif
    amenu R.Help\ (plugin).Options.R\ path :help vimrplugin_r_path<CR>
    amenu R.Help\ (plugin).Options.Arguments\ to\ R :help vimrplugin_r_args<CR>
    amenu R.Help\ (plugin).Options.Time\ building\ omniList :help vimrplugin_buildwait<CR>
    amenu R.Help\ (plugin).Options.Syntax\ highlighting\ of\ \.Rout\ files :help vimrplugin_routmorecolors<CR>
    amenu R.Help\ (plugin).Options.Automatically\ open\ the\ \.Rout\ file :help vimrplugin_routnotab<CR>
    amenu R.Help\ (plugin).Options.Special\ R\ functions :help vimrplugin_listmethods<CR>
    amenu R.Help\ (plugin).Options.Indent\ commented\ lines :help vimrplugin_indent_commented<CR>
    amenu R.Help\ (plugin).Options.maxdeparse :help vimrplugin_maxdeparse<CR>
    amenu R.Help\ (plugin).Options.LaTeX\ command :help vimrplugin_latexcmd<CR>
    amenu R.Help\ (plugin).Options.Never\ unmake\ the\ R\ menu :help vimrplugin_never_unmake_menu<CR>

    amenu R.Help\ (plugin).Custom\ key\ bindings :help r-plugin-key-bindings<CR>
    amenu R.Help\ (plugin).Files :help r-plugin-files<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.All\ tips :help r-plugin-tips<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Indenting\ setup :help r-plugin-indenting<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Folding\ setup :help r-plugin-folding<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Remap\ LocalLeader :help r-plugin-localleader<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Customize\ key\ bindings :help r-plugin-bindings<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.SnipMate :help r-plugin-snippets<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Highlight\ marks :help r-plugin-showmarks<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Global\ plugin :help r-plugin-global<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Jump\ to\ function\ definitions :help r-plugin-tagsfile<CR>
    amenu R.Help\ (plugin).News :help r-plugin-news<CR>

    amenu R.Help\ (R)<Tab>:Rhelp :call SendCmdToR("help.start()")<CR>
    let g:rplugin_hasmenu = 1

    "----------------------------------------------------------------------------
    " ToolBar
    "----------------------------------------------------------------------------
    " Buttons
    amenu <silent> ToolBar.RStart :call StartR("R")<CR>
    amenu <silent> ToolBar.RClose :call RQuit('no')<CR>
    "---------------------------
    if &filetype == "r" || g:vimrplugin_never_unmake_menu
        nmenu <silent> ToolBar.RSendFile :call SendFileToR("echo")<CR>
        imenu <silent> ToolBar.RSendFile <Esc>:call SendFileToR("echo")<CR>
    endif
    nmenu <silent> ToolBar.RSendBlock :call SendMBlockToR("echo", "down")<CR>
    imenu <silent> ToolBar.RSendBlock <Esc>:call SendMBlockToR("echo", "down")<CR>
    nmenu <silent> ToolBar.RSendFunction :call SendFunctionToR("echo", "down")<CR>
    imenu <silent> ToolBar.RSendFunction <Esc>:call SendFunctionToR("echo", "down")<CR>
    vmenu <silent> ToolBar.RSendSelection <ESC>:call SendSelectionToR("echo", "down")<CR>
    nmenu <silent> ToolBar.RSendParagraph :call SendParagraphToR("echo", "down")<CR>
    imenu <silent> ToolBar.RSendParagraph <Esc>:call SendParagraphToR("echo", "down")<CR>
    nmenu <silent> ToolBar.RSendLine :call SendLineToR("down")<CR>
    imenu <silent> ToolBar.RSendLine <Esc>:call SendLineToR("down")<CR>
    "---------------------------
    nmenu <silent> ToolBar.RListSpace :call SendCmdToR("ls()")<CR>
    imenu <silent> ToolBar.RListSpace <Esc>:call SendCmdToR("ls()")<CR>
    nmenu <silent> ToolBar.RClear :call RClearConsole()<CR>
    imenu <silent> ToolBar.RClear <Esc>:call RClearConsole()<CR>
    nmenu <silent> ToolBar.RClearAll :call RClearAll()<CR>
    imenu <silent> ToolBar.RClearAll <Esc>:call RClearAll()<CR>

    " Hints
    tmenu ToolBar.RStart Start R (default)
    tmenu ToolBar.RClose Close R (no save)
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
    let g:rplugin_hasbuttons = 1
endfunction

function UnMakeRMenu()
    if g:rplugin_hasmenu == 0 || g:vimrplugin_never_unmake_menu == 1 || &previewwindow || (&buftype == "nofile" && &filetype != "conque_term" && &filetype != "rbrowser")
        return
    endif
    aunmenu R
    let g:rplugin_hasmenu = 0
    if g:rplugin_hasbuttons
        aunmenu ToolBar.RClearAll
        aunmenu ToolBar.RClear
        aunmenu ToolBar.RListSpace
        aunmenu ToolBar.RSendLine
        aunmenu ToolBar.RSendSelection
        aunmenu ToolBar.RSendParagraph
        aunmenu ToolBar.RSendFunction
        aunmenu ToolBar.RSendBlock
        if g:rplugin_lastft == "r"
            aunmenu ToolBar.RSendFile
        endif
        aunmenu ToolBar.RClose
        aunmenu ToolBar.RStart
        let g:rplugin_hasbuttons = 0
    endif
endfunction


function SpaceForRGrDevice()
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

function RCreateStartMaps()
    " Start
    "-------------------------------------
    call RCreateMaps("nvi", '<Plug>RStart',        'rf', ':call StartR("R")')
    call RCreateMaps("nvi", '<Plug>RVanillaStart', 'rv', ':call StartR("vanilla")')
    call RCreateMaps("nvi", '<Plug>RCustomStart',  'rc', ':call StartR("custom")')

    " Close
    "-------------------------------------
    call RCreateMaps("nvi", '<Plug>RClose',        'rq', ":call RQuit('nosave')")
    call RCreateMaps("nvi", '<Plug>RSaveClose',    'rw', ":call RQuit('save')")

endfunction

function RCreateEditMaps()
    " Edit
    "-------------------------------------
    call RCreateMaps("ni", '<Plug>RCommentLine',   'xx', ':call RComment("normal")')
    call RCreateMaps("v", '<Plug>RCommentLine',   'xx', ':call RComment("selection")')
    call RCreateMaps("ni", '<Plug>RRightComment',   ';', ':call MovePosRCodeComment("normal")')
    call RCreateMaps("v", '<Plug>RRightComment',    ';', ':call MovePosRCodeComment("selection")')
    " Replace 'underline' with '<-'
    if g:vimrplugin_underscore == 1
        imap <buffer><silent> _ <Esc>:call ReplaceUnderS()<CR>a
    endif
    if hasmapto("<Plug>RCompleteArgs", "i")
        imap <buffer><silent> <Plug>RCompleteArgs <C-R>=RCompleteArgs()<CR>
    else
        imap <buffer><silent> <C-X><C-A> <C-R>=RCompleteArgs()<CR>
    endif
endfunction

function RCreateSendMaps()
    " Block
    "-------------------------------------
    call RCreateMaps("ni", '<Plug>RSendMBlock',     'bb', ':call SendMBlockToR("silent", "stay")')
    call RCreateMaps("ni", '<Plug>RESendMBlock',    'be', ':call SendMBlockToR("echo", "stay")')
    call RCreateMaps("ni", '<Plug>RDSendMBlock',    'bd', ':call SendMBlockToR("silent", "down")')
    call RCreateMaps("ni", '<Plug>REDSendMBlock',   'ba', ':call SendMBlockToR("echo", "down")')

    " Function
    "-------------------------------------
    call RCreateMaps("nvi", '<Plug>RSendFunction',  'ff', ':call SendFunctionToR("silent", "stay")')
    call RCreateMaps("nvi", '<Plug>RDSendFunction', 'fe', ':call SendFunctionToR("echo", "stay")')
    call RCreateMaps("nvi", '<Plug>RDSendFunction', 'fd', ':call SendFunctionToR("silent", "down")')
    call RCreateMaps("nvi", '<Plug>RDSendFunction', 'fa', ':call SendFunctionToR("echo", "down")')

    " Selection
    "-------------------------------------
    call RCreateMaps("v", '<Plug>RSendSelection',   'ss', ':call SendSelectionToR("silent", "stay")')
    call RCreateMaps("v", '<Plug>RESendSelection',  'se', ':call SendSelectionToR("echo", "stay")')
    call RCreateMaps("v", '<Plug>RDSendSelection',  'sd', ':call SendSelectionToR("silent", "down")')
    call RCreateMaps("v", '<Plug>REDSendSelection', 'sa', ':call SendSelectionToR("echo", "down")')

    " Paragraph
    "-------------------------------------
    call RCreateMaps("ni", '<Plug>RSendParagraph',   'pp', ':call SendParagraphToR("silent", "stay")')
    call RCreateMaps("ni", '<Plug>RESendParagraph',  'pe', ':call SendParagraphToR("echo", "stay")')
    call RCreateMaps("ni", '<Plug>RDSendParagraph',  'pd', ':call SendParagraphToR("silent", "down")')
    call RCreateMaps("ni", '<Plug>REDSendParagraph', 'pa', ':call SendParagraphToR("echo", "down")')

    " *Line*
    "-------------------------------------
    call RCreateMaps("ni0", '<Plug>RSendLine', 'l', ':call SendLineToR("stay")')
    call RCreateMaps('ni0', '<Plug>RDSendLine', 'd', ':call SendLineToR("down")')
    call RCreateMaps('i', '<Plug>RSendLAndOpenNewOne', 'q', ':call SendLineToR("newline")')
    nmap <LocalLeader>r<Left> :call RSendPartOfLine("left", 0)<CR>
    imap <LocalLeader>r<Left> <Esc>l:call RSendPartOfLine("left", 0)<CR>i
    nmap <LocalLeader>r<Right> :call RSendPartOfLine("right", 0)<CR>
    imap <LocalLeader>r<Right> <Esc>l:call RSendPartOfLine("right", 0)<CR>i

    " For compatibility with Johannes Ranke's plugin
    if g:vimrplugin_map_r == 1
        vnoremap <buffer><silent> r <Esc>:call SendSelectionToR("silent", "down")<CR>
    endif
endfunction

function RBufEnter()
    if &filetype != g:rplugin_lastft
        call UnMakeRMenu()
        if &filetype == "r" || &filetype == "rnoweb" || &filetype == "rdoc" || &filetype == "rbrowser" || &filetype == "rhelp"
            if &filetype == "rbrowser"
                call MakeRBrowserMenu()
            else
                call MakeRMenu()
            endif
        endif
    endif
    if &buftype != "nofile" || &filetype == "conque_term" || &filetype == "rbrowser"
        let g:rplugin_lastft = &filetype
    endif
endfunction

function SetRPath()
    if exists("g:vimrplugin_r_path")
        if isdirectory(g:vimrplugin_r_path)
            let b:rplugin_R = g:vimrplugin_r_path . "/R"
        else
            let b:rplugin_R = g:vimrplugin_r_path
        endif
    else
        let b:rplugin_R = "R"
    endif
    if !exists("g:vimrplugin_r_args")
        let b:rplugin_r_args = " "
    else
        let b:rplugin_r_args = g:vimrplugin_r_args
    endif
endfunction

command RUpdateObjList :call RBuildSyntaxFile("loaded")
command RBuildTags :call SendCmdToR('rtags(ofile = "TAGS")')
command -nargs=? -complete=customlist,RLisObjs Rhelp :call RAskHelp(<q-args>)
command -nargs=? -complete=dir RSourceDir :call RSourceDirectory(<q-args>)

"==========================================================================
" Global variables
" Convention: vimrplugin_ for user options
"             rplugin_    for internal parameters
"==========================================================================

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

" From changelog.vim, with bug fixed by "Si" ("i5ivem")
" Windows logins can include domain, e.g: 'DOMAIN\Username', need to remove
" the backslash from this as otherwise cause file path problems.
let g:rplugin_userlogin = substitute(system('whoami'), "\\", "-", "")

if v:shell_error
    let g:rplugin_userlogin = 'unknown'
else
    let newuline = stridx(g:rplugin_userlogin, "\n")
    if newuline != -1
        let g:rplugin_userlogin = strpart(g:rplugin_userlogin, 0, newuline)
    endif
    unlet newuline
endif

if has("win32") || has("win64")
    let g:rplugin_home = substitute(g:rplugin_home, "\\", "/", "g")
    let g:rplugin_uservimfiles = substitute(g:rplugin_uservimfiles, "\\", "/", "g")
endif

if isdirectory("/tmp")
    let $VIMRPLUGIN_TMPDIR = "/tmp/r-plugin-" . g:rplugin_userlogin
else
    let $VIMRPLUGIN_TMPDIR = g:rplugin_uservimfiles . "/r-plugin"
endif

if !isdirectory($VIMRPLUGIN_TMPDIR)
    call mkdir($VIMRPLUGIN_TMPDIR, "p", 0700)
endif

let g:rplugin_docfile = $VIMRPLUGIN_TMPDIR . "/Rdoc"
let g:rplugin_globalenvfname = $VIMRPLUGIN_TMPDIR . "/GlobalEnvList"

" Variables whose default value is fixed
call RSetDefaultValue("g:vimrplugin_map_r",             0)
call RSetDefaultValue("g:vimrplugin_allnames",          0)
call RSetDefaultValue("g:vimrplugin_underscore",        1)
call RSetDefaultValue("g:vimrplugin_rnowebchunk",       1)
call RSetDefaultValue("g:vimrplugin_i386",              0)
call RSetDefaultValue("g:vimrplugin_screenvsplit",      0)
call RSetDefaultValue("g:vimrplugin_conquevsplit",      0)
call RSetDefaultValue("g:vimrplugin_conqueplugin",      0)
call RSetDefaultValue("g:vimrplugin_listmethods",       0)
call RSetDefaultValue("g:vimrplugin_specialplot",       0)
call RSetDefaultValue("g:vimrplugin_nosingler",         0)
call RSetDefaultValue("g:vimrplugin_noscreenrc",        0)
call RSetDefaultValue("g:vimrplugin_notmuxconf",        0)
call RSetDefaultValue("g:vimrplugin_routnotab",         0) 
call RSetDefaultValue("g:vimrplugin_editor_w",         66)
call RSetDefaultValue("g:vimrplugin_help_w",           46)
call RSetDefaultValue("g:vimrplugin_objbr_w",          40)
call RSetDefaultValue("g:vimrplugin_external_ob",       0)
call RSetDefaultValue("g:vimrplugin_buildwait",        60)
call RSetDefaultValue("g:vimrplugin_indent_commented",  1)
call RSetDefaultValue("g:vimrplugin_by_vim_instance",   0)
call RSetDefaultValue("g:vimrplugin_never_unmake_menu", 0)
call RSetDefaultValue("g:vimrplugin_vimpager",       "'tab'")
call RSetDefaultValue("g:vimrplugin_latexcmd", "'pdflatex'")
call RSetDefaultValue("g:vimrplugin_objbr_place", "'script,right'")


" python has priority over python3, unless ConqueTerm_PyVersion == 3
if has("python3") && exists("g:ConqueTerm_PyVersion") && g:ConqueTerm_PyVersion == 3
    command! -nargs=+ Py :py3 <args>
    command! -nargs=+ PyFile :py3file <args>
elseif has("python")
    command! -nargs=+ Py :py <args>
    command! -nargs=+ PyFile :pyfile <args>
elseif has("python3")
    command! -nargs=+ Py :py3 <args>
    command! -nargs=+ PyFile :py3file <args>
else
    command! -nargs=+ Py :
    command! -nargs=+ PyFile :
endif

exe "PyFile " . g:rplugin_home . "/r-plugin/vimcom.py"

" ^K (\013) cleans from cursor to the right and ^U (\025) cleans from cursor
" to the left. However, ^U causes a beep if there is nothing to clean. The
" solution is to use ^A (\001) to move the cursor to the beginning of the line
" before sending ^K. But the control characters may cause problems in some
" circumstances.
call RSetDefaultValue("g:vimrplugin_ca_ck", 0)

if has("gui_macvim") || has("gui_mac") || has("mac") || has("macunix")
    call RSetDefaultValue("g:vimrplugin_applescript", 1)
else
    call RSetDefaultValue("g:vimrplugin_applescript", 0)
endif

if g:vimrplugin_applescript == 0
    call RSetDefaultValue("g:vimrplugin_screenplugin", 1)
    call RSetDefaultValue("g:vimrplugin_tmux", 1)
else
    let g:vimrplugin_screenplugin = 0
    let g:vimrplugin_conqueplugin = 0
    let g:vimrplugin_tmux = 0
    if isdirectory("/Applications/R64.app")
        let g:rplugin_r64app = 1
    else
        let g:rplugin_r64app = 0
    endif
endif

" The screen.vim plugin only works on terminal emulators
if has('gui_running')
    let g:vimrplugin_screenplugin = 0
endif

if has("win32") || has("win64")
    call RSetDefaultValue("g:vimrplugin_conquesleep", 200)
    let vimrplugin_screenplugin = 0
    let vimrplugin_tmux = 0
else
    call RSetDefaultValue("g:vimrplugin_conquesleep", 100)
endif

if g:vimrplugin_applescript == 0 && !(has("win32") || has("win64"))
    let s:hastmux = executable('tmux')
    let s:hasscreen = executable('screen')
    if s:hastmux == 0 && s:hasscreen == 0 && g:vimrplugin_conqueplugin == 0
        call RWarningMsgInp("Please, install the 'Tmux' application to enable the Vim-R-plugin.")
        let g:rplugin_failed = 1
        finish
    endif
    if s:hastmux == 0 && s:hasscreen == 1
        let g:vimrplugin_tmux = 0
    endif
    if g:vimrplugin_tmux == 0 && s:hasscreen == 0 && g:vimrplugin_conqueplugin == 0
        call RWarningMsgInp("The value of vimrplugin_tmux = 0 but the GNU Screen application was not found.")
        let g:rplugin_failed = 1
        finish
    endif
endif


if g:vimrplugin_screenplugin
    let g:vimrplugin_conqueplugin = 0
    if !exists("g:ScreenVersion")
        call RWarningMsgInp("Please, either install the screen plugin (http://www.vim.org/scripts/script.php?script_id=2711) (recommended) or put 'let vimrplugin_screenplugin = 0' in your vimrc.")
        let g:rplugin_failed = 1
        finish
    endif

    " To get 256 colors you have to set the $TERM environment variable to
    " xterm-256color. See   :h r-plugin-tips 
    if g:vimrplugin_tmux
        let g:ScreenImpl = 'Tmux'
        if g:vimrplugin_notmuxconf == 0
            if $DISPLAY != "" || $TERM =~ "xterm"
                let g:ScreenShellTmuxInitArgs = "-2"
            endif
            let tmxcnf = $VIMRPLUGIN_TMPDIR . "/tmux.conf"
            let cnflines = [
                        \ 'set-option -g prefix C-a',
                        \ 'unbind-key C-b',
                        \ 'bind-key C-a send-prefix',
                        \ 'set-window-option -g mode-keys vi',
                        \ 'set -g status off',
                        \ "set -g terminal-overrides 'xterm*:smcup@:rmcup@'",
                        \ 'set -g mode-mouse on',
                        \ 'set -g mouse-select-pane on',
                        \ 'set -g mouse-resize-pane on']
            call writefile(cnflines, tmxcnf)
            let g:ScreenShellTmuxInitArgs = g:ScreenShellTmuxInitArgs . " -f " . tmxcnf
        endif
    else
        let g:ScreenImpl = 'GnuScreen'
    endif
endif

let s:tmuxversion = system("tmux -V")
let s:tmuxversion = substitute(s:tmuxversion, '.*tmux \([0-9]\.[0-9]\).*', '\1', '')
if strlen(s:tmuxversion) != 3
    let s:tmuxversion = "1.0"
endif
if g:vimrplugin_tmux && s:tmuxversion < "1.5"
    call RWarningMsgInp("Vim-R-plugin requires Tmux >= 1.5")
    let g:rplugin_failed = 1
    finish
endif
unlet s:tmuxversion

if g:vimrplugin_screenplugin
    if g:ScreenVersion < "1.5"
        call RWarningMsgInp("Vim-R-plugin requires Screen plugin >= 1.5")
        let g:rplugin_failed = 1
        finish
    endif
endif

" Start with an empty list of objects in the workspace
let g:rplugin_globalenvlines = []

if has("win32") || has("win64")

    if !has("python") && !has("python3")
        redir => s:vimversion
        silent version
        redir END
        let s:haspy2 = stridx(s:vimversion, '+python ')
        if s:haspy2 < 0
            let s:haspy2 = stridx(s:vimversion, '+python/dyn')
        endif
        let s:haspy3 = stridx(s:vimversion, '+python3')
        if s:haspy2 > 0 || s:haspy3 > 0
            let s:pyver = ""
            if s:haspy2 > 0 && s:haspy3 > 0
                let s:pyver = " (" . substitute(s:vimversion, '.*\(python2.\.dll\).*', '\1', '') . ", "
                let s:pyver = s:pyver . substitute(s:vimversion, '.*\(python3.\.dll\).*', '\1', '') . ")"
            elseif s:haspy3 > 0 && s:haspy2 < 0
                let s:pyver = " (" . substitute(s:vimversion, '.*\(python3.\.dll\).*', '\1', '') . ")"
            elseif s:haspy2 > 0 && s:haspy3 < 0
                let s:pyver = " (" . substitute(s:vimversion, '.*\(python2.\.dll\).*', '\1', '') . ")"
            endif
            let s:xx = substitute(s:vimversion, '.*\([0-9][0-9]-bit\).*', '\1', "")
            call RWarningMsgInp("This version of Vim was compiled against Python" . s:pyver . ", but Python was not found. Please, install " . s:xx . " Python from www.python.org.")
        else
            call RWarningMsgInp("This version of Vim was not compiled with Python support.")
        endif
        let g:rplugin_failed = 1
        finish
    endif
    let rplugin_pywin32 = 1
    exe "PyFile " . substitute(g:rplugin_home, " ", '\ ', "g") . '\r-plugin\windows.py' 
    if rplugin_pywin32 == 0
        let g:rplugin_failed = 1
        finish
    endif
    let g:rplugin_jspath = g:rplugin_home . "\\r-plugin\\vimActivate.js"
    if !exists("g:rplugin_rpathadded")
        if exists("g:vimrplugin_r_path") && isdirectory(g:vimrplugin_r_path)
            let $PATH = g:vimrplugin_r_path . ";" . $PATH
            let b:rplugin_Rgui = g:vimrplugin_r_path . "\\Rgui.exe"
        else
            Py GetRPathPy()
            if s:rinstallpath == "Not found"
                call RWarningMsgInp("Could not find R path in Windows Registry. Please, either install R or set the value of 'vimrplugin_r_path'.")
                let g:rplugin_failed = 1
                finish
            endif
            if isdirectory(s:rinstallpath . '\bin\i386')
                if !isdirectory(s:rinstallpath . '\bin\x64')
                    let g:vimrplugin_i386 = 1
                endif
                if g:vimrplugin_i386
                    let $PATH = s:rinstallpath . '\bin\i386;' . $PATH
                    let b:rplugin_Rgui = s:rinstallpath . '\bin\i386\Rgui.exe'
                else
                    let $PATH = s:rinstallpath . '\bin\x64;' . $PATH
                    let b:rplugin_Rgui = s:rinstallpath . '\bin\x64\Rgui.exe'
                endif
            else
                let $PATH = s:rinstallpath . '\bin;' . $PATH
                let b:rplugin_Rgui = s:rinstallpath . '\bin\Rgui.exe'
            endif
            unlet s:rinstallpath
        endif
        let g:rplugin_rpathadded = 1
    endif
    if !exists("b:rplugin_R")
        let b:rplugin_R = "Rgui.exe"
    endif
    let g:vimrplugin_term_cmd = "none"
    let g:vimrplugin_term = "none"
    let g:vimrplugin_noscreenrc = 1
    if !exists("g:vimrplugin_r_args")
        let g:vimrplugin_r_args = "--sdi"
    endif
    if !exists("g:vimrplugin_sleeptime")
        let g:vimrplugin_sleeptime = 0.02
    endif
endif

if g:vimrplugin_conqueplugin == 1
    if !exists("g:ConqueTerm_Version") || (exists("g:ConqueTerm_Version") && g:ConqueTerm_Version < 230)
        let g:vimrplugin_conqueplugin = 0
        call RWarningMsgInp("You are using Conque Shell plugin " . g:ConqueTerm_Version . ". Vim-R-plugin requires Conque Shell >= 2.3")
        finish
    endif
endif

" Are we in a Debian package? Is the plugin being running for the first time?
let g:rplugin_omnifname = g:rplugin_uservimfiles . "/r-plugin/omnils"
if g:rplugin_home != g:rplugin_uservimfiles
    " Create r-plugin directory if it doesn't exist yet:
    if !isdirectory(g:rplugin_uservimfiles . "/r-plugin")
        call mkdir(g:rplugin_uservimfiles . "/r-plugin", "p")
    endif
endif

" If there is no functions.vim, copy the default one
if !filereadable(g:rplugin_uservimfiles . "/r-plugin/functions.vim")
    if filereadable("/usr/share/vim/addons/r-plugin/functions.vim")
        let ffile = readfile("/usr/share/vim/addons/r-plugin/functions.vim")
        call writefile(ffile, g:rplugin_uservimfiles . "/r-plugin/functions.vim")
        unlet ffile
    else
        if g:rplugin_home != g:rplugin_uservimfiles && filereadable(g:rplugin_home . "/r-plugin/functions.vim")
            let ffile = readfile(g:rplugin_home . "/r-plugin/functions.vim")
            call writefile(ffile, g:rplugin_uservimfiles . "/r-plugin/functions.vim")
            unlet ffile
        endif
    endif
endif

" If there is no omnils, copy the default one
if !filereadable(g:rplugin_omnifname)
    if filereadable("/usr/share/vim/addons/r-plugin/omnils")
        let omnilines = readfile("/usr/share/vim/addons/r-plugin/omnils")
    else
        if filereadable(g:rplugin_home . "/r-plugin/omnils")
            let omnilines = readfile(g:rplugin_home . "/r-plugin/omnils")
        else
            let omnilines = []
        endif
    endif
    call writefile(omnilines, g:rplugin_omnifname)
    unlet omnilines
endif

" Minimum width for the Object Browser
if g:vimrplugin_objbr_w < 10
    let g:vimrplugin_objbr_w = 10
endif

" Keeps the libraries object list in memory to avoid the need of reading the file
" repeatedly:
let g:rplugin_liblist = readfile(g:rplugin_omnifname)
call BuildRHelpList()


" Control the menu 'R' and the tool bar buttons
if !exists("g:rplugin_hasmenu")
    let g:rplugin_hasmenu = 0
endif

" List of marks that the plugin seeks to find the block to be sent to R
let s:all_marks = "abcdefghijklmnopqrstuvwxyz"


" Create an empty file to avoid errors if the user do Ctrl-X Ctrl-O before
" starting R:
call writefile([], g:rplugin_globalenvfname)

" Choose a terminal (code adapted from screen.vim)
if has("win32") || has("win64") || vimrplugin_applescript
    " No external terminal emulator will be called, so any value is good
    let g:vimrplugin_term = "xterm"
else
    let s:terminals = ['gnome-terminal', 'konsole', 'xfce4-terminal', 'terminal', 'Eterm', 'rxvt', 'aterm', 'roxterm', 'terminator', 'xterm']
    if has('mac')
        let s:terminals = ['iTerm', 'Terminal.app'] + s:terminals
    endif
    if exists("g:vimrplugin_term")
        if !executable(g:vimrplugin_term)
            call RWarningMsgInp("'" . g:vimrplugin_term . "' not found. Please change the value of 'vimrplugin_term' in your vimrc.")
            unlet g:vimrplugin_term
        endif
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
    call RWarningMsgInp("Please, set the variable 'g:vimrplugin_term_cmd' in your .vimrc.\nRead the plugin documentation for details.")
    let g:rplugin_failed = 1
    finish
endif

let g:rplugin_termcmd = g:vimrplugin_term . " -e"

if g:vimrplugin_term == "gnome-terminal" || g:vimrplugin_term == "xfce4-terminal" || g:vimrplugin_term == "terminal"
    " Cannot set icon: http://bugzilla.gnome.org/show_bug.cgi?id=126081
    let g:rplugin_termcmd = g:vimrplugin_term . " --working-directory='" . expand("%:p:h") . "' --title R -e"
endif

if g:vimrplugin_term == "terminator"
    let g:rplugin_termcmd = "terminator --working-directory='" . expand("%:p:h") . "' --title R -x"
endif

if g:vimrplugin_term == "konsole"
    let g:rplugin_termcmd = "konsole --workdir '" . expand("%:p:h") . "' --icon " . g:rplugin_home . "/bitmaps/ricon.png -e"
endif

if g:vimrplugin_term == "Eterm"
    let g:rplugin_termcmd = "Eterm --icon " . g:rplugin_home . "/bitmaps/ricon.png -e"
endif

if g:vimrplugin_term == "roxterm"
    " Cannot set icon: http://bugzilla.gnome.org/show_bug.cgi?id=126081
    let g:rplugin_termcmd = "roxterm --directory='" . expand("%:p:h") . "' --title R -e"
endif

if g:vimrplugin_term == "xterm" || g:vimrplugin_term == "uxterm"
    let g:rplugin_termcmd = g:vimrplugin_term . " -xrm '*iconPixmap: " . g:rplugin_home . "/bitmaps/ricon.xbm' -e"
endif

" Override default settings:
if exists("g:vimrplugin_term_cmd")
    let g:rplugin_termcmd = g:vimrplugin_term_cmd
endif

function FinalActions()
    Py StopServer()
    sleep 200m
endfunction

augroup RBufControl
    au BufEnter * let g:rplugin_curbuf = bufname("%")
    au VimLeavePre * call FinalActions()
augroup END

if has("gui_running")
    augroup RMenuControl
        au BufEnter * call RBufEnter()
    augroup END
endif

let g:rplugin_firstbuffer = expand("%:p")
let g:rplugin_running_objbr = 0
let g:rplugin_has_new_lib = 0
let g:rplugin_has_new_obj = 0
let g:rplugin_objbr_port = 0
let g:rplugin_myport = 0
let g:rplugin_editor_port = 0
let g:rplugin_vimcomport = 0
let g:rplugin_ob_busy = 0

call SetRPath()

" Debugging code:
if g:vimrplugin_screenplugin && g:vimrplugin_conqueplugin
    echoerr "Error number 1"
endif
if g:vimrplugin_screenplugin && g:vimrplugin_applescript
    echoerr "Error number 2"
endif
if g:vimrplugin_conqueplugin && g:vimrplugin_applescript
    echoerr "Error number 3"
endif
if g:vimrplugin_screenplugin && has("gui_running")
    echoerr "Error number 4"
endif

