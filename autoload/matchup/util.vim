" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:save_cpo = &cpo
set cpo&vim

function! matchup#util#command(cmd) " {{{1
  let l:lines = ''
  try
    silent! redir => l:lines
      silent! execute a:cmd
    redir END
  finally
    return split(l:lines, "\n")
  endtry
endfunction

" }}}1
function! matchup#util#in_comment(...) " {{{1
  return call('matchup#util#in_syntax', ['Comment'] + a:000)
endfunction

" }}}1
function! matchup#util#in_string(...) " {{{1
  return call('matchup#util#in_syntax', ['String'] + a:000)
endfunction

" }}}1
function! matchup#util#in_syntax(name, ...) " {{{1
  " usage: matchup#util#in_syntax(name, [line, col])

  " get position and correct it if necessary
  let l:pos = a:0 > 0 ? [a:1, a:2] : [line('.'), col('.')]
  if mode() ==# 'i'
    let l:pos[1] -= 1
  endif
  call map(l:pos, 'max([v:val, 1])')

  " check syntax at position
  let l:syn = map(synstack(l:pos[0], l:pos[1]),
         \  "synIDattr(synIDtrans(v:val), 'name')")
  return match(l:syn, '^' . a:name) >= 0
endfunction

" }}}1
function! matchup#util#in_whitespace(...) " {{{1
  let l:pos = a:0 > 0 ? [a:1, a:2] : [line('.'), col('.')]
  return matchstr(getline(l:pos[0]), '\%'.l:pos[1].'c.') =~# '\s'
endfunction

" }}}1
function! matchup#util#in_indent(...) " {{{1
  let l:pos = a:0 > 0 ? [a:1, a:2] : [line('.'), col('.')]
  return l:pos[1] > 0 && getline(l:pos[0]) =~# '^\s*\%'.(l:pos[1]+1).'c'
endfunction

" }}}1

function! matchup#util#uniq(list) " {{{1
  if exists('*uniq') | return uniq(a:list) | endif
  if len(a:list) <= 1 | return a:list | endif

  let l:uniq = [a:list[0]]
  for l:next in a:list[1:]
    if l:uniq[-1] != l:next
      call add(l:uniq, l:next)
    endif
  endfor
  return l:uniq
endfunction

" }}}1
function! matchup#util#uniq_unsorted(list) " {{{1
  if len(a:list) <= 1 | return a:list | endif

  let l:visited = [a:list[0]]
  for l:index in reverse(range(1, len(a:list)-1))
    if index(l:visited, a:list[l:index]) >= 0
      call remove(a:list, l:index)
    else
      call add(l:visited, a:list[l:index])
    endif
  endfor
  return a:list
endfunction

" }}}1
function! matchup#util#has_duplicate_str(list) " {{{1
  if len(a:list) <= 1 | return 0 | endif
  let l:seen = {}
  for l:elem in a:list
    if has_key(l:seen, l:elem)
      return 1
    endif
    let l:seen[l:elem] = 1
  endfor
  return 0
endfunction

" }}}1

let &cpo = s:save_cpo

" vim: fdm=marker sw=2

