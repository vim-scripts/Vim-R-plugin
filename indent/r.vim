" Vim indent file
" Language:	R
" Author:	Jakson Alves de Aquino <jalvesaq@gmail.com>
" URL:		http://www.vim.org/scripts/script.php?script_id=2628
" Last Change:	May 09, 2009


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

" Quit if the buffer is rnoweb:
if &filetype == "rnoweb"
  finish
endif

function! s:Get_paren_balance(line, o, c)
   let line2 = substitute(a:line, a:o, "", "g")
   let openp = strlen(a:line) - strlen(line2)
   let line3 = substitute(line2, a:c, "", "g")
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

" Count groups of () because the indetation should be different for
" '  if(T)' and '  if(T) something()'
function! s:CountGroups(line)
  let ngroups = 0
  let i = 0
  let llen = strlen(a:line)
  while i < llen
    if a:line[i] == '('
      let ngroups += 1
      let k = 1
      let i += 1
      while i < llen && k > 0
        if a:line[i] == '('
          let k += 1
        endif
        if a:line[i] == ')'
          let k -= 1
        endif
        let i += 1
      endwhile
    endif
    let i += 1
  endwhile
  return ngroups
endfunction

" Delete from '#' to the end of the line, unless the '#' is inside a string.
function! s:SanitizeRLine(line)
  let newline = a:line
  let llen = strlen(newline)
  let i = 0
  let isSquo = 0
  let isDquo = 0
  while i < llen
    if newline[i] == '"' && isSquo == 0
      if isDquo && (newline[i-1] != "\\" || (newline[i-1] == "\\" && newline[i-2] == "\\"))
        let isDquo = 0
      else
        let isDquo = 1
      endif
    endif
    if newline[i] == "'" && isDquo == 0
      if isSquo
        let isSquo = 0
      else
        let isSquo = 1
      endif
    endif
    if isDquo == 1 || isSquo == 1
      if newline[i] == '#' || newline[i] == '(' || newline[i] == ')' || newline[i] == '{' || newline[i] == '}'
        let newline = newline[0:(i - 1)] . "a" . newline[(i+1):(llen -1)]
      endif
    endif
    let i += 1
  endwhile
  let newline = substitute(newline, '#.*', "", "")
  return newline
endfunction

function GetRIndent()

  let clnum = v:lnum

  " For debug
  let clnum = line(".")

  " Find the first non blank line above the current line
  let lnum = s:Get_prev_line(clnum)
  " Hit the start of the file, use zero indent.
  if lnum == 0
    return 0
  endif

  " Find the first non blank line above previous line
  let plnum = s:Get_prev_line(lnum)

  let cline = getline(clnum)   " current line
  let cline = s:SanitizeRLine(cline)
  let line = getline(lnum)      " last line
  let line = s:SanitizeRLine(line)
  let pline = getline(plnum)
  let pline = s:SanitizeRLine(pline)

  let ind = indent(lnum)

  let pb = s:Get_paren_balance(line, "(", ")")
  if pb != 0
    let ind += (pb * &sw)
  endif

  let pb = s:Get_paren_balance(line)
  if pb != 0
    let ind = ind + (pb * &sw)
  endif

  " Indent blocks enclosed by {}
  if cline =~ '^\s*}'
    let ind = ind - &sw
    "return ind
  endif
  if line =~ '{\s*$'
    let ind = ind + &sw
    return ind
  endif

  " 'if', 'for', 'while' or 'else' without '{'
  if (line =~ '^\s*\(if\|while\|for\)\s*(.*)\s*$' && s:CountGroups(line) == 1) || line =~ '^\s*else\s*'
    let ind = ind + &sw
    if cline =~ '^\s*{'
      let ind = ind - &sw
    endif
  endif
  if plnum > 0 && ((pline =~ '^\s*\(if\|while\|for\)\s*(.*)\s*$' && s:CountGroups(pline) == 1) || pline =~ '^\s*else\s*') && pline !~ '.*{\s*$'
    let ind = ind - &sw
  endif

  " If you set this option in your .vimrc, the plugin will try to align the
  " arguments of a function that has too many arguments to fit in one line.
  " However, you'll have to manually indent the first line after the parenthesis
  " closing the list of arguments. This option isn't documented in the plugin
  " documentation (~/.vim/doc/r-plugin.txt) because it's a buggy option.
  if exists("g:vimrplugin_funcargsalign")
    if line =~ '.*function\s*(.*$'
      let ind = stridx(line, "(") + 1
    endif
  endif

  return ind
endfunction

