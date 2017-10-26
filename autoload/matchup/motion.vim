" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

function! matchup#motion#init_module() " {{{1
  if !g:matchup_motion_enabled | return | endif

  " Utility map to avoid conflict with "normal" command
  nnoremap <sid>(v) v
  nnoremap <sid>(V) V

  " jump between matching pairs
       " XXX add "forced" omap: dV% (must make v,V,C-V)

       " <silent> XXX
       " todo make % vi compatible wrt yank (:h quote_number)

  nnoremap <silent> <plug>(matchup-%)
    \ :<c-u>call matchup#motion#find_matching_pair(0, 1)<cr>
  nnoremap <silent> <plug>(matchup-g%)
    \ :<c-u>call matchup#motion#find_matching_pair(0, 0)<cr>

  xnoremap  <sid>(matchup-%)
    \ :<c-u>call matchup#motion#find_matching_pair(1, 1)<cr>
  xmap     <plug>(matchup-%) <sid>(matchup-%)
  onoremap <plug>(matchup-%)
    \ :execute "normal \<sid>(v)\<sid>(matchup-%)"<cr>
  xnoremap <plug>(matchup-g%)
    \ :<c-u>call matchup#motion#find_matching_pair(1, 0)<cr>

  nnoremap <silent> <plug>(matchup-]%)
    \ :<c-u>call matchup#motion#find_unmatched(0, 1)<cr>
  nnoremap <silent> <plug>(matchup-[%)
    \ :<c-u>call matchup#motion#find_unmatched(0, 0)<cr>
  
  nnoremap <silent> <plug>(matchup-z%)
    \ :<c-u>call matchup#motion#jump_inside(0)<cr>
endfunction

" }}}1

function! matchup#motion#find_matching_pair(visual, down) " {{{1
  if v:count && !g:matchup_motion_override_Npercent
    exe 'normal!' v:count.'%'
    return
  endif

  if a:visual
    normal! gv
  endif

  " get a delim where the cursor is
  let l:delim = matchup#delim#get_current('all', 'both_all')
  if empty(l:delim)
    " otherwise search forward
    let l:delim = matchup#delim#get_next('all', 'both_all')
    if empty(l:delim) | return | endif
  endif

  let l:matches = matchup#delim#get_matching(l:delim)
  let l:delim = l:delim.links[a:down ? 'next' : 'prev']
  if empty(l:delim) | return | endif

  normal! m`
  let l:column = l:delim.cnum
  if g:matchup_motion_cursor_end
        \ && ((a:down && l:delim.side !=# 'open')
        \       || l:delim.side ==# 'close')
    let l:column += strdisplaywidth(l:delim.match) - 1

    " TODO
    " let l:test = matchup#delim#get_current('all', 'both_all')
    " echo l:test.rematch l:delim.rematch
    " if !empty(l:test) && l:test.rematch !=# l:delim.rematch
    "   let l:column -= 1
    " endif
  endif
  call matchup#pos#set_cursor(l:delim.lnum, l:column)

endfunction

" }}}1
function! matchup#motion#find_unmatched(visual, down) " {{{1
  " XXX handle count
  " XXX handle visual
  
  let [l:open, l:close] = matchup#delim#get_surrounding('delim_all')
 
  if empty(l:open) || empty(l:close)
    return
  endif

  let l:delim = a:down ? l:close : l:open

  " TODO: while loop this
  "
  let l:save_pos = matchup#pos#get_cursor()
  let l:new_pos = [l:delim.lnum, l:delim.cnum]
  if l:delim.side ==# 'close'
    let l:new_pos[1] += strdisplaywidth(l:delim.match) - 1
  endif 

  if matchup#pos#equal(l:save_pos, l:new_pos)
    call matchup#pos#set_cursor(a:down
          \ ? matchup#pos#next(l:new_pos)
          \ : matchup#pos#prev(l:new_pos))

    let [l:open, l:close] = matchup#delim#get_surrounding('delim_all')
    call matchup#pos#set_cursor(l:save_pos)

    if empty(l:open) || empty(l:close)
      return
    endif
    let l:delim = a:down ? l:close : l:open
    let l:new_pos = [l:delim.lnum, l:delim.cnum]
    if l:delim.side ==# 'close'
      let l:new_pos[1] += strdisplaywidth(l:delim.match) - 1
    endif 
  endif

 " echo l:open l:close
   " let [l:open, l:close] = matchup#delim#get_surrounding('delim_all')
  " if empty(l:delim) | return | endif

  normal! m`
  call matchup#pos#set_cursor(l:new_pos)
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

" vim: fdm=marker sw=2
