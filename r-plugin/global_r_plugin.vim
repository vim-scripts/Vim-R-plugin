
runtime r-plugin/common_global.vim
if exists("g:rplugin_failed")
    finish
endif

runtime r-plugin/common_buffer.vim

" Default IsInRCode function when the plugin is used as a global plugin
function! DefaultIsInRCode(vrb)
    return 1
endfunction

let b:IsInRCode = function("DefaultIsInRCode")

call RCreateStartMaps()
call RCreateEditMaps()
call RCreateSendMaps()
call RControlMaps()

" Menu R
if has("gui_running")
    call MakeRMenu()
endif

call RSourceOtherScripts()

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
        call RCreateMaps("ni", '<Plug>RSendFile',     'aa', ':call JuliaSourceLines(getline(1, "$"), "silent")')
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

