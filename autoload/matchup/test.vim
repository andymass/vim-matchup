" vim match-up - even better matching
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

function! matchup#test#assert(condition) abort " {{{1
  if a:condition | return 1 | endif

  call s:fail()
endfunction

" }}}1
function! matchup#test#assert_equal(expect, observe) abort " {{{1
  if a:expect ==# a:observe | return 1 | endif

  call s:fail([
        \ 'expect:  ' . string(a:expect),
        \ 'observe: ' . string(a:observe),
        \])
endfunction

" }}}1
function! matchup#test#assert_match(x, regex) abort " {{{1
  if a:x =~# a:regex | return 1 | endif

  call s:fail([
        \ 'x = ' . string(a:x),
        \ 'regex = ' . a:regex,
        \])
endfunction

" }}}1

function! s:fail(...) abort " {{{1
  echo 'Assertion failed!'

  if a:0 > 0 && !empty(a:1)
    if type(a:1) == v:t_string
      echo a:1
    else
      for line in a:1
        echo line
      endfor
    endif
  endif
  echon "\n"

  cquit
endfunction

" }}}1
