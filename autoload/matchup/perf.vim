" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:save_cpo = &cpo
set cpo&vim

let s:time_start = {}
let s:alpha = 2.0/(10+1)

let g:matchup#perf#times = {}

function! matchup#perf#tic(context)
  let s:time_start[a:context] = reltime()
endfunction

function! matchup#perf#toc(context, state)
  let l:elapsed = s:reltimefloat(reltime(s:time_start[a:context]))

  let l:key = a:context.'#'.a:state
  if has_key(g:matchup#perf#times, l:key)
    if l:elapsed > g:matchup#perf#times[l:key].maximum
      let g:matchup#perf#times[l:key].maximum = l:elapsed
    endif
    let g:matchup#perf#times[l:key].emavg = s:alpha*l:elapsed
          \ + (1-s:alpha)*g:matchup#perf#times[l:key].emavg
  else
    let g:matchup#perf#times[l:key] = {
          \ 'maximum' : l:elapsed,
          \ 'emavg'   : l:elapsed,
          \}
  endif
endfunction

let s:timeout = 0 
let s:timeout_enabled = 0
let s:timeout_pulse_time = reltime()

function! matchup#perf#timeout() " {{{1
  return float2nr(s:timeout)
endfunction

"}}}1
function! matchup#perf#timeout_start(timeout) " {{{1
  let s:timeout = a:timeout 
  let s:timeout_enabled = (a:timeout == 0) ? 0 : 1
  let s:timeout_pulse_time = reltime()
endfunction

" }}}1
function! matchup#perf#timeout_check() " {{{1
  if !s:timeout_enabled | return 0 | endif
  let l:elapsed = 1000.0 * s:reltimefloat(reltime(s:timeout_pulse_time))
  let s:timeout -= l:elapsed
  let s:timeout_pulse_time = reltime()
  return s:timeout <= 0.0
endfunction

" }}}1

function! s:reltimefloat(time) " {{{1
  if s:exists_reltimefloat
    return reltimefloat(a:time)
  else
    return str2float(reltimestr(a:time))
  endif
endfunction
let s:exists_reltimefloat = exists('*reltimefloat')

" }}}1

let &cpo = s:save_cpo

" vim: fdm=marker sw=2

