
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
    if g:vimrplugin_synctex == "none"
        call g:SendCmdToR('vim.interlace.rnoweb("' . expand("%:t") . '", rnwdir = "' . expand("%:p:h") . '", buildpdf = FALSE, synctex = FALSE)')
    else
        call g:SendCmdToR('vim.interlace.rnoweb("' . expand("%:t") . '", rnwdir = "' . expand("%:p:h") . '", buildpdf = FALSE)')
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
    let pdfcmd = 'vim.interlace.rnoweb("' . expand("%:t") . '", rnwdir = "' . expand("%:p:h") . '"'

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
    let scmd = 'vim.interlace.rnoweb("' . expand("%:t") . '", rnwdir = "' . expand("%:p:h") . '", knit = FALSE, buildpdf = FALSE'
    if exists("g:vimrplugin_sweaveargs")
        let scmd .= ', ' . g:vimrplugin_sweaveargs
    endif
    if g:vimrplugin_synctex == "none"
        let scmd .= ", synctex = FALSE"
    endif
    call g:SendCmdToR(scmd . ')')
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
call RCreateMaps("ni",  '<Plug>RSyncFor',     'gp', ':call SyncTeX_forward()')
nmap <buffer><silent> gn :call RnwNextChunk()<CR>
nmap <buffer><silent> gN :call RnwPreviousChunk()<CR>

" Menu R
if has("gui_running")
    call MakeRMenu()
endif

"==========================================================================
" SyncTeX support:

function! SyncTeX_GetMaster()
    if filereadable(expand("%:t:r") . "-concordance.tex")
        return [expand("%:t:r"), "."]
    endif

    let ischild = search('% *!Rnw *root *=', 'bwn')
    if ischild
        let mfile = substitute(getline(ischild), '.*% *!Rnw *root *= *\(.*\) *', '\1', '')
        if mfile =~ "/"
            let mdir = substitute(mfile, '\(.*\)/.*', '\1', '')
            let mfile = substitute(mfile, '.*/', '', '')
            if mdir == '..'
                let mdir = expand("%:p:h:h")
            endif
        else
            let mdir = "."
        endif
        let basenm = substitute(mfile, '\....$', '', '')
        return [basenm, mdir]
    endif

    " Maybe this buffer is a master Rnoweb not compiled yet.
    return [expand("%:t:r"), "."]
endfunction

" See http://www.stats.uwo.ca/faculty/murdoch/9864/Sweave.pdf page 25
function! SyncTeX_readconc(basenm)
    let texidx = 0
    let rnwidx = 0
    let ntexln = len(readfile(a:basenm . ".tex"))
    let lstexln = range(1, ntexln)
    let lsrnwf = range(1, ntexln)
    let lsrnwl = range(1, ntexln)
    let conc = readfile(a:basenm . "-concordance.tex")
    let idx = 0
    let maxidx = len(conc)
    while idx < maxidx && texidx < ntexln && conc[idx] =~ "Sconcordance"
        let texf = substitute(conc[idx], '\\Sconcordance{concordance:\(.\{-}\):.*', '\1', "g")
        let rnwf = substitute(conc[idx], '\\Sconcordance{concordance:.\{-}:\(.\{-}\):.*', '\1', "g")
        let idx += 1
        let concnum = ""
        while idx < maxidx && conc[idx] !~ "Sconcordance"
            let concnum = concnum . conc[idx]
            let idx += 1
        endwhile
        let concnum = substitute(concnum, '%', '', 'g')
        let concnum = substitute(concnum, '}', '', '')
        let concl = split(concnum)
        let ii = 0
        let maxii = len(concl) - 2
        let rnwl = str2nr(concl[0])
        let lsrnwl[texidx] = rnwl
        let lsrnwf[texidx] = rnwf
        let texidx += 1
        while ii < maxii && texidx < ntexln
            let ii += 1
            let lnrange = range(1, concl[ii])
            let ii += 1
            for iii in lnrange
                if  texidx >= ntexln
                    break
                endif
                let rnwl += concl[ii]
                let lsrnwl[texidx] = rnwl
                let lsrnwf[texidx] = rnwf
                let texidx += 1
            endfor
        endwhile
    endwhile
    return {"texlnum": lstexln, "rnwfile": lsrnwf, "rnwline": lsrnwl}
endfunction

function! SyncTeX_backward(fname, ln)
    let flnm = substitute(a:fname, 'file://', '', '') " Evince
    let flnm = substitute(flnm, '/\./', '/', '')      " Okular
    let basenm = substitute(flnm, "\....$", "", "")   " Delete extension
    if basenm =~ "/"
        let basedir = substitute(basenm, '\(.*\)/.*', '\1', '')
    else
        let basedir = '.'
    endif
    if filereadable(basenm . "-concordance.tex")
        let concdata = SyncTeX_readconc(basenm)
        let texlnum = concdata["texlnum"]
        let rnwfile = concdata["rnwfile"]
        let rnwline = concdata["rnwline"]
        let rnwln = 0
        for ii in range(len(texlnum))
            if texlnum[ii] >= a:ln
                let rnwf = rnwfile[ii]
                let rnwln = rnwline[ii]
                break
            endif
        endfor
        if rnwln == 0
            call RWarningMsg("Could not find Rnoweb source line.")
            return
        endif
    else
        if filereadable(basenm . ".Rnw") || filereadable(basenm . ".rnw")
            call RWarningMsg('SyncTeX [Vim-R-plugin]: "' . basenm . '-concordance.tex" not found.')
            return
        elseif filereadable(flnm)
            let rnwf = flnm
            let rnwln = a:ln
        else
            call RWarningMsg("Could not find '" . basenm . ".Rnw'.")
        endif
    endif

    let rnwbn = substitute(rnwf, '.*/', '', '')
    let rnwf = substitute(rnwf, '^\./', '', '')

    if bufname("%") != rnwbn
        if bufloaded(basedir . '/' . rnwf)
            let savesb = &switchbuf
            set switchbuf=useopen,usetab
            exe "sb " . basedir . '/' . rnwf
            exe "set switchbuf=" . savesb
        elseif bufloaded(rnwf)
            let savesb = &switchbuf
            set switchbuf=useopen,usetab
            exe "sb " . rnwf
            exe "set switchbuf=" . savesb
        else
            if filereadable(basedir . '/' . rnwf)
                exe "tabnew " . basedir . '/' . rnwf
            elseif filereadable(rnwf)
                exe "tabnew " . rnwf
            else
                call RWarningMsg('Could not find either "' . rnwbn . ' or "' . rnwf . '" in "' . basedir . '".')
                return
            endif
        endif
    endif
    exe rnwln
    redraw
    if g:rplugin_has_wmctrl
        call system("wmctrl -xa " . g:vimrplugin_vim_window)
    endif
endfunction

function! SyncTeX_forward()
    if expand("%:p") =~ ' '
        call RWarningMsg('SyncTeX will not work because there is empty space in this file path: "' . expand("%:p") . '"')
    endif
    let basenm = expand("%:t:r")
    let lnum = 0
    let rnwf = bufname("%")

    if filereadable(basenm . "-concordance.tex")
        let lnum = line(".")
    else
        let ischild = search('% *!Rnw *root *=', 'bwn')
        if ischild
            let mfile = substitute(getline(ischild), '.*% *!Rnw *root *= *\(.*\) *', '\1', '')
            let basenm = substitute(mfile, '\....$', '', '')
            if filereadable(basenm . "-concordance.tex")
                let mlines = readfile(mfile)
                for ii in range(len(mlines))
                    " Sweave has detailed child information
                    if mlines[ii] =~ 'SweaveInput.*' . bufname("%")
                        let lnum = line(".")
                        break
                    endif
                    " Knitr does not include detailed child information
                    if mlines[ii] =~ '<<.*child *=.*' . bufname("%") . '["' . "']"
                        let lnum = ii + 1
                        let rnwf = substitute(mfile, '.*/', '', '')
                        break
                    endif
                endfor
                if lnum == 0
                    call RWarningMsg('Could not find "child=' . bufname("%") . '" in ' . mfile . '.')
                    return
                endif
            else
                call RWarningMsg('Vim-R-plugin [SyncTeX]: "' . basenm . '-concordance.tex" not found.')
                return
            endif
        else
            call RWarningMsg('SyncTeX [Vim-R-plugin]: "' . basenm . '-concordance.tex" not found.')
            return
        endif
    endif

    let concdata = SyncTeX_readconc(basenm)
    let texlnum = concdata["texlnum"]
    let rnwfile = concdata["rnwfile"]
    let rnwline = concdata["rnwline"]
    let texln = 0
    for ii in range(len(texlnum))
        if rnwfile[ii] =~ rnwf && rnwline[ii] >= lnum
            let texln = texlnum[ii]
            break
        endif
    endfor

    if texln == 0
        call RWarningMsg("Error: did not find LaTeX line.")
        return
    endif
    if basenm =~ '/'
        let basedir = substitute(basenm, '\(.*\)/.*', '\1', '')
        let basenm = substitute(basenm, '.*/', '', '')
        exe "cd " . basedir
    else
        let basedir = ''
    endif

    if g:vimrplugin_synctex == "okular"
        call system("okular --unique " . basenm . ".pdf#src:" . texln . expand("%:p:h") . "/./" . basenm . ".tex 2> /dev/null >/dev/null &")
    elseif g:vimrplugin_synctex == "evince"
        call system("python " . g:rplugin_home . "/r-plugin/synctex_evince_forward.py " . basenm . ".pdf " . texln . " '" . basenm . ".tex' 2> /dev/null >/dev/null &")
        if g:rplugin_has_wmctrl
            call system("wmctrl -a '" . basenm . ".pdf'")
        endif
    elseif g:vimrplugin_synctex == "zathura"
        if g:rplugin_zathura_pid[basenm] == 0
            exe "Py Start_Zathura('" . basenm . "', '" . v:servername . "')"
        elseif g:rplugin_zathura_pid[basenm]
            let result = system("zathura --synctex-forward=" . texln . ":1:" . basenm . ".tex --synctex-pid=" . g:rplugin_zathura_pid[basenm] . " " . basenm . ".pdf")
            if v:shell_error
                " Maybe Zathura was closed.
                let g:rplugin_zathura_pid[basenm] = 0
                exe "Py Start_Zathura('" . basenm . "', '" . v:servername . "')"
            endif
            if g:rplugin_has_wmctrl
                call system("wmctrl -a '" . basenm . ".pdf'")
            endif
        endif
    elseif g:vimrplugin_synctex = "skim"
        " This command is based on Skim wiki (not tested)
        call system("/Applications/Skim.app/Contents/SharedSupport/displayline " . texln . " '" . basenm . ".pdf' 2> /dev/null >/dev/null &")
    else
        call RWarningMsg('SyncTeX support for "' . g:vimrplugin_synctex . '" not implemented yet.')
    endif
    if basedir != ''
        cd -
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
        let [basenm, basedir] = SyncTeX_GetMaster()
        if basedir != '.'
            exe "cd " . basedir
        endif
        if has("nvim")
            let g:rplugin_stx_job = jobstart("synctex", "python", [g:rplugin_home . "/r-plugin/synctex_evince_backward.py", basenm . ".pdf", "nvim"])
            autocmd JobActivity synctex call Handle_SyncTeX_backward()
        else
            if v:servername != ""
                call system("python " . g:rplugin_home . "/r-plugin/synctex_evince_backward.py '" . basenm . ".pdf' " . v:servername . " &")
            endif
        endif
        if basedir != '.'
            cd -
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

if !exists("g:rplugin_zathura_pid")
    let g:rplugin_zathura_pid = {}
endif
let g:rplugin_zathura_pid[expand("%:r")] = 0

call Run_SyncTeX()

call RSourceOtherScripts()

let b:undo_ftplugin .= " | unlet! b:IsInRCode b:SourceLines b:PreviousRChunk b:NextRChunk b:SendChunkToR"
