
if exists("g:disable_r_ftplugin")
    finish
endif

" Source scripts common to R, Rnoweb, Rhelp and Rdoc:
runtime r-plugin/common_global.vim
if exists("g:rplugin_failed")
    finish
endif

" Some buffer variables common to R, Rnoweb, Rhelp and Rdoc need to be defined
" after the global ones:
runtime r-plugin/common_buffer.vim

function! RWriteChunk()
    if getline(".") =~ "^\\s*$" && RnwIsInRCode(0) == 0
        call setline(line("."), "<<>>=")
        exe "normal! o@"
        exe "normal! 0kl"
    else
        exe "normal! a<"
    endif
endfunction

function! RnwIsInRCode(vrb)
    let chunkline = search("^<<", "bncW")
    let docline = search("^@", "bncW")
    if chunkline > docline && chunkline != line(".")
        return 1
    else
        if a:vrb
            call RWarningMsg("Not inside an R code chunk.")
        endif
        return 0
    endif
endfunction

function! RnwPreviousChunk() range
    let rg = range(a:firstline, a:lastline)
    let chunk = len(rg)
    for var in range(1, chunk)
        let curline = line(".")
        if RnwIsInRCode(0)
            let i = search("^<<.*$", "bnW")
            if i != 0
                call cursor(i-1, 1)
            endif
        endif
        let i = search("^<<.*$", "bnW")
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

function! RnwNextChunk() range
    let rg = range(a:firstline, a:lastline)
    let chunk = len(rg)
    for var in range(1, chunk)
        let i = search("^<<.*$", "nW")
        if i == 0
            call RWarningMsg("There is no next R code chunk to go.")
            return
        else
            call cursor(i+1, 1)
        endif
    endfor
    return
endfunction

" knit the current buffer content
function! RKnitRnw()
    update
    call RSetWD()
    if g:vimrplugin_synctex == "none"
        call g:SendCmdToR('vim.interlace.rnoweb("' . expand("%:t") . '", buildpdf = FALSE, synctex = FALSE)')
    else
        call g:SendCmdToR('vim.interlace.rnoweb("' . expand("%:t") . '", buildpdf = FALSE)')
    endif
endfunction

" Sweave and compile the current buffer content
function! RMakePDF(bibtex, knit)
    if g:rplugin_vimcomport == 0
        if has("nvim")
            call jobsend(g:rplugin_clt_job, "DiscoverVimComPort\n")
        else
            Py DiscoverVimComPort()
        endif
        if g:rplugin_vimcomport == 0
            call RWarningMsg("The vimcom package is required to make and open the PDF.")
        endif
    endif
    update
    call RSetWD()
    let pdfcmd = "vim.interlace.rnoweb('" . expand("%:t") . "'"

    if a:knit == 0
        let pdfcmd = pdfcmd . ', knit = FALSE'
    endif

    if g:rplugin_has_latexmk == 0
        let pdfcmd = pdfcmd . ', latexmk = FALSE'
    endif

    if g:vimrplugin_latexcmd != "default"
        let pdfcmd = pdfcmd . ", latexcmd = '" . g:vimrplugin_latexcmd . "'"
    endif

    if g:vimrplugin_synctex == "none"
        let pdfcmd = pdfcmd . ", synctex = FALSE"
    endif

    if a:bibtex == "bibtex"
        let pdfcmd = pdfcmd . ", bibtex = TRUE"
    endif

    if a:bibtex == "verbose"
        let pdfcmd = pdfcmd . ", quiet = FALSE"
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

    if g:vimrplugin_openpdf_quietly
        let pdfcmd = pdfcmd . ", pdfquiet = TRUE"
    endif

    if a:knit == 0 && exists("g:vimrplugin_sweaveargs")
        let pdfcmd = pdfcmd . ", " . g:vimrplugin_sweaveargs
    endif

    let pdfcmd = pdfcmd . ")"
    let ok = g:SendCmdToR(pdfcmd)
    if ok == 0
        return
    endif
endfunction  

" Send Sweave chunk to R
function! RnwSendChunkToR(e, m)
    if RnwIsInRCode(0) == 0
        call RWarningMsg("Not inside an R code chunk.")
        return
    endif
    let chunkline = search("^<<", "bncW") + 1
    let docline = search("^@", "ncW") - 1
    let lines = getline(chunkline, docline)
    let ok = RSourceLines(lines, a:e)
    if ok == 0
        return
    endif
    if a:m == "down"
        call RnwNextChunk()
    endif  
endfunction

" Sweave the current buffer content
function! RSweave()
    update
    call RSetWD()
    if exists("g:vimrplugin_sweaveargs")
        call g:SendCmdToR('Sweave("' . expand("%:t") . '", ' . g:vimrplugin_sweaveargs . ')')
    else
        call g:SendCmdToR('Sweave("' . expand("%:t") . '")')
    endif
endfunction

function! ROpenPDF()
    if has("win32") || has("win64")
        exe 'Py OpenPDF("' . expand("%:t:r") . '.pdf")'
        return
    endif

    if !exists("g:rplugin_pdfviewer")
        let g:rplugin_pdfviewer = "none"
        if has("gui_macvim") || has("gui_mac") || has("mac") || has("macunix")
            if $R_PDFVIEWER == ""
                let pdfvl = ["open"]
            else
                let pdfvl = [$R_PDFVIEWER, "open"]
            endif
        else
            if $R_PDFVIEWER == ""
                let pdfvl = ["xdg-open"]
            else
                let pdfvl = [$R_PDFVIEWER, "xdg-open"]
            endif
        endif
        " List from R configure script:
        let pdfvl += ["evince", "okular", "xpdf", "gv", "gnome-gv", "ggv", "kpdf", "gpdf", "kghostview,", "acroread", "acroread4"]
        for prog in pdfvl
            if executable(prog)
                let g:rplugin_pdfviewer = prog
                break
            endif
        endfor
    endif

    if g:rplugin_pdfviewer == "none"
        if g:vimrplugin_openpdf_quietly
            call g:SendCmdToR('vim.openpdf("' . expand("%:p:r") . ".pdf" . '", TRUE)')
        else
            call g:SendCmdToR('vim.openpdf("' . expand("%:p:r") . ".pdf" . '")')
        endif
    else
        let openlog = system(g:rplugin_pdfviewer . " '" . expand("%:p:r") . ".pdf" . "'")
        if v:shell_error
            let rlog = substitute(openlog, "\n", " ", "g")
            let rlog = substitute(openlog, "\r", " ", "g")
            call RWarningMsg(openlog)
        endif
    endif
endfunction

if g:vimrplugin_rnowebchunk == 1
    " Write code chunk in rnoweb files
    imap <buffer><silent> < <Esc>:call RWriteChunk()<CR>a
endif

" Pointers to functions whose purposes are the same in rnoweb, rrst, rmd,
" rhelp and rdoc and which are called at common_global.vim
let b:IsInRCode = function("RnwIsInRCode")
let b:PreviousRChunk = function("RnwPreviousChunk")
let b:NextRChunk = function("RnwNextChunk")
let b:SendChunkToR = function("RnwSendChunkToR")

" Pointers to functions that must be different if the plugin is used as a
" global one:
let b:SourceLines = function("RSourceLines")

let b:pdf_opened = 0


"==========================================================================
" Key bindings and menu items

call RCreateStartMaps()
call RCreateEditMaps()
call RCreateSendMaps()
call RControlMaps()
call RCreateMaps("nvi", '<Plug>RSetwd',        'rd', ':call RSetWD()')

" Only .Rnw files use these functions:
call RCreateMaps("nvi", '<Plug>RSweave',      'sw', ':call RSweave()')
call RCreateMaps("nvi", '<Plug>RMakePDF',     'sp', ':call RMakePDF("nobib", 0)')
call RCreateMaps("nvi", '<Plug>RBibTeX',      'sb', ':call RMakePDF("bibtex", 0)')
call RCreateMaps("nvi", '<Plug>RKnit',        'kn', ':call RKnitRnw()')
call RCreateMaps("nvi", '<Plug>RMakePDFK',    'kp', ':call RMakePDF("nobib", 1)')
call RCreateMaps("nvi", '<Plug>RBibTeXK',     'kb', ':call RMakePDF("bibtex", 1)')
call RCreateMaps("nvi", '<Plug>ROpenPDF',     'op', ':call ROpenPDF()')
call RCreateMaps("nvi", '<Plug>RIndent',      'si', ':call RnwToggleIndentSty()')
call RCreateMaps("ni",  '<Plug>RSendChunk',   'cc', ':call b:SendChunkToR("silent", "stay")')
call RCreateMaps("ni",  '<Plug>RESendChunk',  'ce', ':call b:SendChunkToR("echo", "stay")')
call RCreateMaps("ni",  '<Plug>RDSendChunk',  'cd', ':call b:SendChunkToR("silent", "down")')
call RCreateMaps("ni",  '<Plug>REDSendChunk', 'ca', ':call b:SendChunkToR("echo", "down")')
call RCreateMaps("ni",  '<Plug>RSyncFor',     'gp', ':call SyncTeX_forward(bufname("%"), line("."))')
nmap <buffer><silent> gn :call RnwNextChunk()<CR>
nmap <buffer><silent> gN :call RnwPreviousChunk()<CR>

" Menu R
if has("gui_running")
    call MakeRMenu()
endif

"==========================================================================
" SyncTeX support:

function! SyncTeX_backward(fname, ln)
    let basenm = substitute(a:fname, "\....$", "", "") " Delete extension
    let basenm = substitute(basenm, 'file://', '', '') " Evince
    let basenm = substitute(basenm, '/\./', '/', '')   " Okular
    if filereadable(basenm . "-concordance.tex")
        let conc = join(readfile(basenm . "-concordance.tex"), "")
        let rnwf = substitute(basenm, '\(.*\)/.*', '\1/', '') . substitute(conc, '\\Sconcordance{concordance:.\{-}:\(.*\):%.*', '\1', "g")
        let conc = substitute(conc, '\\Sconcordance{.*:%', "", "g")
        let conc = substitute(conc, "%", " ", "g")
        let conc = substitute(conc, "}", "", "")
        let concl = split(conc)

        " See http://www.stats.uwo.ca/faculty/murdoch/9864/Sweave.pdf page 25
        let idx = 0
        let maxidx = len(concl) - 2
        let texln = concl[0]
        let rnwln = 1
        let eureka = 0
        while rnwln < a:ln && idx < maxidx && eureka == 0
            let idx += 1
            let lnrange = range(1, concl[idx])
            let idx += 1
            for iii in lnrange
                let rnwln += concl[idx]
                let texln += 1
                if texln >= a:ln
                    let eureka = 1
                    break
                endif
            endfor
        endwhile
    else
        if filereadable(basenm . "Rnw") || filereadable(basenm . "rnw")
            call RWarningMsg('SyncTeX [Vim-R-plugin]: "' . basenm . '-concordance.tex" not found.')
            return
        endif
        " Jump to LaTeX source since there is no Rnoweb file
        let rnwf = a:fname
        let rnwln = a:ln
    endif

    if bufname("%") != rnwf
        if bufloaded(rnwf)
            let savesb = &switchbuf
            set switchbuf=useopen,usetab
            exe "sb " . rnwf
            exe "set switchbuf=" . savesb
        else
            exe "tabnew " . rnwf
        endif
    endif
    exe rnwln
    redraw
    if g:rplugin_has_wmctrl
        call system("wmctrl -xa " . g:vimrplugin_vim_window)
    endif
endfunction

function! SyncTeX_forward(fname, ln)
    let basenm = substitute(a:fname, "\....$", "", "")
    if filereadable(basenm . "-concordance.tex")
        let conc = join(readfile(basenm . "-concordance.tex"), "")
        let conc = substitute(conc, '\\Sconcordance{.*:%', "", "g")
        let conc = substitute(conc, "%", " ", "g")
        let conc = substitute(conc, "}", "", "")
        let concl = split(conc)
        let idx = 0
        let maxidx = len(concl) - 2
        let texln = concl[0]
        let rnwln = 1
        let eureka = 0
        while rnwln < a:ln && idx < maxidx && eureka == 0
            let idx += 1
            let lnrange = range(1, concl[idx])
            let idx += 1
            for iii in lnrange
                let rnwln += concl[idx]
                let texln += 1
                if rnwln >= a:ln
                    let eureka = 1
                    break
                endif
            endfor
        endwhile
    else
        if &filetype == "rnoweb"
            call RWarningMsg('SyncTeX [Vim-R-plugin]: "' . basenm . '-concordance.tex" not found.')
            return
        elseif &filetype == "tex"
            " No conversion needed
            let texln = a:ln
        else
            return
        endif
    endif
    if g:vimrplugin_synctex == "okular"
        call system("okular --unique " . expand("%:r") . ".pdf#src:" . texln . expand("%:p:h") . "/./" . expand("%:r") . ".tex 2> /dev/null >/dev/null &")
    elseif g:vimrplugin_synctex == "evince"
        call system("python " . g:rplugin_home . "/r-plugin/synctex_evince_forward.py " . expand("%:r") . ".pdf " . texln . " " . expand("%:r") . ".tex &")
        if g:rplugin_has_wmctrl
            call system("wmctrl -a '" . expand("%:t:r") . ".pdf'")
        endif
    else
        call RWarningMsg('SyncTeX support for "' . g:vimrplugin_synctex . '" not implemented yet.')
    endif
endfunction

function! SyncTeX_SetPID(spid)
    exe 'autocmd VimLeave * call system("kill ' . a:spid . '")'
endfunction

function! Run_SyncTeX()
    if $DISPLAY == "" || g:vimrplugin_synctex == "none" || exists("b:did_synctex")
        return
    endif
    let b:did_synctex = 1

    if executable("wmctrl")
        let g:rplugin_has_wmctrl = 1
    endif
    if g:vimrplugin_synctex == "evince"
        if has("nvim")
            let g:rplugin_stx_job = jobstart("synctex", "python", [g:rplugin_home . "/r-plugin/synctex_evince_backward.py", expand("%:r") . ".pdf", "nvim"])
            autocmd JobActivity synctex call Handle_SyncTeX_backward()
        else
            if v:servername != ""
                call system("python " . g:rplugin_home . "/r-plugin/synctex_evince_backward.py '" . expand("%:r") . ".pdf' " . v:servername . " &")
            endif
        endif
    elseif g:vimrplugin_synctex == "okular" && has("nvim") && !exists("g:rplugin_okular_search")
        let g:rplugin_okular_search = 1
        call writefile([], $VIMRPLUGIN_TMPDIR . "/okular_search")
        let g:rplugin_stx_job = jobstart("synctex", "tail", ["-f", $VIMRPLUGIN_TMPDIR . "/okular_search"])
        autocmd JobActivity synctex call Handle_SyncTeX_backward()
        autocmd VimLeave * call delete($VIMRPLUGIN_TMPDIR . "/okular_search")
    endif
endfunction

function! Handle_SyncTeX_backward()
    if v:job_data[1] == 'stdout'
        let fname = substitute(v:job_data[2], '|.*', '', '') 
        if g:vimrplugin_synctex == "okular"
            let fname = substitute(fname, '/\./', '/', '')
        endif
        let ln = substitute(v:job_data[2], '.*|\([0-9]*\).*', '\1', '')
        call SyncTeX_backward(fname, ln)
    elseif v:job_data[1] == 'stderr'
        call RWarningMsg(v:job_data[2])
    else
        let g:rplugin_stx_job = 0
    endif
endfunction

call Run_SyncTeX()

call RSourceOtherScripts()

let b:undo_ftplugin .= " | unlet! b:IsInRCode b:SourceLines b:PreviousRChunk b:NextRChunk b:SendChunkToR"
