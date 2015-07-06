
if has("nvim")
    finish
endif

" Only source this once
if exists("*RmFromRLibList")
    if len(g:rplugin_lists_to_load) > 0
        for s:lib in g:rplugin_lists_to_load
            call SourceRFunList(s:lib)
        endfor
        unlet s:lib
    endif
    finish
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set global variables when this script is called for the first time
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Users may define the value of g:vimrplugin_start_libs
if !exists("g:vimrplugin_start_libs")
    let g:vimrplugin_start_libs = "base,stats,graphics,grDevices,utils,methods"
endif

let g:rplugin_lists_to_load = split(g:vimrplugin_start_libs, ",")
let g:rplugin_debug_lists = []
let g:rplugin_loaded_lists = []
let g:rplugin_Rhelp_list = []
let g:rplugin_omni_lines = []
let g:rplugin_new_libs = 0

" syntax/r.vim may have being called before ftplugin/r.vim
if !exists("g:rplugin_compldir")
    runtime r-plugin/setcompldir.vim
endif


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function for highlighting rFunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Must be run for each buffer
function SourceRFunList(lib)
    if isdirectory(g:rplugin_compldir)
        let fnf = split(globpath(g:rplugin_compldir, 'fun_' . a:lib . '_*'), "\n")
        if len(fnf) == 1
            " Highlight R functions
            exe "source " . substitute(fnf[0], ' ', '\\ ', 'g')
        elseif len(fnf) == 0
            let g:rplugin_debug_lists += ['Function list for "' . a:lib . '" not found.']
        elseif len(fnf) > 1
            let g:rplugin_debug_lists += ['There is more than one function list for "' . a:lib . '".']
            for obl in fnf
                let g:rplugin_debug_lists += [obl]
            endfor
        endif
    endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Omnicompletion functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function RLisObjs(arglead, cmdline, curpos)
    let lob = []
    let rkeyword = '^' . a:arglead
    for xx in g:rplugin_Rhelp_list
        if xx =~ rkeyword
            call add(lob, xx)
        endif
    endfor
    return lob
endfunction

function RmFromRLibList(lib)
    for idx in range(len(g:rplugin_loaded_lists))
        if g:rplugin_loaded_lists[idx] == a:lib
            call remove(g:rplugin_loaded_lists, idx)
            break
        endif
    endfor
    for idx in range(len(g:rplugin_lists_to_load))
        if g:rplugin_lists_to_load[idx] == a:lib
            call remove(g:rplugin_lists_to_load, idx)
            break
        endif
    endfor
endfunction

function AddToRLibList(lib)
    if isdirectory(g:rplugin_compldir)
        let omf = split(globpath(g:rplugin_compldir, 'omnils_' . a:lib . '_*'), "\n")
        if len(omf) == 1
            let g:rplugin_loaded_lists += [a:lib]

            " List of objects for omni completion
            let olist = readfile(omf[0])
            let g:rplugin_omni_lines += olist

            " List of objects for :Rhelp completion
            for xx in olist
                let xxx = split(xx, "\x06")
                if len(xxx) > 0 && xxx[0] !~ '\$'
                    call add(g:rplugin_Rhelp_list, xxx[0])
                endif
            endfor
        elseif len(omf) == 0
            let g:rplugin_debug_lists += ['Omnils list for "' . a:lib . '" not found.']
            call RmFromRLibList(a:lib)
            return
        elseif len(omf) > 1
            let g:rplugin_debug_lists += ['There is more than one omnils and function list for "' . a:lib . '".']
            for obl in omf
                let g:rplugin_debug_lists += [obl]
            endfor
            call RmFromRLibList(a:lib)
            return
        endif
    endif
endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function called by vimcom
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function FillRLibList()
    " Avoid crash (segmentation fault)
    if g:rplugin_starting_R
        let g:rplugin_fillrliblist_called = 1
        return
    endif

    " Update the list of objects for omnicompletion
    if filereadable(g:rplugin_tmpdir . "/libnames_" . $VIMINSTANCEID)
        let g:rplugin_lists_to_load = readfile(g:rplugin_tmpdir . "/libnames_" . $VIMINSTANCEID)
        for lib in g:rplugin_lists_to_load
            let isloaded = 0
            for olib in g:rplugin_loaded_lists
                if lib == olib
                    let isloaded = 1
                    break
                endif
            endfor
            if isloaded == 0
                call AddToRLibList(lib)
            endif
        endfor
    endif
    " Now we need to update the syntax in all R files. There should be a
    " better solution than setting a flag to let other buffers know that they
    " also need to update the syntax on CursorMoved event:
    " https://github.com/neovim/neovim/issues/901
    let g:rplugin_new_libs = len(g:rplugin_loaded_lists)
    silent exe 'set filetype=' . &filetype
    let b:rplugin_new_libs = g:rplugin_new_libs
endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Update the buffer syntax if necessary
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function RCheckLibList()
    if b:rplugin_new_libs == g:rplugin_new_libs
        return
    endif
    silent exe 'set filetype=' . &filetype
    let b:rplugin_new_libs = g:rplugin_new_libs
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Source the Syntax scripts for the first time and Load omnilists
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

for s:lib in g:rplugin_lists_to_load
    call SourceRFunList(s:lib)
    call AddToRLibList(s:lib)
endfor

unlet s:lib
