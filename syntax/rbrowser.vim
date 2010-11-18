" Vim syntax file
" Language:	Object browser of Vim-R-plugin
" Maintainer:	Jakson Alves de Aquino (jalvesaq@gmail.com)
" Last Change:	Wed Nov 10, 2010  06:58PM

if exists("b:current_syntax")
  finish
endif
scriptencoding utf-8

setlocal iskeyword=@,48-57,_,.

if has("conceal")
  setlocal conceallevel=2
  setlocal concealcursor=nvc
  syn match rbrowserNumeric	"{#.*	" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserCharacter	/"#.*	/ contains=rbrowserDelim,rbrowserTab
  syn match rbrowserFactor	"'#.*	" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserFunction	"(#.*	" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserList	"\[#.*	" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserLogical	"%#.*	" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserLibrary	"##.*	" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserRepeat	"!#.*	" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserUnknown	"=#.*	" contains=rbrowserDelim,rbrowserTab
else
  syn match rbrowserNumeric	"{.*	" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserCharacter	/".*	/ contains=rbrowserDelim,rbrowserTab
  syn match rbrowserFactor	"'.*	" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserFunction	"(.*	" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserList		"\[.*	" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserLogical	"%.*	" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserLibrary	"#.*	" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserRepeat	"!.*	" contains=rbrowserDelim,rbrowserTab
  syn match rbrowserUnknown	"=.*	" contains=rbrowserDelim,rbrowserTab
endif
syn match rbrowserEnv		"^.GlobalEnv "
syn match rbrowserEnv		"^Libraries "
syn match rbrowserLink		" Libraries$"
syn match rbrowserLink		" .GlobalEnv$"
syn match rbrowserWarn		"^Warning:"
syn match rbrowserWarn		"^The following"
syn match rbrowserWarn		"^library is loaded"
syn match rbrowserWarn		"^but is not in the"
syn match rbrowserWarn		"^libraries are loaded"
syn match rbrowserWarn		"^but are not in the"
syn match rbrowserWarn		"^omniList:"
syn match rbrowserTreePart	"├─"
syn match rbrowserTreePart	"└─"
syn match rbrowserTreePart	"│" 
if &encoding != "utf-8"
  syn match rbrowserTreePart	"|" 
  syn match rbrowserTreePart	"`-"
  syn match rbrowserTreePart	"|-"
endif

syn match rbrowserTab contained "	"
if has("conceal")
  syn match rbrowserDelim contained /'#\|"#\|(#\|\[#\|{#\|%#\|##\|!#\|=#/ conceal
else
  syn match rbrowserDelim contained /'\|"\|(\|\[\|{\|%\|#\|!\|=/
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
hi def link rbrowserRepeat	Repeat
hi def link rbrowserUnknown	Normal
hi def link rbrowserWarn	WarningMsg
hi def link rbrowserTreePart	Comment
hi def link rbrowserDelim	Ignore
hi def link rbrowserTab		Ignore

