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
  let l:elapsed = reltimefloat(reltime(s:time_start[a:context]))

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

let &cpo = s:save_cpo

" vim: fdm=marker sw=2
