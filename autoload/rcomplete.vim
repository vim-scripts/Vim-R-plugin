" Vim completion script
" Language:    R
" Maintainer:  Jakson Alves de Aquino <jalvesaq@gmail.com>
"

fun! rcomplete#CompleteR(findstart, base)
  if &filetype == "rnoweb" && RnwIsInRCode(0) == 0 && exists("*LatexBox_Complete")
      let texbegin = LatexBox_Complete(a:findstart, a:base)
      return texbegin
  endif
  if a:findstart
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && (line[start - 1] =~ '\w' || line[start - 1] =~ '\.' || line[start - 1] =~ '\$')
      let start -= 1
    endwhile
    return start
  else
    if string(g:SendCmdToR) != "function('SendCmdToR_fake')"
      call BuildROmniList()
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
        if g:vimrplugin_show_args
            let info = tmp1[4]
            let info = substitute(info, "\t", ", ", "g")
            let info = substitute(info, "\x07", " = ", "g")
            let tmp2 = {'word': tmp1[0], 'menu': tmp1[1] . ' ' . tmp1[3], 'info': info}
        else
            let tmp2 = {'word': tmp1[0], 'menu': tmp1[1] . ' ' . tmp1[3]}
        endif
	call add(res, tmp2)
      endif
    endfor

    return res
  endif
endfun

