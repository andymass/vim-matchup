" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

if !get(g:, 'matchup_enabled', 1)
  finish
endif

if exists('g:loaded_matchup') || &cp
  finish
endif
let g:loaded_matchup = 1

if exists('g:loaded_matchit')
  echohl WarningMsg
  echo 'matchup must be loaded before matchit'
  echohl NONE
  finish
endif
let g:loaded_matchit = 1

if !exists('g:loaded_matchparen')
  runtime plugin/matchparen.vim
endif
au! matchparen

call matchup#init()

" vim: fdm=marker sw=2

