
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
    let tmuxconf = ['set-environment VIMRPLUGIN_TMPDIR "' . g:rplugin_tmpdir . '"',
                \ 'set-environment VIMR_COMPLDIR "' . substitute(g:rplugin_compldir, ' ', '\\ ', "g") . '"',
                \ 'set-environment VIMEDITOR_SVRNM ' . $VIMEDITOR_SVRNM ,
                \ 'set-environment VIMINSTANCEID ' . $VIMINSTANCEID ,
                \ 'set-environment VIMR_SECRET ' . $VIMR_SECRET ]
    if &t_Co == 256
        call extend(tmuxconf, ['set default-terminal "' . $TERM . '"'])
    endif
    call writefile(tmuxconf, g:rplugin_tmpdir . "/tmux" . $VIMINSTANCEID . ".conf")
    call system("tmux source-file '" . g:rplugin_tmpdir . "/tmux" . $VIMINSTANCEID . ".conf" . "'")
    call delete(g:rplugin_tmpdir . "/tmux" . $VIMINSTANCEID . ".conf")
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

    " Let Tmux automatically kill the panel when R quits.
    let tcmd .= " '" . a:rcmd . "'"

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
    let g:rplugin_last_rcmd = a:rcmd
    if g:vimrplugin_tmux_title != "automatic" && g:vimrplugin_tmux_title != ""
        call system("tmux rename-window " . g:vimrplugin_tmux_title)
    endif
    if WaitVimComStart()
        if g:vimrplugin_after_start != ''
            call system(g:vimrplugin_after_start)
        endif
    endif
endfunction

function StartObjBrowser_Tmux()
    if b:rplugin_extern_ob
        " This is the Object Browser
        echoerr "StartObjBrowser_Tmux() called."
        return
    endif


    " Don't start the Object Browser if it already exists
    if IsExternalOBRunning()
        return
    endif

    let objbrowserfile = g:rplugin_tmpdir . "/objbrowserInit"
    let tmxs = " "

    call writefile([
                \ 'let g:rplugin_vim_pane = "' . g:rplugin_vim_pane . '"',
                \ 'let g:rplugin_rconsole_pane = "' . g:rplugin_rconsole_pane . '"',
                \ 'let $VIMINSTANCEID = "' . $VIMINSTANCEID . '"',
                \ 'let $VIMCOMPORT = "' . g:rplugin_vimcomport . '"',
                \ 'let showmarks_enable = 0',
                \ 'let g:rplugin_tmuxsname = "' . g:rplugin_tmuxsname . '"',
                \ 'let b:rscript_buffer = "' . bufname("%") . '"',
                \ 'set filetype=rbrowser',
                \ 'let g:rplugin_vimcom_home = "' . g:rplugin_vimcom_home . '"',
                \ 'let g:rplugin_vclntsrvr = "' . g:rplugin_vclntsrvr . '"',
                \ 'let b:objbrtitle = "' . b:objbrtitle . '"',
                \ 'let b:rplugin_extern_ob = 1',
                \ 'set shortmess=atI',
                \ 'set rulerformat=%3(%l%)',
                \ 'set laststatus=0',
                \ 'set noruler',
                \ 'set updatetime=100',
                \ 'let g:SendCmdToR = function("SendCmdToR_TmuxSplit")',
                \ 'let g:rplugin_vimcomport = ' . g:rplugin_vimcomport,
                \ 'let vcs_job = job_start([g:rplugin_vclntsrvr], {"out-cb": "ROnJobStdout", "err-cb": "ROnJobStderr"})',
                \ 'let g:rplugin_channel = job_getchannel(vcs_job)',
                \ 'sleep 150m'],
                \ objbrowserfile)

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

    if g:rplugin_is_darwin && has("gui_macvim")
        let vimexec = substitute($VIMRUNTIME, "/MacVim.app/Contents/.*", "", "") . "/MacVim.app/Contents/MacOS/Vim"
        let vimexec = substitute(vimexec, ' ', '\\ ', 'g')
    else
        let vimexec = "vim"
    endif

    let cmd = "tmux split-window -h -l " . panewidth . " -t " . obpane . ' "' . vimexec . " -c 'source " . substitute(objbrowserfile, ' ', '\\ ', 'g') . "'" . '"'
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
    if str =~ '^-'
        let str = ' ' . str
    endif
    let scmd = "tmux set-buffer '" . str . "\<C-M>' && tmux paste-buffer -t " . g:rplugin_rconsole_pane
    let rlog = system(scmd)
    if v:shell_error
        let rlog = substitute(rlog, "\n", " ", "g")
        let rlog = substitute(rlog, "\r", " ", "g")
        call RWarningMsg(rlog)
        call ClearRInfo()
        return 0
    endif
    return 1
endfunction

function CloseExternalOB()
    if IsExternalOBRunning()
        call system("tmux kill-pane -t " . g:rplugin_ob_pane)
        unlet g:rplugin_ob_pane
        sleep 250m
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
