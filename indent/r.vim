" Vim indent file
" Language:	R
" Author:	Jakson Alves de Aquino <jalvesaq@gmail.com>
" URL:		http://www.vim.org/scripts/script.php?script_id=2628
" Last Change:	Thu Nov 18, 2010  01:14PM


" Only load this indent file when no other was loaded.
if exists("b:did_r_indent")
  finish
endif
let b:did_r_indent = 1

setlocal indentkeys=0{,0},:,!^F,o,O,e
setlocal indentexpr=GetRIndent()

" Only define the function once.
if exists("*GetRIndent")
  finish
endif

function s:Delete_quotes(line)
  let i = 0
  let j = 0
  let line1 = ""
  let llen = strlen(a:line)
  while i < llen
    if a:line[i] == '"'
      let i += 1
      while !(a:line[i] == '"' && ((i > 1 && a:line[i-1] == '\' && a:line[i-2] == '\') || a:line[i-1] != '\')) && i < llen
	let i += 1
      endwhile
      if a:line[i] == '"'
	let i += 1
      endif
    else
      if a:line[i] == "'"
	let i += 1
	while !(a:line[i] == "'" && ((i > 1 && a:line[i-1] == '\' && a:line[i-2] == '\') || a:line[i-1] != '\')) && i < llen
	  let i += 1
	endwhile
	if a:line[i] == "'"
	  let i += 1
	endif
      endif
    endif
    if i == llen
      break
    endif
    let line1 = line1 . a:line[i]
    let j += 1
    let i += 1
  endwhile
  return line1
endfunction

function! s:Get_paren_balance(line, o, c)
  let line2 = substitute(a:line, a:o, "", "g")
  let openp = strlen(a:line) - strlen(line2)
  let line3 = substitute(line2, a:c, "", "g")
  let closep = strlen(line2) - strlen(line3)
  return openp - closep
endfunction

function! s:Get_paren_balances(line, cline)
  let pb = s:Get_paren_balance(a:line, '(', ')')
  let pb += s:Get_paren_balance(a:line, '[', ']')
  let pb += s:Get_paren_balance(a:line, '{', '')
  let pb += s:Get_paren_balance(a:cline, '', '}')
  return pb
endfunction

function! s:Get_matching_brace(linenr, o, c)
  let line = getline(a:linenr)
  let pb = s:Get_paren_balance(line, a:o, a:c)
  let i = a:linenr
  while pb != 0 && i > 1
    let i -= 1
    let pb += s:Get_paren_balance(s:SanitizeRLine(getline(i)), a:o, a:c)
  endwhile
  return i
endfunction

" Get previous relevant line. Search back until getting a line that isn't
" comment or blank
function s:Get_prev_line( lineno )
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
function s:CountGroups(line)
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
function s:SanitizeRLine(line)
  let newline = s:Delete_quotes(a:line)
  let newline = substitute(newline, '#.*', "", "")
  return newline
endfunction

function GetRIndent()

  let clnum = line(".")    " current line
  let cline = s:SanitizeRLine(getline(clnum))

  if cline =~ ".*}$"
    let indline = s:Get_matching_brace(clnum, '{', '}')
    if indline > 0
      return indent(indline)
    endif
  endif

  " Find the first non blank line above the current line
  let lnum = s:Get_prev_line(clnum)
  " Hit the start of the file, use zero indent.
  if lnum == 0
    return 0
  endif
  let line = s:SanitizeRLine(getline(lnum))

  " Find the first non blank line above previous line
  if line =~ ".*}$"
    let plnum = s:Get_matching_brace(lnum, '{', '}')
  else
    let plnum = s:Get_prev_line(lnum)
  endif
  if plnum > 0
    let pline = s:SanitizeRLine(getline(plnum))
  endif

  if plnum > 0
    " Find the line previous to the previous line
    if pline =~ '.*}$'
      let pplnum = s:Get_matching_brace(plnum, '{', '}')
    else
      let pplnum = s:Get_prev_line(plnum)
    endif
    if pplnum > 0
      let ppline = s:SanitizeRLine(getline(pplnum))
    endif
  endif

  while pplnum > 0 && ((ppline =~ '^\s*\(if\|while\|for\)\s*(.*)\s*$' && s:CountGroups(ppline) == 1) || ppline =~ '\s*{\s*$') && pline !~ '.*{\s*$'
    let plnum = pplnum
    let pline = ppline
    let pplnum = s:Get_prev_line(pplnum)
    let ppline = s:SanitizeRLine(getline(pplnum))
  endwhile

  let ind = indent(lnum)
  let pb = s:Get_paren_balances(line, cline)
  let ind += pb * &sw


  " 'if', 'for', 'while' or 'else' without '{'
  if (line =~ '^\s*\(if\|while\|for\)\s*(.*)\s*$' && s:CountGroups(line) == 1) || line =~ '^\s*else\s*$'
    let ind = ind + &sw
    if cline =~ '^\s*{'
      let ind = ind - &sw
    endif
    return ind
  endif
  if plnum > 0 && ((pline =~ '^\s*\(if\|while\|for\)\s*(.*)\s*$' && s:CountGroups(pline) == 1) || pline =~ '^\s*else\s*$') && line !~ '.*{\s*$'
    let ind = indent(plnum)
    let pb = s:Get_paren_balances(line, cline)
    let ind += pb * &sw
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

