" vim match-up - even better matching
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

if !exists('g:loaded_matchup') || !exists('b:did_ftplugin')
  finish
endif

if matchup#util#check_match_words('802f71c1')
  call matchup#util#append_match_words('/\*:\*/')
endif

" vim: fdm=marker sw=2
