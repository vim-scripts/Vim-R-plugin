
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

" Run R CMD BATCH on current file and load the resulting .Rout in a split
" window
function! ShowRout()
    let routfile = expand("%:r") . ".Rout"
    if bufloaded(routfile)
        exe "bunload " . routfile
        call delete(routfile)
    endif

    if !exists("b:rplugin_R")
        call SetRPath()
    endif

    " if not silent, the user will have to type <Enter>
    silent update
    if has("win32") || has("win64")
        let rcmd = 'Rcmd.exe BATCH --no-restore --no-save "' . expand("%") . '" "' . routfile . '"'
    else
        let rcmd = b:rplugin_R . " CMD BATCH --no-restore --no-save '" . expand("%") . "' '" . routfile . "'"
    endif
    echo "Please wait for: " . rcmd
    let rlog = system(rcmd)
    if v:shell_error && rlog != ""
        call RWarningMsg('Error: "' . rlog . '"')
        sleep 1
    endif

    if filereadable(routfile)
        if g:vimrplugin_routnotab == 1
            exe "split " . routfile
        else
            exe "tabnew " . routfile
        endif
        set filetype=rout
    else
        call RWarningMsg("The file '" . routfile . "' is not readable.")
    endif
endfunction

" Convert R script into Rmd, md and, then, html.
function! RSpin()
    update
    call RSetWD()
    call g:SendCmdToR('require(knitr); spin("' . expand("%:t") . '")')
endfunction

" Default IsInRCode function when the plugin is used as a global plugin
function! DefaultIsInRCode(vrb)
    return 1
endfunction

let b:IsInRCode = function("DefaultIsInRCode")

" Pointer to function that must be different if the plugin is used as a
" global one:
let b:SourceLines = function("RSourceLines")

"==========================================================================
" Key bindings and menu items

call RCreateStartMaps()
call RCreateEditMaps()

" Only .R files are sent to R
call RCreateMaps("ni", '<Plug>RSendFile',     'aa', ':call SendFileToR("silent")')
call RCreateMaps("ni", '<Plug>RESendFile',    'ae', ':call SendFileToR("echo")')
call RCreateMaps("ni", '<Plug>RShowRout',     'ao', ':call ShowRout()')

" Knitr::spin
" -------------------------------------
call RCreateMaps("ni", '<Plug>RSpinFile',     'ks', ':call RSpin()')

call RCreateSendMaps()
call RControlMaps()
call RCreateMaps("nvi", '<Plug>RSetwd',        'rd', ':call RSetWD()')


" Menu R
if has("gui_running")
    call MakeRMenu()
endif

call RSourceOtherScripts()


let b:undo_ftplugin .= " | unlet! b:IsInRCode b:SourceLines"
