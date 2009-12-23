" Vim completion script
" Language:	R
" Maintainer:	Jakson Alves de Aquino <jalvesaq@gmail.com>
" Last Change:	2009 May 01
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
    if b:needsnewtags == 1
      call BuildRTags("GlobalEnv")
    endif
    let res = []
    if strlen(a:base) == 0
      return res
    endif
    let flines2 = readfile(b:rtagsfile)
    let flines = b:flines1 + flines2
    " The char '$' at the end of 'a:base' is treated as end of line, and
    " the pattern is never found in 'line'.
    let newbase = '^' . substitute(a:base, "\\$$", "", "")
    for line in flines
      if line =~ newbase
        " Skip cols of data frames unless the user is really looking for them.
        if a:base !~ '\$' && line =~ '\$'
          continue
        endif
	"let tmp1 = split(line)
	"let tmp2 = {'word': tmp1[0], 'menu': tmp1[1] . ' ' . tmp1[2]}
	let tmp1 = split(line,':')
	let tmp2 = {'word': tmp1[0], 'menu': tmp1[1] . ' ' . tmp1[2], 'info': tmp1[3]}
	call add(res, tmp2)
      endif
    endfor
    return res
  endif
endfun

set completefunc=CompleteR

