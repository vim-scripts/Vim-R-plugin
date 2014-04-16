
" Users may define the value of g:vimrplugin_permanent_libs to determine what
" functions should be highlighted even if R is not running. By default, the
" functions of packages loaded by R --vanilla are highlighted.
if !exists("g:vimrplugin_permanent_libs")
    let g:vimrplugin_permanent_libs = "base,stats,graphics,grDevices,utils,methods"
endif

" Store the names of R package whose functions were already added to syntax
" highlight to avoid sourcing them repeatedly. Initialize the list with two
" libraries that don't have any visible function.
let b:rplugin_funls = ["datasets", "setwidth"]

" The function RUpdateFunSyntax() is called by the Vim-R-plugin whenever the
" user loads a new package in R. The function should be defined only once.
" Thus, if it's already defined, call it and finish.
if exists("*RUpdateFunSyntax")
    call RUpdateFunSyntax(0)
    finish
endif

function RAddToFunList(lib, verbose)
    " Only run once for each package:
    for pkg in b:rplugin_funls
        if pkg == a:lib
            return
        endif
    endfor

    " The fun_ files list functions of R packages and are created by the
    " Vim-R-plugin:
    let fnf = split(globpath(&rtp, 'r-plugin/objlist/fun_' . a:lib . '_*'), "\n")

    if len(fnf) == 1
        silent exe "source " . substitute(fnf[0], ' ', '\\ ', "g")
        let b:rplugin_funls += [a:lib]
    elseif a:verbose && len(fnf) == 0
        echohl WarningMsg
        echomsg 'Fun_ file for "' . a:lib . '" not found.'
        echohl Normal
        return
    elseif a:verbose && len(fnf) > 1
        echohl WarningMsg
        echomsg 'There is more than one fun_ file for "' . a:lib . '":'
        for fff in fnf
            echomsg fff
        endfor
        echohl Normal
        return
    endif
endfunction

function RUpdateFunSyntax(verbose)
    " Do nothing if called at a buffer that doesn't include R syntax:
    if !exists("b:rplugin_funls")
        return
    endif
    if exists("g:rplugin_libls")
        for lib in g:rplugin_libls
            call RAddToFunList(lib, a:verbose)
        endfor
    else
        if exists("g:vimrplugin_permanent_libs")
            for lib in split(g:vimrplugin_permanent_libs, ",")
                call RAddToFunList(lib, a:verbose)
            endfor
        endif
    endif
endfunction

call RUpdateFunSyntax(0)

