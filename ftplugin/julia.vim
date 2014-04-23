" Vim filetype plugin file
" Language: Julia
" Maintainer: Johannes Degn <j@degn.de>
" Last Change:	Tue April 8, 2014  03:40PM

" Only do this when not yet done for this buffer
if exists("b:did_ftplugin")
  finish
endif

" Don't load another plugin for this buffer
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

setlocal iskeyword=@,48-57,_,.
setlocal formatoptions-=t
setlocal commentstring=#\ %s
setlocal comments=:#',:###,:##,:#

if has("gui_win32") && !exists("b:browsefilter")
  let b:browsefilter = "Julia Source Files (*.jl)\t*.jl\n"
endif

let b:undo_ftplugin = "setl cms< com< fo< isk< | unlet! b:browsefilter"

let &cpo = s:cpo_save
unlet s:cpo_save
