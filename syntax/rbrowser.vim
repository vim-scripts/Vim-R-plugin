" Vim syntax file
" Language:	Object browser of Vim-R-plugin
" Maintainer:	Jakson Alves de Aquino (jalvesaq@gmail.com)
" Last Change:	Sun Oct 24, 2010  07:05AM

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
syn match rbrowserLibrary	"#.*	" contains=rbrowserDelim,rbrowserTab
syn match rbrowserRepeat	"!.*	" contains=rbrowserDelim,rbrowserTab
syn match rbrowserEnv		"^.GlobalEnv$"
syn match rbrowserEnv		"^Libraries$"
syn match rbrowserEnv		"^.GlobalEnv #" contains=rbrowserDelim
syn match rbrowserEnv		"^libraries #" contains=rbrowserDelim
syn match rbrowserLink		"# libraries$" contains=rbrowserDelim
syn match rbrowserLink		"# .GlobalEnv$" contains=rbrowserDelim
syn match rbrowserWarn		".* not in the omnilist."
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
syn match rbrowserDelim contained /'\|"\|(\|\[\|{\|%\|#\|!/

hi def link rbrowserEnv		Statement
hi def link rbrowserNumeric	Number
hi def link rbrowserCharacter	String
hi def link rbrowserFactor	Special
hi def link rbrowserList	Type
hi def link rbrowserLibrary	PreProc
hi def link rbrowserLink	Comment
hi def link rbrowserLogical	Boolean
hi def link rbrowserFunction	Function
hi def link rbrowserRepeat	Repeat
hi def link rbrowserWarn	WarningMsg
hi def link rbrowserTreePart	Comment
hi def link rbrowserDelim	Ignore
hi def link rbrowserTab		Ignore
