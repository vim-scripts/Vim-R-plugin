
function StartR_ExternalTerm(rcmd)
    if $DISPLAY == "" && !g:rplugin_is_darwin
        call RWarningMsg("Start 'tmux' before Vim. The X Window system is required to run R in an external terminal.")
        return
    endif

    if g:vimrplugin_notmuxconf
        let tmuxcnf = ' '
    else
        " Create a custom tmux.conf
        let cnflines = ['set-option -g prefix C-a',
                    \ 'unbind-key C-b',
                    \ 'bind-key C-a send-prefix',
                    \ 'set-window-option -g mode-keys vi',
                    \ 'set -g status off',
                    \ 'set -g default-terminal "screen-256color"',
                    \ "set -g terminal-overrides 'xterm*:smcup@:rmcup@'" ]

        if g:vimrplugin_term == "rxvt" || g:vimrplugin_term == "urxvt"
            let cnflines = cnflines + [
                        \ "set terminal-overrides 'rxvt*:smcup@:rmcup@'" ]
        endif

        if g:vimrplugin_tmux_ob || !has("gui_running")
            if g:rplugin_tmux_version < "2.1"
                call extend(cnflines, ['set -g mode-mouse on', 'set -g mouse-select-pane on', 'set -g mouse-resize-pane on'])
            else
                call extend(cnflines, ['set -g mouse on'])
            endif
        endif
        call writefile(cnflines, g:rplugin_tmpdir . "/tmux.conf")
        let tmuxcnf = '-f "' . g:rplugin_tmpdir . "/tmux.conf" . '"'
    endif

    let rcmd = 'VIMRPLUGIN_TMPDIR=' . substitute(g:rplugin_tmpdir, ' ', '\\ ', 'g') . ' VIMR_COMPLDIR=' . substitute(g:rplugin_compldir, ' ', '\\ ', 'g') . ' VIMINSTANCEID=' . $VIMINSTANCEID . ' VIMR_SECRET=' . $VIMR_SECRET . ' VIMEDITOR_SVRNM=' . $VIMEDITOR_SVRNM . ' ' . a:rcmd

    call system("tmux -L vimr has-session -t " . g:rplugin_tmuxsname)
    if v:shell_error
        if g:rplugin_is_darwin
            let opencmd = printf("tmux -L vimr -2 %s new-session -s %s 'TERM=screen-256color %s'", tmuxcnf, g:rplugin_tmuxsname, rcmd)
            call writefile(["#!/bin/sh", opencmd], $VIMRPLUGIN_TMPDIR . "/openR")
            call system("chmod +x '" . $VIMRPLUGIN_TMPDIR . "/openR'")
            let opencmd = "open '" . $VIMRPLUGIN_TMPDIR . "/openR'"
        else
            if g:rplugin_termcmd =~ "gnome-terminal" || g:rplugin_termcmd =~ "xfce4-terminal" || g:rplugin_termcmd =~ "terminal" || g:rplugin_termcmd =~ "iterm"
                let opencmd = printf("%s 'tmux -L vimr -2 %s new-session -s %s \"%s\"' &", g:rplugin_termcmd, tmuxcnf, g:rplugin_tmuxsname, rcmd)
            else
                let opencmd = printf("%s tmux -L vimr -2 %s new-session -s %s \"%s\" &", g:rplugin_termcmd, tmuxcnf, g:rplugin_tmuxsname, rcmd)
            endif
        endif
    else
        if g:rplugin_is_darwin
            call RWarningMsg("Tmux session with R is already running")
            return
        endif
        if g:rplugin_termcmd =~ "gnome-terminal" || g:rplugin_termcmd =~ "xfce4-terminal" || g:rplugin_termcmd =~ "terminal" || g:rplugin_termcmd =~ "iterm"
            let opencmd = printf("%s 'tmux -L vimr -2 %s attach-session -d -t %s' &", g:rplugin_termcmd, tmuxcnf, g:rplugin_tmuxsname)
        else
            let opencmd = printf("%s tmux -L vimr -2 %s attach-session -d -t %s &", g:rplugin_termcmd, tmuxcnf, g:rplugin_tmuxsname)
        endif
    endif

    let rlog = system(opencmd)
    if v:shell_error
        call RWarningMsg(rlog)
        return
    endif
    let g:SendCmdToR = function('SendCmdToR_Term')
    if WaitVimComStart()
        if g:vimrplugin_after_start != ''
            call system(g:vimrplugin_after_start)
        endif
    endif
endfunction

function SendCmdToR_Term(cmd)
    if g:vimrplugin_ca_ck
        let cmd = "\001" . "\013" . a:cmd
    else
        let cmd = a:cmd
    endif

    " Send the command to R running in an external terminal emulator
    let str = substitute(cmd, "'", "'\\\\''", "g")
    if str =~ '^-'
        let str = ' ' . str
    endif
    let scmd = "tmux -L vimr set-buffer '" . str . "\<C-M>' && tmux -L vimr paste-buffer -t " . g:rplugin_tmuxsname . '.0'
    let rlog = system(scmd)
    if v:shell_error
        let rlog = substitute(rlog, '\n', ' ', 'g')
        let rlog = substitute(rlog, '\r', ' ', 'g')
        call RWarningMsg(rlog)
        call ClearRInfo()
        return 0
    endif
    return 1
endfunction

if g:rplugin_is_darwin
    finish
endif

" Choose a terminal (code adapted from screen.vim)
if exists("g:vimrplugin_term")
    if !executable(g:vimrplugin_term)
        call RWarningMsgInp("'" . g:vimrplugin_term . "' not found. Please change the value of 'vimrplugin_term' in your vimrc.")
        let g:vimrplugin_term = "xterm"
    endif
endif
if has("win32") || has("win64") || g:rplugin_is_darwin || g:rplugin_do_tmux_split
    " No external terminal emulator will be called, so any value is good
    let g:vimrplugin_term = "xterm"
endif
if !exists("g:vimrplugin_term")
    let s:terminals = ['gnome-terminal', 'konsole', 'xfce4-terminal', 'terminal', 'Eterm',
                \ 'rxvt', 'urxvt', 'aterm', 'roxterm', 'terminator', 'lxterminal', 'xterm']
    for s:term in s:terminals
        if executable(s:term)
            let g:vimrplugin_term = s:term
            break
        endif
    endfor
    unlet s:term
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
    if g:vimrplugin_vim_wd
        let g:rplugin_termcmd = g:vimrplugin_term . " -e"
    else
        let g:rplugin_termcmd = g:vimrplugin_term . " --working-directory='" . expand("%:p:h") . "' -e"
    endif
endif

if g:vimrplugin_term == "terminator"
    if g:vimrplugin_vim_wd
        let g:rplugin_termcmd = "terminator --title R -x"
    else
        let g:rplugin_termcmd = "terminator --working-directory='" . expand("%:p:h") . "' --title R -x"
    endif
endif

if g:vimrplugin_term == "konsole"
    if g:vimrplugin_vim_wd
        let g:rplugin_termcmd = "konsole --icon " . g:rplugin_home . "/bitmaps/ricon.png -e"
    else
        let g:rplugin_termcmd = "konsole --workdir '" . expand("%:p:h") . "' --icon " . g:rplugin_home . "/bitmaps/ricon.png -e"
    endif
endif

if g:vimrplugin_term == "Eterm"
    let g:rplugin_termcmd = "Eterm --icon " . g:rplugin_home . "/bitmaps/ricon.png -e"
endif

if g:vimrplugin_term == "roxterm"
    " Cannot set icon: http://bugzilla.gnome.org/show_bug.cgi?id=126081
    if g:vimrplugin_vim_wd
        let g:rplugin_termcmd = "roxterm --title R -e"
    else
        let g:rplugin_termcmd = "roxterm --directory='" . expand("%:p:h") . "' --title R -e"
    endif
endif

if g:vimrplugin_term == "xterm" || g:vimrplugin_term == "uxterm"
    let g:rplugin_termcmd = g:vimrplugin_term . " -e"
endif

if g:vimrplugin_term == "rxvt" || g:vimrplugin_term == "urxvt"
    let g:rplugin_termcmd = g:vimrplugin_term . " -cd '" . expand("%:p:h") . "' -title R -xrm '*iconPixmap: " . g:rplugin_home . "/bitmaps/ricon.xbm' -e"
endif

" Override default settings:
if exists("g:vimrplugin_term_cmd")
    let g:rplugin_termcmd = g:vimrplugin_term_cmd
endif
