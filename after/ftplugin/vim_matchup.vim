
let b:match_skip = 's:comment\|string\|vimSynReg'
  \ . '\|vimSet\|vimFuncName\|vimNotPatSep\|vimVar'

call matchup#util#patch_match_words(
   \ '\<aug\%[roup]\s\+\%(END\>\)\@!\S:',
   \ '\<aug\%[roup]\ze\s\+\%(END\>\)\@!\S:'
   \)

