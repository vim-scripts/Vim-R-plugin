" Check whether Tmux is OK
if !executable('tmux') && g:vimrplugin_source !~ "screenR"
    call RWarningMsgInp("Please, install the 'Tmux' application to enable the Vim-R-plugin.")
    let g:rplugin_failed = 1
    finish
endif

if system("uname") =~ "OpenBSD"
    " Tmux does not have -V option on OpenBSD: https://github.com/jcfaria/Vim-R-plugin/issues/200
    let g:rplugin_tmux_version = "2.1"
else
    let g:rplugin_tmux_version = system("tmux -V")
    let g:rplugin_tmux_version = substitute(g:rplugin_tmux_version, '.*tmux \([0-9]\.[0-9]\).*', '\1', '')
    if strlen(g:rplugin_tmux_version) != 3
        let g:rplugin_tmux_version = "1.0"
    endif
    if g:rplugin_tmux_version < "1.8" && g:vimrplugin_source !~ "screenR"
        call RWarningMsgInp("Vim-R-plugin requires Tmux >= 1.8")
        let g:rplugin_failed = 1
        finish
    endif
endif

if g:rplugin_do_tmux_split
    runtime r-plugin/tmux_split.vim
else
    runtime r-plugin/extern_term.vim
endif
