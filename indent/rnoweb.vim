" Vim indent file
" Language:	Rnoweb
" Author:	Jakson Alves de Aquino <jalvesaq@gmail.com>
" URL:		http://www.vim.org/scripts/script.php?script_id=2628
" Last Change:	Fri Feb 15, 2013  08:06PM


" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1



runtime indent/r.vim
runtime r-plugin/tex_indent.vim

setlocal indentkeys=0{,0},!^F,o,O,e,},=\bibitem,=\item
setlocal indentexpr=GetRnowebIndent()

if exists("*GetRnowebIndent")
  finish
endif

function GetRnowebIndent()
    if getline(".") =~ "^<<.*>>=$"
	return 0
    endif
    if search("^<<", "bncW") > search("^@", "bncW")
	return GetRIndent()
    else
	return GetTeXIndent2()
    endif
endfunction

