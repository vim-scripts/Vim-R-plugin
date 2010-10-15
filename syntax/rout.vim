" Vim syntax file
" Language:    R output Files
" Maintainer:  Jakson Aquino <jalvesaq@gmail.com>
" Last Change: Fri Oct 01, 2010  09:24PM
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
syn region routString start=/"/ skip=/\\\\\|\\"/ end=/"/ end=/$/
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

" Errors and warnings
syn match routError "^Error.*"
syn match routWarn "^Warning.*"

if v:lang =~ "^de"
  syn match routError	"^Fehler.*"
  syn match routWarn	"^Warnung.*"
endif

if v:lang =~ "^es"
  syn match routError	"^Error.*"
  syn match routWarn	"^Aviso.*"
endif

if v:lang =~ "^fr"
  syn match routError	"^Erreur.*"
  syn match routWarn	"^Avis.*"
endif

if v:lang =~ "^it"
  syn match routError	"^Errore.*"
  syn match routWarn	"^Avviso.*"
endif

if v:lang =~ "^nn"
  syn match routError	"^Feil.*"
  syn match routWarn	"^Åtvaring.*"
endif

if v:lang =~ "^pt_BR"
  syn match routError	"^Erro.*"
  syn match routWarn	"^Aviso.*"
endif

if v:lang =~ "^ru"
  syn match routError	"^Ошибка.*"
  syn match routWarn	"^Предупреждение.*"
endif


" Define the default highlighting.
hi def link routComment	Comment
hi def link routNumber	Number
hi def link routFloat	Float
hi def link routString	String
hi def link routError   Error
hi def link routWarn    WarningMsg
hi def link routIndex	Special

let   b:current_syntax = "rout"
