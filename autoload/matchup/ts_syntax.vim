" vim match-up - even better matching
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:save_cpo = &cpo
set cpo&vim

function! s:forward(fn, ...) abort
  let l:ret = luaeval(
        \ 'require"treesitter-matchup.syntax".' . a:fn . '(unpack(_A))',
        \ a:000)
  return l:ret
endfunction

function! matchup#ts_syntax#synID(lnum, col, trans) abort
  return s:forward('synID', a:lnum, a:col, a:trans)
endfunction

let &cpo = s:save_cpo

" vim: fdm=marker sw=2
