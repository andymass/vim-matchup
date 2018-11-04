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
  let g:matchup_matchparen_enabled = 1

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
    autocmd CursorMoved,CursorMovedI *
          \ call s:matchparen.highlight_deferred()
    autocmd WinEnter * call s:matchparen.highlight(1)
    autocmd TextChanged,TextChangedI *
          \ call s:matchparen.highlight_deferred()
    if has('patch-8.0.1494')
      autocmd TextChangedP * call s:matchparen.highlight_deferred()
    endif
    autocmd WinLeave,BufLeave * call s:matchparen.clear()
    autocmd InsertEnter,Insertchange * call s:matchparen.highlight(1, 1)
    autocmd InsertLeave * call s:matchparen.highlight(1)
  augroup END

  if has('vim_starting')
    " prevent this from autoloading during timer callback at startup
    if g:matchup_matchparen_deferred
      call matchup#pos#val(0,0)
    endif

    " prevent loading the delim module at vim startup
    let w:last_changedtick = 2
    let w:last_cursor = [0,1,1,0,1]
  endif
endfunction

" }}}1

function! s:pi_paren_sid() " {{{1
  if s:pi_paren_sid >= 0
    return s:pi_paren_sid
  endif

  let s:pi_paren_sid = 0
  if get(g:, 'loaded_matchparen')
    let l:pat = '\%#=1\V'.expand('$VIM').'\m.\+matchparen\.vim$'
    if v:version >= 800
      " execute() was added in 7.4.2008
      " :filter was introduced in 7.4.2244 but I have not tested it there
      let l:lines = split(execute("filter '".l:pat."' scriptnames"), '\n')
    else
      let l:lines = matchup#util#command('scriptnames')
      call filter(l:lines, 'v:val =~# l:pat')
    endif
    let s:pi_paren_sid = matchstr(get(l:lines, 0), '\d\+\ze: ')
    if !exists('*<SNR>'.s:pi_paren_sid.'_Highlight_Matching_Pair')
      let s:pi_paren_sid = 0
    endif
  endif
  if s:pi_paren_sid
    let s:pi_paren_fcn = function('<SNR>'.s:pi_paren_sid
      \ .'_Highlight_Matching_Pair')
  endif
  return s:pi_paren_sid
endfunction

let s:pi_paren_sid = -1

" }}}1

function! matchup#matchparen#disable() " {{{1
  let g:matchup_matchparen_enabled = 0
  call s:matchparen.clear()
  silent! autocmd! matchup_matchparen
endfunction

" }}}1
function! matchup#matchparen#toggle(...) " {{{1
  let g:matchup_matchparen_enabled = a:0 > 0
        \ ? a:1
        \ : !g:matchup_matchparen_enabled
  call matchup#matchparen#reload()
endfunction

" }}}1
function! matchup#matchparen#reload() " {{{1
  if g:matchup_matchparen_enabled
    call matchup#matchparen#enable()
    call s:matchparen.highlight(1)
  else
    call matchup#matchparen#disable()
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
    if exists('#User#MatchupOffscreenLeave')
      doautocmd <nomodeline> User MatchupOffscreenLeave
    endif
  endif
  if exists('w:matchup_statusline')
    unlet w:matchup_statusline
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
    if exists('#TextYankPost') && !has('patch-8.1.0192')
      " workaround crash with autocmd trigger during regex match (#3175)
      let l:save_ei = &eventignore
      try
        set eventignore+=TextYankPost
        call s:matchparen.highlight()
      finally
        let &eventignore = l:save_ei
      endtry
    else
      call s:matchparen.highlight()
    endif
  elseif w:matchup_need_clear && exists('w:matchup_hi_time')
    " if highlighting becomes too stale, clear it
    let l:elapsed = 1000*s:reltimefloat(reltime(w:matchup_hi_time))
    if l:elapsed >= s:hide_delay
      call s:matchparen.clear()
    endif
  endif
endfunction

" }}}1

" function! s:reltimefloat(time) {{{1
if exists('*reltimefloat')
  function! s:reltimefloat(time)
    return reltimefloat(a:time)
  endfunction
else
  function! s:reltimefloat(time)
    return str2float(reltimestr(a:time))
  endfunction
endif

" }}}1

function! s:matchparen.highlight_deferred() abort dict " {{{1
  if !get(b:, 'matchup_matchparen_deferred',
        \ g:matchup_matchparen_deferred)
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

  if has('vim_starting') | return | endif

  if !g:matchup_matchparen_pumvisible && pumvisible() | return | endif

  if !get(b:, 'matchup_matchparen_enabled', 1)
        \ && get(b:, 'matchup_matchparen_fallback', 1) && s:pi_paren_sid()
    return call(s:pi_paren_fcn, [])
  endif

  if !get(b:, 'matchup_matchparen_enabled', 1) | return | endif

  let l:force_update    = a:0 >= 1 ? a:1 : 0
  let l:changing_insert = a:0 >= 2 ? a:2 : 0
  let l:real_mode = l:changing_insert ? v:insertmode : mode()

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

  let l:modes = g:matchup_matchparen_nomode
  if get(g:, 'matchup_matchparen_novisual', 0)  " deprecated option name
    let l:modes .= "vV\<c-v>"
  endif
  if stridx(l:modes, l:real_mode) >= 0
    return
  endif

  " don't get matches when inside a closed fold
  if foldclosed(line('.')) > -1
    return
  endif

  " in insert mode, cursor is treated as being one behind
  let l:insertmode = l:real_mode ==# 'i'

  " start the timeout period
  let l:timeout = l:insertmode
        \ ? get(b:, 'matchup_matchparen_insert_timeout',
        \           g:matchup_matchparen_insert_timeout)
        \ : get(b:, 'matchup_matchparen_timeout',
        \           g:matchup_matchparen_timeout)
  call matchup#perf#timeout_start(l:timeout)

  let l:current = matchup#delim#get_current('all', 'both_all',
        \ { 'insertmode': l:insertmode,
        \   'stopline': g:matchup_matchparen_stopline,
        \   'highlighting': 1, })
  call matchup#perf#toc('matchparen.highlight', 'get_current')
  if empty(l:current)
    if get(b:, 'matchup_matchparen_deferred',
          \ g:matchup_matchparen_deferred)
          \ && get(b:, 'matchup_matchparen_hi_surround_always',
          \        g:matchup_matchparen_hi_surround_always)
       call s:highlight_surrounding(l:insertmode)
    endif
    return
  endif

  let l:corrlist = matchup#delim#get_matching(l:current,
        \ { 'stopline': g:matchup_matchparen_stopline,
        \   'highlighting': 1, })
  call matchup#perf#toc('matchparen.highlight', 'get_matching')
  if empty(l:corrlist) | return | endif

  if g:matchup_transmute_enabled
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
            \ = copy(w:matchup_matchparen_context.normal)

      let w:matchup_matchparen_context.normal.current = l:current
      let w:matchup_matchparen_context.normal.corrlist = l:corrlist
    endif

    " if transmuted, highlight again (will reset timeout)
    if matchup#transmute#tick(l:insertmode, 'unused')
      " no force_update here because it would screw up prior
      return s:matchparen.highlight(0, l:changing_insert)
    endif
  endif

  if !has_key(l:current, 'match_index')
        \ || len(l:corrlist) <= (l:current.side ==# 'mid' ? 2 : 1)
        \ && !g:matchup_matchparen_singleton
    " TODO this doesn't catch every case, needs refactor
    " TODO singleton doesn't work right for mids
    return
  endif

  " store flag meaning highlighting is active
  let w:matchup_need_clear = 1

  " disable off-screen when scrolling with j/k
  let l:scrolling = g:matchup_matchparen_scrolloff
        \ && winheight(0) > 2*&scrolloff
        \ && (line('.') == line('w$')-&scrolloff
        \     || line('.') == line('w0')+&scrolloff)

  " show off-screen matches
  if g:matchup_matchparen_status_offscreen
        \ && !l:current.skip && !l:scrolling
    call s:do_offscreen(l:current)
  endif

  " add highlighting matches
  call s:add_matches(l:corrlist, l:current)

  call matchup#perf#toc('matchparen.highlight', 'end')
endfunction

" }}}1
function! s:do_offscreen(current) " {{{1
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

  let w:matchup_statusline = s:format_statusline(l:offscreen)
  if !exists('w:matchup_oldstatus')
    let w:matchup_oldstatus = &l:statusline
  endif
  if !g:matchup_matchparen_status_offscreen_manual
    let &l:statusline =  w:matchup_statusline
  endif

  if exists('#User#MatchupOffscreenEnter')
    doautocmd <nomodeline> User MatchupOffscreenEnter
  endif
endfunction

" }}}1
function! matchup#matchparen#highlight_surrounding() " {{{1
  call matchup#perf#timeout_start(500)
  call s:highlight_surrounding()
endfunction

" }}}1

function! MatchupStatusOffscreen() " {{{1
  return get(w:, 'matchup_statusline', '')
endfunction

" }}}1
function! MatchupStatusOffscreenNohl() " {{{1
  return substitute(MatchupStatusOffscreen(), '%#\w*#', '', 'g')
endfunction

" }}}1

function! s:highlight_surrounding(...) " {{{1
  let l:opts = { 'local': 0, 'matches': [] }
  let l:delims = matchup#delim#get_surrounding('delim_all', 1, l:opts)
  let l:open = l:delims[0]
  if empty(l:open) | return | endif

  let l:corrlist = l:opts.matches
  if empty(l:corrlist) | return | endif

  " store flag meaning highlighting is active
  let w:matchup_need_clear = 1

  " add highlighting matches
  call s:add_matches(l:corrlist)
endfunction

"}}}1
function! s:format_statusline(offscreen) " {{{1
  let l:line = getline(a:offscreen.lnum)

  let l:sl = ''
  let l:padding = wincol()-virtcol('.')
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
    let l:padding -= l:nw + 1
  endif

  if empty(l:sl) && a:offscreen.lnum < line('.')
    let l:sl = '%#Search#∆%#Normal#'
    let l:padding -= 1    " OK if this is negative
    if l:padding == -1 && indent(a:offscreen.lnum) == 0
      let l:padding = 0
    endif
  endif

  " possible fold column, up to &foldcolumn characters
  let l:fdcstr = ''
  if &foldcolumn
    let l:fdc = max([1, &foldcolumn-1])
    let l:fdl = foldlevel(a:offscreen.lnum)
    let l:fdcstr = l:fdl <= l:fdc ? repeat('|', l:fdl)
          \ : join(range(l:fdl-l:fdc+1, l:fdl), '')
    let l:padding -= len(l:fdcstr)
    let l:fdcstr = '%#FoldColumn#' . l:fdcstr . '%#Normal#'
  elseif empty(l:sl)
    let l:sl = '%#Normal#'
  endif

  " add remaining padding (this handles rest of fdc and scl)
  let l:sl = l:fdcstr . repeat(' ', l:padding) . l:sl

  let l:lasthi = ''
  for l:c in range(min([winwidth(0), strlen(l:line)]))
    if a:offscreen.cnum <= l:c+1 && l:c+1 <= a:offscreen.cnum
          \ - 1 + strlen(a:offscreen.match)
      let l:wordish = a:offscreen.match !~? '^[[:punct:]]\{1,3\}$'
      " TODO: we can't overlap groups, this might not be totally correct
      let l:curhi = l:wordish ? 'MatchWord' : 'MatchParen'
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

  if has('timers') && exists('*timer_pause')
    if !exists('s:scroll_timer')
      let s:scroll_timer = timer_start(50,
            \ 'matchup#matchparen#scroll_callback',
            \ { 'repeat': -1 })
      call timer_pause(s:scroll_timer, 1)
    endif
    if !g:matchup_matchparen_status_offscreen_manual
      let l:sl .= '%{matchup#matchparen#scroll_update('
            \ .a:offscreen.lnum.')}'
    endif
  endif

  return l:sl
endfunction

function! matchup#matchparen#scroll_callback(tid)
  call timer_pause(a:tid, 1)
  call s:matchparen.highlight(1)
endfunction

function! matchup#matchparen#scroll_update(lnum)
  if line('w0') <= a:lnum && a:lnum <= line('w$')
        \ && exists('s:scroll_timer')
    call timer_pause(s:scroll_timer, 0)
  endif
  return ''
endfunction

" }}}1
function! s:add_matches(corrlist, ...) " {{{1
  if !exists('w:matchup_match_id_list')
    let w:matchup_match_id_list = []
  endif

  " if MatchwordCur is undefined and MatchWord links to MatchParen
  " (as default), behave like MatchWordCur is the same as MatchParenCur
  " otherwise, MatchWordCur is the same as MatchWord
  if a:0
    let l:mwc = hlexists('MatchWordCur') ? 'MatchWordCur'
          \ : (synIDtrans(hlID('MatchWord')) == hlID('MatchParen')
          \     ? 'MatchParenCur' : 'MatchWord')
  endif

  for l:corr in a:corrlist
    let l:wordish = l:corr.match !~? '^[[:punct:]]\{1,3\}$'

    if a:0 && l:corr.match_index == a:1.match_index
      let l:group = l:wordish ? l:mwc : 'MatchParenCur'
    else
      let l:group = l:wordish ? 'MatchWord' : 'MatchParen'
    endif

    call add(w:matchup_match_id_list, matchaddpos(l:group,
          \ [[l:corr.lnum, l:corr.cnum, strlen(l:corr.match)]], 0))
  endfor
endfunction

" }}}1

let &cpo = s:save_cpo

" vim: fdm=marker sw=2

