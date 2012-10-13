" Vim completion script
" Language:    R
" Maintainer:  Jakson Alves de Aquino <jalvesaq@gmail.com>
"

fun! rcomplete#CompleteR(findstart, base)
  if &filetype == "rnoweb" && RnwIsInRCode() == 0 && exists("*LatexBox_Complete")
      let texbegin = LatexBox_Complete(a:findstart, a:base)
      return texbegin
  endif
  if a:findstart
    return match(getline('.')[: (col('.') - 2)], '[[:alnum:].\\]\+$')
  else
    if b:needsnewomnilist == 1
      call BuildROmniList("GlobalEnv", "")
    endif
    let res = []
    if strlen(a:base) == 0
      return res
    endif

    if len(g:rplugin_liblist) == 0
        call add(res, {'word': a:base, 'menu': " [ List is empty. Run  :RUpdateObjList ]"})
    endif

    let flines = g:rplugin_liblist + g:rplugin_globalenvlines
    " The char '$' at the end of 'a:base' is treated as end of line, and
    " the pattern is never found in 'line'.
    let newbase = '^' . substitute(a:base, "\\$$", "", "")
    for line in flines
      if line =~ newbase
        " Skip cols of data frames unless the user is really looking for them.
        if a:base !~ '\$' && line =~ '\$'
            continue
        endif
        let tmp1 = split(line, "\x06", 1)
        let info = tmp1[4]
        let info = substitute(info, "\t", ", ", "g")
        let info = substitute(info, "\x07", " = ", "g")
	let tmp2 = {'word': tmp1[0], 'menu': tmp1[1] . ' ' . tmp1[3], 'info': info}
	call add(res, tmp2)
      endif
    endfor

    " When we use R to get the completions based on the running evironment we
    " miss information stored on the omnils file: class of object and its
    " package.
    "    if len(g:rplugin_liblist) == 0 && len(res) == 0
    "        exe 'Py SendToR("utils:::.win32consoleCompletion(' . "'" . a:base . "', " . strlen(a:base) . ')$comps")'
    "        if strlen(g:rplugin_lastrpl) > 0
    "            let res = split(g:rplugin_lastrpl)
    "        endif
    "    endif

    return res
  endif
endfun

set completefunc=CompleteR

