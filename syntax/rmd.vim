" markdown Text with R statements
" Language: markdown with R code chunks
" Last Change: Wed Jul 11, 2012  07:53AM

" for portability
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

" load all of pandoc info
runtime syntax/pandoc.vim
if exists("b:current_syntax")
    unlet b:current_syntax
endif

syntax match rmdPattern "^```\_s" contained
hi def link rmdPattern Keyword
syntax match rmdrEndblock "^```[ ]*$" contained
hi def link rmdrEndblock Keyword
syntax match rmdrBlockname "^```[ ]*{r *}" contained
hi def link rmdrBlockname Special

" load all of the r syntax highlighting rules into @R
syntax include @R syntax/r.vim
syntax region rmdr start="^```[ ]*{r .*}$" end="^```$" contains=@R, rmdrBlockname, rmdrEndblock, rmdPattern keepend transparent fold

" TODO: Code below doesn't work
" also match and syntax highlight in-line R code
syntax match rmdrInlineStart "`r "
hi def link rmdrInlineStart Keyword
syntax match rmdrInlineAccent "`" contained
hi def link rmdrInlineAccent String
syntax region rmdrInline start="`r[ ]"  end="`" contains=@R, rmdrInlineStart, rmdrInlineAccent keepend

let b:current_syntax = "rmd"
