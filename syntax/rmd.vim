" markdown Text with R statements
" Language: markdown with R code chunks
" Last Change: Tue Feb 26, 2013  01:48PM
"
" CONFIGURATION:
"   To highlight chunk headers as R code, put in your vimrc:
"   let rmd_syn_hl_chunk = 1

" for portability
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

" load all of pandoc info
runtime syntax/pandoc.vim
if exists("b:current_syntax")
    let rmdIsPandoc = 1
    unlet b:current_syntax
else
    let rmdIsPandoc = 0
    runtime syntax/markdown.vim
    if exists("b:current_syntax")
        unlet b:current_syntax
    endif
endif

" load all of the r syntax highlighting rules into @R
syntax include @R syntax/r.vim
if exists("b:current_syntax")
    unlet b:current_syntax
endif

setlocal iskeyword=@,48-57,_,.

if exists("g:rmd_syn_hl_chunk")
    " highlight R code inside chunk header
    syntax match rmdChunkDelim "^```{r" contained
    syntax match rmdChunkDelim "}$" contained
else
    syntax match rmdChunkDelim "^```{r.*}$" contained
endif
syntax match rmdChunkDelim "^```$" contained
syntax region rmdChunk start="^``` *{r.*}$" end="^```$" contains=@R,rmdChunkDelim keepend transparent fold

" also match and syntax highlight in-line R code
syntax match rmdEndInline "`" contained
syntax match rmdBeginInline "`r " contained
syntax region rmdrInline start="`r "  end="`" contains=@R,rmdBeginInline,rmdEndInline keepend transparent


if rmdIsPandoc == 0
    syn match rmdBlockQuote /^\s*>.*\n\(.*\n\@<!\n\)*/ skipnl
    " LaTeX
    syntax include @LaTeX syntax/tex.vim
    if exists("b:current_syntax")
        unlet b:current_syntax
    endif
    " Inline
    syntax match rmdLaTeXInlDelim "\$"
    syntax match rmdLaTeXInlDelim "\\\$"
    syn region texMathZoneX	matchgroup=Delimiter start="\$" skip="\\\\\|\\\$"	matchgroup=Delimiter end="\$" end="%stopzone\>"	contains=@texMathZoneGroup
    " Region
    syntax match rmdLaTeXRegDelim "\$\$" contained
    syntax match rmdLaTeXRegDelim "\$\$latex$" contained
    syntax region rmdLaTeXRegion start="^\$\$" skip="\\\$" end="^\$\$" contains=@LaTeX,rmdLaTeXSt,rmdLaTeXRegDelim keepend 
    hi def link rmdLaTeXSt Statement
    hi def link rmdLaTeXInlDelim Special
    hi def link rmdLaTeXRegDelim Special
endif

hi def link rmdChunkDelim Special
hi def link rmdBeginInline Special
hi def link rmdEndInline Special
hi def link rmdBlockQuote Comment

let b:current_syntax = "rmd"
