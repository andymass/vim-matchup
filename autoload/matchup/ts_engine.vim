" vim match-up - even better matching
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:save_cpo = &cpo
set cpo&vim

function! s:forward(fn, ...)
  let l:ret = luaeval(
        \ 'require"treesitter-matchup.internal".' . a:fn . '(unpack(_A))',
        \ a:000)
  return l:ret
endfunction

function! matchup#ts_engine#is_enabled(bufnr) abort
  if !has('nvim-0.9.0')
    return 0
  endif
  return +s:forward('is_enabled', a:bufnr)
endfunction

function! matchup#ts_engine#get_delim(opts) abort
  call matchup#perf#tic('ts_engine.get_delim')

  let l:res = s:forward('get_delim', bufnr('%'), a:opts)
  if empty(l:res)
    call matchup#perf#toc('ts_engine.get_delim', 'fail')
    return {}
  endif

  let l:res.get_matching = function('matchup#ts_engine#get_matching')

  call matchup#perf#toc('ts_engine.get_delim', 'done')

  return l:res
endfunction

function! matchup#ts_engine#get_matching(down, _) dict abort
  call matchup#perf#tic('ts_engine.get_matching')

  let l:list = s:forward('get_matching', self, a:down, bufnr('%'))

  call matchup#perf#toc('ts_engine.get_matching', 'done')

  return l:list
endfunction

let &cpo = s:save_cpo

" vim: fdm=marker sw=2
