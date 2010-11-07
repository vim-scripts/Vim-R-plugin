" Vim syntax file
" Language:    R output Files
" Maintainer:  Jakson Aquino <jalvesaq@gmail.com>
" Last Change: Mon Oct 25, 2010  07:20PM
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

" Common elements to r and rout file types
runtime r-plugin/rsyntax.vim

if !exists("g:vimrplugin_routmorecolors")
  let g:vimrplugin_routmorecolors = 0
endif

if g:vimrplugin_routmorecolors == 1
  syn include @routR syntax/r.vim
  syn region routColoredR start="^> " end='$' contains=@routR keepend
  syn region routColoredR start="^+ " end='$' contains=@routR keepend
else
  " Comment
  syn match routComment /^> .*/
  syn match routComment /^+ .*/
endif

" Index of vectors
syn match routIndex /^\s*\[\d\+\]/

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
if g:vimrplugin_routmorecolors == 0
  hi def link routComment	Comment
endif
hi def link rNumber	Number
hi def link rComplex	Number
hi def link rInteger	Number
hi def link rBoolean	Boolean
hi def link rConstant	Constant
hi def link rFloat	Float
hi def link routString	String
hi def link routError	Error
hi def link routWarn	WarningMsg
hi def link routIndex	Special

let   b:current_syntax = "rout"
