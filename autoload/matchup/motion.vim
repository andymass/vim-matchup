" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:save_cpo = &cpo
set cpo&vim

function! matchup#motion#init_module() " {{{1
  if !g:matchup_motion_enabled | return | endif

  " utility maps to avoid conflict with "normal" command
  nnoremap <sid>(v) v
  nnoremap <sid>(V) V

  " jump between matching pairs
       " TODO XXX add "forced" omap: dV% (must make v,V,C-V)

       " <silent> XXX
       " todo make % vi compatible wrt yank (:h quote_number)

  " the basic motions % and g%
  nnoremap <silent> <plug>(matchup-%)
        \ :<c-u>call matchup#motion#find_matching_pair(0, 1)<cr>
  nnoremap <silent> <plug>(matchup-g%)
        \ :<c-u>call matchup#motion#find_matching_pair(0, 0)<cr>

  " visual and operator-pending
  xnoremap <silent> <sid>(matchup-%)
        \ :<c-u>call matchup#motion#find_matching_pair(1, 1)<cr>
  xmap     <silent> <plug>(matchup-%) <sid>(matchup-%)
  onoremap <plug>(matchup-%)
        \ :<c-u>call <sid>oper("normal \<sid>(v)\<sid>(matchup-%)")<cr>

  xnoremap <silent> <sid>(matchup-g%)
        \ :<c-u>call matchup#motion#find_matching_pair(1, 0)<cr>
  xmap     <silent> <plug>(matchup-g%) <sid>(matchup-g%)
  onoremap <plug>(matchup-g%)
        \ :<c-u>call <sid>oper("normal \<sid>(v)\<sid>(matchup-g%)")<cr>

  " ]% and [%
  nnoremap <silent> <plug>(matchup-]%)
        \ :<c-u>call matchup#motion#find_unmatched(0, 1)<cr>
  nnoremap <silent> <plug>(matchup-[%)
        \ :<c-u>call matchup#motion#find_unmatched(0, 0)<cr>
  xnoremap <silent> <sid>(matchup-]%)
        \ :<c-u>call matchup#motion#find_unmatched(1, 1)<cr>
  xnoremap <silent> <sid>(matchup-[%)
        \ :<c-u>call matchup#motion#find_unmatched(1, 0)<cr>
  xmap     <plug>(matchup-]%) <sid>(matchup-]%)
  xmap     <plug>(matchup-[%) <sid>(matchup-[%)
  onoremap <plug>(matchup-]%)
        \ :<c-u>call <sid>oper("normal \<sid>(v)"
        \ . v:count1 . "\<sid>(matchup-]%)")<cr>
  onoremap <plug>(matchup-[%)
        \ :<c-u>call <sid>oper("normal \<sid>(v)"
        \ . v:count1 . "\<sid>(matchup-[%)")<cr>

  " jump inside z% 
  nnoremap <silent> <plug>(matchup-z%)
        \ :<c-u>call matchup#motion#jump_inside(0)<cr>
endfunction

" }}}1

function! matchup#motion#force(wise) " {{{1
  let s:v_motion_force = a:wise
endfunction

" :help o_v
let s:v_motion_force = ''

function! s:wise(default)
  return s:v_motion_force !=# '' ? s:v_motion_force : a:default
endfunction

function! s:clearforce()
  let s:v_motion_force = ''
endfunction

" }}}1
function! s:oper(expr) " {{{1
  let s:v_operator = v:operator
  execute a:expr
  unlet s:v_operator
  call s:clearforce()
endfunction

" }}}1

function! matchup#motion#find_matching_pair(visual, down) " {{{1
  if v:count && a:down && !g:matchup_motion_override_Npercent
    exe 'normal!' v:count.'%'
    return
  endif

  if a:visual
    normal! gv
  endif

  let [l:start_lnum, l:start_cnum] =  matchup#pos#get_cursor()[1:2]

  " disable the timeout
  call matchup#perf#timeout_start(0)

  " get a delim where the cursor is
  let l:delim = matchup#delim#get_current('all', 'both_all')
  if empty(l:delim)
    " otherwise search forward
    let l:delim = matchup#delim#get_next('all', 'both_all')
    if empty(l:delim) | return | endif
  endif

  " loop count number of times
  for l:dummy in range(v:count1)
    let l:matches = matchup#delim#get_matching(l:delim)
    let l:delim = l:delim.links[a:down ? 'next' : 'prev']
    if empty(l:delim) | return | endif
  endfor

  " go to the end of the delimiter, if necessary
  let l:column = l:delim.cnum
  if g:matchup_motion_cursor_end
        \ && ((a:down && l:delim.side !=# 'open')
        \       || l:delim.side ==# 'close')

    " XXX spin this off into delim object
    " let l:column += strdisplaywidth(l:delim.match) - 1

  " XXX
    let l:column = matchup#delim#jump_target(l:delim)

    " TODO
    " let l:test = matchup#delim#get_current('all', 'both_all')
    " echo l:test.rematch l:delim.rematch
    " if !empty(l:test) && l:test.rematch !=# l:delim.rematch
    "   let l:column -= 1
    " endif
  endif

  normal! m`
 
 " XXX spin off 
  let l:eom = l:delim.cnum + strdisplaywidth(l:delim.match) - 1

  " special handling for d%/dg% XXX unfinished
  if get(s:, 'v_operator', '') ==# 'd' && l:start_lnum != l:delim.lnum
    let l:tl = [l:start_lnum, l:start_cnum]
    let l:br = [l:delim.lnum, l:eom]
    let [l:tl, l:br, l:swap] = l:tl[0] <= l:br[0]
          \ ? [l:tl, l:br, 0]
          \ : [l:br, l:tl, 1]

    if getline(l:tl[0]) =~# '^[ \t]\+\%'.l:tl[1].'c'
          \ && getline(l:br[0]) =~# '\%'.(l:br[1]+1).'c[ \t]\+$'
      if l:swap
        normal! o
        call matchup#pos#set_cursor(l:br[0],
              \ strdisplaywidth(getline(l:br[0])))
        normal! o
        let l:column = 1
      else
        normal! o
        call matchup#pos#set_cursor(l:tl[0], 1)
        normal! o
        let l:column = strdisplaywidth(getline(l:br[0]))
      endif
    endif
  endif

  call matchup#pos#set_cursor(l:delim.lnum, l:column)

endfunction

" }}}1
function! matchup#motion#find_unmatched(visual, down) " {{{1
  call matchup#perf#tic('motion#find_unmatched')

  let l:count = v:count1

  if a:visual
    normal! gv
  endif

  " disable the timeout
  call matchup#perf#timeout_start(0)

  for l:second_try in range(2)
    let [l:open, l:close] = matchup#delim#get_surrounding('delim_all',
          \ l:second_try ? l:count : 1)

    if empty(l:open) || empty(l:close)
      call matchup#perf#toc('motion#find_unmatched', 'fail'.l:second_try)
      return
    endif

    let l:delim = a:down ? l:close : l:open

    let l:save_pos = matchup#pos#get_cursor()
    let l:new_pos = [l:delim.lnum, l:delim.cnum]
 
    " this is an exclusive motion
    if l:delim.side ==# 'close'
      if empty(get(s:, 'v_operator', 0))
        "XXX spin this off
        let l:new_pos[1] += strdisplaywidth(l:delim.match) - 1
      else
        let l:new_pos[1] -= 1
      endif
    endif 

    " if the cursor didn't move, increment count
    if matchup#pos#equal(l:save_pos, l:new_pos)
      let l:count += 1
    endif

    if l:count <= 1
      break
    endif
  endfor

  normal! m`
  call matchup#pos#set_cursor(l:new_pos)

  call matchup#perf#toc('motion#find_unmatched', 'done')
endfunction

" }}}1
function! matchup#motion#jump_inside(visual) " {{{1
  " TODO handle count
  " TODO handle visual
 
  let l:delim = matchup#delim#get_next('all', 'open')
  if empty(l:delim)
    return
  endif

  let l:new_pos = [l:delim.lnum, l:delim.cnum]
  let l:new_pos[1] += strdisplaywidth(l:delim.match) - 1

  normal! m`
  call matchup#pos#set_cursor(matchup#pos#next(l:new_pos))
endfunction

" }}}1

let &cpo = s:save_cpo

" vim: fdm=marker sw=2

