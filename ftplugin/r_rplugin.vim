
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

function! RCmdBatchJob()
    if v:job_data[1] == 'stdout'
        echo join(v:job_data[2])
    elseif v:job_data[1] == 'stderr'
        call RWarningMsg(join(v:job_data[2]))
    else
        if v:job_data[0] == b:RCmdBatchID
            let b:RCmdBatchID = -2
        endif
        call OpenRout(1)
    endif
endfunction

" Run R CMD BATCH on current file and load the resulting .Rout in a split
" window
function! ShowRout()
    let b:routfile = expand("%:r") . ".Rout"
    if bufloaded(b:routfile)
        exe "bunload " . b:routfile
        call delete(b:routfile)
    endif

    if !exists("b:rplugin_R")
        call SetRPath()
    endif

    " if not silent, the user will have to type <Enter>
    silent update

    if has("nvim")
        if b:RCmdBatchID != -2
            call RWarningMsg("There is R CMD BATCH job running already.")
            return
        endif
        if has("win32") || has("win64")
            let b:RCmdBatchID = jobstart("RCmdBatch", 'Rcmd.exe', ['BATCH', '--no-restore', '--no-save',  expand("%"), b:routfile])
        else
            let b:RCmdBatchID = jobstart("RCmdBatch", b:rplugin_R, ['CMD', 'BATCH', '--no-restore', '--no-save', expand("%"), b:routfile])
        endif
        if b:RCmdBatchID == 0
            call RWarningMsg("The job table is full.")
        elseif b:RCmdBatchID == -1
            call RWarningMsg("Failed to execute R.")
        endif
        echomsg 'R CMD BATCH job is running.'
        return
    endif

    if has("win32") || has("win64")
        let rcmd = 'Rcmd.exe BATCH --no-restore --no-save "' . expand("%") . '" "' . b:routfile . '"'
    else
        let rcmd = b:rplugin_R . " CMD BATCH --no-restore --no-save '" . expand("%") . "' '" . b:routfile . "'"
    endif

    echo "Please wait for: " . rcmd
    let rlog = system(rcmd)
    if v:shell_error && rlog != ""
        call RWarningMsg('Error: "' . rlog . '"')
        sleep 1
    endif
    call OpenRout(0)
    return
endfunction

function! OpenRout(goback)
    if filereadable(b:routfile)
        let curpos = getcurpos()
        if g:vimrplugin_routnotab == 1
            exe "split " . b:routfile
        else
            exe "tabnew " . b:routfile
        endif
        set filetype=rout
        if a:goback
            if g:vimrplugin_routnotab == 1
                exe "normal! \<c-w>p"
            else
                normal! gT
            endif
            call setpos(".", curpos)
        endif
    else
        call RWarningMsg("The file '" . b:routfile . "' is not readable.")
    endif
endfunction

" Convert R script into Rmd, md and, then, html.
function! RSpin()
    update
    call g:SendCmdToR('require(knitr); .vim_oldwd <- getwd(); setwd("' . expand("%:p:h") . '"); spin("' . expand("%:t") . '"); setwd(.vim_oldwd); rm(.vim_oldwd)')
endfunction

" Default IsInRCode function when the plugin is used as a global plugin
function! DefaultIsInRCode(vrb)
    return 1
endfunction

let b:IsInRCode = function("DefaultIsInRCode")

" Pointer to function that must be different if the plugin is used as a
" global one:
let b:SourceLines = function("RSourceLines")

" job id for R CMD BATCH
if has("nvim")
    if !exists("b:RCmdBatchID")
        let b:RCmdBatchID = -2
        autocmd JobActivity RCmdBatch call RCmdBatchJob()
    endif
endif

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

if exists("b:undo_ftplugin")
    let b:undo_ftplugin .= " | unlet! b:IsInRCode b:SourceLines"
else
    let b:undo_ftplugin = "unlet! b:IsInRCode b:SourceLines"   
endif
