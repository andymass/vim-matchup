" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:save_cpo = &cpo
set cpo&vim

function! matchup#quirks#isclike() abort " {{{1
  let l:ft = get(split(&filetype, '\.'), 0, '')
  return index(s:clikeft, l:ft) > -1
endfunction

let s:clikeft = [ 'arduino', 'c', 'cpp', 'cuda',
            \     'go', 'javascript', 'ld', 'php' ]

" }}}1

let s:adjust_max = 7

function! matchup#quirks#status_adjust(offscreen) abort " {{{1
  if a:offscreen.match ==# '{' && matchup#quirks#isclike()
        \ && strpart(getline(a:offscreen.lnum),
        \            0, a:offscreen.cnum-1) =~# '^\s*$'
    " go up to next line with same indent (up to s:adjust_max)
    for l:adjust in range(-1, -s:adjust_max, -1)
      if indent(a:offscreen.lnum + l:adjust) == indent(a:offscreen.lnum)
        return l:adjust
      endif
    endfor
  endif

  return 0
endfunction

" }}}1

let &cpo = s:save_cpo

" vim: fdm=marker sw=2

