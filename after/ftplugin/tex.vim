" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:save_cpo = &cpo
set cpo&vim

function! s:has_plugin(plug)
  return !empty(filter(split(&rtp,','), 'v:val =~? ''\<'.a:plug.'\>'''))
endfunction

if get(g:, 'vimtex_enabled',
      \ s:has_plugin('vimtex') || exists('*vimtex#init'))
  let b:matchup_matchparen_enabled = 0
  let b:matchup_matchparen_fallback = 0
endif

let &cpo = s:save_cpo

" vim: fdm=marker sw=2

