" Vim indent file
" Language:	Rrst
" Author:	Jakson Alves de Aquino <jalvesaq@gmail.com>
" URL:		http://www.vim.org/scripts/script.php?script_id=2628
" Last Change:	Thu Oct 11, 2012  10:52PM


" Only load this indent file when no other was loaded.
if exists("b:did_rrst_indent")
  finish
endif
let b:did_rrst_indent = 1



runtime indent/r.vim

setlocal indentkeys=0{,0},:,!^F,o,O,e
setlocal indentexpr=GetRrstIndent()

if exists("*GetRrstIndent")
  finish
endif

function GetRstIndent()
    let pline = getline(v:lnum - 1)
    let cline = getline(v:lnum)
    if prevnonblank(v:lnum - 1) < v:lnum - 1 || cline =~ '^\s*[-\+\*]\s' || cline =~ '^\s*\d\+\.\s\+'
        return indent(v:lnum)
    elseif pline =~ '^\s*[-\+\*]\s'
        return indent(v:lnum - 1) + 2
    elseif pline =~ '^\s*\d\+\.\s\+'
        return indent(v:lnum - 1) + 3
    endif
    return indent(prevnonblank(v:lnum - 1))
endfunction

function GetRrstIndent()
    if getline(".") =~ '^\.\. {r .*}$' || getline(".") =~ '^\.\. \.\.$'
	return 0
    endif
    if search('^\.\. {r', "bncW") > search('^\.\. \.\.$', "bncW")
	return GetRIndent()
    else
	return GetRstIndent()
    endif
endfunction

