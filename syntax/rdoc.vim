" Vim syntax file
" Language:	Test version of R documentation
" Maintainer:	Jakson A. Aquino <jalvesaq@gmail.com>
" Last Change:	Wed Oct 20, 2010  01:04PM

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

" Define the default highlighting.
hi def link rdocTitle	    Title
hi def link rdocExTitle   Title
hi def link rdocExEnd   Comment
hi def link rdocStringS     Function
hi def link rdocStringD     String
hi def link rdocURL    HtmlLink
hi def link rdocArg         Special
hi def link rdocNote  Todo


let b:current_syntax = "rdoc"

" vim:ts=8 sts=2 sw=2:
