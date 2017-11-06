" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

function! matchup#matchparen#init_module() " {{{1
  if !g:matchup_matchparen_enabled | return | endif

  call matchup#matchparen#enable()
endfunction

" }}}1

function! matchup#matchparen#enable() " {{{1
  augroup matchup_matchparen
    autocmd!
    autocmd CursorMoved,CursorMovedI * call s:matchparen.highlight()
    autocmd WinEnter * call s:matchparen.highlight(1)
    " autocmd TextChanged,TextChangedI * call s:matchparen.highlight()
    autocmd WinLeave * call s:matchparen.clear()
    " autocmd BufLeave * call s:matchparen.clear()
    " autocmd InsertEnter,InsertLeave  * call s:matchparen.highlight()
    autocmd InsertEnter * call s:matchparen.highlight(1, 1)
  augroup END

  let s:pi_paren_sid = 0
  if get(g:, 'loaded_matchparen')
    let l:pat = ','.expand('$VIM').'.\+matchparen\.vim,'
    redir => l:lines
      silent execute 'filter' l:pat 'scriptnames'
    redir END
    let s:pi_paren_sid = matchstr(l:lines, '\d\+\ze: ')
    if !exists('*<SNR>'.s:pi_paren_sid.'_Highlight_Matching_Pair')
      let s:pi_paren_sid = 0
    endif
  endif
  if s:pi_paren_sid 
    let s:pi_paren_fcn = function('<SNR>'.s:pi_paren_sid
      \ .'_Highlight_Matching_Pair')
  endif

  call s:matchparen.highlight()
endfunction

" }}}1
function! matchup#matchparen#disable() " {{{1
  call s:matchparen.clear()
  autocmd! matchup_matchparen
endfunction

" }}}1

let s:matchparen = {}

function! s:matchparen.clear() abort dict " {{{1
  if exists('w:matchup_match_id_list')
    for l:id in w:matchup_match_id_list
      silent! call matchdelete(l:id)
    endfor
    unlet! w:matchup_match_id_list
  endif

  if exists('w:matchup_oldstatus')
    let &statusline = w:matchup_oldstatus
    unlet w:matchup_oldstatus
  endif
endfunction
" }}}1

function! s:matchparen.highlight(...) abort dict " {{{1
  if !g:matchup_matchparen_enabled | return | endif

  if !get(b:, 'matchup_matchparen_enabled', 1)
        \ && get(b:, 'matchup_matchparen_fallback', 1) && s:pi_paren_sid
    return call(s:pi_paren_fcn, [])
  endif

  if !get(b:, 'matchup_matchparen_enabled', 1) | return | endif

  if pumvisible() | return | endif

  let l:force_update    = a:0 >= 1 ? a:1 : 0
  let l:entering_insert = a:0 >= 2 ? a:2 : 0

  if !l:force_update
        \ && exists('w:last_changedtick') && exists('w:last_cursor')
        \ && matchup#pos#equal(w:last_cursor, matchup#pos#get_cursor())
        \ && w:last_changedtick == b:changedtick
    return
  endif
  let w:last_changedtick = b:changedtick
  let w:last_cursor = matchup#pos#get_cursor()

  call matchup#perf#tic('matchparen.highlight')

  call self.clear()

  " in insert mode, cursor is treated as being one behind
  let l:insertmode = l:entering_insert
        \ || (mode() ==# 'i' || mode() ==# 'R')

  " skip if inside string or comment (by default)
  if matchup#delim#skip(line('.'), col('.') - l:insertmode)
    return
  endif

  " start the timeout period
  let l:timeout = l:insertmode
        \ ? g:matchup_matchparen_insert_timeout
        \ : g:matchup_matchparen_timeout
  call matchup#perf#timeout_start(l:timeout)

  let l:current = matchup#delim#get_current('all', 'both_all',
        \ { 'insertmode': l:insertmode })
  call matchup#perf#toc('matchparen.highlight', 'get_current')
  if empty(l:current) | return | endif

  let l:corrlist = matchup#delim#get_matching(l:current, 1)
  call matchup#perf#toc('matchparen.highlight', 'get_matching')
  if empty(l:corrlist) | return | endif

  if !exists('w:matchup_matchparen_context')
    let w:matchup_matchparen_context = {
          \ 'normal': {
          \   'current':   {},
          \   'corrlist':  [],
          \  },
          \ 'prior': {},
          \ 'counter': 0,
          \}
  endif

  let w:matchup_matchparen_context.counter += 1

  if !l:insertmode
    let w:matchup_matchparen_context.prior
          \ = deepcopy(w:matchup_matchparen_context.normal)

    let w:matchup_matchparen_context.normal.current = l:current
    let w:matchup_matchparen_context.normal.corrlist = l:corrlist
  endif

  " if transmuted, highlight again (will reset timeout)
  if matchup#transmute#tick(l:insertmode, l:entering_insert)
    " no force_update here because it would screw up prior
    return s:matchparen.highlight(0, l:entering_insert)
  endif

  if len(l:corrlist) <= 1 && !g:matchup_matchparen_singleton
    return
  endif

  " show off-screen matches
  if g:matchup_matchparen_status_offscreen
    call matchup#matchparen#offscreen(l:current)
  endif

  " add highlighting matches
  if !exists('w:matchup_match_id_list')
    let w:matchup_match_id_list = []
  endif

  for l:corr in l:corrlist
    call add(w:matchup_match_id_list, matchadd('MatchParen',
       \   '\%' . l:corr.lnum . 'l'
       \ . '\%' . l:corr.cnum . 'c'
       \ . '\%(' . l:corr.rematch . '\)'))
  endfor

  call matchup#perf#toc('matchparen.highlight', 'end')
endfunction

" }}}1
function! matchup#matchparen#offscreen(current) " {{{1
  let l:offscreen = {}

  if !has_key(a:current, 'links') | return | endif

  " prefer to show close 
  if a:current.links.open.lnum < line('w0')
    let l:offscreen = a:current.links.open
  endif
  if a:current.links.close.lnum > line('w$')
    let l:offscreen = a:current.links.close
  endif

  if empty(l:offscreen) | return | endif

  let w:matchup_oldstatus = &statusline

  let &statusline = s:format_statusline(l:offscreen)
endfunction

" }}}1
function! s:format_statusline(offscreen) " {{{1
  let l:line = getline(a:offscreen.lnum)

  let l:sl = ''
  if &number
    let l:nw = max([strlen(line('$')), &numberwidth-1])
    let l:linenr = a:offscreen.lnum
    if &relativenumber
      let l:linenr = l:linenr-line('.')
    endif

    let l:sl = printf('%'.(l:nw).'s', l:linenr)
    if l:linenr < line('.')
      let l:sl = '%#Search#' . l:sl . '∆%*'
    else
      let l:sl .= ' '
    endif
  endif

  if !&number && a:offscreen.lnum < line('.')
    let l:sl = '%#Search#∆%*'
  endif

  let l:lasthi = ''
  "for l:idx in range(min([winwidth(0), strchars(l:line)]))
  "  let l:c = strlen(strcharpart(l:line, 0, l:idx))
    " echo l:idx l:c | sleep 1
  "endfor

  " TODO use character indexing
  for l:c in range(min([winwidth(0), strlen(l:line)]))
    if a:offscreen.cnum <= l:c+1 && l:c+1 <= a:offscreen.cnum
          \ - 1 + strlen(a:offscreen.match)
      let l:curhi = 'MatchParen'
    else
      let l:curhi = synIDattr(
            \ synID(a:offscreen.lnum, l:c+1, 1), 'name')
    endif
    let l:sl .= (l:curhi !=# l:lasthi ? '%#'.l:curhi.'#' : '')
    if l:line[l:c] ==# "\t"
      let l:sl .= repeat(' ', strdisplaywidth(strpart(l:line, 0, 1+l:c))
            \ - strdisplaywidth(strpart(l:line, 0, l:c)))
    else
      let l:sl .= l:line[l:c]
    endif
    let l:lasthi = l:curhi
  endfor

  return l:sl
endfunction

function! s:gchar_virtpos(lnum, cnum)
  return matchstr(getline(a:lnum), '\%'.a:cnum.'v.')
endfunction

" }}}1

let &cpo = s:save_cpo

" vim: fdm=marker sw=2
