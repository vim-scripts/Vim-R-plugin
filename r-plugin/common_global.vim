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
    if &filetype != "r" && b:IsInRCode(0) == 0
        let isString = 1
    else
        let j = col(".")
        let s = getline(".")
        if g:vimrplugin_assign_map == "_" && j > 3 && s[j-3] == "<" && s[j-2] == "-" && s[j-1] == " "
            let save_unnamed_reg = @@
            exe "normal! 3h3xr_"
            let @@ = save_unnamed_reg
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

function! ReadEvalReply()
    let reply = "No reply"
    let haswaitwarn = 0
    let ii = 0
    while ii < 20
        sleep 100m
        if filereadable($VIMRPLUGIN_TMPDIR . "/eval_reply")
            let tmp = readfile($VIMRPLUGIN_TMPDIR . "/eval_reply")
            if len(tmp) > 0
                let reply = tmp[0]
                break
            endif
        endif
        let ii += 1
        if ii == 2
            echohl WarningMsg
            echon "\rWaiting for reply"
            echohl Normal
            let haswaitwarn = 1
        endif
    endwhile
    if haswaitwarn
        echon "\r                 "
        redraw
    endif
    return reply
endfunction

function RCheckVimCom(msg)
    if exists("g:rplugin_vimcom_checked")
        return 1
    endif
    if g:rplugin_vimcomport == 0
        Py DiscoverVimComPort()
    endif
    if g:rplugin_vimcomport && g:rplugin_vimcom_pkg == "vimcom"
	call RWarningMsg("The R package vimcom.plus is required to " . a:msg)
        return 1
    endif
    return 0
endfunction

function! CompleteChunkOptions()
    let cline = getline(".")
    let cpos = getpos(".")
    let idx1 = cpos[2] - 2
    let idx2 = cpos[2] - 1
    while cline[idx1] =~ '\w' || cline[idx1] == '.' || cline[idx1] == '_'
        let idx1 -= 1
    endwhile
    let idx1 += 1
    let base = strpart(cline, idx1, idx2 - idx1)
    let rr = []
    if strlen(base) == 0
        let newbase = '.'
    else
        let newbase = '^' . substitute(base, "\\$$", "", "")
    endif
    let ktopt = ["animation.fun=;hook_ffmpeg_html", "aniopts=;'controls.loop'", "autodep=;FALSE", "background=;'#F7F7F7'",
                \ "cache.path=;'cache/'", "cache.vars=; ", "cache=;FALSE", "child=; ", "comment=;'##'",
                \ "dependson=;''", "dev.args=; ", "dev=; ", "dpi=;72", "echo=;TRUE",
                \ "engine=;'R'", "error=;TRUE", "eval=;TRUE", "external=;TRUE",
                \ "fig.align=;'left|right|center'", "fig.cap=;''", "fig.env=;'figure'",
                \ "fig.ext=; ", "fig.height=;7", "fig.keep=;'high|none|all|first|last'",
                \ "fig.lp=;'fig:'", "fig.path=; ", "fig.pos=;''", "fig.scap=;''", "fig.subcap=; ",
                \ "fig.show=;'asis|hold|animate|hide'", "fig.width=;7", "highlight=;TRUE",
                \ "include=;TRUE", "interval=;1", "message=;TRUE", "opts.label=;''",
                \ "out.extra=; ", "out.height=;'7in'", "out.width=;'7in'",
                \ "prompt=;FALSE", "purl=;TRUE", "ref.label=; ", "resize.height=; ",
                \ "resize.width=; ", "results=;'markup|asis|hold|hide'", "sanitize=;FALSE",
                \ "size=;'normalsize'", "split=;FALSE", "tidy=;TRUE", "tidy.opts=; ", "warning=;TRUE"]
    for kopt in ktopt
      if kopt =~ newbase
        let tmp1 = split(kopt, ";")
        let tmp2 = {'word': tmp1[0], 'menu': tmp1[1]}
        call add(rr, tmp2)
      endif
    endfor
    call complete(idx1 + 1, rr)
endfunction

function RCompleteArgs()
    let line = getline(".")
    if (&filetype == "rnoweb" && line =~ "^<<.*>>=$") || (&filetype == "rmd" && line =~ "^``` *{r.*}$") || (&filetype == "rrst" && line =~ "^.. {r.*}$") || (&filetype == "r" && line =~ "^#\+")
        call CompleteChunkOptions()
      return ''
    endif
    let lnum = line(".")
    let cpos = getpos(".")
    let idx = cpos[2] - 2
    let idx2 = cpos[2] - 2
    call cursor(lnum, cpos[2] - 1)
    if line[idx2] == ' ' || line[idx2] == ',' || line[idx2] == '('
        let idx2 = cpos[2]
        let argkey = ''
    else
        let idx1 = idx2
        while line[idx1] =~ '\w' || line[idx1] == '.' || line[idx1] == '_'
            let idx1 -= 1
        endwhile
        let idx1 += 1
        let argkey = strpart(line, idx1, idx2 - idx1 + 1)
        let idx2 = cpos[2] - strlen(argkey)
    endif
    if string(g:SendCmdToR) != "function('SendCmdToR_fake')"
      call BuildROmniList()
    endif
    let flines = g:rplugin_globalenvlines + g:rplugin_liblist
    let np = 1
    let nl = 0

    if has("win32") || has("win64") && g:rplugin_vimcom_pkg == "vimcom"
        if RCheckVimCom("complete function arguments.")
            return
        endif
    endif

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
            let classfor = substitute(classfor, '\\', "", "g")
            let classfor = substitute(classfor, '"', '\\"', "g")
            let rkeyword = '^' . rkeyword0 . "\x06"
            call cursor(cpos[1], cpos[2])

            " If R is running, use it
            call delete($VIMRPLUGIN_TMPDIR . "/eval_reply")
            if classfor == ""
                exe 'Py SendToVimCom("' . g:rplugin_vimcom_pkg . ':::vim.args(' . "'" . rkeyword0 . "', '" . argkey . "')" . '")'
            else
                exe 'Py SendToVimCom("' . g:rplugin_vimcom_pkg . ':::vim.args(' . "'" . rkeyword0 . "', '" . argkey . "', classfor = " . classfor . ")" . '")'
            endif
            if g:rplugin_vimcomport > 0
                let g:rplugin_lastrpl = ReadEvalReply()
                if g:rplugin_lastrpl != "NOT_EXISTS" && g:rplugin_lastrpl != "NO_ARGS" && g:rplugin_lastrpl != "R is busy." && g:rplugin_lastrpl != "NOANSWER" && g:rplugin_lastrpl != "INVALID" && g:rplugin_lastrpl != "" && g:rplugin_lastrpl != "No reply"
                    let args = []
                    if g:rplugin_lastrpl[0] == "\x04" && len(split(g:rplugin_lastrpl, "\x04")) == 1
                        return ''
                    endif
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
            endif

            " If R isn't running, use the prebuilt list of objects
            for omniL in flines
                if omniL =~ rkeyword && omniL =~ "\x06function\x06function\x06"
                    let tmp1 = split(omniL, "\x06")
                    if len(tmp1) < 5
                        return ''
                    endif
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

function RGetFL(mode)
    if a:mode == "normal"
        let fline = line(".")
        let lline = line(".")
    else
        let fline = line("'<")
        let lline = line("'>")
    endif
    if fline > lline
        let tmp = lline
        let lline = fline
        let fline = tmp
    endif
    return [fline, lline]
endfunction

function IsLineInRCode(vrb, line)
    let save_cursor = getpos(".")
    call setpos(".", [0, a:line, 1, 0])
    let isR = b:IsInRCode(a:vrb)
    call setpos('.', save_cursor)
    return isR
endfunction

function RSimpleCommentLine(mode, what)
    let [fline, lline] = RGetFL(a:mode)
    let cstr = g:vimrplugin_rcomment_string
    if (&filetype == "rnoweb"|| &filetype == "rhelp") && IsLineInRCode(0, fline) == 0
        let cstr = "%"
    elseif (&filetype == "rmd" || &filetype == "rrst") && IsLineInRCode(0, fline) == 0
        return
    endif

    if a:what == "c"
        for ii in range(fline, lline)
            call setline(ii, cstr . getline(ii))
        endfor
    else
        for ii in range(fline, lline)
            call setline(ii, substitute(getline(ii), "^" . cstr, "", ""))
        endfor
    endif
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
    let [fline, lline] = RGetFL(a:mode)

    " What comment string to use?
    if g:r_indent_ess_comments
        if g:vimrplugin_indent_commented
            let cmt = '##'
        else
            let cmt = '###'
        endif
    else
        let cmt = '#'
    endif
    if (&filetype == "rnoweb" || &filetype == "rhelp") && IsLineInRCode(0, fline) == 0
        let cmt = "%"
    elseif (&filetype == "rmd" || &filetype == "rrst") && IsLineInRCode(0, fline) == 0
        return
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

" Skip empty lines and lines whose first non blank char is '#'
function GoDown()
    if &filetype == "rnoweb"
        let curline = getline(".")
        let fc = curline[0]
        if fc == '@'
            call RnwNextChunk()
            return
        endif
    elseif &filetype == "rmd"
        let curline = getline(".")
        if curline =~ '^```$'
            call RmdNextChunk()
            return
        endif
    elseif &filetype == "rrst"
        let curline = getline(".")
        if curline =~ '^\.\. \.\.$'
            call RrstNextChunk()
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

" Adapted from screen plugin:
function TmuxActivePane()
  let line = system("tmux list-panes | grep \'(active)$'")
  let paneid = matchstr(line, '\v\%\d+ \(active\)')
  if !empty(paneid)
    return matchstr(paneid, '\v^\%\d+')
  else
    return matchstr(line, '\v^\d+')
  endif
endfunction

function StartR_TmuxSplit(rcmd)
    let g:rplugin_vim_pane = TmuxActivePane()
    call system("tmux set-environment -g VIMRPLUGIN_TMPDIR " . g:rplugin_esc_tmpdir)
    call system("tmux set-environment -g VIMRPLUGIN_HOME " . g:rplugin_home)
    call system("tmux set-environment -g VIM_PANE " . g:rplugin_vim_pane)
    if v:servername != ""
        call system("tmux set-environment VIMEDITOR_SVRNM " . v:servername)
    endif
    call system("tmux set-environment VIMINSTANCEID " . $VIMINSTANCEID)
    let tcmd = "tmux split-window "
    if g:vimrplugin_vsplit
        if g:vimrplugin_rconsole_width == -1
            let tcmd .= "-h"
        else
            let tcmd .= "-h -l " . g:vimrplugin_rconsole_width
        endif
    else
        let tcmd .= "-l " . g:vimrplugin_rconsole_height
    endif
    if !g:vimrplugin_restart
        " Let Tmux automatically kill the panel when R quits.
        let tcmd .= " '" . a:rcmd . "'"
    endif
    let rlog = system(tcmd)
    if v:shell_error
        call RWarningMsg(rlog)
        return
    endif
    let g:rplugin_rconsole_pane = TmuxActivePane()
    let rlog = system("tmux select-pane -t " . g:rplugin_vim_pane)
    if v:shell_error
        call RWarningMsg(rlog)
        return
    endif
    let g:SendCmdToR = function('SendCmdToR_TmuxSplit')
    if g:vimrplugin_restart
        sleep 200m
        let ca_ck = g:vimrplugin_ca_ck
        let g:vimrplugin_ca_ck = 0
        call g:SendCmdToR(a:rcmd)
        let g:vimrplugin_ca_ck = ca_ck
    endif
    let g:rplugin_last_rcmd = a:rcmd
endfunction


function StartR_ExternalTerm(rcmd)
    if $DISPLAY == ""
        call RWarningMsg("Start 'tmux' before Vim. The X Window system is required to run R in an external terminal.")
        return
    endif

    " Create a custom tmux.conf
    let cnflines = [
                \ 'set-environment -g VIMRPLUGIN_TMPDIR ' . g:rplugin_esc_tmpdir,
                \ 'set-environment -g VIMRPLUGIN_HOME ' . g:rplugin_home,
                \ 'set-environment VIMINSTANCEID ' . $VIMINSTANCEID ]
    if v:servername != ""
        let cnflines = cnflines + [ 'set-environment VIMEDITOR_SVRNM ' . v:servername ]
    endif
    if g:vimrplugin_notmuxconf
        let cnflines = cnflines + [ 'source-file ~/.tmux.conf' ]
    else
        let cnflines = cnflines + [
                    \ 'set-option -g prefix C-a',
                    \ 'unbind-key C-b',
                    \ 'bind-key C-a send-prefix',
                    \ 'set-window-option -g mode-keys vi',
                    \ 'set -g status off',
                    \ "set -g terminal-overrides 'xterm*:smcup@:rmcup@'" ]
        if g:vimrplugin_external_ob || !has("gui_running")
            call extend(cnflines, ['set -g mode-mouse on', 'set -g mouse-select-pane on', 'set -g mouse-resize-pane on'])
        endif
    endif
    call extend(cnflines, ['set-environment VIMINSTANCEID "' . $VIMINSTANCEID . '"'])
    call writefile(cnflines, s:tmxcnf)
	
	let is_bash = system('echo $BASH')
	if v:shell_error || len(is_bash) == 0 || empty(matchstr(tolower(is_bash),'undefined variable')) == 0
		let rcmd = a:rcmd
	else
		let rcmd = "VIMINSTANCEID=" . $VIMINSTANCEID . " " . a:rcmd
	endif

    call system('export VIMRPLUGIN_TMPDIR=' . $VIMRPLUGIN_TMPDIR)
    call system('export VIMRPLUGIN_HOME=' . g:rplugin_home)
    call system('export VIMINSTANCEID=' . $VIMINSTANCEID)
    if v:servername != ""
        call system('export VIMEDITOR_SVRNM=' . v:servername)
    endif
    " Start the terminal emulator even if inside a Tmux session
    if $TMUX != ""
        let tmuxenv = $TMUX
        let $TMUX = ""
        call system('tmux set-option -ga update-environment " TMUX_PANE VIMRPLUGIN_TMPDIR VIMINSTANCEID"')
    endif
    let tmuxcnf = '-f "' . s:tmxcnf . '"'

    call system("tmux has-session -t " . g:rplugin_tmuxsname)
    if v:shell_error
        if g:rplugin_termcmd =~ "gnome-terminal" || g:rplugin_termcmd =~ "xfce4-terminal" || g:rplugin_termcmd =~ "terminal" || g:rplugin_termcmd =~ "iterm"
            let opencmd = printf("%s 'tmux -2 %s new-session -s %s \"%s\"' &", g:rplugin_termcmd, tmuxcnf, g:rplugin_tmuxsname, rcmd)
        else
            let opencmd = printf("%s tmux -2 %s new-session -s %s \"%s\" &", g:rplugin_termcmd, tmuxcnf, g:rplugin_tmuxsname, rcmd)
        endif
    else
        if g:rplugin_termcmd =~ "gnome-terminal" || g:rplugin_termcmd =~ "xfce4-terminal" || g:rplugin_termcmd =~ "terminal" || g:rplugin_termcmd =~ "iterm"
            let opencmd = printf("%s 'tmux -2 %s attach-session -d -t %s' &", g:rplugin_termcmd, tmuxcnf, g:rplugin_tmuxsname)
        else
            let opencmd = printf("%s tmux -2 %s attach-session -d -t %s &", g:rplugin_termcmd, tmuxcnf, g:rplugin_tmuxsname)
        endif
    endif

    let rlog = system(opencmd)
    if v:shell_error
        call RWarningMsg(rlog)
        return
    endif
    if exists("tmuxenv")
        let $TMUX = tmuxenv
    endif
    let g:SendCmdToR = function('SendCmdToR_Term')
endfunction

function StartR_Windows()
    if string(g:SendCmdToR) != "function('SendCmdToR_fake')"
        Py FindRConsole()
        Py vim.command("let g:rplugin_rconsole_hndl = " + str(RConsole))
        if g:rplugin_rconsole_hndl != 0
            call RWarningMsg("There is already a window called '" . g:rplugin_R_window_ttl . "'.")
            unlet g:rplugin_R_window_ttl
            return
        endif
    endif
    Py StartRPy()
    lcd -
    let g:SendCmdToR = function('SendCmdToR_Windows')
endfunction

function StartR_OSX()
    if IsSendCmdToRFake()
        return
    endif
    if g:rplugin_r64app && g:vimrplugin_i386 == 0
        let rcmd = "/Applications/R64.app"
    else
        let rcmd = "/Applications/R.app"
    endif
    if b:rplugin_r_args != " "
        " https://github.com/jcfaria/Vim-R-plugin/issues/63
        " https://stat.ethz.ch/pipermail/r-sig-mac/2013-February/009978.html
        call RWarningMsg('R.app does not support command line arguments. To pass "' . b:rplugin_r_args . '" to R, you must run it in a console. Set "vimrplugin_applescript = 0" (you may need to install XQuartz)')
    endif
    let rlog = system("open " . rcmd)
    if v:shell_error
        call RWarningMsg(rlog)
    endif
    lcd -
    let g:SendCmdToR = function('SendCmdToR_OSX')
endfunction

function IsSendCmdToRFake()
    if string(g:SendCmdToR) != "function('SendCmdToR_fake')"
	if exists("g:maplocalleader")
	    call RWarningMsg("As far as I know, R is already running. Did you quit it from within Vim (" . g:maplocalleader . "rq if not remapped)?")
	else
	    call RWarningMsg("As far as I know, R is already running. Did you quit it from within Vim (\\rq if not remapped)?")
	endif
	return 1
    endif
    return 0
endfunction

" Start R
function StartR(whatr)
    call writefile([], $VIMRPLUGIN_TMPDIR . "/globenv_" . $VIMINSTANCEID)
    call writefile([], $VIMRPLUGIN_TMPDIR . "/liblist_" . $VIMINSTANCEID)
    if filereadable($VIMRPLUGIN_TMPDIR . "/libnames_" . $VIMINSTANCEID)
        call delete($VIMRPLUGIN_TMPDIR . "/libnames_" . $VIMINSTANCEID)
    endif

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

    if g:vimrplugin_applescript
        call StartR_OSX()
        return
    endif

    if has("win32") || has("win64")
        call StartR_Windows()
        return
    endif

    if g:vimrplugin_only_in_tmux && $TMUX_PANE == ""
        call RWarningMsg("Not inside Tmux.")
        lcd -
        return
    endif

    " R was already started. Should restart it or warn?
    if string(g:SendCmdToR) != "function('SendCmdToR_fake')"
        if g:rplugin_tmuxwasfirst
            if g:vimrplugin_restart
                call g:SendCmdToR('quit(save = "no")')
                sleep 100m
                call delete($VIMRPLUGIN_TMPDIR . "/vimcom_running")
                let ca_ck = g:vimrplugin_ca_ck
                let g:vimrplugin_ca_ck = 0
                call g:SendCmdToR(g:rplugin_last_rcmd)
                let g:vimrplugin_ca_ck = ca_ck
                if IsExternalOBRunning()
                    call VimExprToOB('ResetVimComPort()')
                    call WaitVimComStart()
                    exe 'Py SendToVimCom("\007' . g:rplugin_obsname . '")'
                    Py SendToVimCom("\003.GlobalEnv [Restarting R]")
                    Py SendToVimCom("\004Libraries [Restarting()]")
                    " vimcom automatically update the libraries view, but not
                    " the GlobalEnv one because vimcom_count_objects() returns 0.
                    call VimExprToOB('UpdateOB("GlobalEnv")')
                endif
                return
            elseif IsSendCmdToRFake()
		return
            endif
        else
            if g:vimrplugin_restart
                call RQuit("restartR")
                call ResetVimComPort()
            endif
        endif
    endif

    if b:rplugin_r_args == " "
        let rcmd = b:rplugin_R
    else
        let rcmd = b:rplugin_R . " " . b:rplugin_r_args
    endif

    if g:rplugin_tmuxwasfirst
        call StartR_TmuxSplit(rcmd)
    else
        if g:vimrplugin_restart && bufloaded(b:objbrtitle)
            call delete($VIMRPLUGIN_TMPDIR . "/vimcom_running")
        endif
        call StartR_ExternalTerm(rcmd)
        if g:vimrplugin_restart && bufloaded(b:objbrtitle)
            call WaitVimComStart()
            exe 'Py SendToVimCom("\007' . v:servername . '")'
            Py SendToVimCom("\003.GlobalEnv [Restarting R]")
            Py SendToVimCom("\004Libraries [Restarting()]")
            if exists("*UpdateOB")
                call UpdateOB("GlobalEnv")
            endif
        endif
    endif

    " Go back to original directory:
    lcd -
    echon
endfunction

function WaitVimComStart()
    sleep 300m
    let ii = 0
    while !filereadable($VIMRPLUGIN_TMPDIR . "/vimcom_running") && ii < 20
        let ii = ii + 1
        sleep 200m
    endwhile
    if filereadable($VIMRPLUGIN_TMPDIR . "/vimcom_running") && g:rplugin_tmuxwasfirst
        sleep 100m
        call g:SendCmdToR("\014")
    endif
endfunction

function IsExternalOBRunning()
    if exists("g:rplugin_ob_pane")
        let plst = system("tmux list-panes | cat")
        if plst =~ g:rplugin_ob_pane
            return 1
        endif
    endif
    return 0
endfunction

function ResetVimComPort()
    Py VimComPort = 0
endfunction

function StartObjBrowser_Tmux()
    if b:rplugin_extern_ob
        " This is the Object Browser
        echoerr "StartObjBrowser_Tmux() called."
        return
    endif

    " Don't start the Object Browser if it already exists
    if IsExternalOBRunning()
        Py SendToVimCom("\003GlobalEnv [OB StartObjBrowser_Tmux]")
        sleep 50m
        Py SendToVimCom("\004Libraries [OB StartObjBrowser_Tmux]")
        sleep 50m
        if $DISPLAY == "" && exists("g:rplugin_ob_pane")
            let slog = system("tmux set-buffer ':silent call UpdateOB(\"both\")\<C-M>:\<Esc>' && tmux paste-buffer -t " . g:rplugin_ob_pane . " && tmux select-pane -t " . g:rplugin_ob_pane)
            if v:shell_error
                call RWarningMsg(slog)
            endif
        endif
        return
    endif

    let objbrowserfile = $VIMRPLUGIN_TMPDIR . "/objbrowserInit"
    let tmxs = " "

    if v:servername == ""
        let myservername = '""'
    else
        let myservername = '"' . v:servername . '"'
    endif

    call writefile([
                \ 'let g:rplugin_editor_sname = ' . myservername,
                \ 'let g:rplugin_vim_pane = "' . g:rplugin_vim_pane . '"',
                \ 'let g:rplugin_rconsole_pane = "' . g:rplugin_rconsole_pane . '"',
                \ 'let b:objbrtitle = "' . b:objbrtitle . '"',
                \ 'let showmarks_enable = 0',
                \ 'let g:rplugin_tmuxsname = "' . g:rplugin_tmuxsname . '"',
                \ 'let b:rscript_buffer = "' . bufname("%") . '"',
                \ 'set filetype=rbrowser',
                \ 'let b:rplugin_extern_ob = 1',
                \ 'set shortmess=atI',
                \ 'set rulerformat=%3(%l%)',
                \ 'set noruler',
                \ 'exe "PyFile " . substitute(g:rplugin_home, " ", '. "'\\\\ '" . ', "g") . "/r-plugin/vimcom.py"',
                \ 'let g:SendCmdToR = function("SendCmdToR_TmuxSplit")',
                \ 'if has("clientserver") && v:servername != ""',
                \ "   exe 'Py SendToVimCom(" . '"\007' . "' . v:servername . '" . '")' . "'",
                \ 'endif',
                \ 'Py SendToVimCom("\003GlobalEnv [OB init]")',
                \ 'sleep 50m',
                \ 'Py SendToVimCom("\004Libraries [OB init]")',
                \ 'if v:servername == ""',
                \ '    sleep 100m',
                \ '    call UpdateOB("GlobalEnv")',
                \ 'endif'], objbrowserfile)

    if g:vimrplugin_objbr_place =~ "left"
        let panw = system("tmux list-panes | cat")
        if g:vimrplugin_objbr_place =~ "console"
            " Get the R Console width:
            let panw = substitute(panw, '.*[0-9]: \[\([0-9]*\)x[0-9]*.\{-}' . g:rplugin_rconsole_pane . '\>.*', '\1', "")
        else
            " Get the Vim width
            let panw = substitute(panw, '.*[0-9]: \[\([0-9]*\)x[0-9]*.\{-}' . g:rplugin_vim_pane . '\>.*', '\1', "")
        endif
        let panewidth = panw - g:vimrplugin_objbr_w
        " Just to be safe: If the above code doesn't work as expected
        " and we get a spurious value:
        if panewidth < 30 || panewidth > 180
            let panewidth = 80
        endif
    else
        let panewidth = g:vimrplugin_objbr_w
    endif
    if g:vimrplugin_objbr_place =~ "console"
        let obpane = g:rplugin_rconsole_pane
    else
        let obpane = g:rplugin_vim_pane
    endif

    if has("clientserver")
        let obsname = "--servername " . g:rplugin_obsname
    else
        let obsname = " "
    endif

    let cmd = "tmux split-window -h -l " . panewidth . " -t " . obpane . ' "vim ' . obsname . " -c 'source " . substitute(objbrowserfile, ' ', '\\ ', 'g') . "'" . '"'
    let rlog = system(cmd)
    if v:shell_error
        let rlog = substitute(rlog, '\n', ' ', 'g')
        let rlog = substitute(rlog, '\r', ' ', 'g')
        call RWarningMsg(rlog)
        let g:rplugin_running_objbr = 0
        return 0
    endif

    let g:rplugin_ob_pane = TmuxActivePane()
    let rlog = system("tmux select-pane -t " . g:rplugin_vim_pane)
    if v:shell_error
        call RWarningMsg(rlog)
        return 0
    endif

    if g:vimrplugin_objbr_place =~ "left"
        if g:vimrplugin_objbr_place =~ "console"
            call system("tmux swap-pane -d -s " . g:rplugin_rconsole_pane . " -t " . g:rplugin_ob_pane)
        else
            call system("tmux swap-pane -d -s " . g:rplugin_vim_pane . " -t " . g:rplugin_ob_pane)
        endif
    endif
    if g:rplugin_ob_warn_shown == 0
        if !has("clientserver")
            call RWarningMsg("The +clientserver feature is required to automatically update the Object Browser.")
            sleep 200m
        else
            if $DISPLAY == ""
                call RWarningMsg("The X Window system is required to automatically update the Object Browser.")
                sleep 200m
            endif
        endif
        let g:rplugin_ob_warn_shown = 1
    endif
    return
endfunction

function StartObjBrowser_Vim()
    let wmsg = ""
    if v:servername == ""
        if g:rplugin_ob_warn_shown == 0
            if !has("clientserver")
                let wmsg = "The +clientserver feature is required to automatically update the Object Browser."
            else
                if $DISPLAY == "" && !(has("win32") || has("win64"))
                    let wmsg = "The X Window system is required to automatically update the Object Browser."
                else
                    let wmsg ="The Object Browser will not be automatically updated because Vim's client/server was not started."
                endif
            endif
        endif
        let g:rplugin_ob_warn_shown = 1
    else
        exe 'Py SendToVimCom("\007' . v:servername . '")'
    endif

    " Either load or reload the Object Browser
    let savesb = &switchbuf
    set switchbuf=useopen,usetab
    if bufloaded(b:objbrtitle)
        exe "sb " . b:objbrtitle
        let wmsg = ""
    else
        " Copy the values of some local variables that will be inherited
        let g:tmp_objbrtitle = b:objbrtitle
        let g:tmp_tmuxsname = g:rplugin_tmuxsname
        let g:tmp_curbufname = bufname("%")

        let l:sr = &splitright
        if g:vimrplugin_objbr_place =~ "left"
            set nosplitright
        else
            set splitright
        endif
        sil exe "vsplit " . b:objbrtitle
        let &splitright = l:sr
        sil exe "vertical resize " . g:vimrplugin_objbr_w
        sil set filetype=rbrowser

        " Inheritance of some local variables
        let g:rplugin_tmuxsname = g:tmp_tmuxsname
        let b:objbrtitle = g:tmp_objbrtitle
        let b:rscript_buffer = g:tmp_curbufname
        unlet g:tmp_objbrtitle
        unlet g:tmp_tmuxsname
        unlet g:tmp_curbufname
        exe "PyFile " . substitute(g:rplugin_home, " ", '\\ ', "g") . "/r-plugin/vimcom.py"
        Py SendToVimCom("\003GlobalEnv [StartObjBrowser_Vim]")
        Py SendToVimCom("\004Libraries [StartObjBrowser_Vim]")
        call UpdateOB("GlobalEnv")
    endif
    if wmsg != ""
        call RWarningMsg(wmsg)
        sleep 200m
    endif
endfunction

" Open an Object Browser window
function RObjBrowser()
    if !has("python") && !has("python3")
        call RWarningMsg("Python support is required to run the Object Browser.")
        return
    endif

    " Only opens the Object Browser if R is running
    if string(g:SendCmdToR) == "function('SendCmdToR_fake')"
        call RWarningMsg("The Object Browser can be opened only if R is running.")
        return
    endif

    if has("win32") || has("win64") && g:rplugin_vimcom_pkg == "vimcom"
        if RCheckVimCom("run the Object Browser on Windows.")
            return
        endif
    endif

    if g:rplugin_running_objbr == 1
        " Called twice due to BufEnter event
        return
    endif

    let g:rplugin_running_objbr = 1

    if !b:rplugin_extern_ob
        if g:rplugin_tmuxwasfirst
            call StartObjBrowser_Tmux()
        else
            call StartObjBrowser_Vim()
        endif
    endif
    if exists("*UpdateOB")
        Py SendToVimCom("\003GlobalEnv [RObjBrowser()]")
        Py SendToVimCom("\004Libraries [RObjBrowser()]")
        call UpdateOB("both")
    endif
    let g:rplugin_running_objbr = 0
    return
endfunction

function VimExprToOB(msg)
    if serverlist() =~ "\\<" . g:rplugin_obsname . "\n"
        return remote_expr(g:rplugin_obsname, a:msg)
    endif
    return "Vim server not found"
endfunction

function RBrowserOpenCloseLists(status)
    if a:status == 1
        if exists("g:rplugin_curview")
            let curview = g:rplugin_curview
        else
            if IsExternalOBRunning()
                let curview = VimExprToOB('g:rplugin_curview')
                if curview == "Vim server not found"
                    return
                endif
            else
                let curview = "GlobalEnv"
            endif
        endif
        if curview == "libraries"
            echohl WarningMsg
            echon "GlobalEnv command only."
            sleep 1
            echohl Normal
            normal! :<Esc>
            return
        endif
    endif

    " Avoid possibly freezing cross messages between Vim and R
    if exists("g:rplugin_curview") && v:servername != ""
        Py SendToVimCom("\x08Stop updating info [RBrowserOpenCloseLists()]")
        let stt = a:status
    else
        let stt = a:status + 2
    endif

    let switchedbuf = 0
    if buflisted("Object_Browser") && g:rplugin_curbuf != "Object_Browser"
        let savesb = &switchbuf
        set switchbuf=useopen,usetab
        sil noautocmd sb Object_Browser
        let switchedbuf = 1
    endif

    exe 'Py SendToVimCom("' . "\006" . stt . '")'

    if g:rplugin_lastrpl == "R is busy."
        call RWarningMsg("R is busy.")
    endif

    if switchedbuf
        exe "sil noautocmd sb " . g:rplugin_curbuf
        exe "set switchbuf=" . savesb
    endif
    if exists("g:rplugin_curview")
        call UpdateOB("both")
        if v:servername != ""
            exe 'Py SendToVimCom("\007' . v:servername . '")'
        endif
    elseif IsExternalOBRunning()
        call VimExprToOB('UpdateOB("GlobalEnv")')
        exe 'Py SendToVimCom("\007' . g:rplugin_obsname . '")'
    endif
endfunction

function RFormatCode() range
    if g:rplugin_vimcomport == 0
        exe "Py DiscoverVimComPort()"
        if g:rplugin_vimcomport == 0
            return
        endif
    endif

    if has("win32") || has("win64") && g:rplugin_vimcom_pkg == "vimcom"
        if RCheckVimCom("run :Rformat.")
            return
        endif
    endif

    let lns = getline(a:firstline, a:lastline)
    call writefile(lns, $VIMRPLUGIN_TMPDIR . "/unformatted_code")
    let wco = &textwidth
    if wco == 0
        let wco = 78
    elseif wco < 20
        let wco = 20
    elseif wco > 180
        let wco = 180
    endif
    call delete($VIMRPLUGIN_TMPDIR . "/eval_reply")
    exe "Py SendToVimCom('formatR::tidy.source(\"" . $VIMRPLUGIN_TMPDIR . "/unformatted_code" . "\", file = \"" . $VIMRPLUGIN_TMPDIR . "/formatted_code\", width.cutoff = " . wco . ")')"
    let g:rplugin_lastrpl = ReadEvalReply()
    if g:rplugin_lastrpl == "R is busy." || g:rplugin_lastrpl == "UNKNOWN" || g:rplugin_lastrpl =~ "^Error" || g:rplugin_lastrpl == "INVALID" || g:rplugin_lastrpl == "ERROR" || g:rplugin_lastrpl == "EMPTY" || g:rplugin_lastrpl == "No reply"
        call RWarningMsg(g:rplugin_lastrpl)
        return
    endif
    let lns = readfile($VIMRPLUGIN_TMPDIR . "/formatted_code")
    silent exe a:firstline . "," . a:lastline . "delete"
    call append(a:firstline - 1, lns)
    echo (a:lastline - a:firstline + 1) . " lines formatted."
endfunction

function RInsert(cmd)
    if g:rplugin_vimcomport == 0
        exe "Py DiscoverVimComPort()"
        if g:rplugin_vimcomport == 0
            return
        endif
    endif

    if has("win32") || has("win64") && g:rplugin_vimcom_pkg == "vimcom"
        if RCheckVimCom("run :Rinsert.")
            return
        endif
    endif

    call delete($VIMRPLUGIN_TMPDIR . "/eval_reply")
    call delete($VIMRPLUGIN_TMPDIR . "/Rinsert")
    exe "Py SendToVimCom('capture.output(" . a:cmd . ', file = "' . $VIMRPLUGIN_TMPDIR . "/Rinsert" . '")' . "')"
    let g:rplugin_lastrpl = ReadEvalReply()
    if g:rplugin_lastrpl == "R is busy." || g:rplugin_lastrpl == "UNKNOWN" || g:rplugin_lastrpl =~ "^Error" || g:rplugin_lastrpl == "INVALID" || g:rplugin_lastrpl == "ERROR" || g:rplugin_lastrpl == "EMPTY" || g:rplugin_lastrpl == "No reply"
        call RWarningMsg(g:rplugin_lastrpl)
    else
        silent exe "read " . g:rplugin_esc_tmpdir . "/Rinsert"
    endif
endfunction

" Function to send commands
" return 0 on failure and 1 on success
function SendCmdToR_fake(cmd)
    call RWarningMsg("Did you already start R?")
    return 0
endfunction

function SendCmdToR_TmuxSplit(cmd)
    if g:vimrplugin_ca_ck
        let cmd = "\001" . "\013" . a:cmd
    else
        let cmd = a:cmd
    endif

    if !exists("g:rplugin_rconsole_pane")
        " Should never happen
        call RWarningMsg("Missing internal variable: g:rplugin_rconsole_pane")
    endif
    let str = substitute(cmd, "'", "'\\\\''", "g")
    let scmd = "tmux set-buffer '" . str . "\<C-M>' && tmux paste-buffer -t " . g:rplugin_rconsole_pane
    let rlog = system(scmd)
    if v:shell_error
        let rlog = substitute(rlog, "\n", " ", "g")
        let rlog = substitute(rlog, "\r", " ", "g")
        call RWarningMsg(rlog)
        let g:SendCmdToR = function('SendCmdToR_fake')
        return 0
    endif
    return 1
endfunction

function SendCmdToR_Windows(cmd)
    if g:vimrplugin_ca_ck
        let cmd = "\001" . "\013" . a:cmd
    else
        let cmd = a:cmd
    endif

    let cmd = cmd . "\n"
    let slen = len(cmd)
    let str = ""
    for i in range(0, slen)
        let str = str . printf("\\x%02X", char2nr(cmd[i]))
    endfor
    exe "Py" . " SendToRConsole(b'" . str . "')"
    return 1
endfunction

function SendCmdToR_OSX(cmd)
    if g:vimrplugin_ca_ck
        let cmd = "\001" . "\013" . a:cmd
    else
        let cmd = a:cmd
    endif

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
endfunction

function SendCmdToR_Term(cmd)
    if g:vimrplugin_ca_ck
        let cmd = "\001" . "\013" . a:cmd
    else
        let cmd = a:cmd
    endif

    " Send the command to R running in an external terminal emulator
    let str = substitute(cmd, "'", "'\\\\''", "g")
    let scmd = "tmux set-buffer '" . str . "\<C-M>' && tmux paste-buffer -t " . g:rplugin_tmuxsname . '.0'
    let rlog = system(scmd)
    if v:shell_error
        let rlog = substitute(rlog, '\n', ' ', 'g')
        let rlog = substitute(rlog, '\r', ' ', 'g')
        call RWarningMsg(rlog)
        let g:SendCmdToR = function('SendCmdToR_fake')
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
    setlocal iskeyword=@,48-57,_,.,$,@-@
    let rkeyword = expand("<cword>")
    exe "setlocal iskeyword=" . save_keyword
    call setpos(".", save_cursor)
    return rkeyword
endfunction

" Send sources to R
function RSourceLines(lines, e)
    let lines = a:lines
    if &filetype == "rrst"
        let lines = map(copy(lines), 'substitute(v:val, "^\\.\\. \\?", "", "")')
    endif
    if &filetype == "rmd"
        let lines = map(copy(lines), 'substitute(v:val, "^\\`\\`\\?", "", "")')
    endif
    call writefile(lines, b:rsource)
    if a:e == "echo"
        if exists("g:vimrplugin_maxdeparse")
            let rcmd = 'base::source("' . b:rsource . '", echo=TRUE, max.deparse=' . g:vimrplugin_maxdeparse . ')'
        else
            let rcmd = 'base::source("' . b:rsource . '", echo=TRUE)'
        endif
    else
        let rcmd = 'base::source("' . b:rsource . '")'
    endif
    let ok = g:SendCmdToR(rcmd)
    return ok
endfunction

" Send file to R
function SendFileToR(e)
    update
    let fpath = expand("%:p")
    if has("win32") || has("win64")
        let fpath = substitute(fpath, "\\", "/", "g")
    endif
    if a:e == "echo"
        call g:SendCmdToR('base::source("' . fpath . '", echo=TRUE)')
    else
        call g:SendCmdToR('base::source("' . fpath . '")')
    endif
endfunction

" Send block to R
" Adapted of the plugin marksbrowser
" Function to get the marks which the cursor is between
function SendMBlockToR(e, m)
    if &filetype != "r" && b:IsInRCode(1) == 0
        return
    endif

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
    if &filetype != "r" && b:IsInRCode(1) == 0
        return
    endif

    let startline = line(".")
    let save_cursor = getpos(".")
    let line = SanitizeRLine(getline("."))
    let i = line(".")
    while i > 0 && line !~ "function"
        let i -= 1
        let line = SanitizeRLine(getline(i))
    endwhile
    if i == 0
        call RWarningMsg("Begin of function not found.")
        return
    endif
    let functionline = i
    while i > 0 && line !~ "<-"
        let i -= 1
        let line = SanitizeRLine(getline(i))
    endwhile
    if i == 0
        call RWarningMsg("The function assign operator  <-  was not found.")
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
        call RWarningMsg("The function opening brace was not found.")
        return
    endif
    let nb = CountBraces(line)
    while i < tt && nb > 0
        let i += 1
        let line = SanitizeRLine(getline(i))
        let nb += CountBraces(line)
    endwhile
    if nb != 0
        call RWarningMsg("The function closing brace was not found.")
        return
    endif
    let lastline = i

    if startline > lastline
        call setpos(".", [0, firstline - 1, 1])
        call SendFunctionToR(a:e, a:m)
        call setpos(".", save_cursor)
        return
    endif

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
    if &filetype != "r" && b:IsInRCode(1) == 0
        if !(&filetype == "rnoweb" && getline(".") =~ "\\Sexpr{")
            return
        endif
    endif

    if line("'<") == line("'>")
        let i = col("'<") - 1
        let j = col("'>") - i
        let l = getline("'<")
        let line = strpart(l, i, j)
        let ok = g:SendCmdToR(line)
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
    if &filetype != "r" && b:IsInRCode(1) == 0
        return
    endif

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

" Send R code from the first chunk up to current line
function SendFHChunkToR()
    if &filetype == "rnoweb"
        let begchk = "^<<.*>>=\$"
        let endchk = "^@"
    elseif &filetype == "rmd"
        let begchk = "^[ \t]*```[ ]*{r"
        let endchk = "^[ \t]*```$"
    elseif &filetype == "rrst"
        let begchk = "^\\.\\. {r"
        let endchk = "^\\.\\. \\.\\."
    else
        " Should never happen
        call RWarningMsg('Strange filetype (SendFHChunkToR): "' . &filetype '"')
    endif

    let codelines = []
    let here = line(".")
    let curbuf = getline(1, "$")
    let idx = 1
    while idx < here
        if curbuf[idx] =~ begchk
            let idx += 1
            while curbuf[idx] !~ endchk && idx < here
                let codelines += [curbuf[idx]]
                let idx += 1
            endwhile
        else
            let idx += 1
        endif
    endwhile
    call RSourceLines(codelines, "silent")
endfunction

" Send current line to R.
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
        if RnwIsInRCode(1) == 0
            return
        endif
    endif

    if &filetype == "rmd"
        if line =~ "^```$"
            if a:godown =~ "down"
                call GoDown()
            endif
            return
        endif
        let line = substitute(line, "^\\`\\`\\?", "", "")
        if RmdIsInRCode(1) == 0
            return
        endif
    endif

    if &filetype == "rrst"
        if line =~ "^\.\. \.\.$"
            if a:godown =~ "down"
                call GoDown()
            endif
            return
        endif
        let line = substitute(line, "^\\.\\. \\?", "", "")
        if RrstIsInRCode(1) == 0
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
        if RdocIsInRCode(1) == 0
            return
        endif
    endif

    if &filetype == "rhelp" && RhelpIsInRCode(1) == 0
        return
    endif

    let ok = g:SendCmdToR(line)
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
    call g:SendCmdToR(rcmd)
endfunction

" Clear the console screen
function RClearConsole()
    if (has("win32") || has("win64"))
        Py RClearConsolePy()
    else
        call g:SendCmdToR("\014")
    endif
endfunction

" Remove all objects
function RClearAll()
    if g:vimrplugin_rmhidden
        call g:SendCmdToR("rm(list=ls(all.names = TRUE))")
    else
        call g:SendCmdToR("rm(list=ls())")
    endif
    sleep 500m
    call RClearConsole()
endfunction

"Set working directory to the path of current buffer
function RSetWD()
    let wdcmd = 'setwd("' . expand("%:p:h") . '")'
    if has("win32") || has("win64")
        let wdcmd = substitute(wdcmd, "\\", "/", "g")
    endif
    call g:SendCmdToR(wdcmd)
    sleep 100m
endfunction

function CloseExternalOB()
    if IsExternalOBRunning()
        call system("tmux kill-pane -t " . g:rplugin_ob_pane)
        unlet g:rplugin_ob_pane
        sleep 250m
    endif
endfunction

" Quit R
function RQuit(how)
    if a:how != "restartR"
        if bufloaded(b:objbrtitle)
            exe "bunload! " . b:objbrtitle
            sleep 30m
        endif
    endif

    if exists("b:quit_command")
        let qcmd = b:quit_command
    else
        if a:how == "save"
            let qcmd = 'quit(save = "yes")'
        else
            let qcmd = 'quit(save = "no")'
        endif
    endif

    if has("win32") || has("win64")
        exe "Py SendQuitMsg('" . qcmd . "')"
    else
        call g:SendCmdToR(qcmd)
        if g:rplugin_tmuxwasfirst
            if a:how == "save"
                sleep 200m
            endif
            if g:vimrplugin_restart
                let ca_ck = g:vimrplugin_ca_ck
                let g:vimrplugin_ca_ck = 0
                call g:SendCmdToR("exit")
                let g:vimrplugin_ca_ck = ca_ck
            endif
        endif
    endif

    sleep 50m

    call CloseExternalOB()

    if exists("g:rplugin_rconsole_pane")
        unlet g:rplugin_rconsole_pane
    endif

    call delete($VIMRPLUGIN_TMPDIR . "/globenv_" . $VIMINSTANCEID)
    call delete($VIMRPLUGIN_TMPDIR . "/liblist_" . $VIMINSTANCEID)
    call delete($VIMRPLUGIN_TMPDIR . "/libnames_" . $VIMINSTANCEID)
    call delete($VIMRPLUGIN_TMPDIR . "/GlobalEnvList_" . $VIMINSTANCEID)
    let g:SendCmdToR = function('SendCmdToR_fake')
endfunction

" knit the current buffer content
function! RKnit()
    update
    call RSetWD()
    call g:SendCmdToR('require(knitr); knit("' . expand("%:t") . '")')
endfunction

" Tell R to create a list of objects file listing all currently available
" objects in its environment. The file is necessary for omni completion.
function BuildROmniList()

    if has("win32") || has("win64") && g:rplugin_vimcom_pkg == "vimcom"
	if !exists("g:rplugin_vimcom_omni_warn")
	    let g:rplugin_vimcom_omni_warn = 1
            if RCheckVimCom("complete the names of objects from R's workspace.")
                sleep 2
                return
            endif
        else
            return
	endif
    endif

    let omnilistcmd = 'vim.bol("' . $VIMRPLUGIN_TMPDIR . "/GlobalEnvList_" . $VIMINSTANCEID . '"'
    if g:vimrplugin_allnames == 1
        let omnilistcmd = omnilistcmd . ', allnames = TRUE'
    endif
    let omnilistcmd = omnilistcmd . ')'

    call delete($VIMRPLUGIN_TMPDIR . "/vimbol_finished")
        call delete($VIMRPLUGIN_TMPDIR . "/eval_reply")
        exe "Py SendToVimCom('" . omnilistcmd . "')"
        if g:rplugin_vimcomport == 0
            sleep 500m
            return
        endif
        let g:rplugin_lastrpl = ReadEvalReply()
        if g:rplugin_lastrpl == "R is busy." || g:rplugin_lastrpl == "No reply"
            call RWarningMsg(g:rplugin_lastrpl)
            sleep 800m
            return
        endif
        sleep 20m
    let ii = 0
    while !filereadable($VIMRPLUGIN_TMPDIR . "/vimbol_finished") && ii < 5
        let ii += 1
        sleep
    endwhile
    echon "\r               "
    if ii == 5
        call RWarningMsg("No longer waiting...")
        return
    endif

    let g:rplugin_globalenvlines = readfile($VIMRPLUGIN_TMPDIR . "/GlobalEnvList_" . $VIMINSTANCEID)
    echon
endfunction

function RRemoveFromLibls(nlib)
    let idx = 0
    for lib in g:rplugin_libls
        if lib == a:nlib
            call remove(g:rplugin_libls, idx)
            break
        endif
        let idx += 1
    endfor
endfunction

function RAddToLibList(nlib, verbose)
    if isdirectory(g:rplugin_uservimfiles . "/r-plugin/objlist")
        let omf = split(globpath(&rtp, 'r-plugin/objlist/omnils_' . a:nlib . '_*'), "\n")
        if len(omf) == 1
            let nlist = readfile(omf[0])

            " List of objects for omni completion
            let g:rplugin_liblist = g:rplugin_liblist + nlist

            " List of objects for :Rhelp completion
            for xx in nlist
                let xxx = split(xx, "\x06")
                if len(xxx) > 0 && xxx[0] !~ '\$'
                    call add(s:list_of_objs, xxx[0])
                endif
            endfor
        elseif a:verbose && len(omf) == 0
            call RWarningMsg('Omnils file for "' . a:nlib . '" not found.')
            call RRemoveFromLibls(a:nlib)
            return
        elseif a:verbose && len(omf) > 1
            call RWarningMsg('There is more than one omnils file for "' . a:nlib . '".')
            for obl in omf
                call RWarningMsg(obl)
            endfor
            call RRemoveFromLibls(a:nlib)
            return
        endif
    endif
endfunction

" This function is called by the R package vimcom.plus whenever a library is
" loaded.
function RFillLibList()
    " Update the list of objects for omnicompletion
    if filereadable($VIMRPLUGIN_TMPDIR . "/libnames_" . $VIMINSTANCEID)
        let newls = readfile($VIMRPLUGIN_TMPDIR . "/libnames_" . $VIMINSTANCEID)
        for nlib in newls
            let isold = 0
            for olib in g:rplugin_libls
                if nlib == olib
                    let isold = 1
                    break
                endif
            endfor
            if isold == 0
                let g:rplugin_libls = g:rplugin_libls + [ nlib ]
                call RAddToLibList(nlib, 1)
            endif
        endfor
    endif

    if exists("*RUpdateFunSyntax")
        call RUpdateFunSyntax(0)
        if &filetype != "r"
            silent exe "set filetype=" . &filetype
        endif
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
                " The editor window is large enough to be split
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
        let g:rplugin_htw = g:rplugin_htw - (&number || &relativenumber) * &numberwidth
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
        if (line =~ '^\k*\s*(' || line =~ '^\k*\s*=\s*\k*\s*(') && line !~ '[.*('
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
        elseif line =~ '^\(\k\|\$\)*\s*[' || line =~ '^\(k\|\$\)*\s*=\s*\(\k\|\$\)*\s*[.*('
            let idx = 0
            while line[idx] != '['
                let idx += 1
            endwhile
            let idx += 1
            let nparen = 1
            let len = strlen(line)
            let lnum = line(".")
            while nparen != 0
                if line[idx] == '['
                    let nparen += 1
                else
                    if line[idx] == ']'
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

    if (has("win32") || has("win64")) && g:rplugin_vimcom_pkg == "vimcom"
        if RCheckVimCom("see R help on Vim buffer.")
            return
        endif
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
    call delete($VIMRPLUGIN_TMPDIR . "/eval_reply")
    if classfor == "" && a:package == ""
        exe 'Py SendToVimCom("vim.help(' . "'" . a:rkeyword . "', " . g:rplugin_htw . 'L)")'
    elseif a:package != ""
        exe 'Py SendToVimCom("vim.help(' . "'" . a:rkeyword . "', " . g:rplugin_htw . "L, package='" . a:package  . "')". '")'
    else
        let classfor = substitute(classfor, '\\', "", "g")
        let classfor = substitute(classfor, '"', '\\"', "g")
        exe 'Py SendToVimCom("vim.help(' . "'" . a:rkeyword . "', " . g:rplugin_htw . "L, " . classfor . ")". '")'
    endif
    let g:rplugin_lastrpl = ReadEvalReply()
    if g:rplugin_lastrpl != "VIMHELP"
        if g:rplugin_lastrpl =~ "^MULTILIB"
            echo "The topic '" . a:rkeyword . "' was found in more than one library:"
            let libs = split(g:rplugin_lastrpl)
            for idx in range(1, len(libs) - 1)
                echo idx . " : " . libs[idx]
            endfor
            let chn = input("Please, select one of them: ")
            if chn > 0 && chn < len(libs)
                call delete($VIMRPLUGIN_TMPDIR . "/eval_reply")
                exe 'Py SendToVimCom("vim.help(' . "'" . a:rkeyword . "', " . g:rplugin_htw . "L, package='" . libs[chn] . "')" . '")'
                let g:rplugin_lastrpl = ReadEvalReply()
            endif
        else
            call RWarningMsg(g:rplugin_lastrpl)
            return
        endif
    endif

    " Local variables that must be inherited by the rdoc buffer
    let g:tmp_tmuxsname = g:rplugin_tmuxsname
    let g:tmp_objbrtitle = b:objbrtitle

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
            echomsg 'Invalid vimrplugin_vimpager value: "' . g:vimrplugin_vimpager . '". Valid values are: "tab", "vertical", "horizontal", "tabnew" and "no".'
            echohl Normal
            return
        endif
    endif

    setlocal modifiable
    let g:rplugin_curbuf = bufname("%")

    " Inheritance of local variables from the script buffer
    let b:objbrtitle = g:tmp_objbrtitle
    let g:rplugin_tmuxsname = g:tmp_tmuxsname
    unlet g:tmp_objbrtitle

    let save_unnamed_reg = @@
    sil normal! ggdG
    let fcntt = readfile(g:rplugin_docfile)
    call setline(1, fcntt)
    set filetype=rdoc
    normal! gg
    let @@ = save_unnamed_reg
    setlocal nomodified
    setlocal nomodifiable
    redraw
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
        call g:SendCmdToR("vim.srcdir()")
    else
        call g:SendCmdToR("vim.srcdir('" . dir . "')")
    endif
endfunction

function RAskHelp(...)
    if a:1 == ""
        call g:SendCmdToR("help.start()")
        return
    endif
    if g:vimrplugin_vimpager != "no"
        call ShowRDoc(a:1, "", 0)
    else
        call g:SendCmdToR("help(" . a:1. ")")
    endif
endfunction

function PrintRObject(rkeyword)
    if bufname("%") =~ "Object_Browser"
        let classfor = ""
    else
        let classfor = RGetClassFor(a:rkeyword)
    endif
    if classfor == ""
        call g:SendCmdToR("print(" . a:rkeyword . ")")
    else
        call g:SendCmdToR('vim.print("' . a:rkeyword . '", ' . classfor . ")")
    endif
endfunction

" Call R functions for the word under cursor
function RAction(rcmd)
    if &filetype == "rbrowser"
        let rkeyword = RBrowserGetName(1, 0)
    else
        let rkeyword = RGetKeyWord()
    endif
    if strlen(rkeyword) > 0
        if a:rcmd == "help"
            if g:vimrplugin_vimpager == "no"
                call g:SendCmdToR("help(" . rkeyword . ")")
            else
                if bufname("%") =~ "Object_Browser" || b:rplugin_extern_ob
                    if g:rplugin_curview == "libraries"
                        let pkg = RBGetPkgName()
                    else
                        let pkg = ""
                    endif
                    if b:rplugin_extern_ob
                        if g:rplugin_vim_pane == "none"
                            call RWarningMsg("Cmd not available.")
                        else
                            if g:rplugin_editor_sname == ""
                                let slog = system("tmux set-buffer '" . "\<C-\>\<C-N>" . ':call ShowRDoc("' . rkeyword . '", "' . pkg . '", 0)' . "\<C-M>' && tmux paste-buffer -t " . g:rplugin_vim_pane . " && tmux select-pane -t " . g:rplugin_vim_pane)
                                if v:shell_error
                                    call RWarningMsg(slog)
                                endif
                            else
                                silent exe 'call remote_expr("' . g:rplugin_editor_sname . '", ' . "'ShowRDoc(" . '"' . rkeyword . '", "' . pkg . '", 0)' . "')"
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
            call g:SendCmdToR(raction)
            return
        endif

        let raction = rfun . "(" . rkeyword . ")"
        call g:SendCmdToR(raction)
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
    call RCreateMenuItem("nvi", 'Command.List\ space', '<Plug>RListSpace', 'rl', ':call g:SendCmdToR("ls()")')
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
    call RCreateMaps("nvi", '<Plug>RListSpace',    'rl', ':call g:SendCmdToR("ls()")')
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
    if g:vimrplugin_insert_mode_cmds == 1 && a:type =~ "i"
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
    if &filetype == "rnoweb" || &filetype == "rmd" || &filetype == "rrst" || g:vimrplugin_never_unmake_menu
        menu R.Send.-Sep2- <nul>
        call RCreateMenuItem("ni", 'Send.Chunk\ (cur)', '<Plug>RSendChunk', 'cc', ':call b:SendChunkToR("silent", "stay")')
        call RCreateMenuItem("ni", 'Send.Chunk\ (cur,\ echo)', '<Plug>RESendChunk', 'ce', ':call b:SendChunkToR("echo", "stay")')
        call RCreateMenuItem("ni", 'Send.Chunk\ (cur,\ down)', '<Plug>RDSendChunk', 'cd', ':call b:SendChunkToR("silent", "down")')
        call RCreateMenuItem("ni", 'Send.Chunk\ (cur,\ echo\ and\ down)', '<Plug>REDSendChunk', 'ca', ':call b:SendChunkToR("echo", "down")')
        call RCreateMenuItem("ni", 'Send.Chunk\ (from\ first\ to\ here)', '<Plug>RSendChunkFH', 'ch', ':call SendFHChunkToR()')
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
    if &filetype == "rnoweb" || &filetype == "rmd" || &filetype == "rrst" || g:vimrplugin_never_unmake_menu
        if &filetype == "rnoweb" || g:vimrplugin_never_unmake_menu
            menu R.Command.-Sep5- <nul>
            call RCreateMenuItem("nvi", 'Command.Sweave\ (cur\ file)', '<Plug>RSweave', 'sw', ':call RSweave()')
            call RCreateMenuItem("nvi", 'Command.Sweave\ and\ PDF\ (cur\ file)', '<Plug>RMakePDF', 'sp', ':call RMakePDF("nobib", 0)')
            if has("win32") || has("win64")
                call RCreateMenuItem("nvi", 'Command.Sweave\ and\ PDF\ (cur\ file,\ verbose)', '<Plug>RMakePDF', 'sv', ':call RMakePDF("verbose", 0)')
            else
                call RCreateMenuItem("nvi", 'Command.Sweave,\ BibTeX\ and\ PDF\ (cur\ file)', '<Plug>RBibTeX', 'sb', ':call RMakePDF("bibtex", 0)')
            endif
        endif
        menu R.Command.-Sep6- <nul>
        call RCreateMenuItem("nvi", 'Command.Knit\ (cur\ file)', '<Plug>RKnit', 'kn', ':call RKnit()')
        if &filetype == "rnoweb" || g:vimrplugin_never_unmake_menu
            call RCreateMenuItem("nvi", 'Command.Knit\ and\ PDF\ (cur\ file)', '<Plug>RMakePDFK', 'kp', ':call RMakePDF("nobib", 1)')
            if has("win32") || has("win64")
                call RCreateMenuItem("nvi", 'Command.Knit\ and\ PDF\ (cur\ file,\ verbose)', '<Plug>RMakePDFKv', 'kv', ':call RMakePDF("verbose", 1)')
            else
                call RCreateMenuItem("nvi", 'Command.Knit,\ BibTeX\ and\ PDF\ (cur\ file)', '<Plug>RBibTeXK', 'kb', ':call RMakePDF("bibtex", 1)')
            endif
        endif
        if &filetype == "rmd" || g:vimrplugin_never_unmake_menu
            call RCreateMenuItem("nvi", 'Command.Knit\ and\ PDF\ (cur\ file)', '<Plug>RMakePDFK', 'kp', ':call RMakePDFrmd("latex")')
            call RCreateMenuItem("nvi", 'Command.Knit\ and\ Beamer\ PDF\ (cur\ file)', '<Plug>RMakePDFKb', 'kl', ':call RMakePDFrmd("beamer")')
            call RCreateMenuItem("nvi", 'Command.Knit\ and\ HTML\ (cur\ file)', '<Plug>RMakeHTML', 'kh', ':call RMakeHTMLrmd("html")')
            call RCreateMenuItem("nvi", 'Command.Knit\ and\ ODT\ (cur\ file)', '<Plug>RMakeODT', 'ko', ':call RMakeHTMLrmd("odt")')
            call RCreateMenuItem("nvi", 'Command.Slidify\ (cur\ file)', '<Plug>RMakeSlides', 'sl', ':call RMakeSlidesrmd()')
        endif
        if &filetype == "rrst" || g:vimrplugin_never_unmake_menu
            call RCreateMenuItem("nvi", 'Command.Knit\ and\ PDF\ (cur\ file)', '<Plug>RMakePDFK', 'kp', ':call RMakePDFrrst()')
            call RCreateMenuItem("nvi", 'Command.Knit\ and\ HTML\ (cur\ file)', '<Plug>RMakeHTML', 'kh', ':call RMakeHTMLrrst("html")')
            call RCreateMenuItem("nvi", 'Command.Knit\ and\ ODT\ (cur\ file)', '<Plug>RMakeODT', 'ko', ':call RMakeHTMLrrst("odt")')
        endif
        menu R.Command.-Sep61- <nul>
        call RCreateMenuItem("nvi", 'Command.Open\ PDF\ (cur\ file)', '<Plug>ROpenPDF', 'op', ':call ROpenPDF()')
    endif
    "-------------------------------
    if &filetype == "rrst" || g:vimrplugin_never_unmake_menu
        menu R.Command.-Sep5- <nul>
        call RCreateMenuItem("nvi", 'Command.Knit\ (cur\ file)', '<Plug>RKnit', 'kn', ':call RKnit()')
        call RCreateMenuItem("nvi", 'Command.Knit\ and\ PDF\ (cur\ file)', '<Plug>RMakePDF', 'kp', ':call RMakePDF("nobib")')
    endif
    "-------------------------------
    if &filetype == "r" || g:vimrplugin_never_unmake_menu
        menu R.Command.-Sep71- <nul>
        call RCreateMenuItem("nvi", 'Command.Spin\ (cur\ file)', '<Plug>RSpinFile', 'ks', ':call RSpin()')
    endif
    menu R.Command.-Sep72- <nul>
    if &filetype == "r" || &filetype == "rnoweb" || g:vimrplugin_never_unmake_menu
        nmenu <silent> R.Command.Build\ tags\ file\ (cur\ dir)<Tab>:RBuildTags :call g:SendCmdToR('rtags(ofile = "TAGS")')<CR>
        imenu <silent> R.Command.Build\ tags\ file\ (cur\ dir)<Tab>:RBuildTags <Esc>:call g:SendCmdToR('rtags(ofile = "TAGS")')<CR>a
    endif

    menu R.-Sep7- <nul>

    "----------------------------------------------------------------------------
    " Edit
    "----------------------------------------------------------------------------
    if &filetype == "r" || &filetype == "rnoweb" || &filetype == "rrst" || &filetype == "rhelp" || g:vimrplugin_never_unmake_menu
        if g:vimrplugin_assign == 1
            silent exe 'imenu <silent> R.Edit.Insert\ \"\ <-\ \"<Tab>' . g:vimrplugin_assign_map . ' <Esc>:call ReplaceUnderS()<CR>a'
        endif
        imenu <silent> R.Edit.Complete\ object\ name<Tab>^X^O <C-X><C-O>
        if hasmapto("<Plug>RCompleteArgs", "i")
            let boundkey = RIMapCmd("<Plug>RCompleteArgs")
            exe "imenu <silent> R.Edit.Complete\\ function\\ arguments<Tab>" . boundkey . " " . boundkey
        else
            imenu <silent> R.Edit.Complete\ function\ arguments<Tab>^X^A <C-X><C-A>
        endif
        menu R.Edit.-Sep71- <nul>
        nmenu <silent> R.Edit.Indent\ (line)<Tab>== ==
        vmenu <silent> R.Edit.Indent\ (selected\ lines)<Tab>= =
        nmenu <silent> R.Edit.Indent\ (whole\ buffer)<Tab>gg=G gg=G
        menu R.Edit.-Sep72- <nul>
        call RCreateMenuItem("ni", 'Edit.Toggle\ comment\ (line/sel)', '<Plug>RToggleComment', 'xx', ':call RComment("normal")')
        call RCreateMenuItem("v", 'Edit.Toggle\ comment\ (line/sel)', '<Plug>RToggleComment', 'xx', ':call RComment("selection")')
        call RCreateMenuItem("ni", 'Edit.Comment\ (line/sel)', '<Plug>RSimpleComment', 'xc', ':call RSimpleCommentLine("normal", "c")')
        call RCreateMenuItem("v", 'Edit.Comment\ (line/sel)', '<Plug>RSimpleComment', 'xc', ':call RSimpleCommentLine("selection", "c")')
        call RCreateMenuItem("ni", 'Edit.Uncomment\ (line/sel)', '<Plug>RSimpleUnComment', 'xu', ':call RSimpleCommentLine("normal", "u")')
        call RCreateMenuItem("v", 'Edit.Uncomment\ (line/sel)', '<Plug>RSimpleUnComment', 'xu', ':call RSimpleCommentLine("selection", "u")')
        call RCreateMenuItem("ni", 'Edit.Add/Align\ right\ comment\ (line,\ sel)', '<Plug>RRightComment', ';', ':call MovePosRCodeComment("normal")')
        call RCreateMenuItem("v", 'Edit.Add/Align\ right\ comment\ (line,\ sel)', '<Plug>RRightComment', ';', ':call MovePosRCodeComment("selection")')
        if &filetype == "rnoweb" || &filetype == "rrst" || &filetype == "rmd" || g:vimrplugin_never_unmake_menu
            menu R.Edit.-Sep73- <nul>
            nmenu <silent> R.Edit.Go\ (next\ R\ chunk)<Tab>gn :call b:NextRChunk()<CR>
            nmenu <silent> R.Edit.Go\ (previous\ R\ chunk)<Tab>gN :call b:PreviousRChunk()<CR>
        endif
    endif

    "----------------------------------------------------------------------------
    " Object Browser
    "----------------------------------------------------------------------------
    call RBrowserMenu()

    "----------------------------------------------------------------------------
    " Help
    "----------------------------------------------------------------------------
    menu R.-Sep8- <nul>
    amenu R.Help\ (plugin).Overview :help r-plugin-overview<CR>
    amenu R.Help\ (plugin).Main\ features :help r-plugin-features<CR>
    amenu R.Help\ (plugin).Installation :help r-plugin-installation<CR>
    amenu R.Help\ (plugin).Use :help r-plugin-use<CR>
    amenu R.Help\ (plugin).Known\ bugs\ and\ workarounds :help r-plugin-known-bugs<CR>

    amenu R.Help\ (plugin).Options.Assignment\ operator\ and\ Rnoweb\ code :help vimrplugin_assign<CR>
    amenu R.Help\ (plugin).Options.Object\ Browser :help vimrplugin_objbr_place<CR>
    amenu R.Help\ (plugin).Options.Vim\ as\ pager\ for\ R\ help :help vimrplugin_vimpager<CR>
    if !(has("gui_win32") || has("gui_win64"))
        amenu R.Help\ (plugin).Options.Terminal\ emulator :help vimrplugin_term<CR>
    endif
    if has("gui_macvim") || has("gui_mac") || has("mac") || has("macunix")
        amenu R.Help\ (plugin).Options.Integration\ with\ Apple\ Script :help vimrplugin_applescript<CR>
    endif
    if has("gui_win32") || has("gui_win64")
        amenu R.Help\ (plugin).Options.Use\ 32\ bit\ version\ of\ R :help vimrplugin_i386<CR>
        amenu R.Help\ (plugin).Options.Sleep\ time :help vimrplugin_sleeptime<CR>
    endif
    amenu R.Help\ (plugin).Options.R\ path :help vimrplugin_r_path<CR>
    amenu R.Help\ (plugin).Options.Arguments\ to\ R :help vimrplugin_r_args<CR>
    amenu R.Help\ (plugin).Options.Omni\ completion\ when\ R\ not\ running :help vimrplugin_permanent_libs<CR>
    amenu R.Help\ (plugin).Options.Syntax\ highlighting\ of\ \.Rout\ files :help vimrplugin_routmorecolors<CR>
    amenu R.Help\ (plugin).Options.Automatically\ open\ the\ \.Rout\ file :help vimrplugin_routnotab<CR>
    amenu R.Help\ (plugin).Options.Special\ R\ functions :help vimrplugin_listmethods<CR>
    amenu R.Help\ (plugin).Options.Indent\ commented\ lines :help vimrplugin_indent_commented<CR>
    amenu R.Help\ (plugin).Options.LaTeX\ command :help vimrplugin_latexcmd<CR>
    amenu R.Help\ (plugin).Options.Never\ unmake\ the\ R\ menu :help vimrplugin_never_unmake_menu<CR>

    amenu R.Help\ (plugin).Custom\ key\ bindings :help r-plugin-key-bindings<CR>
    amenu R.Help\ (plugin).Files :help r-plugin-files<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.All\ tips :help r-plugin-tips<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Indenting\ setup :help r-plugin-indenting<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Folding\ setup :help r-plugin-folding<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Remap\ LocalLeader :help r-plugin-localleader<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Customize\ key\ bindings :help r-plugin-bindings<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.ShowMarks :help r-plugin-showmarks<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.SnipMate :help r-plugin-snippets<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.LaTeX-Box :help r-plugin-latex-box<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Highlight\ marks :help r-plugin-showmarks<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Global\ plugin :help r-plugin-global<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Jump\ to\ function\ definitions :help r-plugin-tagsfile<CR>
    amenu R.Help\ (plugin).News :help r-plugin-news<CR>

    amenu R.Help\ (R)<Tab>:Rhelp :call g:SendCmdToR("help.start()")<CR>
    amenu R.Configure\ (Vim-R)<Tab>:RpluginConfig :RpluginConfig<CR>
    let g:rplugin_hasmenu = 1

    "----------------------------------------------------------------------------
    " ToolBar
    "----------------------------------------------------------------------------
    if g:rplugin_has_icons
        " Buttons
        amenu <silent> ToolBar.RStart :call StartR("R")<CR>
        amenu <silent> ToolBar.RClose :call RQuit('no')<CR>
        "---------------------------
        if &filetype == "r" || g:vimrplugin_never_unmake_menu
            nmenu <silent> ToolBar.RSendFile :call SendFileToR("echo")<CR>
            imenu <silent> ToolBar.RSendFile <Esc>:call SendFileToR("echo")<CR>
            let g:rplugin_hasRSFbutton = 1
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
        nmenu <silent> ToolBar.RListSpace :call g:SendCmdToR("ls()")<CR>
        imenu <silent> ToolBar.RListSpace <Esc>:call g:SendCmdToR("ls()")<CR>
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
    else
        let g:rplugin_hasbuttons = 0
    endif
endfunction

function UnMakeRMenu()
    if g:rplugin_hasmenu == 0 || g:vimrplugin_never_unmake_menu == 1 || &previewwindow || (&buftype == "nofile" && &filetype != "rbrowser")
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
        if g:rplugin_hasRSFbutton
            aunmenu ToolBar.RSendFile
            let g:rplugin_hasRSFbutton = 0
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
    setlocal nomodifiable
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
    call RCreateMaps("ni", '<Plug>RToggleComment',   'xx', ':call RComment("normal")')
    call RCreateMaps("v", '<Plug>RToggleComment',   'xx', ':call RComment("selection")')
    call RCreateMaps("ni", '<Plug>RSimpleComment',   'xc', ':call RSimpleCommentLine("normal", "c")')
    call RCreateMaps("v", '<Plug>RSimpleComment',   'xc', ':call RSimpleCommentLine("selection", "c")')
    call RCreateMaps("ni", '<Plug>RSimpleUnComment',   'xu', ':call RSimpleCommentLine("normal", "u")')
    call RCreateMaps("v", '<Plug>RSimpleUnComment',   'xu', ':call RSimpleCommentLine("selection", "u")')
    call RCreateMaps("ni", '<Plug>RRightComment',   ';', ':call MovePosRCodeComment("normal")')
    call RCreateMaps("v", '<Plug>RRightComment',    ';', ':call MovePosRCodeComment("selection")')
    " Replace 'underline' with '<-'
    if g:vimrplugin_assign == 1
        silent exe 'imap <buffer><silent> ' . g:vimrplugin_assign_map . ' <Esc>:call ReplaceUnderS()<CR>a'
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

    if &filetype == "rnoweb" || &filetype == "rmd" || &filetype == "rrst"
        call RCreateMaps("ni", '<Plug>RSendChunkFH', 'ch', ':call SendFHChunkToR()')
    endif

    " *Line*
    "-------------------------------------
    call RCreateMaps("ni", '<Plug>RSendLine', 'l', ':call SendLineToR("stay")')
    call RCreateMaps('ni0', '<Plug>RDSendLine', 'd', ':call SendLineToR("down")')
    call RCreateMaps('i', '<Plug>RSendLAndOpenNewOne', 'q', ':call SendLineToR("newline")')
    nmap <LocalLeader>r<Left> :call RSendPartOfLine("left", 0)<CR>
    nmap <LocalLeader>r<Right> :call RSendPartOfLine("right", 0)<CR>
    if g:vimrplugin_insert_mode_cmds
        imap <buffer><silent> <LocalLeader>r<Left> <Esc>l:call RSendPartOfLine("left", 0)<CR>i
        imap <buffer><silent> <LocalLeader>r<Right> <Esc>l:call RSendPartOfLine("right", 0)<CR>i
    endif

    " For compatibility with Johannes Ranke's plugin
    if g:vimrplugin_map_r == 1
        vnoremap <buffer><silent> r <Esc>:call SendSelectionToR("silent", "down")<CR>
    endif
endfunction

function RBufEnter()
    let g:rplugin_curbuf = bufname("%")
    if has("gui_running")
        if &filetype != g:rplugin_lastft
            call UnMakeRMenu()
            if &filetype == "r" || &filetype == "rnoweb" || &filetype == "rmd" || &filetype == "rrst" || &filetype == "rdoc" || &filetype == "rbrowser" || &filetype == "rhelp"
                if &filetype == "rbrowser"
                    call MakeRBrowserMenu()
                else
                    call MakeRMenu()
                endif
            endif
        endif
        if &buftype != "nofile" || (&buftype == "nofile" && &filetype == "rbrowser")
            let g:rplugin_lastft = &filetype
        endif
    endif

    " It would be better if we could call RUpdateFunSyntax() for all buffers
    " immediately after a new library was loaded, but the command :bufdo
    " temporarily disables Syntax events.
    if exists("b:rplugin_funls") && len(b:rplugin_funls) < len(g:rplugin_libls)
        call RUpdateFunSyntax(0)
        " If R code is included in another file type (like rnoweb or
        " rhelp), the R syntax isn't automatically updated. So, we force
        " it: 
        silent exe "set filetype=" . &filetype
    endif
endfunction

function RVimLeave()
    if exists("b:rsource")
        " b:rsource only exists if the filetype of the last buffer is .R*
        call delete(b:rsource)
    endif
    call delete($VIMRPLUGIN_TMPDIR . "/eval_reply")
    call delete($VIMRPLUGIN_TMPDIR . "/formatted_code")
    call delete($VIMRPLUGIN_TMPDIR . "/GlobalEnvList_" . $VIMINSTANCEID)
    call delete($VIMRPLUGIN_TMPDIR . "/globenv_" . $VIMINSTANCEID)
    call delete($VIMRPLUGIN_TMPDIR . "/liblist_" . $VIMINSTANCEID)
    call delete($VIMRPLUGIN_TMPDIR . "/libnames_" . $VIMINSTANCEID)
    call delete($VIMRPLUGIN_TMPDIR . "/objbrowserInit")
    call delete($VIMRPLUGIN_TMPDIR . "/Rdoc")
    call delete($VIMRPLUGIN_TMPDIR . "/Rinsert")
    call delete($VIMRPLUGIN_TMPDIR . "/tmux.conf")
    call delete($VIMRPLUGIN_TMPDIR . "/unformatted_code")
    call delete($VIMRPLUGIN_TMPDIR . "/vimbol_finished")
    call delete($VIMRPLUGIN_TMPDIR . "/vimcom_running")
endfunction

function SetRPath()
    if exists("g:vimrplugin_r_path")
        let b:rplugin_R = expand(g:vimrplugin_r_path)
        if isdirectory(b:rplugin_R)
            let b:rplugin_R = b:rplugin_R . "/R"
        endif
    else
        let b:rplugin_R = "R"
    endif
    if !executable(b:rplugin_R)
        call RWarningMsgInp("R executable not found: '" . b:rplugin_R . "'")
    endif
    if !exists("g:vimrplugin_r_args")
        let b:rplugin_r_args = " "
    else
        let b:rplugin_r_args = g:vimrplugin_r_args
    endif
endfunction

function RSourceOtherScripts()
    if exists("g:vimrplugin_source")
        let flist = split(g:vimrplugin_source, ",")
        for fl in flist
            if fl =~ " "
                call RWarningMsgInp("Invalid file name (empty spaces are not allowed): '" . fl . "'")
            else
                exe "source " . escape(fl, ' \')
            endif
        endfor
    endif
endfunction

command -nargs=1 -complete=customlist,RLisObjs Rinsert :call RInsert(<q-args>)
command -range=% Rformat <line1>,<line2>:call RFormatCode()
command RBuildTags :call g:SendCmdToR('rtags(ofile = "TAGS")')
command -nargs=? -complete=customlist,RLisObjs Rhelp :call RAskHelp(<q-args>)
command -nargs=? -complete=dir RSourceDir :call RSourceDirectory(<q-args>)
command RpluginConfig :runtime r-plugin/vimrconfig.vim

" TODO: Delete these two commands (Nov 2013):
command RUpdateObjList :call RWarningMsg("This command is deprecated. Now the list of objects is automatically updated by the R package vimcom.plus.")
command -nargs=? RAddLibToList :call RWarningMsg("This command is deprecated. Now the list of objects is automatically updated by the R package vimcom.plus.")

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
    if $USERNAME != ""
        let g:rplugin_userlogin = substitute($USERNAME, " ", "", "g")
    endif
endif

let $VIMRPLUGIN_HOME = g:rplugin_home
if v:servername != ""
    let $VIMEDITOR_SVRNM = v:servername
endif

if isdirectory("/tmp")
    let $VIMRPLUGIN_TMPDIR = "/tmp/r-plugin-" . g:rplugin_userlogin
else
    let $VIMRPLUGIN_TMPDIR = g:rplugin_uservimfiles . "/r-plugin/tmp"
endif
let g:rplugin_esc_tmpdir = substitute($VIMRPLUGIN_TMPDIR, ' ', '\\ ', 'g')

if !isdirectory($VIMRPLUGIN_TMPDIR)
    call mkdir($VIMRPLUGIN_TMPDIR, "p", 0700)
endif

" Old name of vimrplugin_assign option
if exists("g:vimrplugin_underscore")
    let g:vimrplugin_assign = g:vimrplugin_underscore
endif

" Variables whose default value is fixed
call RSetDefaultValue("g:vimrplugin_map_r",             0)
call RSetDefaultValue("g:vimrplugin_allnames",          0)
call RSetDefaultValue("g:vimrplugin_rmhidden",          0)
call RSetDefaultValue("g:vimrplugin_assign",            1)
call RSetDefaultValue("g:vimrplugin_assign_map",    "'_'")
call RSetDefaultValue("g:vimrplugin_rnowebchunk",       1)
call RSetDefaultValue("g:vimrplugin_strict_rst",        1)
call RSetDefaultValue("g:vimrplugin_openpdf",           0)
call RSetDefaultValue("g:vimrplugin_openpdf_quietly",   0)
call RSetDefaultValue("g:vimrplugin_openhtml",          0)
call RSetDefaultValue("g:vimrplugin_i386",              0)
call RSetDefaultValue("g:vimrplugin_Rterm",             0)
call RSetDefaultValue("g:vimrplugin_restart",           0)
call RSetDefaultValue("g:vimrplugin_vsplit",            0)
call RSetDefaultValue("g:vimrplugin_rconsole_width",   -1)
call RSetDefaultValue("g:vimrplugin_rconsole_height",  15)
call RSetDefaultValue("g:vimrplugin_listmethods",       0)
call RSetDefaultValue("g:vimrplugin_specialplot",       0)
call RSetDefaultValue("g:vimrplugin_notmuxconf",        0)
call RSetDefaultValue("g:vimrplugin_only_in_tmux",      0)
call RSetDefaultValue("g:vimrplugin_routnotab",         0)
call RSetDefaultValue("g:vimrplugin_editor_w",         66)
call RSetDefaultValue("g:vimrplugin_help_w",           46)
call RSetDefaultValue("g:vimrplugin_objbr_w",          40)
call RSetDefaultValue("g:vimrplugin_external_ob",       0)
call RSetDefaultValue("g:vimrplugin_show_args",         0)
call RSetDefaultValue("g:vimrplugin_never_unmake_menu", 0)
call RSetDefaultValue("g:vimrplugin_insert_mode_cmds",  1)
call RSetDefaultValue("g:vimrplugin_indent_commented",  1)
call RSetDefaultValue("g:vimrplugin_rcomment_string", "'# '")
call RSetDefaultValue("g:vimrplugin_vimpager",        "'tab'")
call RSetDefaultValue("g:vimrplugin_objbr_place",     "'script,right'")
call RSetDefaultValue("g:vimrplugin_permanent_libs",  "'base,stats,graphics,grDevices,utils,datasets,methods'")

if executable("latexmk")
    call RSetDefaultValue("g:vimrplugin_latexcmd", "'latexmk -pdf'")
else
    call RSetDefaultValue("g:vimrplugin_latexcmd", "'pdflatex'")
endif

" Look for invalid options
let objbrplace = split(g:vimrplugin_objbr_place, ",")
let obpllen = len(objbrplace) - 1
if obpllen > 1
    call RWarningMsgInp("Too many options for vimrplugin_objbr_place.")
    let g:rplugin_failed = 1
    finish
endif
for idx in range(0, obpllen)
    if objbrplace[idx] != "console" && objbrplace[idx] != "script" && objbrplace[idx] != "left" && objbrplace[idx] != "right"
        call RWarningMsgInp('Invalid option for vimrplugin_objbr_place: "' . objbrplace[idx] . '". Valid options are: console or script and right or left."')
        let g:rplugin_failed = 1
        finish
    endif
endfor
unlet objbrplace
unlet obpllen



" python has priority over python3
if has("python3")
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

exe "PyFile " . substitute(g:rplugin_home, " ", '\\ ', "g") . "/r-plugin/vimcom.py"

" ^K (\013) cleans from cursor to the right and ^U (\025) cleans from cursor
" to the left. However, ^U causes a beep if there is nothing to clean. The
" solution is to use ^A (\001) to move the cursor to the beginning of the line
" before sending ^K. But the control characters may cause problems in some
" circumstances.
call RSetDefaultValue("g:vimrplugin_ca_ck", 0)

" ========================================================================
" Set default mean of communication with R

if has('gui_running')
    let g:rplugin_tmuxwasfirst = 0
endif

if has("win32") || has("win64")
    let g:vimrplugin_applescript = 0
endif

if has("gui_macvim") || has("gui_mac") || has("mac") || has("macunix")
    let g:rplugin_r64app = 0
    if isdirectory("/Applications/R64.app")
        call RSetDefaultValue("g:vimrplugin_applescript", 1)
        let g:rplugin_r64app = 1
    elseif isdirectory("/Applications/R.app")
        call RSetDefaultValue("g:vimrplugin_applescript", 1)
    else
        call RSetDefaultValue("g:vimrplugin_applescript", 0)
    endif
else
    let g:vimrplugin_applescript = 0
endif

if has("gui_running")
    let vimrplugin_only_in_tmux = 0
endif

if g:vimrplugin_applescript
    let g:vimrplugin_only_in_tmux = 0
endif

if $TMUX != ""
    let g:rplugin_tmuxwasfirst = 1
    let g:vimrplugin_applescript = 0
else
    let g:vimrplugin_external_ob = 0
    let g:rplugin_tmuxwasfirst = 0
endif


" ========================================================================

if g:vimrplugin_external_ob == 1
    let g:vimrplugin_objbr_place = substitute(g:vimrplugin_objbr_place, "script", "console", "")
endif

if g:vimrplugin_objbr_place =~ "console"
    let g:vimrplugin_external_ob = 1
endif

" Check whether Tmux is OK
if !has("win32") && !has("win64") && !has("gui_win32") && !has("gui_win64") && g:vimrplugin_applescript == 0
    if !executable('tmux')
        call RWarningMsgInp("Please, install the 'Tmux' application to enable the Vim-R-plugin.")
        let g:rplugin_failed = 1
        finish
    endif

    let s:tmuxversion = system("tmux -V")
    let s:tmuxversion = substitute(s:tmuxversion, '.*tmux \([0-9]\.[0-9]\).*', '\1', '')
    if strlen(s:tmuxversion) != 3
        let s:tmuxversion = "1.0"
    endif
    if s:tmuxversion < "1.5"
        call RWarningMsgInp("Vim-R-plugin requires Tmux >= 1.5")
        let g:rplugin_failed = 1
        finish
    endif
    unlet s:tmuxversion

    " To get 256 colors you have to set the $TERM environment variable to
    " xterm-256color. See   :h r-plugin-tips
    let s:tmxcnf = $VIMRPLUGIN_TMPDIR . "/tmux.conf"
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
    exe "PyFile " . substitute(g:rplugin_home, " ", '\\ ', "g") . '\r-plugin\windows.py'
    if rplugin_pywin32 == 0
        let g:rplugin_failed = 1
        finish
    endif
    if !exists("g:rplugin_rpathadded")
        if exists("g:vimrplugin_r_path") && isdirectory(g:vimrplugin_r_path)
            let $PATH = g:vimrplugin_r_path . ";" . $PATH
            let g:rplugin_Rgui = g:vimrplugin_r_path . "\\Rgui.exe"
        else
            Py GetRPath()
            if exists("s:rinstallpath")
                if s:rinstallpath == "Key not found"
                    call RWarningMsgInp("Could not find R key in Windows Registry. Please, either install R or set the value of 'vimrplugin_r_path'.")
                    let g:rplugin_failed = 1
                    finish
                endif
                if s:rinstallpath == "Path not found"
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
                        let g:rplugin_Rgui = s:rinstallpath . '\bin\i386\Rgui.exe'
                    else
                        let $PATH = s:rinstallpath . '\bin\x64;' . $PATH
                        let g:rplugin_Rgui = s:rinstallpath . '\bin\x64\Rgui.exe'
                    endif
                else
                    let $PATH = s:rinstallpath . '\bin;' . $PATH
                    let g:rplugin_Rgui = s:rinstallpath . '\bin\Rgui.exe'
                endif
                unlet s:rinstallpath
            endif
        endif
        let g:rplugin_rpathadded = 1
    endif
    if !exists("b:rplugin_R")
        let b:rplugin_R = "Rgui.exe"
    endif
    let g:vimrplugin_term_cmd = "none"
    let g:vimrplugin_term = "none"
    if !exists("g:vimrplugin_r_args")
        let g:vimrplugin_r_args = "--sdi"
    endif
    if !exists("g:vimrplugin_sleeptime")
        let g:vimrplugin_sleeptime = 0.02
    endif
    if g:vimrplugin_Rterm
        let g:rplugin_Rgui = substitute(g:rplugin_Rgui, "Rgui", "Rterm", "")
    endif
    if !exists("g:vimrplugin_R_window_title")
        if g:vimrplugin_Rterm
            let g:vimrplugin_R_window_title = "Rterm"
        else
            let g:vimrplugin_R_window_title = "R Console"
        endif
    endif
endif

" Are we in a Debian package? Is the plugin running for the first time?
let g:rplugin_omnidname = g:rplugin_uservimfiles . "/r-plugin/objlist/"
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

" Minimum width for the Object Browser
if g:vimrplugin_objbr_w < 10
    let g:vimrplugin_objbr_w = 10
endif


" Control the menu 'R' and the tool bar buttons
if !exists("g:rplugin_hasmenu")
    let g:rplugin_hasmenu = 0
endif

" List of marks that the plugin seeks to find the block to be sent to R
let s:all_marks = "abcdefghijklmnopqrstuvwxyz"


" Choose a terminal (code adapted from screen.vim)
if has("win32") || has("win64") || g:vimrplugin_applescript || $DISPLAY == "" || g:rplugin_tmuxwasfirst
    " No external terminal emulator will be called, so any value is good
    let g:vimrplugin_term = "xterm"
else
    let s:terminals = ['gnome-terminal', 'konsole', 'xfce4-terminal', 'terminal', 'Eterm', 'rxvt', 'aterm', 'roxterm', 'terminator', 'lxterminal', 'xterm']
    if has('mac')
        let s:terminals = ['iTerm', 'Terminal', 'Terminal.app'] + s:terminals
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
    call RWarningMsgInp("Please, set the variable 'g:vimrplugin_term_cmd' in your .vimrc. Read the plugin documentation for details.")
    let g:rplugin_failed = 1
    finish
endif

let g:rplugin_termcmd = g:vimrplugin_term . " -e"

if g:vimrplugin_term == "gnome-terminal" || g:vimrplugin_term == "xfce4-terminal" || g:vimrplugin_term == "terminal" || g:vimrplugin_term == "lxterminal"
    " Cannot set gnome-terminal icon: http://bugzilla.gnome.org/show_bug.cgi?id=126081
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

autocmd BufEnter * call RBufEnter()
if &filetype != "rbrowser"
    autocmd VimLeave * call RVimLeave()
endif
autocmd BufLeave * if exists("b:rsource") | call delete(b:rsource) | endif

let g:rplugin_firstbuffer = expand("%:p")
let g:rplugin_running_objbr = 0
let g:rplugin_has_new_lib = 0
let g:rplugin_has_new_obj = 0
let g:rplugin_ob_warn_shown = 0
let g:rplugin_vimcomport = 0
let g:rplugin_vimcom_pkg = "vimcom"
let g:rplugin_lastrpl = ""
let g:rplugin_ob_busy = 0
let g:rplugin_hasRSFbutton = 0
let g:rplugin_errlist = []
let g:rplugin_tmuxsname = substitute("vimrplugin-" . g:rplugin_userlogin . localtime() . g:rplugin_firstbuffer, '\W', '', 'g')

" If this is the Object Browser running in a Tmux pane, $VIMINSTANCEID is
" already defined and shouldn't be changed
if $VIMINSTANCEID == ""
    let $VIMINSTANCEID = substitute(g:rplugin_firstbuffer . localtime(), '\W', '', 'g')
endif

let g:rplugin_obsname = toupper(substitute(substitute(expand("%:r"), '\W', '', 'g'), "_", "", "g"))

let g:rplugin_docfile = $VIMRPLUGIN_TMPDIR . "/Rdoc"

" Create an empty file to avoid errors if the user do Ctrl-X Ctrl-O before
" starting R:
if &filetype != "rbrowser"
    call writefile([], $VIMRPLUGIN_TMPDIR . "/GlobalEnvList_" . $VIMINSTANCEID)
endif

call SetRPath()

" Keeps the names object list in memory to avoid the need of reading the files
" repeatedly:
let g:rplugin_libls = split(g:vimrplugin_permanent_libs, ",")
let g:rplugin_liblist = []
let s:list_of_objs = []
for lib in g:rplugin_libls
    call RAddToLibList(lib, 0)
endfor

" Check whether tool bar icons exist
if has("win32") || has("win64")
    let g:rplugin_has_icons = len(globpath(&rtp, "bitmaps/RStart.bmp")) > 0
else
    let g:rplugin_has_icons = len(globpath(&rtp, "bitmaps/RStart.png")) > 0
endif

" Compatibility with old versions (August 2013):
if exists("g:vimrplugin_tmux")
    call RWarningMsg("The option vimrplugin_tmux is deprecated and will be ignored.")
endif
if exists("g:vimrplugin_noscreenrc")
    call RWarningMsg("The option vimrplugin_noscreenrc is deprecated and will be ignored.")
endif
if exists("g:vimrplugin_screenplugin")
    call RWarningMsg("The option vimrplugin_screenplugin is deprecated and will be ignored.")
endif
if exists("g:vimrplugin_screenvsplit")
    call RWarningMsg("The option vimrplugin_screenvsplit is deprecated. Please use vimrplugin_vsplit instead.")
endif
