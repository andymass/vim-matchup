" vim match-up - even better matching
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

function! matchup#test#finished() abort " {{{1
  for l:error in v:errors
    let l:match = matchlist(l:error, '\(.*\) line \(\d\+\): \(.*\)')
    let l:file = fnamemodify(l:match[1], ':.')
    let l:lnum = l:match[2]
    let l:msg = l:match[3]
    echo printf("%s:%d: %s\n", l:file, l:lnum, l:msg)
  endfor

  if len(v:errors) > 0
    cquit
  else
    quitall!
  endif
endfunction

" }}}1

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
