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
" Last Change: Sun Oct 24, 2010  06:25PM
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
set winfixwidth

" Popup menu
if !exists("g:rplugin_hasbrowsermenu")
  let g:rplugin_hasbrowsermenu = 0
endif

" Current cursor position in the object browser and in the library browser
let g:rplugin_curbline = 1
let g:rplugin_curbcol = 0
let g:rplugin_curlline = 1
let g:rplugin_curlcol = 0

" Current view of the object browser: .GlobalEnv X loaded libraries
let g:rplugin_curview = "GlobalEnv"

" The list of objects in R's workspace is a dictionary. Each key in the
" dictionary is a dictionary with at least the key 'class'. If the class is
" "list", it will have the key 'items' (which lists the elements of the list).
let b:workspace = {}

" Dictionary storing flags indicating whether the elements of an R's list
" must be shown in the object browser. By default, "data.frame" objects are
" included in the dictionary with the flag 1, but other list objects are
" inserted in the dictionary with the flag 0.
if !exists("g:rplugin_opendict")
  let g:rplugin_opendict = {}
endif

" Dictionary storing the order of the elements in a list. This is necessary
" because Vim's dictionary stores the items in an "arbitrary" order.
let b:list_order = {}

let b:liblist = []

function! RBrowserMakeLibDict()
  let b:libdict = {}
  let b:nobjs = len(g:rplugin_liblist)
  let i = 0
  let obj = split(g:rplugin_liblist[i], ':')
  while i < b:nobjs
    let curlib = obj[2]
    let haslib = 0
    for lib in b:liblist
      if lib == obj[2]
	let haslib = 1
	let b:libdict[obj[2]] = {'class': "library", 'items': {}}
	while curlib == obj[2]
	  if stridx(obj[0], "$") == -1
	    let b:libdict[obj[2]]['items'][obj[0]] = {'class': obj[1]}
	  endif
	  let i += 1
	  if i == b:nobjs
	    break
	  endif
	  let obj = split(g:rplugin_liblist[i], ':')
	endwhile
	break
      endif
    endfor
    if haslib == 0
      while curlib == obj[2]
	let i += 1
	if i == b:nobjs
	  break
	endif
	let obj = split(g:rplugin_liblist[i], ':')
      endwhile
    endif
  endwhile
endfunction

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
  elseif cls == "function" || cls == "standardGeneric"
    let line = a:prefix . '(' . a:key . '	'
  elseif cls == "logical"
    let line = a:prefix . '%' . a:key . '	'
  elseif cls == "library"
    let line = a:prefix . '#' . a:key . '	'
  elseif cls == "flow-control"
    let line = a:prefix . '!' . a:key . '	'
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
  if (g:rplugin_curview == "GlobalEnv" && (cls == "data.frame" || cls == "list")) || cls == "library"
    let whattodo = "addkey"
    for i in keys(g:rplugin_opendict)
      if i == a:key
	if g:rplugin_opendict[a:key] == 0
	  return
	else
	  let whattodo = "show elements"
	endif
      endif
    endfor
    if whattodo == "addkey"
      if cls == "data.frame"
	let g:rplugin_opendict[a:key] = g:vimrplugin_open_df
      else
	let g:rplugin_opendict[a:key] = g:vimrplugin_open_list
      endif
    endif
    if g:rplugin_opendict[a:key] == 0
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
    if cls == "library"
      let thesubkeys = sort(keys(g:rplugin_curdict))
    else
      let s:curlist = s:curlist . "-" . a:key
      let thesubkeys = b:list_order[s:curlist]
    endif
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

function! RBrowserShowGE(fromother)
  let g:rplugin_curview = "GlobalEnv"
  set modifiable
  if a:fromother == 0
    let g:rplugin_curbline = line(".")
    let g:rplugin_curbcol = col(".")
  endif
  sil normal! ggdG
  if g:vimrplugin_objbr_w > 25
    call setline(1, ".GlobalEnv #|# libraries")
  else
    call setline(1, ".GlobalEnv")
  endif
  call setline(2, "")
  let thekeys = sort(keys(b:workspace))
  for key in thekeys
    let s:curlist = ""
    let g:rplugin_curdict = b:workspace
    call RBrowserMakeLine(key, "  ")
  endfor
  call cursor(g:rplugin_curbline, g:rplugin_curbcol)
  set nomodifiable
endfunction

function! RBrowserShowLibs(fromother)
  if !exists("b:libdict")
    call RBrowserMakeLibDict()
  endif
  let g:rplugin_curview = "libraries"
  set modifiable
  if a:fromother == 0
    let g:rplugin_curlline = line(".")
    let g:rplugin_curlcol = col(".")
  endif
  sil normal! ggdG
  if g:vimrplugin_objbr_w > 17
    call setline(1, "libraries #|# .GlobalEnv")
  else
    call setline(1, "Libraries")
  endif
  call setline(2, "")
  let thekeys = sort(keys(b:libdict))
  for key in thekeys
    let s:curlist = ""
    let g:rplugin_curdict = b:libdict
    call RBrowserMakeLine(key, "  ")
  endfor
  let hasmissing = 0
  call setline(line("$") + 1, "")
  for lib in b:liblist
    if search('#' . lib, "wn") == 0
      let hasmissing = 1
      call setline(line("$") + 1, lib . " not in the omnilist.")
    endif
  endfor
  if hasmissing
    call setline(line("$") + 1, "")
    call setline(line("$") + 1, "Please do:")
    call setline(line("$") + 1, "  :h :RUpdateObjList")
    call setline(line("$") + 1, "to know how to show all loaded")
    call setline(line("$") + 1, "libraries in the object browser.")
    normal! gqap
  endif
  call cursor(g:rplugin_curlline, g:rplugin_curlcol)
  set nomodifiable
endfunction

function! RBrowserFill()
  if g:rplugin_curview == "libraries"
    call RBrowserShowLibs(0)
  else
    call RBrowserShowGE(0)
  endif
  echon
endfunction

function! RBrowserDoubleClick()
  " Toggle view: Objects in the workspace X List of libraries
  if line(".") == 1
    if g:rplugin_curview == "libraries"
      call RBrowserShowGE(1)
    else
      call RBrowserShowLibs(1)
    endif
    return
  endif

  " Toggle state of list or data.frame: open X closed
  let key = expand("<cword>")
  for i in keys(g:rplugin_opendict)
    if i == key
      let g:rplugin_opendict[key] = !g:rplugin_opendict[key]
      if g:rplugin_curview == "libraries"
	call RBrowserShowLibs(0)
      else
	call RBrowserShowGE(0)
      endif
      break
    endif
  endfor
  echon
endfunction

function! RBrowserRightClick()
  if line(".") == 1
    return
  endif

  let key = RBrowserGetName()
  if key != ""
    if g:rplugin_hasbrowsermenu == 1
      aunmenu ]RBrowser
    endif
    exe 'amenu ]RBrowser.args('. key . ') :call rplugin#RAction("args")<CR>'
    exe 'amenu ]RBrowser.example('. key . ') :call rplugin#RAction("example")<CR>'
    exe 'amenu ]RBrowser.help('. key . ') :call rplugin#RAction("help")<CR>'
    exe 'amenu ]RBrowser.names('. key . ') :call rplugin#RAction("names")<CR>'
    exe 'amenu ]RBrowser.plot('. key . ') :call rplugin#RAction("plot")<CR>'
    exe 'amenu ]RBrowser.print(' . key . ') :call rplugin#RAction("print")<CR>'
    exe 'amenu ]RBrowser.str('. key . ') :call rplugin#RAction("str")<CR>'
    exe 'amenu ]RBrowser.summary('. key . ') :call rplugin#RAction("summary")<CR>'
    popup ]RBrowser
    let g:rplugin_hasbrowsermenu = 1
  endif
endfunction

function! RBrowserFindParent(word, curline, curpos)
  let curline = a:curline
  let curpos = a:curpos
  while curline > 1 && curpos >= a:curpos
    let curline -= 1
    let line = substitute(getline(curline), "	.*", "", "")
    let curpos = stridx(line, '[')
    if curpos == -1
      let curpos = a:curpos
    endif
  endwhile

  if curline > 1
    let word = substitute(line, '.*[', "", "") . '$' . a:word
    if curpos != 2
      let word = RBrowserFindParent(word, line("."), curpos)
    endif
    return word
  else
    " Didn't find the parent: should never happen.
    let msg = "R-plugin Error: " . a:word . ":" . curline
    echoerr msg
  endif
  return ""
endfunction

function! RBrowserGetName()
  let curpos = col(".")
  let tabpos = stridx(getline("."), "	")
  if curpos > tabpos
    echo tabpos . "::" . curpos
    sleep 1
    return
  endif
  let word = expand("<cword>")

  if g:rplugin_curview == "libraries"
    " There is no parent list or data.frame to find
    return word
  endif

  " Is the object a top level one (curpos == 2)?
  let line = getline(".")
  let delim = ['{', '[', '(', '"', "'", '%']
  for i in delim
    let curpos = stridx(line, i)
    if curpos != -1
      break
    endif
  endfor

  if curpos == 2
    " top level object
    return word
  else
    if curpos > 2
      " Find the parent data.frame or list
      let word = RBrowserFindParent(word, line("."), curpos)
      return word
    else
      " Wrong object name delimiter: should never happen.
      let msg = "R-plugin Error: " . curpos
      echoerr msg
      return ""
    endif
  endif
endfunction

function! MakeRBrowserMenu()
  if g:rplugin_hasmenu == 1
    return
  endif
  " Do not translate "File":
  menutranslate clear
  call rplugin#ControlMenu()
  let g:rplugin_hasmenu = 1
endfunction

function! UnMakeRBrowserMenu()
  if g:rplugin_curview == "libraries"
    let g:rplugin_curlline = line(".")
    let g:rplugin_curlcol = col(".")
  else
    let g:rplugin_curbline = line(".")
    let g:rplugin_curbcol = col(".")
  endif
  if exists("g:rplugin_hasmenu") && g:rplugin_hasmenu == 0
    return
  endif
  if g:vimrplugin_never_unmake_menu == 1
    return
  endif
  if &previewwindow			" don't do this in the preview window
    return
  endif
  aunmenu R
  let g:rplugin_hasmenu = 0
endfunction

nmap <buffer> <CR> :call RBrowserDoubleClick()<CR>
nmap <buffer> <2-LeftMouse> :call RBrowserDoubleClick()<CR>
nmap <buffer> <RightMouse> :call RBrowserRightClick()<CR>

"----------------------------------------------------------------------------
" ***Control***
"----------------------------------------------------------------------------
" List space, clear console, clear all
"-------------------------------------
call rplugin#RCreateMaps("nvi", '<Plug>RListSpace',    'rl', ':call SendCmdToScreen("ls()", 0)<CR>:echon')
call rplugin#RCreateMaps("nvi", '<Plug>RClearConsole', 'rr', ':call RClearConsole()')
call rplugin#RCreateMaps("nvi", '<Plug>RClearAll',     'rm', ':call RClearAll()')

" Print, names, structure
"-------------------------------------
call rplugin#RCreateMaps("nvi", '<Plug>RObjectPr',     'rp', ':call rplugin#RAction("print")')
call rplugin#RCreateMaps("nvi", '<Plug>RObjectNames',  'rn', ':call rplugin#RAction("names")')
call rplugin#RCreateMaps("nvi", '<Plug>RObjectStr',    'rt', ':call rplugin#RAction("str")')

" Arguments, example, help
"-------------------------------------
call rplugin#RCreateMaps("nvi", '<Plug>RShowArgs',     'ra', ':call rplugin#RAction("args")')
call rplugin#RCreateMaps("nvi", '<Plug>RShowEx',       're', ':call rplugin#RAction("example")')
call rplugin#RCreateMaps("nvi", '<Plug>RHelp',         'rh', ':call rplugin#RAction("help")')

" Summary, plot, both
"-------------------------------------
call rplugin#RCreateMaps("nvi", '<Plug>RSummary',      'rs', ':call rplugin#RAction("summary")')
call rplugin#RCreateMaps("nvi", '<Plug>RPlot',         'rg', ':call rplugin#RAction("plot")')
call rplugin#RCreateMaps("nvi", '<Plug>RSPlot',        'rb', ':call rplugin#RAction("plot")<CR>:call rplugin#RAction("summary")')

augroup VimRPluginObjBrowser
  au BufEnter * if &filetype == "rbrowser" | call MakeRBrowserMenu() | endif
  au BufLeave * if &filetype == "rbrowser" | call UnMakeRBrowserMenu() | endif
augroup END

