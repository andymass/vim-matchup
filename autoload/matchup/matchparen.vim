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

  nnoremap <silent> <plug>(matchup-hi-surround)
        \ :<c-u>call matchup#matchparen#highlight_surrounding()<cr>
endfunction

" }}}1

function! matchup#matchparen#enable() " {{{1
  if g:matchup_matchparen_deferred
        \ && (!has('timers') || !exists('*timer_pause')
        \     || has('nvim') && !has('nvim-0.2.1'))
    let g:matchup_matchparen_deferred = 0
    echohl WarningMsg
    echom "match-up's deferred highlighting feature is "
          \ . 'not supported in your vim version'
    echohl None
  endif

  augroup matchup_matchparen
    autocmd!
    autocmd CursorMoved,CursorMovedI * call s:matchparen.highlight_deferred()
    autocmd WinEnter * call s:matchparen.highlight(1)
    autocmd TextChanged,TextChangedI * call s:matchparen.highlight_deferred()
    if has('patch-8.0.1494')
      autocmd TextChangedP * call s:matchparen.highlight_deferred()
    endif
    autocmd WinLeave * call s:matchparen.clear()
    " autocmd BufLeave * call s:matchparen.clear()
    " autocmd InsertEnter,InsertLeave  * call s:matchparen.highlight()
    autocmd InsertEnter * call s:matchparen.highlight(1, 1)
  augroup END

  let s:pi_paren_sid = 0
  if get(g:, 'loaded_matchparen')
    let l:pat = expand('$VIM').'.\+matchparen\.vim'
    let l:lines = matchup#util#command('scriptnames')
    call filter(l:lines, 'v:val =~# l:pat')
    let s:pi_paren_sid = matchstr(get(l:lines, 0), '\d\+\ze: ')
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
function! matchup#matchparen#toggle(...) " {{{1
  let g:matchup_matchparen_enabled = a:0 > 0
        \ ? a:1
        \ : !g:matchup_matchparen_enabled
  if g:matchup_matchparen_enabled
    call s:matchparen.highlight(1)
  else
    call s:matchparen.clear()
  endif
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
    let &l:statusline = w:matchup_oldstatus
    unlet w:matchup_oldstatus
  endif

  let w:matchup_need_clear = 0
endfunction

" }}}1

function! s:timer_callback(win_id, timer_id) abort " {{{1
  if a:win_id != win_getid()
    call timer_pause(a:timer_id, 1)
    return
  endif

  " if we timed out, do a highlight and pause the timer
  let l:elapsed = 1000*s:reltimefloat(reltime(w:matchup_pulse_time))
  if l:elapsed >= s:show_delay
    let w:matchup_timer_paused = 1
    call timer_pause(a:timer_id, 1)
    call s:matchparen.highlight()
  elseif w:matchup_need_clear && exists('w:matchup_hi_time')
    " if highlighting becomes too stale, clear it
    let l:elapsed = 1000*s:reltimefloat(reltime(w:matchup_hi_time))
    if l:elapsed >= s:hide_delay
      call s:matchparen.clear()
    endif
  endif
endfunction

function! s:reltimefloat(time)
  if s:exists_reltimefloat
    return reltimefloat(a:time)
  else
    return str2float(reltimestr(a:time))
  endif
endfunction
let s:exists_reltimefloat = exists('*reltimefloat')

" }}}1
function! s:matchparen.highlight_deferred() abort dict " {{{1
  if !g:matchup_matchparen_deferred
    return s:matchparen.highlight()
  endif

  if !exists('w:matchup_timer')
    let s:show_delay = g:matchup_matchparen_deferred_show_delay
    let s:hide_delay = g:matchup_matchparen_deferred_hide_delay
    let w:matchup_timer = timer_start(s:show_delay,
          \ function('s:timer_callback', [ win_getid() ]),
          \ {'repeat': -1})
    if !exists('w:matchup_need_clear')
      let w:matchup_need_clear = 0
    endif
  endif

  " keep the timer alive with a heartbeat
  let w:matchup_pulse_time = reltime()

  " if the timer is paused, some time has passed
  if timer_info(w:matchup_timer)[0].paused
    " unpause the timer
    call timer_pause(w:matchup_timer, 0)

    " set the hi time to the pulse time
    let w:matchup_hi_time = w:matchup_pulse_time
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

  " don't get matches when inside a closed fold
  if foldclosed(line('.')) > -1
    return
  endif

  " in insert mode, cursor is treated as being one behind
  let l:insertmode = l:entering_insert
        \ || (mode() ==# 'i' || mode() ==# 'R')

  " start the timeout period
  let l:timeout = l:insertmode
        \ ? get(b:, 'matchup_matchparen_insert_timeout',
        \           g:matchup_matchparen_insert_timeout)
        \ : get(b:, 'matchup_matchparen_timeout',
        \           g:matchup_matchparen_timeout)
  call matchup#perf#timeout_start(l:timeout)

  let l:current = matchup#delim#get_current('all', 'both_all',
        \ { 'insertmode': l:insertmode,
        \   'stopline': g:matchup_matchparen_stopline, })
  call matchup#perf#toc('matchparen.highlight', 'get_current')
  if empty(l:current) | return | endif

  let l:corrlist = matchup#delim#get_matching(l:current,
        \ { 'stopline': g:matchup_matchparen_stopline, })
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

  " store flag meaning highlighting is active
  let w:matchup_need_clear = 1

  " disable off-screen when scrolling with j/k
  let l:scrolling = winheight(0) > 2*&scrolloff
        \ && (line('.') == line('w$')-&scrolloff
        \     || line('.') == line('w0')+&scrolloff)

  " show off-screen matches
  if g:matchup_matchparen_status_offscreen && !l:current.skip
        \ && (!l:scrolling || g:matchup_matchparen_deferred)
    call matchup#matchparen#offscreen(l:current)
  endif

  " add highlighting matches
  if !exists('w:matchup_match_id_list')
    let w:matchup_match_id_list = []
  endif

  for l:corr in l:corrlist
    call add(w:matchup_match_id_list, matchaddpos('MatchParen',
       \   [[l:corr.lnum, l:corr.cnum, strlen(l:corr.match)]]))
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

  let w:matchup_oldstatus = &l:statusline

  let &l:statusline = s:format_statusline(l:offscreen)
endfunction

" }}}1
function! matchup#matchparen#highlight_surrounding() " {{{1
  call matchup#perf#timeout_start(0)
  let l:delims = matchup#delim#get_surrounding('delim_all', 1)
  if empty(l:delims[0]) | return | endif

  let l:save_pos = matchup#pos#get_cursor()
  call matchup#pos#set_cursor(l:delims[0])
  call s:matchparen.highlight(1)

  call matchup#pos#set_cursor(l:save_pos)
endfunction

"}}}1
function! s:format_statusline(offscreen) " {{{1
  let l:line = getline(a:offscreen.lnum)

  let l:sl = ''
  if &number || &relativenumber
    let l:nw = max([strlen(line('$')), &numberwidth-1])
    let l:linenr = a:offscreen.lnum
    let l:direction = l:linenr < line('.')

    if &relativenumber
      let l:linenr = abs(l:linenr-line('.'))
    endif

    let l:sl = printf('%'.(l:nw).'s', l:linenr)
    if l:direction
      let l:sl = '%#Search#' . l:sl . '∆%#Normal#'
    else
      let l:sl = '%#LineNr#' . l:sl . ' %#Normal#'
    endif
  endif

  if !&number && a:offscreen.lnum < line('.')
    let l:sl = '%#Search#∆%#Normal#'
  endif

  let l:lasthi = ''
  for l:c in range(min([winwidth(0), strlen(l:line)]))
    if a:offscreen.cnum <= l:c+1 && l:c+1 <= a:offscreen.cnum
          \ - 1 + strlen(a:offscreen.match)
      " TODO: we can't overlap groups, this might not be totally correct
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
  let l:sl .= '%#Normal#'

  return l:sl
endfunction

function! s:gchar_virtpos(lnum, cnum)
  return matchstr(getline(a:lnum), '\%'.a:cnum.'v.')
endfunction

" }}}1

let &cpo = s:save_cpo

" vim: fdm=marker sw=2
