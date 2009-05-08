" Vim indent file
" Language:	R
" Author:	Jakson Alves de Aquino <jalvesaq@gmail.com>
" URL:		
" Last Change:	
" Version:	
" Notes:  
" Changes: 
" Options: 

" Based on awk.vim and on the script written by Jeremy Stephens:
" http://biostat.mc.vanderbilt.edu/twiki/pub/Main/RVim/indent-r.vim

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal indentexpr=GetRIndent()

" Only define the function once.
if exists("*GetRIndent")
  finish
endif

function! s:Get_paren_balance(line)
   let line2 = substitute(a:line, "(", "", "g")
   let openp = strlen(a:line) - strlen(line2)
   let line3 = substitute(line2, ")", "", "g")
   let closep = strlen(line2) - strlen(line3)
   return openp - closep
endfunction

" Get previous relevant line. Search back until getting a line that isn't
" comment or blank
function! s:Get_prev_line( lineno )
   let lnum = a:lineno - 1
   let data = getline( lnum )
   while lnum > 0 && (data =~ '^\s*#' || data =~ '^\s*$')
      let lnum = lnum - 1
      let data = getline( lnum )
   endwhile
   return lnum
endfunction

function GetRIndent()

  " Find the first non blank line above the current line
  let lnum = s:Get_prev_line(v:lnum)

  " Hit the start of the file, use zero indent.
  if lnum == 0
    return 0
  endif

  " Find the first non blank line above the previous line
  let plnum = s:Get_prev_line(lnum)

  let cline = getline(v:lnum)   " current line
  let line = getline(lnum)	" last line
  let pline = getline(plnum)	" previous to last line

  let ind = indent(lnum)

  let pb = s:Get_paren_balance(line)
  if pb != 0
    let ind = ind + (pb * &sw)
  endif

  " Indent blocks enclosed by {}
  if cline =~ '^\s*}'
    let ind = ind - &sw
    return ind
  endif
  if line =~ '{\s*$'
    let ind = ind + &sw
    return ind
  endif

  " 'if', 'for', 'while' or 'else' without '{'
  if line =~ '^\s*\(if\|while\|for\)\s*(.*)\s*$' || line =~ '^\s*else\s*'
    let ind = ind + &sw
    if cline =~ '^\s*{'
      let ind = ind - &sw
    endif
  endif
  if plnum > 0 && (pline =~ '^\s*\(if\|while\|for\)\s*(.*)\s*$' || pline =~ '^\s*else\s*')
    let ind = ind - &sw
  endif

  return ind
endfunction

