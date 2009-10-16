
" New line, carriage return, tab, bell, feed, backslash
syn match rSpecial display contained "\\\(n\|r\|t\|a\|f\|'\|\"\)\|\\\\"

" Hexadecimal and Octal digits
syn match rSpecial display contained "\\\(x\x\{1,2}\|\o\{1,3}\)"

syn keyword rBoolean  FALSE TRUE T F
syn match rComment contains=@Spell /\#.*/
syn region rString contains=rSpecial,@Spell start=/"/ skip=/\\\\\|\\"/ end=/"/
syn region rString contains=rSpecial,@Spell start=/'/ skip=/\\\\\|\\'/ end=/'/

hi def link rSpecial SpecialChar

