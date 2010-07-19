" Vim syntax file
" Language:    R output Files
" Maintainer:  Jakson Aquino <jalvesaq@gmail.com>
" Last Change: 2010 Jul 16
"

" Version Clears: {{{1
" For version 5.x: Clear all syntax items
" For version 6.x and 7.x: Quit when a syntax file was already loaded
if version < 600 
  syntax clear
elseif exists("b:current_syntax")
  finish
endif 

syn case match

" Strings
syn region routString start=/"/ skip=/\\\\\|\\"/ end=/"/
" Numbers
syn match routNumber /\<\d\+\>/
" floating point number with integer and fractional parts and optional exponent
syn match routFloat /\<\d\+\.\d*\([Ee][-+]\=\d\+\)\=\>/
" floating point number with no integer part and optional exponent
syn match routFloat /\<\.\d\+\([Ee][-+]\=\d\+\)\=\>/
" floating point number with no fractional part and optional exponent
syn match routFloat /\<\d\+[Ee][-+]\=\d\+\>/
syn match routIndex /^\s*\[\d\+\]/
" Comment
syn match routComment /^> .*/
syn match routComment /^+ .*/

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_r_syn_inits")
  if version < 508
    let did_r_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif
  HiLink routComment	Comment
  HiLink routNumber	Number
  HiLink routFloat	Float
  HiLink routString	String
  HiLink routIndex	Special
  delcommand HiLink
endif

let   b:current_syntax = "rout"
