" Vim syntax file
" Language:	Test version of R documentation
" Maintainer:	Jakson A. Aquino <jalvesaq@gmail.com>
" Last Change:	Sun Nov 20, 2011  06:36PM

if exists("b:current_syntax")
  finish
endif

if !exists("rdoc_minlines")
  let rdoc_minlines = 200
endif
if !exists("rdoc_maxlines")
  let rdoc_maxlines = 2 * rdoc_minlines
endif
exec "syn sync minlines=" . rdoc_minlines . " maxlines=" . rdoc_maxlines


syn match  rdocTitle	      "^[A-Z].*:"
syn match  rdocTitle "^\S.*R Documentation$"
syn region rdocStringS  start="â€˜" end="â€™"
syn region rdocStringS  start="‘" end="’"
syn region rdocStringD  start='"' skip='\\"' end='"'
syn match rdocURL `\v<(((https?|ftp|gopher)://|(mailto|file|news):)[^'	<>"]+|(www|web|w3)[a-z0-9_-]*\.[a-z0-9._-]+\.[^'  <>"]+)[a-zA-Z0-9/]`
syn keyword rdocNote		note Note NOTE note: Note: NOTE: Notes Notes:
syn match rdocArg  "^\s*\([a-z]\|[A-Z]\|[0-9]\|\.\)*: "

syn include @rdocR syntax/r.vim
syn region rdocExample matchgroup=rdocExTitle start="^Examples:$" matchgroup=rdocExEnd end='^###$' contains=@rdocR keepend

" When using vim as R pager to see the output of help.search():
syn region rdocPackage start="^[A-Za-z]\S*::" end="[\s\r]" contains=rdocPackName,rdocFuncName transparent
syn match rdocPackName "^[A-Za-z][A-Za-z0-9\.]*" contained
syn match rdocFuncName "::[A-Za-z0-9\.\-]*" contained

" Define the default highlighting.
hi def link rdocTitle	    Title
hi def link rdocExTitle   Title
hi def link rdocExEnd   Comment
hi def link rdocStringS     Function
hi def link rdocStringD     String
hi def link rdocURL    HtmlLink
hi def link rdocArg         Special
hi def link rdocNote  Todo

hi def link rdocPackName Title
hi def link rdocFuncName Function

let b:current_syntax = "rdoc"

" vim:ts=8 sts=2 sw=2:
