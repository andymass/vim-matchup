" vim match-up - even better matching
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

if !exists('g:loaded_matchup') || !exists('b:did_ftplugin')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

call matchup#util#append_match_words('``:``\g{syn;!JanetString}')

let &cpo = s:save_cpo

" vim: fdm=marker sw=2
