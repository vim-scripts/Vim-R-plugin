" Vim indent file
" Language:	Rnoweb
" Author:	Jakson Alves de Aquino <jalvesaq@gmail.com>
" URL:		http://www.vim.org/scripts/script.php?script_id=2628
" Last Change:	Sat Oct 30, 2010  04:41PM


" Only load this indent file when no other was loaded.
if exists("b:did_rnoweb_indent")
  finish
endif
let b:did_rnoweb_indent = 1


" Only define the function once.
if exists("*GetRnowebIndent")
  finish
endif

runtime indent/r.vim
runtime indent/tex.vim

if !exists("*GetRnowebIndent")
  if exists("g:rplugin_home")
    exe "source " . g:rplugin_home . "/r-plugin/tex_indent.vim"
  endif
endif

setlocal indentkeys=0{,0},!^F,o,O,e,},=\bibitem,=\item
setlocal indentexpr=GetRnowebIndent()

function GetRnowebIndent()
  if search("^<<", "bncW") > search("^@", "bncW")
    return GetRIndent()
  else
    return GetTeXIndent()
endfunction

