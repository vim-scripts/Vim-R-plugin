" Vim syntax file
" Language:	Object browser of Vim-R-plugin
" Maintainer:	Jakson Alves de Aquino (jalvesaq@gmail.com)
" Last Change:	Sat Oct 16, 2010  10:24AM

if exists("b:current_syntax")
  finish
endif

setlocal iskeyword=@,48-57,_,.

syn match rbrowserNumeric	"{.*	" contains=rbrowserDelim,rbrowserTab
syn match rbrowserCharacter	/".*	/ contains=rbrowserDelim,rbrowserTab
syn match rbrowserFactor	"'.*	" contains=rbrowserDelim,rbrowserTab
syn match rbrowserFunction	"(.*	" contains=rbrowserDelim,rbrowserTab
syn match rbrowserList		"\[.*	" contains=rbrowserDelim,rbrowserTab
syn match rbrowserLogical	"%.*	" contains=rbrowserDelim,rbrowserTab
syn match rbrowserEnv		"Objects in the Workspace"
syn match rbrowserOpenTree	"\~"
syn match rbrowserClosedTr	"+"
if v:lang =~ "UTF-8"
  syn match rbrowserTreePart	"├─"
  syn match rbrowserTreePart	"└─"
  syn match rbrowserTreePart	"│" 
else
  syn match rbrowserTreePart	"|" 
  syn match rbrowserTreePart	"`-"
  syn match rbrowserTreePart	"|-"
endif

syn match rbrowserTab contained "	"
syn match rbrowserDelim contained /'\|"\|(\|\[\|{\|%/

hi def link rbrowserEnv		Statement
hi def link rbrowserNumeric	Number
hi def link rbrowserCharacter	String
hi def link rbrowserFactor	Special
hi def link rbrowserList	Type
hi def link rbrowserLogical	Boolean
hi def link rbrowserFunction	Function
hi def link rbrowserOpenTree	Comment
hi def link rbrowserClosedTr	Comment
hi def link rbrowserTreePart	Comment
hi def link rbrowserDelim	Ignore
hi def link rbrowserTab		Ignore
