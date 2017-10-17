" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

function! matchup#util#command(cmd) " {{{1
  let l:a = @a
  try
    silent! redir @a
    silent! execute a:cmd
    redir END
  finally
    let l:res = @a
    let @a = l:a
    return split(l:res, "\n")
  endtry
endfunction

" }}}1
function! matchup#util#shellescape(cmd) " {{{1
  "
  " Path used in "cmd" only needs to be enclosed by double quotes.
  " shellescape() on Windows with "shellslash" set will produce a path
  " enclosed by single quotes, which "cmd" does not recognize and reports an
  " error.
  "
  if has('win32')
    let l:shellslash = &shellslash
    set noshellslash
    let l:cmd = escape(shellescape(a:cmd), '\')
    let &shellslash = l:shellslash
    return l:cmd
  else
    return escape(shellescape(a:cmd), '\')
  endif
endfunction

" }}}1
function! matchup#util#get_os() " {{{1
  if has('win32')
    return 'win'
  elseif has('unix')
    if system('uname') =~# 'Darwin'
      return 'mac'
    else
      return 'linux'
    endif
  endif
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

  " Usage: matchup#util#in_syntax(name, [line, col])

  " Get position and correct it if necessary
  let l:pos = a:0 > 0 ? [a:1, a:2] : [line('.'), col('.')]
  if mode() ==# 'i'
    let l:pos[1] -= 1
  endif
  call map(l:pos, 'max([v:val, 1])')

  " Check syntax at position
  let l:syn = map(synstack(l:pos[0], l:pos[1]),
         \  "synIDattr(synIDtrans(v:val), 'name')")
  return match(l:syn, '^' . a:name) >= 0
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

" vim: fdm=marker sw=2
