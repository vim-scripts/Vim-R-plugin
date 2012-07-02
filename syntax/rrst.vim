" reStructured Text with R statements
" Language: reST with R code chunks
" Maintainer: Alex Zvoleff, azvoleff@mail.sdsu.edu
" Last Change: 2012 Jun 12

" for portability
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

" load all of the rst info
runtime syntax/rst.vim
unlet b:current_syntax

" highlight the ".." symbols used in R rst files
syntax match rstrTwodots "^\.\.\_s" contained
hi def link rstrTwodots rstDirective
syntax match rstrEndblock "^\.\. \.\.$" contained
hi def link rstrEndblock rstDirective
"TODO: fix the next line - the \zs isn't working
syntax match rstrBlockname "^\.\. {r \zs[a-zA-Z0-9_-]*" contained
hi def link rstrBlockname Special

" load all of the r syntax highlighting rules into @R
syntax include @R syntax/r.vim
syntax region rstr start="^\.\. {r .*}$" end="^\.\. \.\.$" contains=@R, rstrBlockname, rstrEndblock, rstrTwodots keepend transparent fold

" also match and syntax highlight in-line R code
syntax match rstrInlineStart ":r:"
hi def link rstrInlineStart rstDirective
syntax match rstrInlineAccent "`" contained
hi def link rstrInlineAccent String
syntax region rstrInline start=":r:[ ]*`" skip=/\\\\\|\\`/ end="`" contains=@R, rstrInlineStart, rstrInlineAccent keepend

let b:current_syntax = "rrst"
