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

  nnoremap <plug>(matchup-]%)
    \ :<c-u>call matchup#motion#find_unmatched(0, 1)<cr>
  nnoremap <plug>(matchup-[%)
    \ :<c-u>call matchup#motion#find_unmatched(0, 0)<cr>
endfunction

" }}}1

function! matchup#motion#find_matching_pair(visual, down) " {{{1
  if v:count
    exe 'normal!' v:count.'%'
    return
  endif

  if a:visual
    normal! gv
  endif

  let l:delim = matchup#delim#get_current('all', 'both_all')
  if empty(l:delim)
    let l:delim = matchup#delim#get_next('all', 'both_all')
    if empty(l:delim) | return | endif
  endif

  let l:matches = matchup#delim#get_matching(l:delim)
  let l:delim = l:delim.links[a:down ? 'next' : 'prev']
  if empty(l:delim) | return | endif

  normal! m`
  call matchup#pos#set_cursor(l:delim.lnum,
        \ (l:delim.side ==# 'close'
        \   ? l:delim.cnum + strdisplaywidth(l:delim.match) - 1
        \   : l:delim.cnum))
endfunction

" }}}1
function! matchup#motion#find_unmatched(visual, down) " {{{1
  " XXX handle visual
  
  let [l:open, l:close] = matchup#delim#get_surrounding('delim_all')

  let l:delim = a:down ? l:close : l:open
  if empty(l:delim) | return | endif

  normal! m`
  call matchup#pos#set_cursor(l:delim.lnum,
        \ (l:delim.side ==# 'close'
        \   ? l:delim.cnum + strdisplaywidth(l:delim.match) - 1
        \   : l:delim.cnum))
endfunction

" }}}1

" vim: fdm=marker sw=2
