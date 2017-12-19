" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

if !get(g:, 'matchup_enabled', 1) || &cp
  finish
endif

if !get(g:, 'matchup_no_version_check', 0)
      \ && !(v:version >= 704 || has('nvim-0.1.7'))
  echoerr 'match-up does not support this version of vim'
  finish
endif

if !has('reltime')
  echoerr 'match-up requires reltime()'
  finish
endif

if exists('g:loaded_matchup')
  finish
endif
let g:loaded_matchup = 1

if exists('g:loaded_matchit')
  echoerr 'match-up must be loaded before matchit'
  finish
endif
let g:loaded_matchit = 1

if get(g:, 'matchup_matchparen_enabled', 1)
  if !exists('g:loaded_matchparen')
    runtime plugin/matchparen.vim
  endif
  au! matchparen
  command! NoMatchParen call matchup#matchparen#toggle(0)
  command! DoMatchParen call matchup#matchparen#toggle(1)
endif

if get(g:, 'matchup_override_vimtex', 0)
  let g:vimtex_matchparen_enabled = 0
endif

call matchup#init()

" vim: fdm=marker sw=2

