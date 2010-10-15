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
" Last Change: Tue Oct 12, 2010  08:34AM
"
" Please see doc/r-plugin.txt for usage details.
"==========================================================================

function! s:SetRTextWidth()
  " Store the default values of some R options
  if !exists("g:RHelpType")
    let roptionsfile = g:rplugin_docfile . "Roptions"
    let rlockfile = g:rplugin_docfile . "Rlock"
    if filereadable(roptionsfile)
      call delete(roptionsfile)
    endif
    call writefile(['Wait!'], rlockfile)
    call SendCmdToScreen("sink('" . roptionsfile . "')", 1)
    call SendCmdToScreen('cat(paste(options("pager"), "\n", options("help_type"), "\n", options("help_text_width"), "\n", sep = ""))', 1)
    call SendCmdToScreen("sink()", 1)
    call SendCmdToScreen("unlink('" . rlockfile . "')", 1)
    let i = 0
    while filereadable(rlockfile) && i < 20
      sleep 100m
      let i += 1
    endwhile
    sleep 100m
    if i == 20 && !filereadable(roptionsfile)
      echohl WarningMsg
      echomsg "Error setting help options!"
      echohl Normal
      sleep 2
      return
    endif
    sleep 100m
    let [g:RPager, g:RHelpType, g:RHelpTextWidth] = readfile(roptionsfile)
    if g:RPager != "NULL"
      let g:RPager = "'" . g:RPager . "'"
    endif
    if g:RHelpType != "NULL"
      let g:RHelpType = "'" . g:RHelpType . "'"
    endif
  endif

  if !bufloaded(s:rdoctitle) || g:vimrplugin_newsize == 1
    " Bug fix for Vim < 7.2.318
    let curlang = v:lang
    language C


    let g:vimrplugin_newsize = 0

    " s:vimpager is used to calculate the width of the R help documentation
    " and to decide whether to obey vimrplugin_vimpager = 'vertical'
    let s:vimpager = g:vimrplugin_vimpager

    let wwidth = winwidth(0)
    if wwidth <= (g:vimrplugin_help_w + g:vimrplugin_editor_w)
      let s:vimpager = "horizontal"
    endif

    if g:vimrplugin_vimpager == "tab" || g:vimrplugin_vimpager == "tabnew"
      let s:vimpager = "horizontal"
    endif

    if s:vimpager != "vertical"
      "Default help_text_width:
      let htwf = (wwidth > 80) ? 88.1 : ((wwidth - 1) / 0.9)
    else
      " Not enough room to split vertically

      let min_e = (g:vimrplugin_editor_w > 80) ? g:vimrplugin_editor_w : 80
      let min_h = (g:vimrplugin_help_w > 73) ? g:vimrplugin_help_w : 73

      if wwidth > (min_e + min_h)
	" The editor window is large enough to be splitted as either >80+73 or
	" the user defined minimum values
	let s:hwidth = min_h
      elseif wwidth > (min_e + g:vimrplugin_help_w)
	" The help window must have less than min_h columns
	let s:hwidth = wwidth - min_e
      else
	" The help window must have the minimum value
	let s:hwidth = g:vimrplugin_help_w
      endif
      let htwf = (s:hwidth - 1) / 0.9
    endif
    let htw = printf("%f", htwf)
    let g:rplugin_htw = substitute(htw, "\\..*", "", "")
    exe "language " . curlang
  endif

  call SendCmdToScreen("options(help_type = 'text', help_text_width = " . g:rplugin_htw . ", pager = 'cat > " . g:rplugin_docfile . "')", 1)
endfunction

" Show R's help doc in Vim's buffer
" (based  on pydoc plugin)
function! rplugin#ShowRDoc(rkeyword)
  if filewritable(g:rplugin_docfile)
    call delete(g:rplugin_docfile)
  endif

  if g:vimrplugin_vimpager == "tabnew"
    let s:rdoctitle = a:rkeyword . "\\ -\\ help" 
  else
    let s:rdoctitle = "R_doc"
  endif

  call s:SetRTextWidth()

  call SendCmdToScreen("help(" . a:rkeyword . ")", 1)

  " Reset default R options
  call SendCmdToScreen("options(help_type = " . g:RHelpType . ", help_text_width = " . g:RHelpTextWidth . ", pager = " . g:RPager . ")", 1)

  let i = 0
  while !filereadable(g:rplugin_docfile) && i < 20
    sleep 100m
    let i += 1
  endwhile
  if i == 20
    echohl WarningMsg
    echomsg "Waited too much time..."
    echohl Normal
    return
  endif

  if bufloaded(s:rdoctitle)
    let savesb = &switchbuf
    set switchbuf=useopen,usetab
    execute "sb ". s:rdoctitle
    exe "set switchbuf=" . savesb
  else
    if exists("b:vimjspath")
      let g:vimjspath_tmp = b:vimjspath
    endif
    if exists("b:screensname")
      let g:screensname_tmp = b:screensname
    endif

    if g:vimrplugin_vimpager == "tab" || g:vimrplugin_vimpager == "tabnew"
      execute 'tabnew ' . s:rdoctitle
    elseif s:vimpager == "vertical"
      let l:sr = &splitright
      set splitright
      execute s:hwidth . 'vsplit ' . s:rdoctitle
      let &splitright = l:sr
    elseif s:vimpager == "horizontal"
      execute 'split ' . s:rdoctitle
      if winheight(0) < 20
	resize 20
      endif
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
  endif

  setlocal noswapfile
  set buftype=nofile
  autocmd VimResized <buffer> let g:vimrplugin_newsize = 1
  setlocal modifiable
  normal! ggdG
  exe "silent read " . g:rplugin_docfile
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
	if filewritable(g:rplugin_docfile)
	  call delete(g:rplugin_docfile)
	endif
	call rplugin#ShowRDoc(rkeyword)
      else
	call SendCmdToScreen("help(" . rkeyword . ")", 0)
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
    let ok = SendCmdToScreen(raction, 0)
    if ok == 0
      return
    endif
  endif
endfunction

