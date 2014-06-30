function! RFindString(lll, sss)
    for line in a:lll
        if line =~ a:sss
            return 1
        endif
    endfor
    return 0
endfunction

function! RGetYesOrNo(ans)
    if a:ans =~ "^[yY]"
        return 1
    elseif a:ans =~ "^[nN]" || a:ans == ""
        return 0
    else
        echohl WarningMsg
        let newans = input('Please, type "y", "n" or <Enter>: ')
        echohl Normal
        return RGetYesOrNo(newans)
    endif
endfunction

" Configure .Rprofile
function! RConfigRprofile()
    call delete($VIMRPLUGIN_TMPDIR . "/configR_result")
    let configR = ['if(.Platform$OS.type == "windows"){',
                \ '    .rpf <- Sys.getenv("R_PROFILE_USER")',
                \ '    if(.rpf == ""){',
                \ '        if(Sys.getenv("R_USER") == "")',
                \ '            stop("R_USER environment variable not set.")',
                \ '        .rpf <- paste0(Sys.getenv("R_USER"), "\\.Rprofile")',
                \ '    }',
                \ '} else {',
                \ '    if(Sys.getenv("HOME") == ""){',
                \ '        stop("HOME environment variable not set.")',
                \ '    } else {',
                \ '        .rpf <- paste0(Sys.getenv("HOME"), "/.Rprofile")',
                \ '        if(length(find.package("colorout", quiet = TRUE)) > 0)',
                \ '            .rpf <- c(.rpf, "HasColorout")',
                \ '        else',
                \ '            .rpf <- c(.rpf, "NoColorout")',
                \ '        if(length(find.package("setwidth", quiet = TRUE)) > 0)',
                \ '            .rpf <- c(.rpf, "HasSetwidth")',
                \ '        else',
                \ '            .rpf <- c(.rpf, "NoSetwidth")',
                \ '    }',
                \ '}',
                \ 'writeLines(.rpf, con = paste0(Sys.getenv("VIMRPLUGIN_TMPDIR"), "/configR_result"))',
                \ 'rm(.rpf)']
    call RSourceLines(configR, "silent")
    sleep 1
    if !filereadable($VIMRPLUGIN_TMPDIR . "/configR_result")
        sleep 2
    endif
    if filereadable($VIMRPLUGIN_TMPDIR . "/configR_result")
        let resp = readfile($VIMRPLUGIN_TMPDIR . "/configR_result")
        call delete($VIMRPLUGIN_TMPDIR . "/configR_result")
        if filereadable(resp[0])
            let rpflines = readfile(resp[0])
        else
            let rpflines = []
        endif

        let hasvimcom = 0
        for line in rpflines
            if line =~ "library.*vimcom" || line =~ "require.*vimcom"
                let hasvimcom = 1
                break
            endif
        endfor
        if hasvimcom
            echohl WarningMsg
            echo 'The string "vimcom" was found in your .Rprofile. No change was done.'
            echohl Normal
        else
            let rpflines += ['']
            if exists("*strftime")
                let rpflines += ['# Lines added by the Vim-R-plugin command :RpluginConfig (' . strftime("%Y-%b-%d %H:%M") . '):']
            else
                let rpflines += ['# Lines added by the Vim-R-plugin command :RpluginConfig:']
            endif
            let rpflines += ['if(interactive()){']
            if has("win32") || has("win64")
                let rpflines += ["    options(editor = '" . '"C:/Program Files (x86)/Vim/vim74/gvim.exe" "-c" "set filetype=r"' . "')"]
            else
                let rpflines += ['    if(nchar(Sys.getenv("DISPLAY")) > 1)',
                            \ "        options(editor = '" . 'gvim -f -c "set ft=r"' . "')",
                            \ '    else',
                            \ "        options(editor = '" . s:vimprog . ' -c "set ft=r"' . "')",
                            \ '    # See ?setOutputColors256 to know how to customize R output colors']
                if len(resp) > 1 && resp[1] == "HasColorout"
                    let rpflines += ['    library(colorout)']
                else
                    let rpflines += ['    # library(colorout)']
                endif
                if len(resp) > 2 && resp[2] == "HasSetwidth"
                    let rpflines += ['    library(setwidth)']
                else
                    let rpflines += ['    # library(setwidth)']
                endif
            endif
            if has("win32") || has("win64")
                let rpflines += ['    if(Sys.getenv("VIMRPLUGIN_TMPDIR") != "")',
                            \ '        library(vimcom)']
            else
                let rpflines += ['    library(vimcom)']
            endif

            if !(has("win32") || has("win64"))
                redraw
                echo " "
                echo "By defalt, R uses the 'less' application to show help documents."
                echohl Question
                let what = input("Dou you prefer to see help documents in Vim? [y/N]: ")
                echohl Normal
                if RGetYesOrNo(what)
                    let rpflines += ['    # See R documentation on Vim buffer even if asking for help in R Console:']
                    if ($PATH =~ "\\~/bin" || $PATH =~ expand("~/bin")) && filewritable(expand("~/bin")) == 2 && !filereadable(expand("~/bin/vimrpager"))
                        call writefile(['#!/bin/sh',
                                    \ 'cat | ' . s:vimprog . ' -c "set ft=rdoc" -'], expand("~/bin/vimrpager"))
                        call system("chmod +x " . expand("~/bin/vimrpager"))
                        let rpflines += ['    options(help_type = "text", pager = "' . expand("~/bin/vimrpager") . '")']
                    endif
                    let rpflines += ['    if(Sys.getenv("VIM_PANE") != "")',
                                \ '        options(pager = vim.pager)']
                endif

                if executable("w3m") && ($PATH =~ "\\~/bin" || $PATH =~ expand("~/bin")) && filewritable(expand("~/bin")) == 2 && !filereadable(expand("~/bin/vimrw3mbrowser"))
                    redraw
                    echo " "
                    echo "The w3m application, a text based web browser, is installed in your system."
                    echo "When R is running inside of a Tmux session, it can be configured to"
                    echo "start its help system in w3m running in a Tmux pane."
                    echohl Question
                    let what = input("Do you want to use w3m instead of your default web browser? [y/N]: ")
                    if RGetYesOrNo(what)
                        call writefile(['#!/bin/sh',
                                    \ 'NCOLS=$(tput cols)',
                                    \ 'if [ "$NCOLS" -gt "140" ]',
                                    \ 'then',
                                    \ '    if [ "x$VIM_PANE" = "x" ]',
                                    \ '    then',
                                    \ '        tmux split-window -h "w3m $1 && exit"',
                                    \ '    else',
                                    \ '        tmux split-window -h -t $VIM_PANE "w3m $1 && exit"',
                                    \ '    fi',
                                    \ 'else',
                                    \ '    tmux new-window "w3m $1 && exit"',
                                    \ 'fi'], expand("~/bin/vimrw3mbrowser"))
                        call system("chmod +x " . expand("~/bin/vimrw3mbrowser"))
                        let rpflines += ['    # Use the text based web browser w3m to navigate through R docs:',
                                    \ '    # Replace VIM_PANE with TMUX if you know what you are doing.',
                                    \ '    if(Sys.getenv("VIM_PANE") != "")',
                                    \ '        options(browser="' . expand("~/bin/vimrw3mbrowser") . '")']
                    endif
                endif
            endif

            let rpflines += ["}"]
            call writefile(rpflines, resp[0])
            redraw
            echo " "
            echohl WarningMsg
            echo 'Your new .Rprofile was created.'
            echohl Normal
        endif

        if has("win32") || has("win64") || !hasvimcom
            echohl Question
            let what = input("Do you want to see your .Rprofile now? [y/N]: ")
            echohl Normal
            if RGetYesOrNo(what)
                silent exe "tabnew " . resp[0]
            endif
        else
            echohl Question
            let what = input("Do you want to see your .Rprofile along with tips on how to\nconfigure it? [y/N]: ")
            echohl Normal
            if RGetYesOrNo(what)
                silent exe "tabnew " . resp[0]
                silent help r-plugin-R-setup
            endif
        endif
        redraw
    else
        redraw
        echo " "
        call RWarningMsg("Error: configR_result not found.")
        sleep 1
        return 1
    endif
    return 0
endfunction

" Configure vimrc
function! RConfigVimrc()
    if has("win32") || has("win64")
        let uvimrc = $HOME . "/_vimrc"
        if !filereadable(uvimrc) && filereadable($HOME . "/vimfiles/vimrc")
            let uvimrc = $HOME . "/vimfiles/vimrc"
        endif
    elseif has("neovim")
        let uvimrc = $HOME . "/.nvimrc"
        if !filereadable(uvimrc) && filereadable($HOME . "/.nvim/nvimrc")
            let uvimrc = $HOME . "/.nvim/nvimrc"
        endif
    else
        let uvimrc = $HOME . "/.vimrc"
        if !filereadable(uvimrc) && filereadable($HOME . "/.vim/vimrc")
            let uvimrc = $HOME . "/.vim/vimrc"
        endif
    endif

    if filereadable(uvimrc)
        let hasvimrc = 1
        echo " "
        echohl WarningMsg
        echo "You already have a vimrc."
        echohl Normal
        echohl Question
        let what = input("Do you want to add to the bottom of your vimrc some options that\nmost users consider convenient for the Vim-R-plugin? [y/N]: ")
        echohl Normal
        if RGetYesOrNo(what)
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
        if RGetYesOrNo(what)
            let vlines = []
        else
            redraw
            return
        endif
    endif

    let vlines += ['']
    if exists("*strftime")
        let vlines += ['" Lines added by the Vim-R-plugin command :RpluginConfig (' . strftime("%Y-%b-%d %H:%M") . '):']
    else
        let vlines += ['" Lines added by the Vim-R-plugin command :RpluginConfig:']
    endif

    if RFindString(vlines, 'syntax\s*on') == 0 && RFindString(vlines, 'syntax\s*enable') == 0
        let vlines += ['syntax enable']
    endif
    if RFindString(vlines, 'filet.* plugin on') == 0
        let vlines += ['filetype plugin on']
    endif
    if RFindString(vlines, 'filet.* indent on') == 0
        let vlines += ['filetype indent on']
    endif

    if RFindString(vlines, "maplocalleader") == 0
        redraw
        echo " "
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
        if RGetYesOrNo(what)
            let vlines += ['" Change the <LocalLeader> key:',
                        \ 'let maplocalleader = ","']
        endif
    endif

    if RFindString(vlines, "<C-x><C-o>") == 0 && RFindString(vlines, "<C-X><C-O>") == 0 && RFindString(vlines, "<c-x><c-o>") == 0
        redraw
        echo " "
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
        if RGetYesOrNo(what)
            let vlines += ['" Use Ctrl+Space to do omnicompletion:',
                        \ 'if has("gui_running")',
                        \ '    inoremap <C-Space> <C-x><C-o>',
                        \ 'else',
                        \ '    inoremap <Nul> <C-x><C-o>',
                        \ 'endif']
        endif
    endif

    if RFindString(vlines, "RDSendLine") == 0 || RFindString(vlines, "RDSendSelection") == 0
        redraw
        echo " "
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
        if RGetYesOrNo(what)
            let vlines += ['" Press the space bar to send lines (in Normal mode) and selections to R:',
                        \ 'vmap <Space> <Plug>RDSendSelection',
                        \ 'nmap <Space> <Plug>RDSendLine']
        endif
    endif

    if has("unix") && has("syntax") && RFindString(vlines, "t_Co") == 0
        redraw
        echo " "
        echo "Vim is capable of displaying 256 colors in terminal emulators. However, it"
        echo "doesn't always detect that the terminal has this feature and defaults to"
        echo "using only 8 colors."
        echohl Question
        let what = input("Do you want to enable the use of 256 colors whenever possible? [y/N]: ")
        echohl Normal
        if RGetYesOrNo(what)
            let vlines += ['',
                        \ '" Force Vim to use 256 colors if running in a capable terminal emulator:',
                        \ 'if &term =~ "xterm" || &term =~ "256" || $DISPLAY != "" || $HAS_256_COLORS == "yes"',
                        \ '    set t_Co=256',
                        \ 'endif']
        endif
    endif

    if !hasvimrc
        redraw
        echo " "
        echo "There are some options that most Vim users like, but that are not enabled by"
        echo "default such as highlighting the last search pattern, incremental search"
        echo "and setting the indentation as four spaces."
        echohl Question
        let what = input("Do you want these options in your vimrc? [y/N]: ")
        echohl Normal
        if RGetYesOrNo(what)
            let vlines += ['',
                        \ '" The lines below were also added by the Vim-R-plugin because you did not have',
                        \ '" a vimrc yet in the hope that they will help you getting started with Vim:',
                        \ '',
                        \ '" Highlight the last searched pattern:',
                        \ 'set hlsearch',
                        \ '',
                        \ '" Show where the next pattern is as you type it:',
                        \ 'set incsearch',
                        \ '',
                        \ '" By default, Vim indents code by 8 spaces. Most people prefer 4 spaces:',
                        \ 'set sw=4']
        endif
    endif

    if RFindString(vlines, "colorscheme") == 0
        let vlines += ['',
                    \ '" There are hundreds of color schemes for Vim on the internet, but you can',
                    \ '" start with color schemes already installed.',
                    \ '" Click on GVim menu bar "Edit / Color scheme" to know the name of your',
                    \ '" preferred color scheme, then, remove the double quote (which is a comment',
                    \ '" character, like the # is for R language) and replace the value "not_defined"',
                    \ '" below:',
                    \ '"colorscheme not_defined']
    endif
    call writefile(vlines, uvimrc)

    redraw
    echo " "
    echohl WarningMsg
    echo "The changes in your vimrc will be effective"
    echo "only after you quit Vim and start it again."
    echohl Question
    let what = input("Do you want to see your vimrc now? [y/N]: ")
    echohl Normal
    if RGetYesOrNo(what)
        silent exe "tabnew " . uvimrc
        normal! G
    endif
    redraw
endfunction

" Configure .bashrc
function! RConfigBash()
    if filereadable($HOME . "/.bashrc")
        let blines = readfile($HOME . "/.bashrc")
        let hastvim = 0
        for line in blines
            if line =~ "tvim"
                let hastvim = 1
                break
            endif
        endfor

        redraw
        echo " "
        if hastvim
            echohl WarningMsg
            echo "Nothing was added to your ~/.bashrc because the string 'tvim' was found in it."
            echohl Question
            let what = input("Do you want to see your ~/.bashrc along with the plugin\ntips on how to configure Bash? [y/N]: ")
            echohl Normal
            if RGetYesOrNo(what)
                silent exe "tabnew " . $HOME . "/.bashrc"
                silent help r-plugin-bash-setup
            endif
        else
            echo "Vim and Tmux can display up to 256 colors in the terminal emulator,"
            echo "but we have to configure the TERM environment variable for that."
            echo "Instead of starting Tmux and then starting Vim, we can configure"
            echo "Bash to start both at once with the 'tvim' command."
            if !has("neovim")
                echo "The 'clientserver' feature must be enabled for automatic update of"
                echo "the Object Browser and syntax highlight of function names."
            endif
            echohl Question
            let what = input("Do you want that all these features are added to your .bashrc? [y/N]: ")
            echohl Normal
            if RGetYesOrNo(what)
                let blines += ['']
                if exists("*strftime")
                    let blines += ['# Lines added by the Vim-R-plugin command :RpluginConfig (' . strftime("%Y-%b-%d %H:%M") . '):']
                else
                    let blines += ['# Lines added by the Vim-R-plugin command :RpluginConfig:']
                endif
                if has("neovim")
                    let blines += ['# Change the TERM environment variable (to get 256 colors) and creates',
                                \ '# a function to run Tmux and Neovim at once:',
                                \ 'if [ "$TERM" = "xterm" ] || [ "$TERM" = "xterm-256color" ]',
                                \ 'then',
                                \ '    export TERM=xterm-256color',
                                \ '    export HAS_256_COLORS=yes',
                                \ 'fi',
                                \ 'if [ "$TERM" = "screen" ] && [ "$HAS_256_COLORS" = "yes" ]',
                                \ 'then',
                                \ '    export TERM=screen-256color',
                                \ 'fi',
                                \ 'if [ "$HAS_256_COLORS" = "yes" ]',
                                \ 'then',
                                \ '    function tvim(){ tmux new-session "TERM=screen-256color nvim $@" ; }',
                                \ 'else',
                                \ '    function tvim(){ tmux new-session "nvim $@" ; }',
                                \ 'fi' ]
                else
                    let blines += ['# Change the TERM environment variable (to get 256 colors) and make Vim',
                                \ '# connecting to X Server even if running in a terminal emulator (to get',
                                \ '# dynamic update of syntax highlight and Object Browser):',
                                \ 'if [ "$TERM" = "xterm" ] || [ "$TERM" = "xterm-256color" ]',
                                \ 'then',
                                \ '    export TERM=xterm-256color',
                                \ '    export HAS_256_COLORS=yes',
                                \ 'fi',
                                \ 'if [ "$TERM" = "screen" ] && [ "$HAS_256_COLORS" = "yes" ]',
                                \ 'then',
                                \ '    export TERM=screen-256color',
                                \ 'fi',
                                \ 'if [ "x$DISPLAY" != "x" ]',
                                \ 'then',
                                \ '    alias vim="vim --servername VIM"',
                                \ '    if [ "$HAS_256_COLORS" = "yes" ]',
                                \ '    then',
                                \ '        function tvim(){ tmux new-session "TERM=screen-256color vim --servername VIM $@" ; }',
                                \ '    else',
                                \ '        function tvim(){ tmux new-session "vim --servername VIM $@" ; }',
                                \ '    fi',
                                \ 'else',
                                \ '    if [ "$HAS_256_COLORS" = "yes" ]',
                                \ '    then',
                                \ '        function tvim(){ tmux new-session "TERM=screen-256color vim $@" ; }',
                                \ '    else',
                                \ '        function tvim(){ tmux new-session "vim $@" ; }',
                                \ '    fi',
                                \ 'fi' ]
                endif
                call writefile(blines, $HOME . "/.bashrc")
                if !has("gui_running")
                    redraw
                    echo " "
                    echohl WarningMsg
                    echo "The changes in your bashrc will be effective"
                    echo "only after you exit from Bash and start it again"
                    if $DISPLAY == ""
                        echo "(logoff and login again)."
                    else
                        echo "(close the terminal emulator and start it again)."
                    endif
                endif
                echohl Question
                let what = input("Do you want to see your .bashrc now? [y/N]: ")
                echohl Normal
                if RGetYesOrNo(what)
                    silent exe "tabnew " . $HOME . "/.bashrc"
                    normal! G32k
                endif
            endif
        endif
        redraw
    endif
endfunction

function! RConfigTmux()
    redraw
    echo " "
    if filereadable($HOME . "/.tmux.conf")
        echohl WarningMsg
        echo "You already have a .tmux.conf."
        echohl Question
        let what = input("Do you want to see it along with the plugin tips on how to\nconfigure Tmux? [y/N]: ")
        echohl Normal
        if RGetYesOrNo(what)
            silent exe "tabnew " . $HOME . "/.tmux.conf"
            silent help r-plugin-tmux-setup
        endif
        redraw
    else
        echohl Question
        let what = input("You don't have a ~/.tmux.conf yet. Should I create it now? [y/N]: ")
        echohl Normal
        if RGetYesOrNo(what)
            let tlines = ['']
            if exists("*strftime")
                let tlines += ['# Lines added by the Vim-R-plugin command :RpluginConfig (' . strftime("%Y-%b-%d %H:%M") . '):']
            else
                let tlines += ['# Lines added by the Vim-R-plugin command :RpluginConfig:']
            endif
            let tlines += ["set-option -g prefix C-a",
                        \ "unbind-key C-b",
                        \ "bind-key C-a send-prefix",
                        \ '# Set "status on" if you usually create new Tmux windows',
                        \ "set -g status off",
                        \ "set-window-option -g mode-keys vi",
                        \ "set -g terminal-overrides 'xterm*:smcup@:rmcup@'",
                        \ "set -g mode-mouse on",
                        \ "set -g mouse-select-pane on",
                        \ "set -g mouse-resize-pane on"]
            call writefile(tlines, $HOME . "/.tmux.conf")
            redraw
            echo " "
            echohl Question
            let what = input("Do you want to see your .tmux.conf now? [y/N]: ")
            echohl Normal
            if RGetYesOrNo(what)
                silent exe "tabnew " . $HOME . "/.tmux.conf"
            endif
            redraw
        endif
    endif
endfunction

function! RConfigVimR()
    if has("neovim")
        let s:vimprog = "nvim"
    else
        let s:vimprog = "vim"
    endif
    exe "helptags " . g:rplugin_uservimfiles . "/doc"
    if string(g:SendCmdToR) == "function('SendCmdToR_fake')"
        if hasmapto("<Plug>RStart", "n")
            let cmd = RNMapCmd("<Plug>RStart")
        else
            if exists("g:maplocalleader")
                let cmd = g:maplocalleader . "rf"
            else
                let cmd = "\\rf"
            endif
        endif
        call RWarningMsg("Please type  " . cmd . "  to start R before running  :RpluginConfig")
        return
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

