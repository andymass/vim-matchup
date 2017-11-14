" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:save_cpo = &cpo
set cpo&vim

function! matchup#surround#init_module() " {{{1
  if !g:matchup_surround_enabled | return | endif

  for [l:map, l:name, l:opt] in [
        \ ['%', 'delimited', 'delim_all'],
        \]
    let l:p1 = 'noremap <silent> <plug>(matchup-'
    let l:p2 = l:map . ') :<c-u>call matchup#surround#' . l:name
    let l:p3 = empty(l:opt) ? ')<cr>' : ', ''' . l:opt . ''')<cr>'
    execute 'n' . l:p1 . 'ds' . l:p2 . '(0, "d"' . l:p3
  endfor
endfunction

" }}}1
function! matchup#surround#delimited(is_cap, op, type) " {{{1
  call matchup#perf#timeout_start(0)

  let [l:open, l:close] = matchup#delim#get_surrounding(a:type, 0)
  if empty(l:open) || empty(l:close)
    return
  endif

  let [l:l1, l:c11, l:c12] = [l:open.lnum, l:open.cnum,
        \ l:open.cnum + strlen(l:open.match) - 1]
  let [l:l2, l:c21, l:c22] = [l:close.lnum, l:close.cnum,
        \ l:close.cnum + strlen(l:close.match) - 1]

  call matchup#pos#set_cursor(l2, c21)
  normal! v
  call matchup#pos#set_cursor(l2, c22)
  execute 'normal!' a:op

  call matchup#pos#set_cursor(l1, c11)
  normal! v
  call matchup#pos#set_cursor(l1, c12)
  execute 'normal!' a:op
endfunction

" }}}1

let &cpo = s:save_cpo

" vim: fdm=marker sw=2

