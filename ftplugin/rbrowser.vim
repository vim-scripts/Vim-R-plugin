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
" ftplugin for RBrowser files (created by the Vim-R-plugin)
"
" Authors: Jakson Alves de Aquino <jalvesaq@gmail.com>
"          
" Last Change: Sat Oct 16, 2010  01:28PM
"==========================================================================

" Only do this when not yet done for this buffer
if exists("b:did_ftplugin")
  finish
endif

" Don't load another plugin for this buffer
let b:did_ftplugin = 1

setlocal noswapfile
set buftype=nofile
set nowrap

" The list of objects in R's workspace is a dictionary. Each key in the
" dictionary is a dictionary with at least the key 'class'. If the class is
" "list", it will have the key 'items' (which lists the elements of the list).
let b:workspace = {}

" Dictionary storing flags indicating whether the elements of an R's list
" must be shown in the object browser. By default, "data.frame" objects are
" included in the dictionary with the flag 1, but other list objects are
" inserted in the dictionary with the flag 0.
if !exists("g:rplugin_openlist")
  let g:rplugin_openlist = {}
endif

" Dictionary storing the order of the elements in a list. This is necessary
" because Vim's dictionary stores the items in an "arbitrary" order.
let b:list_order = {}

function! RBrowserMakeLine(key, prefix)
  exe "let curkey = g:rplugin_curdict['" . a:key . "']"
  let cls = curkey['class']
  if cls == "data.frame" || cls == "list"
    let line = a:prefix . '[' . a:key . '	'
  elseif cls == "numeric"
    let line = a:prefix . '{' . a:key . '	'
  elseif cls == "character"
    let line = a:prefix . '"' . a:key . '	'
  elseif cls == "factor"
    let line = a:prefix . "'" . a:key . '	'
  elseif cls == "function"
    let line = a:prefix . '(' . a:key . '	'
  elseif cls == "logical"
    let line = a:prefix . '%' . a:key . '	'
  else
    let line = a:prefix . ' ' . a:key . '	'
  endif

  " If the object's label exists, then append it to the end of the line
  let thekeys = keys(curkey)
  for subkey in thekeys
    if subkey == "label"
      let line = line . curkey['label']
    endif
  endfor
  let lnr = line("$") + 1
  call setline(lnr, line)

  " If the object is a data.frame, show its columns
  if cls == "data.frame" || cls == "list"
    let whattodo = "addkey"
    for i in keys(g:rplugin_openlist)
      if i == a:key
	if g:rplugin_openlist[a:key] == 0
	  return
	else
	  let whattodo = "show elements"
	endif
      endif
    endfor
    if whattodo == "addkey"
      if cls == "data.frame"
	let g:rplugin_openlist[a:key] = g:vimrplugin_open_df
      else
	let g:rplugin_openlist[a:key] = g:vimrplugin_open_list
      endif
    endif
    if g:rplugin_openlist[a:key] == 0
      return
    endif

    if v:lang =~ "UTF-8"
      let strL = " └─"
      let strT = " ├─"
      let strI = " │ "
    else
      let strL = " `-"
      let strT = " |-"
      let strI = " | "
    endif

    if a:prefix =~ strL
      let newprefix = substitute(a:prefix, strL, "   ", "")
    else
      let newprefix = substitute(a:prefix, strT, strI, "") 
    endif
    let newprefix = newprefix . strT
    let olddict = g:rplugin_curdict
    let g:rplugin_curdict = curkey['items']
    let s:curlist = s:curlist . "-" . a:key
    let thesubkeys = b:list_order[s:curlist]
    let nkeys = len(thesubkeys)
    let i = 0
    for key in thesubkeys
      let i += 1
      if i < nkeys
	call RBrowserMakeLine(key, newprefix)
      else
	let newprefix = substitute(newprefix, strT, strL, "")
	call RBrowserMakeLine(key, newprefix)
      endif
    endfor
    let g:rplugin_curdict = olddict
  endif
endfunction

function! RBrowserFill()
  let curline = line(".")
  let curcol = col(".")
  sil normal! ggdG
  call setline(1, "Objects in the Workspace")
  call setline(2, "")
  let thekeys = sort(keys(b:workspace))
  for key in thekeys
    let s:curlist = ""
    let g:rplugin_curdict = b:workspace
    call RBrowserMakeLine(key, "  ")
  endfor
  call cursor(curline, curcol)
endfunction

function! RBrowserToogleValue()
  let key = expand("<cword>")
  for i in keys(g:rplugin_openlist)
    if i == key
      let g:rplugin_openlist[key] = !g:rplugin_openlist[key]
      call RBrowserFill()
      break
    endif
  endfor
  echon
endfunction

nmap <buffer> <CR> :call RBrowserToogleValue()<CR>
nmap <buffer> <2-LeftMouse> :call RBrowserToogleValue()<CR>
