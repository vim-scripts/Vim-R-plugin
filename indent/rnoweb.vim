" Vim indent file
" Language:	Rnoweb
" Author:	Jakson Alves de Aquino <jalvesaq@gmail.com>
" URL:		http://www.vim.org/scripts/script.php?script_id=2628
" Last Change:	Sun Jan 16, 2011  04:32PM


" Only load this indent file when no other was loaded.
if exists("b:did_rnoweb_indent")
  finish
endif
let b:did_rnoweb_indent = 1



runtime indent/r.vim

if exists("g:rplugin_home")
  exe "source " . g:rplugin_home . "/r-plugin/tex_indent.vim"
else
  runtime indent/tex.vim
endif

setlocal indentkeys=0{,0},!^F,o,O,e,},=\bibitem,=\item
setlocal indentexpr=GetRnowebIndent()

function GetRnowebIndent()
  if getline(".") =~ "^<<.*>>=$"
    return 0
  endif
  if search("^<<", "bncW") > search("^@", "bncW")
    return GetRIndent()
  else
    return GetTeXIndent()
endfunction

