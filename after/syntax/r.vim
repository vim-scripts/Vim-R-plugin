
" New line, carriage return, tab, bell, feed, backslash
syn match rSpecial display contained "\\\(n\|r\|t\|a\|f\|'\|\"\)\|\\\\"

" Hexadecimal and Octal digits
syn match rSpecial display contained "\\\(x\x\{1,2}\|\o\{1,3}\)"

syn keyword rBoolean  T F
syn keyword rConstant R.version.string
syn match rComment contains=@Spell /\#.*/
syn region rString contains=rSpecial,@Spell start=/"/ skip=/\\\\\|\\"/ end=/"/
syn region rString contains=rSpecial,@Spell start=/'/ skip=/\\\\\|\\'/ end=/'/
let rfunfile = system("echo -n $HOME") . "/.vim/tools/rfunctions"
if filereadable(rfunfile)
  source ~/.vim/tools/rfunctions
endif


hi def link rSpecial SpecialChar
hi def link rFunction Function

