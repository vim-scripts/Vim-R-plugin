
if exists("g:disable_r_ftplugin")
    finish
endif


" Source scripts common to R, Rrst, Rnoweb, Rhelp and Rdoc:
runtime r-plugin/common_global.vim
if exists("g:rplugin_failed")
    finish
endif

" Some buffer variables common to R, Rmd, Rrst, Rnoweb, Rhelp and Rdoc need to
" be defined after the global ones:
runtime r-plugin/common_buffer.vim

function! RmdIsInRCode(vrb)
    let chunkline = search("^[ \t]*```[ ]*{r", "bncW")
    let docline = search("^[ \t]*```$", "bncW")
    if chunkline > docline && chunkline != line(".")
        return 1
    else
        if a:vrb
            call RWarningMsg("Not inside an R code chunk.")
        endif
        return 0
    endif
endfunction

function! RmdPreviousChunk() range
    let rg = range(a:firstline, a:lastline)
    let chunk = len(rg)
    for var in range(1, chunk)
        let curline = line(".")
        if RmdIsInRCode(0)
            let i = search("^[ \t]*```[ ]*{r", "bnW")
            if i != 0
                call cursor(i-1, 1)
            endif
        endif
        let i = search("^[ \t]*```[ ]*{r", "bnW")
        if i == 0
            call cursor(curline, 1)
            call RWarningMsg("There is no previous R code chunk to go.")
            return
        else
            call cursor(i+1, 1)
        endif
    endfor
    return
endfunction

function! RmdNextChunk() range
    let rg = range(a:firstline, a:lastline)
    let chunk = len(rg)
    for var in range(1, chunk)
        let i = search("^[ \t]*```[ ]*{r", "nW")
        if i == 0
            call RWarningMsg("There is no next R code chunk to go.")
            return
        else
            call cursor(i+1, 1)
        endif
    endfor
    return
endfunction

function! RMakeHTMLrmd(t)
    call RSetWD()
    update
    let rcmd = 'require(knitr); knit2html("' . expand("%:t") . '")'
    if a:t == "odt"
        if g:rplugin_has_soffice == 0
            if has("win32") || has("win64")
                let soffbin = "soffice.exe"
            else
                let soffbin = "soffice"
            endif
            if executable(soffbin)
                let g:rplugin_has_soffice = 1
            else
                call RWarningMsg("Is Libre Office installed? Cannot convert into ODT: '" . soffbin . "' not found.")
            endif
        endif
        let rcmd = rcmd . '; system("' . soffbin . ' --invisible --convert-to odt ' . expand("%:r:t") . '.html")'
    endif
    if g:vimrplugin_openhtml && a:t == "html"
        let rcmd = rcmd . '; browseURL("' . expand("%:r:t") . '.html")'
    endif
    call g:SendCmdToR(rcmd)
endfunction

function! RMakeSlidesrmd()
    call RSetWD()
    update
    let rcmd = 'require(slidify); slidify("' . expand("%:t") . '")'
    if g:vimrplugin_openhtml
        let rcmd = rcmd . '; browseURL("' . expand("%:r:t") . '.html")'
    endif
    call g:SendCmdToR(rcmd)
endfunction


function! RMakePDFrmd(t)
    if g:rplugin_vimcomport == 0
        if has("neovim")
            call jobwrite(g:rplugin_clt_job, "DiscoverVimComPort\n")
        else
            Py DiscoverVimComPort()
        endif
        if g:rplugin_vimcomport == 0
            call RWarningMsg("The vimcom package is required to make and open the PDF.")
        endif
    endif
    if g:rplugin_has_pandoc == 0
        if executable("pandoc")
            let g:rplugin_has_pandoc = 1
        else
            call RWarningMsg("Cannot convert into PDF: 'pandoc' not found.")
            return
        endif
    endif
    call RSetWD()
    update
    let pdfcmd = "vim.interlace.rmd('" . expand("%:t") . "'"
    let pdfcmd = pdfcmd . ", pdfout = '" . a:t  . "'"
    if exists("g:vimrplugin_rmdcompiler")
        let pdfcmd = pdfcmd . ", compiler='" . g:vimrplugin_rmdcompiler . "'"
    endif
    if exists("g:vimrplugin_knitargs")
        let pdfcmd = pdfcmd . ", " . g:vimrplugin_knitargs
    endif
    if exists("g:vimrplugin_rmd2pdfpath")
        pdfcmd = pdfcmd . ", rmd2pdfpath='" . g:vimrplugin_rmd2pdf_path . "'"
    endif
    if exists("g:vimrplugin_pandoc_args")
        let pdfcmd = pdfcmd . ", pandoc_args = '" . g:vimrplugin_pandoc_args . "'"
    endif
    if g:vimrplugin_openpdf == 0
        let pdfcmd = pdfcmd . ", view = FALSE"
    else
        if g:vimrplugin_openpdf == 1
            if b:pdf_opened == 0
                let b:pdf_opened = 1
            else
                let pdfcmd = pdfcmd . ", view = FALSE"
            endif
        endif
    endif
    let pdfcmd = pdfcmd . ")"
    call g:SendCmdToR(pdfcmd)
endfunction  

" Send Rmd chunk to R
function! SendRmdChunkToR(e, m)
    if RmdIsInRCode(0) == 0
        call RWarningMsg("Not inside an R code chunk.")
        return
    endif
    let chunkline = search("^[ \t]*```[ ]*{r", "bncW") + 1
    let docline = search("^[ \t]*```", "ncW") - 1
    let lines = getline(chunkline, docline)
    let ok = RSourceLines(lines, a:e)
    if ok == 0
        return
    endif
    if a:m == "down"
        call RmdNextChunk()
    endif  
endfunction

let b:IsInRCode = function("RmdIsInRCode")
let b:PreviousRChunk = function("RmdPreviousChunk")
let b:NextRChunk = function("RmdNextChunk")
let b:SendChunkToR = function("SendRmdChunkToR")
let b:SourceLines = function("RSourceLines")

"==========================================================================
" Key bindings and menu items

call RCreateStartMaps()
call RCreateEditMaps()
call RCreateSendMaps()
call RControlMaps()
call RCreateMaps("nvi", '<Plug>RSetwd',        'rd', ':call RSetWD()')

" Only .Rmd files use these functions:
call RCreateMaps("nvi", '<Plug>RKnit',        'kn', ':call RKnit()')
call RCreateMaps("nvi", '<Plug>RMakePDFK',    'kp', ':call RMakePDFrmd("latex")')
call RCreateMaps("nvi", '<Plug>RMakePDFKb',   'kl', ':call RMakePDFrmd("beamer")')
call RCreateMaps("nvi", '<Plug>RMakeHTML',    'kh', ':call RMakeHTMLrmd("html")')
call RCreateMaps("nvi", '<Plug>RMakeSlides',  'sl', ':call RMakeSlidesrmd()')
call RCreateMaps("nvi", '<Plug>RMakeODT',     'ko', ':call RMakeHTMLrmd("odt")')
call RCreateMaps("ni",  '<Plug>RSendChunk',   'cc', ':call b:SendChunkToR("silent", "stay")')
call RCreateMaps("ni",  '<Plug>RESendChunk',  'ce', ':call b:SendChunkToR("echo", "stay")')
call RCreateMaps("ni",  '<Plug>RDSendChunk',  'cd', ':call b:SendChunkToR("silent", "down")')
call RCreateMaps("ni",  '<Plug>REDSendChunk', 'ca', ':call b:SendChunkToR("echo", "down")')
nmap <buffer><silent> gn :call b:NextRChunk()<CR>
nmap <buffer><silent> gN :call b:PreviousRChunk()<CR>

" Menu R
if has("gui_running")
    call MakeRMenu()
endif

let g:rplugin_has_pandoc = 0
let g:rplugin_has_soffice = 0

call RSourceOtherScripts()


let b:undo_ftplugin .= " | unlet! b:IsInRCode b:SourceLines b:PreviousRChunk b:NextRChunk b:SendChunkToR"
