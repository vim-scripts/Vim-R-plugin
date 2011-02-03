" Vim completion script
" Language:    R
" Maintainer:  Jakson Alves de Aquino <jalvesaq@gmail.com>
" Last Change: Tue Jan 18, 2011  10:11AM
"

fun! rcomplete#CompleteR(findstart, base)
  if a:findstart
    " locate the start of the word
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && (line[start - 1] =~ '\a' || line[start - 1] =~ '\.' || line[start - 1] =~ '\$' || line[start - 1] =~ '\d')
      let start -= 1
    endwhile
    return start
  else
    if b:needsnewomnilist == 1
      call BuildROmniList("GlobalEnv", "none")
    endif
    let res = []
    if strlen(a:base) == 0
      return res
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
	let tmp1 = split(line, ';')
	if len(tmp1) == 5
	  let info = tmp1[4]
	else
	  let tlen = len(tmp1)
	  let info = tmp1[4]
	  let i = 5
	  while i < tlen
	    let info = info . ';' . tmp1[i]
	    let i += 1
	  endwhile
	endif
	let info = substitute(info, "\t", "\n", "g")
	let tmp2 = {'word': tmp1[0], 'menu': tmp1[1] . ' ' . tmp1[3], 'info': info}
	call add(res, tmp2)
      endif
    endfor
    return res
  endif
endfun

set completefunc=CompleteR

