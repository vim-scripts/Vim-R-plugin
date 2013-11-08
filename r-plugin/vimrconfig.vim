
function! RFindString(lll, sss)
    for line in a:lll
        if line =~ a:sss
            return 1
        endif
    endfor
    return 0
endfunction

" Configure .Rprofile
function! RConfigRprofile()
    call delete($VIMRPLUGIN_TMPDIR . "/configR_result")
    let rcmd = 'source("' . g:rplugin_uservimfiles . '/r-plugin/Rconfig.R")'
    call g:SendCmdToR(rcmd)
    sleep 1
    if filereadable($VIMRPLUGIN_TMPDIR . "/configR_result")
        let res = readfile($VIMRPLUGIN_TMPDIR . "/configR_result")
        if res[1] == "vimcom_found"
            call RWarningMsg('The string "vimcom" was found in your .Rprofile. No change was done.')
        elseif res[1] == "new_Rprofile"
            call RWarningMsg('Your new .Rprofile was created.')
        endif
        if has("win32") || has("win64")
            echohl Question
            let what = input("Do you want to see your .Rprofile now? [y/N]: ")
            echohl Normal
            if what =~ "^[yY]"
                silent exe "tabnew " . res[0]
            endif
        else
            echohl Question
            let what = input("Do you want to see your .Rprofile along with tips on how to\nconfigure it? [y/N]: ")
            echohl Normal
            if what =~ "^[yY]"
                silent exe "tabnew " . res[0]
                silent help r-plugin-quick-R-setup
            endif
        endif
        redraw
    else
        redraw
        call RWarningMsg("Error: configR_result not found.")
        sleep 1
        return 1
    endif
    return 0
endfunction

" Configure vimrc
function! RConfigVimrc()
    if has("win32") || has("win64")
        if filereadable($HOME . "/_vimrc")
            let uvimrc = $HOME . "/_vimrc"
        elseif filereadable($HOME . "/vimfiles/vimrc")
            let uvimrc = $HOME . "/vimfiles/vimrc"
        else
            let uvimrc = $HOME . "/_vimrc"
        endif
    else
        if filereadable($HOME . "/.vimrc")
            let uvimrc = $HOME . "/.vimrc"
        elseif filereadable($HOME . "/.vim/vimrc")
            let uvimrc = $HOME . "/.vim/vimrc"
        else
            let uvimrc = $HOME . "/.vimrc"
        endif
    endif

    if filereadable(uvimrc)
        let hasvimrc = 1
        echohl WarningMsg
        echo "You already have a vimrc."
        echohl Normal
        echohl Question
        let what = input("Do you want to add to the bottom of your vimrc some options that\nmost users consider convenient for the Vim-R-plugin? [y/N]: ")
        echohl Normal
        if what =~ "^[yY]"
            let vlines = readfile(uvimrc)
        else
            redraw
            return
        endif
    else
        let hasvimrc = 0
        echohl Question
        let what = input("It seems that you don't have a vimrc yet. Should I create it now? [y/N]: ")
        echohl Normal
        if what =~ "^[yY]"
            let vlines = []
        else
            redraw
            return
        endif
    endif

    let vlines = vlines + ['']
    if exists("*strftime")
        let vlines = vlines + ['" Lines added by the Vim-R-plugin command :RpluginConfig (' . strftime("%Y-%b-%d %H:%M") . '):']
    else
        let vlines = vlines + ['" Lines added by the Vim-R-plugin command :RpluginConfig:']
    endif

    if RFindString(vlines, 'set\s*nocompatible') == 0 && RFindString(vlines, 'set\s*nocp') == 0
        let vlines = vlines + ['set nocompatible']
    endif
    if RFindString(vlines, 'syntax\s*on') == 0
        let vlines = vlines + ['syntax on']
    endif
    if RFindString(vlines, 'filet.* plugin on') == 0
        let vlines = vlines + ['filetype plugin on']
    endif
    if RFindString(vlines, 'filet.* indent on') == 0
        let vlines = vlines + ['filetype indent on']
    endif

    echo " "
    if RFindString(vlines, "maplocalleader") == 0
        if hasvimrc
            echohl WarningMsg
            echo "It seems that you didn't map your <LocalLeader> to another key."
            echohl Normal
        endif
        echo "By default, Vim's LocalLeader is the backslash (\\) which is problematic"
        echo "if we are editing LaTeX or Rnoweb (R+LaTeX) files."
        echohl Question
        let what = input("Do you want to change the LocalLeader to a comma (,)? [y/N]: ")
        echohl Normal
        if what =~ "^[yY]"
            let vlines = vlines + ['" Change the <LocalLeader> key:',
                        \ 'let maplocalleader = ","']
        endif
    endif

    echo " "
    if RFindString(vlines, "<C-x><C-o>") == 0 && RFindString(vlines, "<C-X><C-O>") == 0 && RFindString(vlines, "<c-x><c-o>") == 0
        if hasvimrc
            echohl WarningMsg
            echo "It seems that you didn't create an easier map for omnicompletion yet."
            echohl Normal
        endif
        echo "By default, you have to press Ctrl+X Ctrl+O to complete the names of"
        echo "functions and other objects. This is called omnicompletion."
        echohl Question
        let what = input("Do you want to press Ctrl+Space to do omnicompletion?  [y/N]: ")
        echohl Normal
        if what =~ "^[yY]"
            let vlines = vlines + ['" Use Ctrl+Space to do omnicompletion:',
                        \ 'if has("gui_running")',
                        \ '    inoremap <C-Space> <C-x><C-o>',
                        \ 'else',
                        \ '    inoremap <Nul> <C-x><C-o>',
                        \ 'endif']
        endif
    endif

    echo " "
    if RFindString(vlines, "RDSendLine") == 0 || RFindString(vlines, "RDSendSelection") == 0
        if hasvimrc
            echohl WarningMsg
            echo "It seems that you didn't create an easier map to"
            echo "either send lines or send selected lines."
            echohl Normal
        endif
        echo "By default, you have to press \\d to send one line of code to R"
        echo "and \\ss to send a selection of lines."
        echohl Question
        let what = input("Do you prefer to press the space bar to send lines and selections\nto R Console? [y/N]: ")
        echohl Normal
        if what =~ "^[yY]"
            let vlines = vlines + ['" Press the space bar to send lines (in Normal mode) and selections to R:',
                        \ 'vmap <Space> <Plug>RDSendSelection',
                        \ 'nmap <Space> <Plug>RDSendLine']
        endif
    endif
    call writefile(vlines, uvimrc)

    echo " "
    echohl Question
    let what = input("Do you want to see your vimrc now? [y/N]: ")
    echohl Normal
    if what =~ "^[yY]"
        silent exe "tabnew " . uvimrc
        normal! G
    endif
    redraw
    echohl WarningMsg
    echo "The changes in your vimrc will be effective"
    echo "only after you quit Vim and start it again."
    echohl Normal
endfunction

" Configure .bashrc
function! RConfigBash()
    echo " "
    if filereadable($HOME . "/.bashrc")
        let blines = readfile($HOME . "/.bashrc")
        let hastvim = 0
        for line in blines
            if line =~ "tvim"
                let hastvim = 1
                break
            endif
        endfor

        if hastvim
            echohl WarningMsg
            echo "Nothing was added to your ~/.bashrc because the string 'tvim' was found in it."
            echohl Question
            let what = input("Do you want to see your ~/.bashrc along with the plugin\ntips on how to configure Bash? [y/N]: ")
            echohl Normal
            if what =~ "^[yY]"
                silent exe "tabnew " . $HOME . "/.bashrc"
                silent help r-plugin-quick-bash-setup
            endif
        else
            echo "Vim and Tmux can display up to 256 colors in the terminal emulator,"
            echo "but we have to configure the TERM environment variable for that."
            echo "Instead of starting Tmux and then starting Vim, we can configure"
            echo "Bash to start both at once with the 'tvim' command."
            echo "The serverclient feature must be enabled for automatic update of the"
            echo "Object Browser and syntax highlight of function names."
            echohl Question
            let what = input("Do you want that all these features are added to your .bashrc? [y/N]: ")
            echohl Normal
            if what =~ "^[yY]"
                let blines = blines + ['']
                if exists("*strftime")
                    let blines = blines + ['# Lines added by the Vim-R-plugin command :RpluginConfig (' . strftime("%Y-%b-%d %H:%M") . '):']
                else
                    let blines = blines + ['# Lines added by the Vim-R-plugin command :RpluginConfig:']
                endif
                let blines = blines + ['# Change the TERM environment variable (to get 256 colors) and make Vim',
                            \ '# connecting to X Server even if running in a terminal emulator (to get',
                            \ '# dynamic update of syntax highlight and Object Browser):',
                            \ 'if [ "x$DISPLAY" != "x" ]',
                            \ 'then',
                            \ '    if [ "screen" = "$TERM" ]',
                            \ '    then',
                            \ '        export TERM=screen-256color',
                            \ '    else',
                            \ '        export TERM=xterm-256color',
                            \ '    fi',
                            \ '    alias vim="vim --servername VIM"',
                            \ '    if [ "x$TERM" == "xxterm" ] || [ "x$TERM" == "xxterm-256color" ]',
                            \ '    then',
                            \ '        function tvim(){ tmux -2 new-session "TERM=screen-256color vim --servername VIM $@" ; }',
                            \ '    else',
                            \ '        function tvim(){ tmux new-session "vim --servername VIM $@" ; }',
                            \ '    fi',
                            \ 'else',
                            \ '    if [ "x$TERM" == "xxterm" ] || [ "x$TERM" == "xxterm-256color" ]',
                            \ '    then',
                            \ '        function tvim(){ tmux -2 new-session "TERM=screen-256color vim $@" ; }',
                            \ '    else',
                            \ '        function tvim(){ tmux new-session "vim $@" ; }',
                            \ '    fi',
                            \ 'fi' ]
                call writefile(blines, $HOME . "/.bashrc")
                echohl Question
                let what = input("Do you want to see your .bashrc now? [y/N]: ")
                echohl Normal
                if what =~ "^[yY]"
                    silent exe "tabnew " . $HOME . "/.bashrc"
                    normal! G27k
                endif
            endif
        endif
        redraw
    endif
endfunction

function! RConfigTmux()
    echo " "
    if filereadable($HOME . "/.tmux.conf")
        echohl WarningMsg
        echo "You already have a .tmux.conf."
        echohl Question
        let what = input("Do you want to see it along with the plugin tips on how to\nconfigure Tmux? [y/N]: ")
        echohl Normal
        if what =~ "^[yY]"
            silent exe "tabnew " . $HOME . "/.tmux.conf"
            silent help r-plugin-quick-tmux-setup
        endif
        redraw
    else
        echohl Question
        let what = input("You don't have a ~/.tmux.conf yet. Should I create it now? [y/N]: ")
        echohl Normal
        if what =~ "^[yY]"
            let tlines = ['']
            if exists("*strftime")
                let tlines = tlines + ['# Lines added by the Vim-R-plugin command :RpluginConfig (' . strftime("%Y-%b-%d %H:%M") . '):']
            else
                let tlines = tlines + ['# Lines added by the Vim-R-plugin command :RpluginConfig:']
            endif
            let tlines = tlines + ["set-option -g prefix C-a",
                        \ "unbind-key C-b",
                        \ "bind-key C-a send-prefix",
                        \ "set -g status off",
                        \ "set-window-option -g mode-keys vi",
                        \ "set -g terminal-overrides 'xterm*:smcup@:rmcup@'",
                        \ "set -g mode-mouse on",
                        \ "set -g mouse-select-pane on",
                        \ "set -g mouse-resize-pane on"]
            call writefile(tlines, $HOME . "/.tmux.conf")
            echo " "
            echohl Question
            let what = input("Do you want to see your .tmux.conf now? [y/N]: ")
            echohl Normal
            if what =~ "^[yY]"
                silent exe "tabnew " . $HOME . "/.tmux.conf"
            endif
            redraw
        endif
    endif
endfunction

function! RConfigVimR()
    if string(g:SendCmdToR) == "function('SendCmdToR_fake')"
        call StartR("R")
        echohl WarningMsg
        echo "Please wait..."
        echohl Normal
        sleep 2
    endif
    if RConfigRprofile()
        return
    endif
    call RConfigVimrc()
    if has("win32") || has("win64")
        return
    endif
    call RConfigTmux()
    call RConfigBash()
endfunction

call RConfigVimR()

