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
" Last Change: Sat Oct 23, 2010  12:32PM
"
" Please see doc/r-plugin.txt for usage details.
"==========================================================================

function! s:SetRTextWidth()
  if !bufloaded(s:rdoctitle) || g:vimrplugin_newsize == 1
    " Bug fix for Vim < 7.2.318
    if !has("gui_win32")
      let curlang = v:lang
      language C
    endif

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
    if !has("gui_win32")
      exe "language " . curlang
    endif
  endif
endfunction

" Show R's help doc in Vim's buffer
" (based  on pydoc plugin)
function! rplugin#ShowRDoc(rkeyword)
  if filewritable(g:rplugin_docfile)
    call delete(g:rplugin_docfile)
  endif

  if bufname("%") == "Object_Browser"
    let savesb = &switchbuf
    set switchbuf=useopen,usetab
    exe "sb " . g:rplugin_curscriptbuf
    exe "set switchbuf=" . savesb
  endif

  if g:vimrplugin_vimpager == "tabnew"
    let s:rdoctitle = a:rkeyword . "\\ -\\ help" 
  else
    let s:rdoctitle = "R_doc"
  endif

  call s:SetRTextWidth()

  call writefile(['Wait...'], g:rplugin_docfile . "lock")
  call SendCmdToScreen("source('" . g:r_plugin_home . "/r-plugin/vimhelp.R') ; .vim.help('" . a:rkeyword . "', " . g:rplugin_htw . "L)", 0)
  sleep 50m

  let i = 0
  while filereadable(g:rplugin_docfile . "lock") && i < 40
    sleep 50m
    let i += 1
  endwhile
  if i == 40
    echohl WarningMsg
    echomsg "Waited too much time..."
    echohl Normal
    return
  endif

  if bufloaded(s:rdoctitle)
    let savesb = &switchbuf
    set switchbuf=useopen,usetab
    exe "sb ". s:rdoctitle
    exe "set switchbuf=" . savesb
  else
    if g:vimrplugin_vimpager == "tab" || g:vimrplugin_vimpager == "tabnew"
      exe 'tabnew ' . s:rdoctitle
    elseif s:vimpager == "vertical"
      let l:sr = &splitright
      set splitright
      exe s:hwidth . 'vsplit ' . s:rdoctitle
      let &splitright = l:sr
    elseif s:vimpager == "horizontal"
      exe 'split ' . s:rdoctitle
      if winheight(0) < 20
	resize 20
      endif
    else
      echohl WarningMsg
      echomsg "Invalid vimrplugin_vimpager value: '" . g:vimrplugin_vimpager . "'"
      echohl Normal
      return
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
    let lnr = line("$") + 1
    call setline(lnr, "###")
    let lnr = lnr + 1
    call setline(lnr, "")
  endif
  setlocal nomodified
  set filetype=rdoc
  normal! ggdd

endfunction

" Call R functions for the word under cursor
function! rplugin#RAction(rcmd)
  echon
  if &filetype == "rbrowser"
    let rkeyword = RBrowserGetName()
  else
    let rkeyword = RGetKeyWord()
  endif
  if strlen(rkeyword) > 0
    if a:rcmd == "help"
      if g:vimrplugin_vimpager != "no"
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

if exists('g:maplocalleader')
  let s:tll = '<Tab>' . g:maplocalleader
else
  let s:tll = '<Tab>\\'
endif

redir => s:ikblist
silent imap
redir END
redir => s:nkblist
silent nmap
redir END
redir => s:vkblist
silent vmap
redir END
let s:iskblist = split(s:ikblist, "\n")
let s:nskblist = split(s:nkblist, "\n")
let s:vskblist = split(s:vkblist, "\n")
let s:imaplist = []
let s:vmaplist = []
let s:nmaplist = []
for i in s:iskblist
  let si = split(i)
  if len(si) == 3 && si[2] =~ "<Plug>R"
      call add(s:imaplist, [si[1], si[2]])
  endif
endfor
for i in s:nskblist
  let si = split(i)
  if len(si) == 3 && si[2] =~ "<Plug>R"
      call add(s:nmaplist, [si[1], si[2]])
  endif
endfor
for i in s:vskblist
  let si = split(i)
  if len(si) == 3 && si[2] =~ "<Plug>R"
      call add(s:vmaplist, [si[1], si[2]])
  endif
endfor
unlet s:ikblist
unlet s:nkblist
unlet s:vkblist
unlet s:iskblist
unlet s:nskblist
unlet s:vskblist
unlet i
unlet si

function! RNMapCmd(plug)
  for [el1, el2] in s:nmaplist
    if el2 == a:plug
      return el1
    endif
  endfor
endfunction

function! RIMapCmd(plug)
  for [el1, el2] in s:imaplist
    if el2 == a:plug
      return el1
    endif
  endfor
endfunction

function! RVMapCmd(plug)
  for [el1, el2] in s:vmaplist
    if el2 == a:plug
      return el1
    endif
  endfor
endfunction

function! rplugin#RCreateMenuItem(type, label, plug, combo, target)
  if a:type =~ '0'
    let tg = a:target . '<CR>0'
    let il = 'i'
  else
    let tg = a:target . '<CR>'
    let il = 'a'
  endif
  if a:type =~ "n"
    if hasmapto(a:plug, "n")
      let boundkey = RNMapCmd(a:plug)
      exec 'nmenu &R.' . a:label . '<Tab>' . boundkey . ' ' . tg
    else
      exec 'nmenu &R.' . a:label . s:tll . a:combo . ' ' . tg
    endif
  endif
  if a:type =~ "v"
    if hasmapto(a:plug, "v")
      let boundkey = RVMapCmd(a:plug)
      exec 'vmenu &R.' . a:label . '<Tab>' . boundkey . ' ' . tg
    else
      exec 'vmenu &R.' . a:label . s:tll . a:combo . ' ' . '<Esc>' . tg
    endif
  endif
  if a:type =~ "i"
    if hasmapto(a:plug, "i")
      let boundkey = RIMapCmd(a:plug)
      exec 'imenu &R.' . a:label . '<Tab>' . boundkey . ' ' . tg
    else
      exec 'imenu &R.' . a:label . s:tll . a:combo . ' ' . '<Esc>' . tg . il
    endif
  endif
endfunction

function! rplugin#ControlMenu()
  call rplugin#RCreateMenuItem("nvi", 'Control.List\ space', '<Plug>RListSpace', 'rl', ':call SendCmdToScreen("ls()", 0)')
  call rplugin#RCreateMenuItem("nvi", 'Control.Clear\ console\ screen', '<Plug>RClearConsole', 'rr', ':call RClearConsole()')
  call rplugin#RCreateMenuItem("nvi", 'Control.Clear\ all', '<Plug>RClearAll', 'rm', ':call RClearAll()')
  "-------------------------------
  menu R.Control.-Sep1- <nul>
  call rplugin#RCreateMenuItem("nvi", 'Control.Object\ (print)', '<Plug>RObjectPr', 'rp', ':call rplugin#RAction("print")')
  call rplugin#RCreateMenuItem("nvi", 'Control.Object\ (names)', '<Plug>RObjectNames', 'rn', ':call rplugin#RAction("names")')
  call rplugin#RCreateMenuItem("nvi", 'Control.Object\ (str)', '<Plug>RObjectStr', 'rt', ':call rplugin#RAction("str")')
  "-------------------------------
  menu R.Control.-Sep2- <nul>
  call rplugin#RCreateMenuItem("nvi", 'Control.Arguments\ (cur)', '<Plug>RShowArgs', 'ra', ':call rplugin#RAction("args")')
  call rplugin#RCreateMenuItem("nvi", 'Control.Example\ (cur)', '<Plug>RShowEx', 're', ':call rplugin#RAction("example")')
  call rplugin#RCreateMenuItem("nvi", 'Control.Help\ (cur)', '<Plug>RHelp', 'rh', ':call rplugin#RAction("help")')
  "-------------------------------
  menu R.Control.-Sep3- <nul>
  call rplugin#RCreateMenuItem("nvi", 'Control.Summary\ (cur)', '<Plug>RSummary', 'rs', ':call rplugin#RAction("summary")')
  call rplugin#RCreateMenuItem("nvi", 'Control.Plot\ (cur)', '<Plug>RPlot', 'rg', ':call rplugin#RAction("plot")')
  call rplugin#RCreateMenuItem("nvi", 'Control.Plot\ and\ summary\ (cur)', '<Plug>RSPlot', 'rb', ':call rplugin#RAction("plot")<CR>:call rplugin#RAction("summary")')
endfunction


" For each noremap we need a vnoremap including <Esc> before the :call,
" otherwise vim will call the function as many times as the number of selected
" lines. If we put the <Esc> in the noremap, vim will bell.
" RCreateMaps Args:
"   type : modes to which create maps (normal, visual and insert) and whether
"          the cursor have to go the beginning of the line
"   plug : the <Plug>Name
"   combo: the combination of letter that make the shortcut
"   target: the command or function to be called
function! rplugin#RCreateMaps(type, plug, combo, target)
  if a:type =~ '0'
    let tg = a:target . '<CR>0'
    let il = 'i'
  else
    let tg = a:target . '<CR>'
    let il = 'a'
  endif
  if a:type =~ "n"
    if hasmapto(a:plug, "n")
      exec 'noremap <buffer> ' . a:plug . ' ' . tg
    else
      exec 'noremap <buffer> <LocalLeader>' . a:combo . ' ' . tg
    endif
  endif
  if a:type =~ "v"
    if hasmapto(a:plug, "v")
      exec 'vnoremap <buffer> ' . a:plug . ' <Esc>' . tg
    else
      exec 'vnoremap <buffer> <LocalLeader>' . a:combo . ' <Esc>' . tg
    endif
  endif
  if a:type =~ "i"
    if hasmapto(a:plug, "i")
      exec 'inoremap <buffer> ' . a:plug . ' <Esc>' . tg . il
    else
      exec 'inoremap <buffer> <LocalLeader>' . a:combo . ' <Esc>' . tg . il
    endif
  endif
endfunction

