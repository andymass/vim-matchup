" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:save_cpo = &cpo
set cpo&vim

function! matchup#text_obj#init_module() " {{{1
  if !g:matchup_text_obj_enabled | return | endif

  for [l:map, l:name, l:opt] in [
        \ ['%', 'delimited', 'delim_all'],
        \]
    let l:p1 = 'noremap <silent> <plug>(matchup-'
    let l:p2 = l:map . ') :<c-u>call matchup#text_obj#' . l:name
    let l:p3 = empty(l:opt) ? ')<cr>' : ', ''' . l:opt . ''')<cr>'
    execute 'x' . l:p1 . 'i' . l:p2 . '(1, 1' . l:p3
    execute 'x' . l:p1 . 'a' . l:p2 . '(0, 1' . l:p3
    execute 'o' . l:p1 . 'i' . l:p2 . '(1, 0' . l:p3
    execute 'o' . l:p1 . 'a' . l:p2 . '(0, 0' . l:p3
  endfor
endfunction

" }}}1
function! matchup#text_obj#delimited(is_inner, visual, type) " {{{1
  " get the current selection, move to end of range
  if a:visual
    let l:selection = getpos("'<")[1:2] + getpos("'>")[1:2]
    call matchup#pos#set_cursor(getpos("'>"))
  endif

  " motion forcing
  let l:forced = a:visual ? '' : g:v_motion_force

  " determine if operator is able to act line-wise (i.e., for inner)
  let l:linewise_op = index(g:matchup_text_obj_linewise_operators,
        \ v:operator) >= 0

  " disable the timeout
  call matchup#perf#timeout_start(0)

  " try up to three times (rarely)
  for l:try_again in range(3)
    " on the first try, we use v:count which may be zero
    " on the next tries, use the previous count plus one
    " TODO: make sure this logic is right
    let [l:open, l:close] = matchup#delim#get_surrounding(
          \ a:type, l:try_again ? (v:count1 + l:try_again) : v:count)

    if empty(l:open)
      if a:visual
        normal! gv
      endif
      return
    endif

    " heuristic to handle overlapping any-blocks;
    " if the start delimiter is inside our already visually selected
    " area, try again but this time find open instead of open_mid
    if a:visual && !l:try_again
          \ && (l:open.lnum > l:selection[0]
          \    || l:open.lnum == l:selection[0]
          \    && l:open.cnum >= l:selection[1])
      let [l:open, l:close] = matchup#delim#get_surrounding(
            \ a:type, v:count1 + l:try_again)
    endif

    let [l:l1, l:c1, l:l2, l:c2] = [l:open.lnum,  l:open.cnum,
          \ l:close.lnum, l:close.cnum]

    " XXX should be > 0 or > 1?
    let l:is_multiline = (l:l2 - l:l1) > 1 ? 1 : 0

    " special case: if inner and the current selection coincides
    " with the open and close positions, try for a second time
    " this allows vi% in [[   ]] to work
    if a:visual && a:is_inner && l:selection == [l:l1, l:c1, l:l2, l:c2]
      continue
    endif

    " adjust the borders of the selection
    if a:is_inner
      let l:c1 += matchup#delim#end_offset(l:open)
      let [l:l1, l:c1] = matchup#pos#next(l:l1, l:c1)[1:2]
      let [l:l2, l:c2] = matchup#pos#prev(l:l2, l:c2)[1:2]

      " don't select only indent at close
      let l:sol = (l:c2 <= 1)
      while matchup#util#in_indent(l:l2, l:c2)
        let l:c2 = 1
        let [l:l2, l:c2] = matchup#pos#prev(l:l2, l:c2)[1:2]
        let l:sol = 1
      endwhile

      " include the line break if we had wrapped around
      if l:sol
        let l:c2 = strlen(getline(l:l2))+1
      endif

      " not visual, get rid of a single line-break-only line
      if !a:visual && l:sol && strlen(getline(l:l2)) == 0
            \ && (l:forced ==# '')
        let [l:l2, l:c2] = matchup#pos#prev(l:l2, l:c2)[1:2]
      endif

      " check for the line-wise special case
      if l:is_multiline && l:linewise_op && strlen(l:close.match) > 1
        if l:c1 != 1
          let l:l1 += 1
          let l:c1 = 1
        endif
        let l:c2 = strlen(getline(l:l2))+1
      endif
  
      " toggle exclusive: difference between di% and dvi%
      " TODO: &selection
      if l:forced ==# 'v'
        let [l:l2, l:c2] = matchup#pos#prev(l:l2, l:c2)[1:2]
      endif

      " possible extra line with force
      if l:sol && (l:forced =~# 'V' || l:forced ==# 'v')
        let l:l2 += 1
        let l:c2 = 1
      endif
    else
      let l:c2 += matchup#delim#end_offset(l:close)

      " special case for delete operator
      if v:operator ==# 'd'
            \ && strpart(getline(l:l2), l:c2) =~# '^\s*$'
            \ && strpart(getline(l:l2), 0, l:c1-1) =~# '^\s*$'
        let l:c1 = 1
        let l:c2 = strlen(getline(l:l2))+1
      endif
    endif

    " TODO: is there still a bug here in V mode?
    " in visual line mode, force new selection to not be smaller
    if a:visual && visualmode() ==# 'V'
          \ && (l:l1 > l:selection[0] || l:l2 < l:selection[2])
      continue
    endif

    " try again if we reached the same selection
    " for visual line mode, only check line numbers
    " workaround for cases where the cursor might get fooled
    " into going into one of the inner blocks
    if a:visual && (l:selection == [l:l1, l:c1, l:l2, l:c2] 
          \ || visualmode() ==# 'V'
          \    && [l:selection[0], l:selection[2]] == [l:l1, l:l2])
      continue
    else
      break
    endif
  endfor

  " set the proper visual mode for this selection
  let l:select_mode = (v:operator ==# ':')
        \ ? visualmode()
        \ : (l:forced !=# '')
        \   ? l:forced
        \   : 'v'

  if &selection ==# 'exclusive'
    let [l:l2, l:c2] = matchup#pos#next_eol(l:l2, l:c2)[1:2]
  endif

  " apply selection
  execute 'normal!' l:select_mode
  normal! o
  call matchup#pos#set_cursor(l:l1, l:c1)
  normal! o
  call matchup#pos#set_cursor(l:l2, l:c2)
endfunction

" }}}1

let &cpo = s:save_cpo

" vim: fdm=marker sw=2

