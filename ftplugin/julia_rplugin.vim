
if exists("g:disable_r_ftplugin")
    finish
endif

" Source scripts common to R, Rnoweb, Rhelp, Rmd, Rrst and rdoc files:
runtime r-plugin/common_global.vim
if exists("g:rplugin_failed")
    finish
endif

" Some buffer variables common to R, Rnoweb, Rhelp, Rmd, Rrst and rdoc files
" need be defined after the global ones:
runtime r-plugin/common_buffer.vim

" Default IsInRCode function when the plugin is used as a global plugin
function! DefaultIsInRCode(vrb)
    return 1
endfunction

let b:IsInRCode = function("DefaultIsInRCode")


" Source Lines into Julia
function JuliaSourceLines(lines, e)
    call writefile(a:lines, b:rsource)
    let jcmd = 'include("' . b:rsource . '")'
    let ok = g:SendCmdToR(jcmd)
    return ok
endfunction

" send file to Julia
function SendFileToJulia()
    let fpath = expand("%:p")
    call g:SendCmdToR('include("' . fpath . '")')
endfunction

" Pointer to function that must be different if the plugin is used as a
" global one:
let b:SourceLines = function("JuliaSourceLines")
let b:SendFile = function("SendFileToJulia")

"==========================================================================
" Key bindings and menu items

call RCreateStartMaps()
call RCreateEditMaps()

" Only .R files are sent to R
call RCreateMaps("ni", '<Plug>RSendFile',     'aa', ':call SendFileToJulia()')


call RCreateSendMaps()
call RControlMaps()


" Menu R
if has("gui_running")
    call MakeRMenu()
endif

call RSourceOtherScripts()


let b:undo_ftplugin .= " | unlet! b:IsInRCode b:SourceLines"
