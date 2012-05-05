" Vim syntax file
" Language:	Object browser of Vim-R-plugin
" Maintainer:	Jakson Alves de Aquino (jalvesaq@gmail.com)
" Last Change:	Mon Apr 30, 2012  12:41PM

if exists("b:current_syntax")
  finish
endif
scriptencoding utf-8

setlocal iskeyword=@,48-57,_,.

if has("conceal")
  setlocal conceallevel=2
  setlocal concealcursor=nvc
  syn match rbrowserNumeric	"{#.*\t" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserCharacter	/"#.*\t/ contains=rbrowserDelim,rbrowserTab
  syn match rbrowserFactor	"'#.*\t" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserFunction	"(#.*\t" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserList	"\[#.*\t" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserLogical	"%#.*\t" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserLibrary	"##.*\t" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserS4  	"<#.*\t" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserUnknown	"=#.*\t" contains=rbrowserDelim,rbrowserTab
else
  syn match rbrowserNumeric	"{.*\t" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserCharacter	/".*\t/ contains=rbrowserDelim,rbrowserTab
  syn match rbrowserFactor	"'.*\t" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserFunction	"(.*\t" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserList	"\[.*\t" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserLogical	"%.*\t" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserLibrary	"#.*\t" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserS4	        "<.*\t" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserUnknown	"=.*\t" contains=rbrowserDelim,rbrowserTab
endif
syn match rbrowserEnv		"^.GlobalEnv "
syn match rbrowserEnv		"^Libraries "
syn match rbrowserLink		" Libraries$"
syn match rbrowserLink		" .GlobalEnv$"
syn match rbrowserTreePart	"├─"
syn match rbrowserTreePart	"└─"
syn match rbrowserTreePart	"│" 
if &encoding != "utf-8"
  syn match rbrowserTreePart	"|" 
  syn match rbrowserTreePart	"`-"
  syn match rbrowserTreePart	"|-"
endif

syn match rbrowserTab contained "\t"
if has("conceal")
  syn match rbrowserDelim contained /'#\|"#\|(#\|\[#\|{#\|%#\|##\|<#\|=#/ conceal
else
  syn match rbrowserDelim contained /'\|"\|(\|\[\|{\|%\|#\|<\|=/
endif

hi def link rbrowserEnv		Statement
hi def link rbrowserNumeric	Number
hi def link rbrowserCharacter	String
hi def link rbrowserFactor	Special
hi def link rbrowserList	Type
hi def link rbrowserLibrary	PreProc
hi def link rbrowserLink	Comment
hi def link rbrowserLogical	Boolean
hi def link rbrowserFunction	Function
hi def link rbrowserS4  	Statement
hi def link rbrowserUnknown	Normal
hi def link rbrowserWarn	WarningMsg
hi def link rbrowserTreePart	Comment
hi def link rbrowserDelim	Ignore
hi def link rbrowserTab		Ignore

