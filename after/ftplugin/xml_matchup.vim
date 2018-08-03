" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:save_cpo = &cpo
set cpo&vim

if matchup#util#matchpref('tagnameonly', 0)
  call matchup#util#patch_match_words('\)\%(', '\)\g{hlend}\%(')
  call matchup#util#patch_match_words('\)\%(', '\)\g{hlend}\%(')
endif

let &cpo = s:save_cpo

" vim: fdm=marker sw=2

