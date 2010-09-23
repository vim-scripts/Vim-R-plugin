"  This program is free software; you can redistribute it and/or modify
"  it under the terms of the GNU General Public License as published by
"  the Free Software Foundation; either version 2 of the License, or
"  (at your option) any later version.
"
"  This program is distributed in the hope that it will be useful,
"  but WITHOUT ANY WARRANTY; without even the implied warranty of
"  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"  GNU General Public License for more details.
"
"  A copy of the GNU General Public License is available at
"  http://www.r-project.org/Licenses/

"==========================================================================
" ftplugin for R files
"
" Authors: Jakson Alves de Aquino <jalvesaq@gmail.com>
"          Jose Claudio Faria
"          
"          Based on previous work by Johannes Ranke
"
" Last Change: Mon Sep 20, 2010  06:29PM
"
" Please see doc/r-plugin.txt for usage details.
"==========================================================================


" Show R's help doc in Vim's buffer
" (based  on pydoc plugin)
function! rplugin#ShowRDoc()
  let i = 0
  while !filereadable(g:vimrplugin_docfile) && i < 20
    sleep 100m
    let i += 1
  endwhile
  if i == 20
    echohl WarningMsg
    echomsg "Waited too much time..."
    echohl Normal
    return
  endif
  if bufloaded("R_doc")
    execute "sb R_doc"
  else
    if exists("b:vimjspath")
      let g:vimjspath_tmp = b:vimjspath
    endif
    if exists("b:screensname")
      let g:screensname_tmp = b:screensname
    endif
    if g:vimrplugin_vimpager == "vertical" || (g:vimrplugin_vimpager == "smart" && winwidth(0) > (72 + g:vimrplugin_editor_w))
      let l:sr = &splitright
      set splitright
      execute '72vsplit R_doc'
      let &splitright = l:sr
    elseif g:vimrplugin_vimpager == "horizontal" || g:vimrplugin_vimpager == "smart"
      execute 'split R_doc'
      if winheight(0) < 20
	resize 20
      endif
    elseif g:vimrplugin_vimpager == "tab"
      execute 'tabnew R_doc'
    else
      echohl WarningMsg
      echomsg "Invalid vimrplugin_vimpager value: '" . g:vimrplugin_vimpager . "'"
      echohl Normal
      return
    endif
    if exists("g:vimjspath_tmp")
      let b:vimjspath = g:vimjspath_tmp
      unlet g:vimjspath_tmp
    endif
    if exists("g:screensname_tmp")
      let b:screensname = g:screensname_tmp
      unlet g:screensname_tmp
    endif
    if winwidth(0) <= 72
      exe "normal! 72\<C-W>|"
    endif
  endif
  setlocal noswapfile
  set buftype=nofile
  setlocal modifiable
  normal! ggdG
  exe "silent read " . g:vimrplugin_docfile
  exe "silent %s/_//g"
  let has_ex = search("^Examples:$")
  if has_ex
    call cursor(line("$"), 1)
    let savereg = @@
    let @@ = '###'
    put
    let @@ = savereg
  endif
  setlocal nomodified
  set filetype=rdoc
  normal! ggdd
endfunction

" Call R functions for the word under cursor
function! rplugin#RAction(rcmd)
  echon
  let rkeyword = RGetKeyWord()
  if strlen(rkeyword) > 0
    if a:rcmd == "help"
      if g:vimrplugin_vimpager != "no"
	if filewritable(g:vimrplugin_docfile)
	  call delete(g:vimrplugin_docfile)
	endif
      endif
      call SendCmdToScreen("help(" . rkeyword . ")")
      if g:vimrplugin_vimpager != "no"
	call rplugin#ShowRDoc()
      endif
      return
    endif
    let rfun = a:rcmd
    if a:rcmd == "args" && g:vimrplugin_listmethods == 1
      let rfun = ".vim.list.args"
    endif
    if a:rcmd == "plot" && g:vimrplugin_specialplot == 1
      let rfun = ".vim.plot"
    endif
    let raction = rfun . "(" . rkeyword . ")"
    let ok = SendCmdToScreen(raction)
    if ok == 0
      return
    endif
  endif
endfunction

