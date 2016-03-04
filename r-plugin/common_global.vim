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
    call input(a:wmsg . " [Press <Enter> to continue] ")
    echohl Normal
    if savedlz == 0
        set nolazyredraw
    endif
    let &shortmess = savedsm
endfunction

if !exists("*job_getchannel")
    call RWarningMsgInp("The Vim-R-plugin requires Vim >= 7.4.1453")
    let g:rplugin_failed = 1
    finish
endif

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
        let save_unnamed_reg = @@
        let j = col(".")
        let s = getline(".")
        if g:vimrplugin_assign == 1 && g:vimrplugin_assign_map == "_" && j > 3 && s[j-3] == "<" && s[j-2] == "-" && s[j-1] == " "
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
                if s[j-1] == '"' || s[j-1] == "'" && g:vimrplugin_assign == 1
                    let synName = synIDattr(synID(line("."), j-2, 1), "name")
                    if synName == "rString" || synName == "rSpecial"
                        let isString = 0
                    endif
                endif
            else
                if g:vimrplugin_assign == 2
                    if s[j-1] != "_" && !(j > 3 && s[j-3] == "<" && s[j-2] == "-" && s[j-1] == " ")
                        let isString = 1
                    elseif j > 3 && s[j-3] == "<" && s[j-2] == "-" && s[j-1] == " "
                        exe "normal! 3h3xr_a_"
                        let @@ = save_unnamed_reg
                        return
                    else
                        if j == len(s)
                            exe "normal! 1x"
                            let @@ = save_unnamed_reg
                        else
                            exe "normal! 1xi <- "
                            let @@ = save_unnamed_reg
                            return
                        endif
                    endif
                endif
            endif
        endif
    endif
    if isString
        exe "normal! a" . g:vimrplugin_assign_map
    else
        exe "normal! a <- "
    endif
endfunction

function ReadEvalReply()
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
            echon "\rWaiting for reply"
            let haswaitwarn = 1
        endif
    endwhile
    if haswaitwarn
        echon "\r                 "
        redraw
    endif
    if reply == "No reply" || reply =~ "^Error" || reply == "INVALID" || reply == "ERROR" || reply == "EMPTY" || reply == "NO_ARGS" || reply == "NOT_EXISTS" || reply == ""
        return "R error: " . reply
    else
        return reply
    endif
endfunction

function CompleteChunkOptions()
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

    let ktopt = ["eval=;TRUE", "echo=;TRUE", "results=;'markup|asis|hold|hide'",
                \ "warning=;TRUE", "error=;TRUE", "message=;TRUE", "split=;FALSE",
                \ "include=;TRUE", "strip.white=;TRUE", "tidy=;FALSE", "tidy.opts=; ",
                \ "prompt=;FALSE", "comment=;'##'", "highlight=;TRUE", "background=;'#F7F7F7'",
                \ "cache=;FALSE", "cache.path=;'cache/'", "cache.vars=; ",
                \ "cache.lazy=;TRUE", "cache.comments=; ", "dependson=;''",
                \ "autodep=;FALSE", "fig.path=; ", "fig.keep=;'high|none|all|first|last'",
                \ "fig.show=;'asis|hold|animate|hide'", "dev=; ", "dev.args=; ",
                \ "fig.ext=; ", "dpi=;72", "fig.width=;7", "fig.height=;7",
                \ "out.width=;'7in'", "out.height=;'7in'", "out.extra=; ",
                \ "resize.width=; ", "resize.height=; ", "fig.align=;'left|right|center'",
                \ "fig.env=;'figure'", "fig.cap=;''", "fig.scap=;''", "fig.lp=;'fig:'",
                \ "fig.pos=;''", "fig.subcap=; ", "fig.process=; ", "interval=;1",
                \ "aniopts=;'controls.loop'", "code=; ", "ref.label=; ",
                \ "child=; ", "engine=;'R'", "opts.label=;''", "purl=;TRUE",
                \ 'R.options=; ']
    if &filetype == "rnoweb"
        let ktopt += ["external=;TRUE", "sanitize=;FALSE", "size=;'normalsize'"]
    endif
    if &filetype == "rmd" || &filetype == "rrst"
        let ktopt += ["fig.retina=;1"]
        if &filetype == "rmd"
            let ktopt += ["collapse=;FALSE"]
        endif
    endif
    call sort(ktopt)

    for kopt in ktopt
        if kopt =~ newbase
            let tmp1 = split(kopt, ";")
            let tmp2 = {'word': tmp1[0], 'menu': tmp1[1]}
            call add(rr, tmp2)
        endif
    endfor
    call complete(idx1 + 1, rr)
endfunction

function IsFirstRArg(lnum, cpos)
    let line = getline(a:lnum)
    let ii = a:cpos[2] - 2
    let cchar = line[ii]
    while ii > 0 && cchar != '('
        let cchar = line[ii]
        if cchar == ','
            return 0
        endif
        let ii -= 1
    endwhile
    return 1
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
            let objclass = RGetFirstObjClass(rkeyword0)
            let rkeyword = '^' . rkeyword0 . "\x06"
            call cursor(cpos[1], cpos[2])

            " If R is running, use it
            if string(g:SendCmdToR) != "function('SendCmdToR_fake')"
                call delete(g:rplugin_tmpdir . "/eval_reply")
                let msg = 'vimcom:::vim.args("'
                if objclass == ""
                    let msg = msg . rkeyword0 . '", "' . argkey . '"'
                else
                    let msg = msg . rkeyword0 . '", "' . argkey . '", objclass = ' . objclass
                endif
                if rkeyword0 == "library" || rkeyword0 == "require"
                    let isfirst = IsFirstRArg(lnum, cpos)
                else
                    let isfirst = 0
                endif
                if isfirst
                    let msg = msg . ', firstLibArg = TRUE)'
                else
                    let msg = msg . ')'
                endif
                call SendToVimCom("\x08" . $VIMINSTANCEID . msg)

                if g:rplugin_vimcomport > 0
                    let g:rplugin_lastev = ReadEvalReply()
                    if g:rplugin_lastev !~ "^R error: "
                        let args = []
                        if g:rplugin_lastev[0] == "\x04" && len(split(g:rplugin_lastev, "\x04")) == 1
                            return ''
                        endif
                        let tmp0 = split(g:rplugin_lastev, "\x04")
                        let tmp = split(tmp0[0], "\x09")
                        if(len(tmp) > 0)
                            for id in range(len(tmp))
                                let tmp2 = split(tmp[id], "\x07")
                                if tmp2[0] == '...' || isfirst
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
            endif

            " If R isn't running, use the prebuilt list of objects
            let flines = g:rplugin_globalenvlines + g:rplugin_omni_lines
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

function CleanOxygenLine(line)
    let cline = a:line
    if cline =~ "^\s*#\\{1,2}'"
        let synName = synIDattr(synID(line("."), col("."), 1), "name")
        if synName == "rOExamples"
            let cline = substitute(cline, "^\s*#\\{1,2}'", "", "")
        endif
    endif
    return cline
endfunction

function CleanCurrentLine()
    let curline = substitute(getline("."), '^\s*', "", "")
    if &filetype == "r"
        let curline = CleanOxygenLine(curline)
    endif
    return curline
endfunction

" Skip empty lines and lines whose first non blank char is '#'
function GoDown()
    if &filetype == "rnoweb"
        let curline = getline(".")
        if curline[0] == '@'
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
    let curline = CleanCurrentLine()
    let lastLine = line("$")
    while i < lastLine && (curline[0] == '#' || strlen(curline) == 0)
        let i = i + 1
        call cursor(i, 1)
        let curline = CleanCurrentLine()
    endwhile
endfunction

function DelayedFillLibList()
    autocmd! RStarting
    augroup! RStarting
        let g:rplugin_starting_R = 0
        if exists("g:rplugin_fillrliblist_called") && g:rplugin_fillrliblist_called
            let g:rplugin_fillrliblist_called = 0
            call FillRLibList()
        endif
    augroup END
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
    call writefile([], g:rplugin_tmpdir . "/globenv_" . $VIMINSTANCEID)
    call writefile([], g:rplugin_tmpdir . "/liblist_" . $VIMINSTANCEID)
    call delete(g:rplugin_tmpdir . "/libnames_" . $VIMINSTANCEID)

    if g:vimrplugin_objbr_opendf
        let start_options = ['options(vimcom.opendf = TRUE)']
    else
        let start_options = ['options(vimcom.opendf = FALSE)']
    endif
    if g:vimrplugin_objbr_openlist
        let start_options += ['options(vimcom.openlist = TRUE)']
    else
        let start_options += ['options(vimcom.openlist = FALSE)']
    endif
    if g:vimrplugin_objbr_allnames
        let start_options += ['options(vimcom.allnames = TRUE)']
    else
        let start_options += ['options(vimcom.allnames = FALSE)']
    endif
    if g:vimrplugin_texerr
        let start_options += ['options(vimcom.texerrs = TRUE)']
    else
        let start_options += ['options(vimcom.texerrs = FALSE)']
    endif
    if g:vimrplugin_objbr_labelerr
        let start_options += ['options(vimcom.labelerr = TRUE)']
    else
        let start_options += ['options(vimcom.labelerr = FALSE)']
    endif
    if g:vimrplugin_vimpager == "no"
        let start_options += ['options(vimcom.vimpager = FALSE)']
    else
        let start_options += ['options(vimcom.vimpager = TRUE)']
    endif
    let start_options += ['if(utils::packageVersion("vimcom") != "1.2.9") warning("Your version of Vim-R-plugin requires vimcom-1.2-9.", call. = FALSE)']

    let rwd = ""
    if g:vimrplugin_vim_wd == 0
        let rwd = expand("%:p:h")
    elseif g:vimrplugin_vim_wd == 1
        let rwd = getcwd()
    endif
    if rwd != ""
        if has("win32")
            let rwd = substitute(rwd, '\\', '/', 'g')
        endif
        if has("win32") && &encoding == "utf-8"
            let start_options += ['.vim.rwd <- "' . rwd . '"']
            let start_options += ['Encoding(.vim.rwd) <- "UTF-8"']
            let start_options += ['setwd(.vim.rwd)']
            let start_options += ['rm(.vim.rwd)']
        else
            let start_options += ['setwd("' . rwd . '")']
        endif
    endif
    call writefile(start_options, g:rplugin_tmpdir . "/start_options.R")

    if !exists("g:vimrplugin_r_args")
        let b:rplugin_r_args = " "
    else
        let b:rplugin_r_args = g:vimrplugin_r_args
    endif

    if a:whatr =~ "custom"
        call inputsave()
        let b:rplugin_r_args = input('Enter parameters for R: ')
        call inputrestore()
    endif

    let g:rplugin_starting_R = 1

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
        return
    endif

    if IsSendCmdToRFake()
        return
    endif

    if b:rplugin_r_args == " "
        let rcmd = g:rplugin_R
    else
        let rcmd = g:rplugin_R . " " . b:rplugin_r_args
    endif

    if g:rplugin_do_tmux_split
        call StartR_TmuxSplit(rcmd)
    else
        call StartR_ExternalTerm(rcmd)
    endif
endfunction

" Send SIGINT to R
function StopR()
    if g:rplugin_r_pid
        call system("kill -s SIGINT " . g:rplugin_r_pid)
    endif
endfunction

function WaitVimComStart()
    if b:rplugin_r_args =~ "vanilla"
        return 0
    endif
    if g:vimrplugin_vimcom_wait < 300
        g:vimrplugin_vimcom_wait = 300
    endif
    redraw
    echo "Waiting vimcom loading..."
    sleep 300m
    let ii = 300
    let waitmsg = 0
    while !filereadable(g:rplugin_tmpdir . "/vimcom_running_" . $VIMINSTANCEID) && ii < g:vimrplugin_vimcom_wait
        let ii = ii + 200
        sleep 200m
    endwhile
    echon "\r                              "
    redraw
    sleep 100m
    if filereadable(g:rplugin_tmpdir . "/vimcom_running_" . $VIMINSTANCEID)
        let vr = readfile(g:rplugin_tmpdir . "/vimcom_running_" . $VIMINSTANCEID)
        let g:rplugin_vimcom_version = vr[0]
        let g:rplugin_vimcom_home = vr[1]
        let g:rplugin_vimcomport = vr[2]
        let g:rplugin_r_pid = vr[3]
        let $RCONSOLE = vr[4]
        if has("win64")
            let g:rplugin_vclntsrvr = g:rplugin_vimcom_home . "/bin/x64/vclientserver.exe"
            let g:rplugin_vimcom_lib = g:rplugin_vimcom_home . "/bin/x64/libVimR.dll"
        elseif has("win32")
            let g:rplugin_vclntsrvr = g:rplugin_vimcom_home . "/bin/i386/vclientserver.exe"
            let g:rplugin_vimcom_lib = g:rplugin_vimcom_home . "/bin/i386/libVimR.dll"
        else
            let g:rplugin_vclntsrvr = g:rplugin_vimcom_home . "/bin/vclientserver"
        endif

        if isdirectory(g:rplugin_vimcom_home . "/bin/x64")
            let vimcom_bin_dir = g:rplugin_vimcom_home . "/bin/x64"
        elseif isdirectory(g:rplugin_vimcom_home . "/bin/i386")
            let vimcom_bin_dir = g:rplugin_vimcom_home . "/bin/i386"
        else
            let vimcom_bin_dir = g:rplugin_vimcom_home . "/bin"
        endif
        if $PATH !~ vimcom_bin_dir
            if has("win32")
                let $PATH = vimcom_bin_dir . ';' . $PATH
            else
                let $PATH = vimcom_bin_dir . ':' . $PATH
            endif
        endif

        if filereadable(g:rplugin_vclntsrvr)
            " Set vimcom port in the vclientserver
            let $VIMCOMPORT = g:rplugin_vimcomport
            " Set RConsole window ID in vclientserver to ArrangeWindows()
            if has("win32")
                if $RCONSOLE == "0"
                    call RWarningMsg("vimcom did not save R window ID")
                endif
                if $WINDOWID == ""
                    if v:windowid == 0
                        call RWarningMsg("GVim did not define $WINDOWID")
                    else
                        let $WINDOWID = v:windowid
                    endif
                endif
            endif
            let vcs_job = job_start([g:rplugin_vclntsrvr],
                        \ {'out-cb': 'ROnJobStdout', 'err-cb': "ROnJobStderr"})
            let g:rplugin_channel = job_getchannel(vcs_job)
        else
            call RWarningMsgInp('Could not find "' . g:rplugin_vclntsrvr . '".')
        endif
        if g:rplugin_vimcom_version != "1.2.9"
            call RWarningMsg('This version of Vim-R-plugin requires vimcom 1.2.9.')
            sleep 1
        endif
        call delete(g:rplugin_tmpdir . "/vimcom_running_" . $VIMINSTANCEID)


        if g:rplugin_do_tmux_split
            " Environment variables persists across Tmux windows.
            " Unset VIMRPLUGIN_TMPDIR to avoid vimcom loading its C library
            " when R was not started by Vim:
            call system("tmux set-environment -u VIMRPLUGIN_TMPDIR")
        endif
        call delete(g:rplugin_tmpdir . "/start_options.R")

        " Vim may crash when the syntax highlight is changed while the window
        " is being resized, although only if the R syntax is included in
        " another filetype. To guarantee a safer startup, we delay the
        " highlight of functions for all cases:
        augroup RStarting
            autocmd!
            autocmd CursorMoved <buffer> call DelayedFillLibList()
            autocmd CursorMovedI <buffer> call DelayedFillLibList()
        augroup END

        return 1
    else
        call RWarningMsg("The package vimcom wasn't loaded yet.")
        sleep 500m
        return 0
    endif
endfunction

function StartObjBrowser_Vim()
    let wmsg = ""
    call SendToVimCom("\002" . g:rplugin_myport)

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
        sleep 50m
    endif
    if wmsg != ""
        call RWarningMsg(wmsg)
        sleep 200m
    endif
endfunction

" Open an Object Browser window
function RObjBrowser()
    " Only opens the Object Browser if R is running
    if string(g:SendCmdToR) == "function('SendCmdToR_fake')"
        call RWarningMsg("The Object Browser can be opened only if R is running.")
        return
    endif

    if g:rplugin_running_objbr == 1
        " Called twice due to BufEnter event
        return
    endif

    let g:rplugin_running_objbr = 1

    if !b:rplugin_extern_ob
        if g:vimrplugin_tmux_ob
            call StartObjBrowser_Tmux()
        else
            call StartObjBrowser_Vim()
        endif
    endif
    let g:rplugin_running_objbr = 0
    return
endfunction

function RBrOpenCloseLs(stt)
    call SendToVimCom("\007" . a:stt)
endfunction

function SendToVimCom(cmd)
    if g:rplugin_vimcomport == 0
        call RWarningMsg("VimCom port is unknown.")
        call RWarningMsg(a:cmd)
        return
    endif
    call ch_sendraw(g:rplugin_channel, "\002" . a:cmd . "\n")
endfunction

function RSetMyPort(p)
    let g:rplugin_myport = a:p
    let $VIMR_PORT = a:p
    if &filetype == "rbrowser" && g:rplugin_do_tmux_split
        call SendToVimCom("\002" . g:rplugin_myport)
    elseif g:rplugin_vimcomport
        call SendToVimCom("\001" . g:rplugin_myport)
    endif
endfunction

function RFormatCode() range
    if g:rplugin_vimcomport == 0
        return
    endif

    let lns = getline(a:firstline, a:lastline)
    call writefile(lns, g:rplugin_tmpdir . "/unformatted_code")
    let wco = &textwidth
    if wco == 0
        let wco = 78
    elseif wco < 20
        let wco = 20
    elseif wco > 180
        let wco = 180
    endif
    call delete(g:rplugin_tmpdir . "/eval_reply")
    call SendToVimCom("\x08" . $VIMINSTANCEID . 'formatR::tidy_source("' . g:rplugin_tmpdir . '/unformatted_code", file = "' . g:rplugin_tmpdir . '/formatted_code", width.cutoff = ' . wco . ')')
    let g:rplugin_lastev = ReadEvalReply()
    if g:rplugin_lastev =~ "^R error: "
        call RWarningMsg(g:rplugin_lastev)
        return
    endif
    let lns = readfile(g:rplugin_tmpdir . "/formatted_code")
    silent exe a:firstline . "," . a:lastline . "delete"
    call append(a:firstline - 1, lns)
    echo (a:lastline - a:firstline + 1) . " lines formatted."
endfunction

function RInsert(...)
    if g:rplugin_vimcomport == 0
        return
    endif

    call delete(g:rplugin_tmpdir . "/eval_reply")
    call delete(g:rplugin_tmpdir . "/Rinsert")
    call SendToVimCom("\x08" . $VIMINSTANCEID . 'capture.output(' . a:1 . ', file = "' . g:rplugin_tmpdir . '/Rinsert")')
    let g:rplugin_lastev = ReadEvalReply()
    if g:rplugin_lastev =~ "^R error: "
        call RWarningMsg(g:rplugin_lastev)
        return 0
    else
        if a:0 == 2 && a:2 == "newtab"
            tabnew
            set ft=rout
        endif
        silent exe "read " . substitute(g:rplugin_tmpdir, ' ', '\\ ', 'g') . "/Rinsert"
        return 1
    endif
endfunction

function SendLineToRAndInsertOutput()
    let lin = getline(".")
    if RInsert("print(" . lin . ")")
        let curpos = getpos(".")
        " comment the output
        let ilines = readfile(g:rplugin_tmpdir . "/Rinsert")
        for iln in ilines
            call RSimpleCommentLine("normal", "c")
            normal! j
        endfor
        call setpos(".", curpos)
    endif
endfunction

" Function to send commands
" return 0 on failure and 1 on success
function SendCmdToR_fake(cmd)
    call RWarningMsg("Did you already start R?")
    return 0
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

function GetROutput(outf)
    if a:outf =~ g:rplugin_tmpdir
        let tnum = 1
        while bufexists("so" . tnum)
            let tnum += 1
        endwhile
        exe 'tabnew so' . tnum
        exe 'read ' . substitute(a:outf, " ", '\\ ', 'g')
        set filetype=rout
        setlocal buftype=nofile
        setlocal noswapfile
    else
        exe 'tabnew ' . substitute(a:outf, " ", '\\ ', 'g')
    endif
    normal! gT
    redraw
endfunction

function RViewDF(oname)
    if exists("g:vimrplugin_csv_app")
        if !executable(g:vimrplugin_csv_app)
            call RWarningMsg('vimrplugin_csv_app ("' . g:vimrplugin_csv_app . '") is not executable')
            return
        endif
        normal! :<Esc>
        call system('cp "' . g:rplugin_tmpdir . '/Rinsert" "' . a:oname . '.csv"')
        if has("win32") || has("win64")
            silent exe '!start "' . g:vimrplugin_csv_app . '" "' . a:oname . '.csv"'
        else
            call system(g:vimrplugin_csv_app . ' "' . a:oname . '.csv" >/dev/null 2>/dev/null &')
        endif
        return
    endif
    echo 'Opening "' . a:oname . '.csv"'
    silent exe 'tabnew ' . a:oname . '.csv'
    silent 1,$d
    silent exe 'read ' . substitute(g:rplugin_tmpdir, " ", '\\ ', 'g') . '/Rinsert'
    silent 1d
    set filetype=csv
    set nomodified
    redraw
    if !exists(":CSVTable") && g:vimrplugin_csv_warn
        call RWarningMsg("csv.vim is not installed (http://www.vim.org/scripts/script.php?script_id=2830)")
    endif
endfunction

function GetSourceArgs(e)
    let sargs = ""
    if g:vimrplugin_source_args != ""
        let sargs = ", " . g:vimrplugin_source_args
    endif
    if a:e == "echo"
        let sargs .= ', echo=TRUE'
    endif
    return sargs
endfunction

" Send sources to R
function RSourceLines(...)
    let lines = a:1
    if &filetype == "rrst"
        let lines = map(copy(lines), 'substitute(v:val, "^\\.\\. \\?", "", "")')
    endif
    if &filetype == "rmd"
        let lines = map(copy(lines), 'substitute(v:val, "^(\\`\\`)\\?", "", "")')
    endif
    call writefile(lines, g:rplugin_rsource)

    if a:0 == 3 && a:3 == "NewtabInsert"
        call SendToVimCom("\x08" . $VIMINSTANCEID . 'vimcom:::vim_capture_source_output("' . g:rplugin_rsource . '", "' . g:rplugin_tmpdir . '/Rinsert")')
        return 1
    endif

    let sargs = GetSourceArgs(a:2)
    let rcmd = 'base::source("' . g:rplugin_rsource . '"' . sargs . ')'
    let ok = g:SendCmdToR(rcmd)
    return ok
endfunction

" Send file to R
function SendFileToR(e)
    update
    let fpath = expand("%:p")
    if has("win32")
        let fpath = substitute(fpath, "\\", "/", "g")
    endif
    let sargs = GetSourceArgs(a:e)
    call g:SendCmdToR('base::source("' . fpath .  '"' . sargs . ')')
endfunction

" Send block to R
" Adapted from marksbrowser plugin
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
function SendSelectionToR(...)
    if &filetype != "r"
        if b:IsInRCode(0) == 0
            if (&filetype == "rnoweb" && getline(".") !~ "\\Sexpr{") || (&filetype == "rmd" && getline(".") !~ "`r ") || (&filetype == "rrst" && getline(".") !~ ":r:`")
                call RWarningMsg("Not inside an R code chunk.")
                return
            endif
        endif
    endif

    if line("'<") == line("'>")
        let i = col("'<") - 1
        let j = col("'>") - i
        let l = getline("'<")
        let line = strpart(l, i, j)
        let line = CleanOxygenLine(line)
        let ok = g:SendCmdToR(line)
        if ok && a:2 =~ "down"
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

    let curpos = getpos(".")
    let curline = line("'<")
    for idx in range(0, len(lines) - 1)
        call setpos(".", [0, curline, 1, 0])
        let lines[idx] = CleanOxygenLine(lines[idx])
        let curline += 1
    endfor
    call setpos(".", curpos)

    if a:0 == 3 && a:3 == "NewtabInsert"
        let ok = RSourceLines(lines, a:1, "NewtabInsert")
    else
        let ok = RSourceLines(lines, a:1)
    endif

    if ok == 0
        return
    endif

    if a:2 == "down"
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
        elseif &filetype == "rmd" && line =~ "^[ \t]*```$"
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
        let chdchk = "^<<.*child *= *"
    elseif &filetype == "rmd"
        let begchk = "^[ \t]*```[ ]*{r"
        let endchk = "^[ \t]*```$"
        let chdchk = "^```.*child *= *"
    elseif &filetype == "rrst"
        let begchk = "^\\.\\. {r"
        let endchk = "^\\.\\. \\.\\."
        let chdchk = "^\.\. {r.*child *= *"
    else
        " Should never happen
        call RWarningMsg('Strange filetype (SendFHChunkToR): "' . &filetype '"')
    endif

    let codelines = []
    let here = line(".")
    let curbuf = getline(1, "$")
    let idx = 0
    while idx < here
        if curbuf[idx] =~ begchk
            " Child R chunk
            if curbuf[idx] =~ chdchk
                " First run everything up to child chunk and reset buffer
                call RSourceLines(codelines, "silent")
                let codelines = []

                " Next run child chunk and continue
                call KnitChild(curbuf[idx], 'stay')
                let idx += 1
                " Regular R chunk
            else
                let idx += 1
                while curbuf[idx] !~ endchk && idx < here
                    let codelines += [curbuf[idx]]
                    let idx += 1
                endwhile
            endif
        else
            let idx += 1
        endif
    endwhile
    call RSourceLines(codelines, "silent")
endfunction

function KnitChild(line, godown)
    let nline = substitute(a:line, '.*child *= *', "", "")
    let cfile = substitute(nline, nline[0], "", "")
    let cfile = substitute(cfile, nline[0] . '.*', "", "")
    if filereadable(cfile)
        let ok = g:SendCmdToR("require(knitr); knit('" . cfile . "', output=" . g:rplugin_null . ")")
        if a:godown =~ "down"
            call cursor(line(".")+1, 1)
            call GoDown()
        endif
    else
        call RWarningMsg("File not found: '" . cfile . "'")
    endif
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
        if line =~ "^<<.*child *= *"
            call KnitChild(line, a:godown)
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
        if line =~ "^```.*child *= *"
            call KnitChild(line, a:godown)
            return
        endif
        let line = substitute(line, "^(\\`\\`)\\?", "", "")
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
        if line =~ "^\.\. {r.*child *= *"
            call KnitChild(line, a:godown)
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
            call AskRDoc(topic, package, 1)
            return
        endif
        if RdocIsInRCode(1) == 0
            return
        endif
    endif

    if &filetype == "rhelp" && RhelpIsInRCode(1) == 0
        return
    endif

    if &filetype == "r"
        let line = CleanOxygenLine(line)
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
        let rcmd = strpart(lin, 0, idx + 1)
    endif
    call g:SendCmdToR(rcmd)
endfunction

" Clear the console screen
function RClearConsole(...)
    if has("win32")
        call ch_sendraw(g:rplugin_channel, "\006\n")
        call foreground()
    elseif !g:vimrplugin_applescript
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

function ClearRInfo()
    if exists("g:rplugin_rconsole_pane")
        unlet g:rplugin_rconsole_pane
    endif

    call delete(g:rplugin_tmpdir . "/globenv_" . $VIMINSTANCEID)
    call delete(g:rplugin_tmpdir . "/liblist_" . $VIMINSTANCEID)
    call delete(g:rplugin_tmpdir . "/libnames_" . $VIMINSTANCEID)
    call delete(g:rplugin_tmpdir . "/GlobalEnvList_" . $VIMINSTANCEID)
    call delete(g:rplugin_tmpdir . "/vimcom_running_" . $VIMINSTANCEID)
    call delete(g:rplugin_tmpdir . "/rconsole_hwnd_" . $VIMR_SECRET)
    let g:SendCmdToR = function('SendCmdToR_fake')
    let g:rplugin_r_pid = 0
    let g:rplugin_vimcomport = 0

    if g:rplugin_do_tmux_split && g:vimrplugin_tmux_title != "automatic" && g:vimrplugin_tmux_title != ""
        call system("tmux set automatic-rename on")
    endif

    if bufloaded(b:objbrtitle)
        exe "bunload! " . b:objbrtitle
        sleep 30m
    endif
endfunction

" Quit R
function RQuit(how)
    if exists("b:quit_command")
        let qcmd = b:quit_command
    else
        if a:how == "save"
            let qcmd = 'quit(save = "yes")'
        else
            let qcmd = 'quit(save = "no")'
        endif
    endif

    if g:vimrplugin_save_win_pos
        " SaveWinPos
        call ch_sendraw(g:rplugin_channel, "\004" . $VIMR_COMPLDIR . "\n")
    endif

    call g:SendCmdToR(qcmd)
    if g:rplugin_do_tmux_split && a:how == "save"
        sleep 200m
    endif

    sleep 50m
    if g:rplugin_do_tmux_split
        call CloseExternalOB()
    endif
    call ClearRInfo()
endfunction

" knit the current buffer content
function RKnit()
    update
    if has("win32") || has("win64")
        call g:SendCmdToR('require(knitr); .vim_oldwd <- getwd(); setwd("' . substitute(expand("%:p:h"), '\\', '/', 'g') . '"); knit("' . expand("%:t") . '"); setwd(.vim_oldwd); rm(.vim_oldwd)')
    else
        call g:SendCmdToR('require(knitr); .vim_oldwd <- getwd(); setwd("' . expand("%:p:h") . '"); knit("' . expand("%:t") . '"); setwd(.vim_oldwd); rm(.vim_oldwd)')
    endif
endfunction

function SetRTextWidth(rkeyword)
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
    if !bufloaded(s:rdoctitle) || g:vimrplugin_newsize == 1
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
    endif
endfunction

function RGetFirstObjClass(rkeyword)
    let firstobj = ""
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
            return firstobj
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
            let firstobj = strpart(line, 0, idx)
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
            let firstobj = strpart(line, 0, idx)
        else
            let firstobj = substitute(line, ').*', '', "")
            let firstobj = substitute(firstobj, ',.*', '', "")
            let firstobj = substitute(firstobj, ' .*', '', "")
        endif
    endif

    " Fix some problems
    if firstobj =~ '^"' && firstobj !~ '"$'
        let firstobj = firstobj . '"'
    elseif firstobj =~ "^'" && firstobj !~ "'$"
        let firstobj = firstobj . "'"
    endif
    if firstobj =~ "^'" && firstobj =~ "'$"
        let firstobj = substitute(firstobj, "^'", '"', "")
        let firstobj = substitute(firstobj, "'$", '"', "")
    endif
    if firstobj =~ '='
        let firstobj = "eval(expression(" . firstobj . "))"
    endif

    let objclass = ""
    call SendToVimCom("\x08" . $VIMINSTANCEID . "vimcom:::vim.getclass(" . firstobj . ")")
    if g:rplugin_vimcomport > 0
        let g:rplugin_lastev = ReadEvalReply()
        if g:rplugin_lastev !~ "^R error: "
            let objclass = '"' . g:rplugin_lastev . '"'
        endif
    endif

    return objclass
endfunction

" Show R's help doc in Vim's buffer
" (based  on pydoc plugin)
function AskRDoc(rkeyword, package, getclass)
    if filewritable(g:rplugin_docfile)
        call delete(g:rplugin_docfile)
    endif

    let objclass = ""
    if bufname("%") =~ "Object_Browser"
        let savesb = &switchbuf
        set switchbuf=useopen,usetab
        exe "sb " . b:rscript_buffer
        exe "set switchbuf=" . savesb
    else
        if a:getclass
            let objclass = RGetFirstObjClass(a:rkeyword)
        endif
    endif

    call SetRTextWidth(a:rkeyword)

    if objclass == "" && a:package == ""
        let rcmd = 'vimcom:::vim.help("' . a:rkeyword . '", ' . g:rplugin_htw . 'L)'
    elseif a:package != ""
        let rcmd = 'vimcom:::vim.help("' . a:rkeyword . '", ' . g:rplugin_htw . 'L, package="' . a:package  . '")'
    else
        let rcmd = 'vimcom:::vim.help("' . a:rkeyword . '", ' . g:rplugin_htw . 'L, ' . objclass . ')'
    endif

    call SendToVimCom("\x08" . $VIMINSTANCEID . rcmd)
endfunction

" This function is called by vimcom
function ShowRDoc(rkeyword)
    let rkeyw = a:rkeyword
    if a:rkeyword =~ "^MULTILIB"
        let msgs = split(a:rkeyword)
        " Vim cannot receive message from vimcom before replying to this message
        let flines = ['',
                    \ 'The topic "' . msgs[-1] . '" was found in more than one library.',
                    \ 'Press <Enter> over one of them to see the R documentation:',
                    \ '']
        for idx in range(1, len(msgs) - 2)
            let flines += [ '   ' . msgs[idx] ]
        endfor
        call writefile(flines, g:rplugin_docfile)
        let rkeyw = msgs[-1]
    endif

    " If the help command was triggered in the R Console, jump to Vim pane
    if g:rplugin_do_tmux_split && !g:rplugin_running_rhelp
        let slog = system("tmux select-pane -t " . g:rplugin_vim_pane)
        if v:shell_error
            call RWarningMsg(slog)
        endif
    endif
    let g:rplugin_running_rhelp = 0

    if bufname("%") =~ "Object_Browser"
        let savesb = &switchbuf
        set switchbuf=useopen,usetab
        exe "sb " . b:rscript_buffer
        exe "set switchbuf=" . savesb
    endif
    call SetRTextWidth(rkeyw)

    " Local variables that must be inherited by the rdoc buffer
    let g:tmp_tmuxsname = g:rplugin_tmuxsname
    let g:tmp_objbrtitle = b:objbrtitle

    let rdoccaption = substitute(s:rdoctitle, '\', '', "g")
    if a:rkeyword =~ "R History"
        let rdoccaption = "R_History"
        let s:rdoctitle = "R_History"
    endif
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
    unlet g:tmp_tmuxsname

    let save_unnamed_reg = @@
    sil normal! ggdG
    let fcntt = readfile(g:rplugin_docfile)
    call setline(1, fcntt)
    if a:rkeyword =~ "R History"
        set filetype=r
        call cursor(1, 1)
    elseif a:rkeyword =~ "^MULTILIB"
        syn match Special '<Enter>'
        exe 'syn match String /"' . rkeyw . '"/'
        for idx in range(1, len(msgs) - 2)
            exe "syn match PreProc '^   " . msgs[idx] . "'"
        endfor
        exe 'nmap <buffer><silent> <CR> :call AskRDoc("' . rkeyw . '", expand("<cword>"), 0)<CR>'
        redraw
        call cursor(5, 4)
    else
        set filetype=rdoc
        call cursor(1, 1)
    endif
    let @@ = save_unnamed_reg
    setlocal nomodified
    redraw
    stopinsert
endfunction

function ROpenPDF(path)
    if a:path == "Get Master"
        let tmpvar = SyncTeX_GetMaster()
        let pdfpath = tmpvar[1] . '/' . tmpvar[0] . '.pdf'
    else
        let pdfpath = a:path
    endif
    let basenm = substitute(substitute(pdfpath, '.*/', '', ''), '\.pdf$', '', '')

    let olddir = getcwd()
    if olddir != expand("%:p:h")
        exe "cd " . substitute(expand("%:p:h"), ' ', '\\ ', 'g')
    endif

    if !filereadable(basenm . ".pdf")
        call RWarningMsg('File not found: "' . basenm . '.pdf".')
        exe "cd " . substitute(olddir, ' ', '\\ ', 'g')
        return
    endif
    if g:rplugin_pdfviewer == "none"
        call RWarningMsg("Could not find a PDF viewer, and vimrplugin_pdfviewer is not defined.")
    else
        if g:rplugin_pdfviewer == "okular"
            let pcmd = "okular --unique '" .  pdfpath . "' 2>/dev/null >/dev/null &"
            call system(pcmd)
        elseif g:rplugin_pdfviewer == "zathura"
            if system("wmctrl -xl") =~ 'Zathura.*' . basenm . '.pdf' && g:rplugin_zathura_pid[basenm] != 0
                call system("wmctrl -a '" . basenm . ".pdf'")
            else
                let g:rplugin_zathura_pid[basenm] = 0
                call RStart_Zathura(basenm)
            endif
            exe "cd " . substitute(olddir, ' ', '\\ ', 'g')
            return
        elseif g:rplugin_pdfviewer == "sumatra" && (g:rplugin_sumatra_path != "" || FindSumatra())
            silent exe '!start "' . g:rplugin_sumatra_path . '" -reuse-instance -inverse-search "vclientserver.exe ' . "\\%f \\%l" . '" "' . basenm . '.pdf"'
            exe "cd " . substitute(olddir, ' ', '\\ ', 'g')
            return
        elseif g:rplugin_pdfviewer == "skim"
            call system(g:macvim_skim_app_path . '/Contents/MacOS/Skim "' . basenm . '.pdf" 2> /dev/null >/dev/null &')
        else
            let pcmd = g:rplugin_pdfviewer . " '" . pdfpath . "' 2>/dev/null >/dev/null &"
            call system(pcmd)
        endif
        if g:rplugin_has_wmctrl
            call system("wmctrl -a '" . basenm . ".pdf'")
        endif
    endif
    exe "cd " . substitute(olddir, ' ', '\\ ', 'g')
endfunction

function RStart_Zathura(basenm)
    let a2 = 'a2 = "vclientserver ' . "'%{input}' %{line}" . '"'
    let pycode = ["# -*- coding: " . &encoding . " -*-",
                \ "import subprocess",
                \ "import os",
                \ "import sys",
                \ "FNULL = open(os.devnull, 'w')",
                \ "a1 = '--synctex-editor-command'",
                \ a2,
                \ "a3 = '" . a:basenm . ".pdf'",
                \ "zpid = subprocess.Popen(['zathura', a1, a2, a3], stdout = FNULL, stderr = FNULL).pid",
                \ "sys.stdout.write(str(zpid))" ]
    call writefile(pycode, g:rplugin_tmpdir . "/start_zathura.py")
    let pid = system("python '" . g:rplugin_tmpdir . "/start_zathura.py" . "'")
    if pid == 0
        call RWarningMsg("Failed to run Zathura: " . substitute(pid, "\n", " ", "g"))
    else
        let g:rplugin_zathura_pid[a:basenm] = pid
    endif
    call delete(g:rplugin_tmpdir . "/start_zathura.py")
endfunction

function RSetPDFViewer()
    if exists("g:vimrplugin_pdfviewer") && g:vimrplugin_pdfviewer != "none"
        let g:rplugin_pdfviewer = tolower(g:vimrplugin_pdfviewer)
    else
        " Try to guess what PDF viewer is used:
        if has("win32") || has("win64")
            let g:rplugin_pdfviewer = "sumatra"
        elseif g:rplugin_is_darwin
            let g:rplugin_pdfviewer = "skim"
        elseif executable("zathura")
            let g:rplugin_pdfviewer = "zathura"
        elseif executable("evince")
            let g:rplugin_pdfviewer = "evince"
        elseif executable("okular")
            let g:rplugin_pdfviewer = "okular"
        else
            let g:rplugin_pdfviewer = "none"
            if $R_PDFVIEWER == ""
                let pdfvl = ["xdg-open"]
            else
                let pdfvl = [$R_PDFVIEWER, "xdg-open"]
            endif
            " List from R configure script:
            let pdfvl += ["xpdf", "gv", "gnome-gv", "ggv", "kpdf", "gpdf", "kghostview,", "acroread", "acroread4"]
            for prog in pdfvl
                if executable(prog)
                    let g:rplugin_pdfviewer = prog
                    break
                endif
            endfor
        endif
    endif

    if executable("wmctrl")
        let g:rplugin_has_wmctrl = 1
    else
        let g:rplugin_has_wmctrl = 0
    endif

    if g:rplugin_pdfviewer == "zathura"
        if g:rplugin_has_wmctrl == 0
            let g:rplugin_pdfviewer = "none"
            call RWarningMsgInp("The application wmctrl must be installed to use Zathura as PDF viewer.")
        else
            if executable("dbus-send")
                let g:rplugin_has_dbussend = 1
            else
                let g:rplugin_has_dbussend = 0
            endif
        endif
    endif
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
        call AskRDoc(a:1, "", 0)
    else
        call g:SendCmdToR("help(" . a:1. ")")
    endif
endfunction

function DisplayArgs()
    if &filetype == "r" || b:IsInRCode(0)
        let rkeyword = RGetKeyWord()
        let s:sttl_str = g:rplugin_status_line
        let fargs = "Not a function"
        for omniL in g:rplugin_omni_lines
            if omniL =~ '^' . rkeyword . "\x06"
                let tmp = split(omniL, "\x06")
                if len(tmp) < 5
                    break
                else
                    let fargs = rkeyword . '(' . tmp[4] . ')'
                endif
            endif
        endfor
        if fargs !~ "Not a function"
            let fargs = substitute(fargs, "NO_ARGS", '', 'g')
            let fargs = substitute(fargs, "\x07", '=', 'g')
            let s:sttl_str = substitute(fargs, "\x09", ', ', 'g')
            silent set statusline=%!RArgsStatusLine()
        endif
    endif
    exe "normal! a("
endfunction

function RArgsStatusLine()
    return s:sttl_str
endfunction

function RestoreStatusLine()
    exe 'set statusline=' . substitute(g:rplugin_status_line, ' ', '\\ ', 'g')
    normal! a)
endfunction

function PrintRObject(rkeyword)
    if bufname("%") =~ "Object_Browser"
        let objclass = ""
    else
        let objclass = RGetFirstObjClass(a:rkeyword)
    endif
    if objclass == ""
        call g:SendCmdToR("print(" . a:rkeyword . ")")
    else
        call g:SendCmdToR('vim.print("' . a:rkeyword . '", ' . objclass . ")")
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
                if !b:rplugin_extern_ob
                    let g:rplugin_running_rhelp = 1
                endif
                if bufname("%") =~ "Object_Browser" || b:rplugin_extern_ob
                    if g:rplugin_curview == "libraries"
                        let pkg = RBGetPkgName()
                    else
                        let pkg = ""
                    endif
                    call AskRDoc(rkeyword, pkg, 0)
                    return
                endif
                call AskRDoc(rkeyword, "", 1)
            endif
            return
        endif
        if a:rcmd == "print"
            call PrintRObject(rkeyword)
            return
        endif
        let rfun = a:rcmd
        if a:rcmd == "args"
            if g:vimrplugin_listmethods == 1
                call g:SendCmdToR('vim.list.args("' . rkeyword . '")')
            else
                call g:SendCmdToR('args("' . rkeyword . '")')
            endif
            return
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
        if a:rcmd == "viewdf"
            if exists("g:vimrplugin_df_viewer")
                call g:SendCmdToR(printf(g:vimrplugin_df_viewer, rkeyword))
            else
                echo "Wait..."
                call delete(g:rplugin_tmpdir . "/Rinsert")
                call SendToVimCom("\x08" . $VIMINSTANCEID . 'vimcom:::vim_viewdf("' . rkeyword . '")')
            endif
            return
        endif

        let raction = rfun . "(" . rkeyword . ")"
        call g:SendCmdToR(raction)
    endif
endfunction

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
    call RCreateMaps("nvi", '<Plug>RViewDF',    'rv', ':call RAction("viewdf")')

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
    call RCreateMaps("nvi", '<Plug>ROpenLists',        'r=', ':call RBrOpenCloseLs(1)')
    call RCreateMaps("nvi", '<Plug>RCloseLists',       'r-', ':call RBrOpenCloseLs(0)')
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
        elseif g:vimrplugin_user_maps_only == 0
            exec 'noremap <buffer><silent> <LocalLeader>' . a:combo . ' ' . tg
        endif
    endif
    if a:type =~ "v"
        if hasmapto(a:plug, "v")
            exec 'vnoremap <buffer><silent> ' . a:plug . ' <Esc>' . tg
        elseif g:vimrplugin_user_maps_only == 0
            exec 'vnoremap <buffer><silent> <LocalLeader>' . a:combo . ' <Esc>' . tg
        endif
    endif
    if g:vimrplugin_insert_mode_cmds == 1 && a:type =~ "i"
        if hasmapto(a:plug, "i")
            exec 'inoremap <buffer><silent> ' . a:plug . ' <Esc>' . tg . il
        elseif g:vimrplugin_user_maps_only == 0
            exec 'inoremap <buffer><silent> <LocalLeader>' . a:combo . ' <Esc>' . tg . il
        endif
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
    if g:vimrplugin_assign == 1 || g:vimrplugin_assign == 2
        silent exe 'inoremap <buffer><silent> ' . g:vimrplugin_assign_map . ' <Esc>:call ReplaceUnderS()<CR>a'
    endif
    if g:vimrplugin_args_in_stline
        inoremap <buffer><silent> ( <Esc>:call DisplayArgs()<CR>a
        inoremap <buffer><silent> ) <Esc>:call RestoreStatusLine()<CR>a
    endif
    if hasmapto("<Plug>RCompleteArgs", "i")
        inoremap <buffer><silent> <Plug>RCompleteArgs <C-R>=RCompleteArgs()<CR>
    else
        inoremap <buffer><silent> <C-X><C-A> <C-R>=RCompleteArgs()<CR>
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
    call RCreateMaps('v', '<Plug>RSendSelAndInsertOutput', 'so', ':call SendSelectionToR("echo", "stay", "NewtabInsert")')

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
    call RCreateMaps('ni0', '<Plug>RDSendLineAndInsertOutput', 'o', ':call SendLineToRAndInsertOutput()')
    call RCreateMaps('v', '<Plug>RDSendLineAndInsertOutput', 'o', ':call RWarningMsg("This command does not work over a selection of lines.")')
    call RCreateMaps('i', '<Plug>RSendLAndOpenNewOne', 'q', ':call SendLineToR("newline")')
    call RCreateMaps('n', '<Plug>RNLeftPart', 'r<left>', ':call RSendPartOfLine("left", 0)')
    call RCreateMaps('n', '<Plug>RNRightPart', 'r<right>', ':call RSendPartOfLine("right", 0)')
    call RCreateMaps('i', '<Plug>RILeftPart', 'r<left>', 'l:call RSendPartOfLine("left", 1)')
    call RCreateMaps('i', '<Plug>RIRightPart', 'r<right>', 'l:call RSendPartOfLine("right", 1)')

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
endfunction

function RVimLeave()
    call delete(g:rplugin_rsource)
    call delete(g:rplugin_tmpdir . "/start_options.R")
    call delete(g:rplugin_tmpdir . "/eval_reply")
    call delete(g:rplugin_tmpdir . "/formatted_code")
    call delete(g:rplugin_tmpdir . "/GlobalEnvList_" . $VIMINSTANCEID)
    call delete(g:rplugin_tmpdir . "/globenv_" . $VIMINSTANCEID)
    call delete(g:rplugin_tmpdir . "/liblist_" . $VIMINSTANCEID)
    call delete(g:rplugin_tmpdir . "/libnames_" . $VIMINSTANCEID)
    call delete(g:rplugin_tmpdir . "/objbrowserInit")
    call delete(g:rplugin_tmpdir . "/Rdoc")
    call delete(g:rplugin_tmpdir . "/Rinsert")
    call delete(g:rplugin_tmpdir . "/tmux.conf")
    call delete(g:rplugin_tmpdir . "/unformatted_code")
    call delete(g:rplugin_tmpdir . "/vimbol_finished")
    call delete(g:rplugin_tmpdir . "/vimcom_running_" . $VIMINSTANCEID)
    call delete(g:rplugin_tmpdir . "/rconsole_hwnd_" . $VIMR_SECRET)
    call delete(g:rplugin_tmpdir . "/openR'")
    if executable("rmdir")
        call system("rmdir '" . g:rplugin_tmpdir . "'")
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

function ROnJobStdout(job_id, msg)
    let cmd = substitute(a:msg, '\n', '', 'g')
    let cmd = substitute(a:msg, '\r', '', 'g')
    if cmd =~ "^call " || cmd =~ "^let "
        exe cmd
    else
        call RWarningMsg('[Job] Unknown command: "' . cmd . '"')
    endif
endfunction

function ROnJobStderr(job_id, msg)
    call RWarningMsg('[Job] ' . substitute(a:msg, '\n', ' ', 'g'))
endfunction

command -nargs=1 -complete=customlist,RLisObjs Rinsert :call RInsert(<q-args>)
command -range=% Rformat <line1>,<line2>:call RFormatCode()
command RBuildTags :call g:SendCmdToR('rtags(ofile = "TAGS")')
command -nargs=? -complete=customlist,RLisObjs Rhelp :call RAskHelp(<q-args>)
command -nargs=? -complete=dir RSourceDir :call RSourceDirectory(<q-args>)
command RStop :call StopR()


"==========================================================================
" Global variables
" Convention: vimrplugin_ for user options
"             rplugin_    for internal parameters
"==========================================================================

if !exists("g:rplugin_compldir")
    runtime r-plugin/setcompldir.vim
endif


if exists("g:vimrplugin_tmpdir")
    let g:rplugin_tmpdir = expand(g:vimrplugin_tmpdir)
else
    if has("win32") || has("win64")
        if isdirectory($TMP)
            let g:rplugin_tmpdir = $TMP . "/r-plugin-" . g:rplugin_userlogin
        elseif isdirectory($TEMP)
            let g:rplugin_tmpdir = $TEMP . "/r-plugin-" . g:rplugin_userlogin
        else
            let g:rplugin_tmpdir = g:rplugin_uservimfiles . "/r-plugin/tmp"
        endif
        let g:rplugin_tmpdir = substitute(g:rplugin_tmpdir, "\\", "/", "g")
    else
        if isdirectory($TMPDIR)
            if $TMPDIR =~ "/$"
                let g:rplugin_tmpdir = $TMPDIR . "r-plugin-" . g:rplugin_userlogin
            else
                let g:rplugin_tmpdir = $TMPDIR . "/r-plugin-" . g:rplugin_userlogin
            endif
        elseif isdirectory("/tmp")
            let g:rplugin_tmpdir = "/tmp/r-plugin-" . g:rplugin_userlogin
        else
            let g:rplugin_tmpdir = g:rplugin_uservimfiles . "/r-plugin/tmp"
        endif
    endif
endif

let $VIMRPLUGIN_TMPDIR = g:rplugin_tmpdir
if !isdirectory(g:rplugin_tmpdir)
    call mkdir(g:rplugin_tmpdir, "p", 0700)
endif

" Make the file name of files to be sourced
let g:rplugin_rsource = g:rplugin_tmpdir . "/Rsource-" . getpid()

let g:rplugin_is_darwin = system("uname") =~ "Darwin"

" Variables whose default value is fixed
call RSetDefaultValue("g:vimrplugin_map_r",             0)
call RSetDefaultValue("g:vimrplugin_allnames",          0)
call RSetDefaultValue("g:vimrplugin_rmhidden",          0)
call RSetDefaultValue("g:vimrplugin_assign",            1)
call RSetDefaultValue("g:vimrplugin_assign_map",    "'_'")
call RSetDefaultValue("g:vimrplugin_args_in_stline",    0)
call RSetDefaultValue("g:vimrplugin_rnowebchunk",       1)
call RSetDefaultValue("g:vimrplugin_strict_rst",        1)
call RSetDefaultValue("g:vimrplugin_openpdf",           2)
call RSetDefaultValue("g:vimrplugin_synctex",           1)
call RSetDefaultValue("g:vimrplugin_openhtml",          0)
call RSetDefaultValue("g:vimrplugin_vim_wd",            0)
call RSetDefaultValue("g:vimrplugin_source_args",    "''")
call RSetDefaultValue("g:vimrplugin_after_start",    "''")
call RSetDefaultValue("g:vimrplugin_vsplit",            0)
call RSetDefaultValue("g:vimrplugin_csv_warn",          1)
call RSetDefaultValue("g:vimrplugin_rconsole_width",   -1)
call RSetDefaultValue("g:vimrplugin_rconsole_height",  15)
call RSetDefaultValue("g:vimrplugin_tmux_title", "'VimR'")
call RSetDefaultValue("g:vimrplugin_listmethods",       0)
call RSetDefaultValue("g:vimrplugin_specialplot",       0)
call RSetDefaultValue("g:vimrplugin_notmuxconf",        0)
call RSetDefaultValue("g:vimrplugin_only_in_tmux",      0)
call RSetDefaultValue("g:vimrplugin_routnotab",         0)
call RSetDefaultValue("g:vimrplugin_editor_w",         66)
call RSetDefaultValue("g:vimrplugin_help_w",           46)
call RSetDefaultValue("g:vimrplugin_objbr_w",          40)
call RSetDefaultValue("g:vimrplugin_objbr_opendf",      1)
call RSetDefaultValue("g:vimrplugin_objbr_openlist",    0)
call RSetDefaultValue("g:vimrplugin_objbr_allnames",    0)
call RSetDefaultValue("g:vimrplugin_texerr",            1)
call RSetDefaultValue("g:vimrplugin_objbr_labelerr",    1)
call RSetDefaultValue("g:vimrplugin_i386",              0)
call RSetDefaultValue("g:vimrplugin_vimcom_wait",    5000)
call RSetDefaultValue("g:vimrplugin_show_args",         0)
call RSetDefaultValue("g:vimrplugin_never_unmake_menu", 0)
call RSetDefaultValue("g:vimrplugin_insert_mode_cmds",  1)
call RSetDefaultValue("g:vimrplugin_source",         "''")
call RSetDefaultValue("g:vimrplugin_vimpager",      "'tab'")
call RSetDefaultValue("g:vimrplugin_objbr_place",     "'script,right'")
call RSetDefaultValue("g:vimrplugin_user_maps_only", 0)
call RSetDefaultValue("g:vimrplugin_latexcmd", "'default'")
call RSetDefaultValue("g:vimrplugin_rmd_environment", "'.GlobalEnv'")
call RSetDefaultValue("g:vimrplugin_indent_commented",  1)

if !exists("g:r_indent_ess_comments")
    let g:r_indent_ess_comments = 0
endif
if g:r_indent_ess_comments
    if g:vimrplugin_indent_commented
        call RSetDefaultValue("g:vimrplugin_rcomment_string", "'## '")
    else
        call RSetDefaultValue("g:vimrplugin_rcomment_string", "'### '")
    endif
else
    call RSetDefaultValue("g:vimrplugin_rcomment_string", "'# '")
endif

if has("win32") || has("win64")
    call RSetDefaultValue("g:vimrplugin_Rterm",           0)
    call RSetDefaultValue("g:vimrplugin_save_win_pos",    1)
    call RSetDefaultValue("g:vimrplugin_arrange_windows", 1)
else
    let g:vimrplugin_Rterm = 0
    call RSetDefaultValue("g:vimrplugin_save_win_pos",    0)
    call RSetDefaultValue("g:vimrplugin_arrange_windows", 0)
endif

" The C code in VimCom/src/apps/vimr.c to send strings to RTerm is not working:
let g:vimrplugin_Rterm = 0

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


" ^K (\013) cleans from cursor to the right and ^U (\025) cleans from cursor
" to the left. However, ^U causes a beep if there is nothing to clean. The
" solution is to use ^A (\001) to move the cursor to the beginning of the line
" before sending ^K. But the control characters may cause problems in some
" circumstances.
call RSetDefaultValue("g:vimrplugin_ca_ck", 0)

" ========================================================================
" Set default mean of communication with R

if has('gui_running')
    let g:rplugin_do_tmux_split = 0
endif

if g:rplugin_is_darwin
    let g:rplugin_r64app = 0
    if isdirectory("/Applications/R64.app")
        call RSetDefaultValue("g:vimrplugin_applescript", 1)
        let g:rplugin_r64app = 1
    elseif isdirectory("/Applications/R.app")
        call RSetDefaultValue("g:vimrplugin_applescript", 1)
    else
        call RSetDefaultValue("g:vimrplugin_applescript", 0)
    endif
    if !exists("g:macvim_skim_app_path")
        let g:macvim_skim_app_path = '/Applications/Skim.app'
    endif
else
    let g:vimrplugin_applescript = 0
endif

if has("gui_running") || g:vimrplugin_applescript
    let vimrplugin_only_in_tmux = 0
endif

if $TMUX == ""
    let g:rplugin_do_tmux_split = 0
    let g:vimrplugin_tmux_ob = 0
    if g:vimrplugin_objbr_place =~ "console"
        let g:vimrplugin_objbr_place = substitute(g:vimrplugin_objbr_place, "console", "script", "")
    endif
else
    let g:rplugin_do_tmux_split = 1
    let g:vimrplugin_applescript = 0
    call RSetDefaultValue("g:vimrplugin_tmux_ob", 1)
endif

if has("gui_running") || has("win32") || g:vimrplugin_applescript
    let g:rplugin_do_tmux_split = 0
    let g:vimrplugin_tmux_ob = 0
    if g:vimrplugin_objbr_place =~ "console"
        let g:vimrplugin_objbr_place = substitute(g:vimrplugin_objbr_place, "console", "script", "")
    endif
endif

if g:vimrplugin_objbr_place =~ "console"
    let g:vimrplugin_tmux_ob = 1
endif


" ========================================================================

" Start with an empty list of objects in the workspace
let g:rplugin_globalenvlines = []

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

if filewritable('/dev/null')
    let g:rplugin_null = "'/dev/null'"
elseif has("win32") && filewritable('NUL')
    let g:rplugin_null = "'NUL'"
else
    let g:rplugin_null = 'tempfile()'
endif

autocmd BufEnter * call RBufEnter()
if &filetype != "rbrowser"
    autocmd VimLeave * call RVimLeave()
endif

let g:rplugin_firstbuffer = expand("%:p")
let g:rplugin_running_objbr = 0
let g:rplugin_running_rhelp = 0
let g:rplugin_newliblist = 0
let g:rplugin_status_line = &statusline
let g:rplugin_r_pid = 0
let g:rplugin_myport = 0
let g:rplugin_vimcomport = 0
let g:rplugin_vimcom_home = ""
let g:rplugin_vimcom_version = 0
let g:rplugin_lastev = ""
let g:rplugin_last_r_prompt = ""
let g:rplugin_hasRSFbutton = 0
let g:rplugin_tmuxsname = "VimR-" . substitute(localtime(), '.*\(...\)', '\1', '')
let g:rplugin_starting_R = 0

" SyncTeX options
let g:rplugin_has_wmctrl = 0
let g:rplugin_synctexpid = 0
let g:rplugin_zathura_pid = {}

let g:rplugin_py_exec = "none"
if executable("python3")
    let g:rplugin_py_exec = "python3"
elseif executable("python")
    let g:rplugin_py_exec = "python"
endif

function GetRandomNumber(width)
    if g:rplugin_py_exec != "none"
        let pycode = ["import os, sys, base64",
                    \ "sys.stdout.write(base64.b64encode(os.urandom(" . a:width . ")).decode())" ]
        call writefile(pycode, g:rplugin_tmpdir . "/getRandomNumber.py")
        let randnum = system(g:rplugin_py_exec . ' "' . g:rplugin_tmpdir . '/getRandomNumber.py"')
        call delete(g:rplugin_tmpdir . "/getRandomNumber.py")
    elseif !has("win32") && !has("win64") && !has("gui_win32") && !has("gui_win64")
        let randnum = system("echo $RANDOM")
    else
        let randnum = localtime()
    endif
    return substitute(randnum, '\W', '', 'g')
endfunction

" If this is the Object Browser running in a Tmux pane, $VIMINSTANCEID is
" already defined and shouldn't be changed
if &filetype == "rbrowser"
    if $VIMINSTANCEID == ""
        call RWarningMsgInp("VIMINSTANCEID is undefined")
    endif
else
    let $VIMR_SECRET = GetRandomNumber(16)
    let $VIMINSTANCEID = substitute(g:rplugin_firstbuffer . GetRandomNumber(16), '\W', '', 'g')
    if strlen($VIMINSTANCEID) > 64
        let $VIMINSTANCEID = substitute($VIMINSTANCEID, '.*\(...............................................................\)', '\1', '')
    endif
endif

let g:rplugin_docfile = g:rplugin_tmpdir . "/Rdoc"

" Create an empty file to avoid errors if the user do Ctrl-X Ctrl-O before
" starting R:
if &filetype != "rbrowser"
    call writefile([], g:rplugin_tmpdir . "/GlobalEnvList_" . $VIMINSTANCEID)
endif

" Set the value of R path
if exists("g:vimrplugin_r_path")
    let g:rplugin_R = expand(g:vimrplugin_r_path)
    if isdirectory(g:rplugin_R)
        let g:rplugin_R = g:rplugin_R . "/R"
    endif
elseif has("win32") || has("win64")
    if g:vimrplugin_Rterm
        let g:rplugin_R = "Rgui.exe"
    else
        let g:rplugin_R = "Rterm.exe"
    endif
else
    let g:rplugin_R = "R"
endif

if has("win32")
    runtime r-plugin/windows.vim
    let g:rplugin_has_icons = len(globpath(&rtp, "bitmaps/RStart.bmp")) > 0
else
    let g:rplugin_has_icons = len(globpath(&rtp, "bitmaps/RStart.png")) > 0
endif

if g:vimrplugin_applescript
    runtime r-plugin/osx.vim
endif

if !has("win32") && !g:vimrplugin_applescript
    runtime r-plugin/tmux.vim
endif

if has("gui_running")
    runtime r-plugin/gui_running.vim
endif

if !executable(g:rplugin_R)
    call RWarningMsgInp("R executable not found: '" . g:rplugin_R . "'")
endif
