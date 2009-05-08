
syn keyword rBoolean  FALSE TRUE T F
syn match rComment contains=@Spell /\#.*/
syn region rString contains=@Spell start=/"/ skip=/\\\\\|\\"/ end=/"/
syn region rString contains=@Spell start=/'/ skip=/\\\\\|\\'/ end=/'/
