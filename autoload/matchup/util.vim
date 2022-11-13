" vim match-up - even better matching
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:save_cpo = &cpo
set cpo&vim

function! matchup#util#command(cmd) " {{{1
  let l:lines = ''
  try
    execute 'silent! redir => l:lines'
      silent! execute a:cmd
    redir END
  finally
    return split(l:lines, '\n')
  endtry
endfunction

" }}}1

function! matchup#util#in_comment(...) " {{{1
  return call('matchup#util#in_syntax', ['^Comment$'] + a:000)
endfunction

" }}}1
function! matchup#util#in_string(...) " {{{1
  return call('matchup#util#in_syntax', ['^String$'] + a:000)
endfunction

" }}}1
function! matchup#util#in_comment_or_string(...) " {{{1
  return call('matchup#util#in_syntax',
        \ ['\%(String\|Comment\)'] + a:000)
endfunction

" }}}1
function! matchup#util#in_syntax(name, ...) " {{{1
  " usage: matchup#util#in_syntax(name, [line, col])
  let l:pos = a:0 > 0 ? [a:1, a:2] : [line('.'), col('.')]

  " check syntax at position (same as matchit's s: method)
  let l:syn = synIDattr(synID(l:pos[0], l:pos[1], 1), 'name')
  return l:syn =~? a:name
endfunction

" }}}1
function! matchup#util#in_synstack(name, ...) abort " {{{1
  let l:pos = a:0 > 0 ? [a:1, a:2] : [line('.'), col('.')]
  let l:syn = map(synstack(l:pos[0], l:pos[1]),
        \ "synIDattr(v:val, 'name')")
  return match(l:syn, '^' . a:name . '$') >= 0
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

function! matchup#util#patch_match_words(from, to, ...) abort " {{{1
  if !exists('b:match_words') | return | endif

  " if extra argument is given, give diagnostic information
  if a:0
    let l:first = stridx(b:match_words, a:from)
    if l:first < 0
      echoerr 'match-up: patch_match_words:' a:from 'not found'
      return
    elseif stridx(b:match_words, a:from, l:first+1) > -1
      echoerr 'match-up: patch_match_words: multiple occurences of' a:from
      return
    endif
  endif

  let b:match_words = substitute(b:match_words,
        \ '\V'.escape(a:from, '\'),
        \ escape(a:to, '\'),
        \ '')
endfunction

" }}}1
function! matchup#util#check_match_words(sha256) abort " {{{1
  if !exists('b:match_words') | return 0 | endif
  return sha256(b:match_words) =~# '^'.a:sha256
endfunction

" }}}1
function! matchup#util#append_match_words(str) abort " {{{1
  if !exists('b:match_words')
    let b:match_words = ''
  endif

  if len(b:match_words) && b:match_words[-1] !=# ',' && a:str[0] !=# ','
    let b:match_words .= ','
  endif
  let b:match_words .= a:str
endfunction

" }}}1

function! matchup#util#matchpref(id, default) abort " {{{1
  return get(get(g:matchup_matchpref, &filetype, {}), a:id, a:default)
endfunction

" }}}1

function! matchup#util#standard_html(...) abort " {{{1
  let l:prefs = a:0 ? a:1 : {}
  let l:variant = get(l:prefs, 'variant', 'html')

  let l:words = '<:>,<\@<=!--:-->'

  if l:variant ==# 'html' && get(l:prefs, 'lists', 0)
    let l:words .= ',<\@<=[ou]l\>\g{hlend}[^>]*\%(>\|$\)'
          \ . ':<\@<=li\>'
          \ . ':<\@<=/[ou]l\g{hlend}>'
    let l:words .= ',<\@<=dl\>\g{hlend}[^>]*\%(>\|$\)'
          \ . ':<\@<=d[td]\>'
          \ . ':<\@<=/dl\g{hlend}>'
  endif

  if l:variant ==# 'html'
    let l:words .= ',<\@<=\([^/!][^ \t>]*\)\g{hlend}'
          \ . '\%(>\|$\|[ \t][^>]*\%(>\|$\)\)'
          \ . ':<\@<=/\1\g{hlend}>'
  elseif l:variant ==# 'xml'
    let l:words .= ',<\@<=!\[CDATA\[:]]>'
    let l:words .= ',<\@<=?\k\+:?>'
    let l:words .= ',<\@<=\([^ \t>/]\+\)\g{hlend}'
          \ . '\%(\s\+[^>]*\%([^/]>\|$\)\|>\|$\)'
          \ . ':<\@<=/\1\g{hlend}>'
    let l:words .= ',<\@<=\%([^ \t>/]\+\)\g{hlend}'
          \ . '\%(\s\+[^>]*[^/>]\|$\)'
          \ . ':/>'
  else
    echoerr 'match-up: invalid variant' l:variant
  endif

  if !get(l:prefs, 'tagnameonly', 1)
    let l:words = substitute(l:words, '\\g{hlend}', '', 'g')
  endif

  return l:words
endfunction

" }}}1
function! matchup#util#standard_xml(...) abort " {{{1
  let l:prefs = a:0 ? copy(a:1) : {}
  let l:prefs['variant'] = 'xml'
  return matchup#util#standard_html(l:prefs)
endfunction

" }}}1

let &cpo = s:save_cpo

" vim: fdm=marker sw=2
