
runtime ftplugin/r.vim

function SourceNotDefined(lines, e)
    echohl WarningMsg
    echo 'The function to source "' . &filetype . '" lines is not defined.'
    echohl Normal
endfunction

function JuliaSourceLines(lines, e)
    call writefile(a:lines, b:rsource)
    let jcmd = 'include("' . b:rsource . '")'
    let ok = g:SendCmdToR(jcmd)
    return ok
endfunction

function SetExeCmd()
    runtime r-plugin/common_buffer.vim
    if &filetype == "julia"
        let b:rplugin_R = "julia"
        let b:rplugin_r_args = " "
        let b:quit_command = "quit()"
        let b:SourceLines = function("JuliaSourceLines")
    elseif &filetype == "python"
        let b:rplugin_R = "python"
        let b:rplugin_r_args = " "
        let b:quit_command = "quit()"
        let b:SourceLines = function("SourceNotDefined")
    elseif &filetype == "haskell"
        let b:rplugin_R = "ghci"
        let b:rplugin_r_args = " "
        let b:quit_command = ":quit"
        let b:SourceLines = function("SourceNotDefined")
    elseif &filetype == "ruby"
        let b:rplugin_R = "irb"
        let b:rplugin_r_args = " "
        let b:quit_command = "quit"
        let b:SourceLines = function("SourceNotDefined")
    elseif &filetype == "lisp"
        let b:rplugin_R = "clisp"
        let b:rplugin_r_args = " "
        let b:quit_command = "(quit)"
        let b:SourceLines = function("SourceNotDefined")
    endif
endfunction

autocmd FileType * call SetExeCmd()
call SetExeCmd()

