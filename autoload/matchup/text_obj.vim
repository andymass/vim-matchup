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

  nnoremap <silent> <plug>(matchup-double-click)
    \ :<c-u>call matchup#text_obj#double_click()<cr>
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

  if v:operator ==# 'g@'
    let l:spec = matchlist(g:matchup_text_obj_linewise_operators,
          \ '^g@\%(,\(.\+\)\)\?')
    if !empty(l:spec)
      if empty(l:spec[1])
        let l:linewise_op = 1
      else
        execute 'let l:linewise_op =' l:spec[1]
      endif
    endif
  elseif v:operator ==# ':'
        \ && index(g:matchup_text_obj_linewise_operators,
        \          visualmode()) >= 0
    let l:linewise_op = 1
  endif

  " set the timeout fairly high
  call matchup#perf#timeout_start(725)

  " try up to four times
  for l:try_again in range(4)
    " on the first try, we use v:count which may be zero
    " on the next tries, use v:count1 and increment each time
    " TODO: make sure this logic is right
    let [l:open, l:close] = matchup#delim#get_surrounding(
          \ a:type, l:try_again ? (v:count1 + l:try_again - 1) : v:count)

    if empty(l:open)
      if a:visual
        normal! gv
      else
        " TODO: can this be simplified by making omaps <expr>?
        " invalid text object, try to do nothing
        " cause a drop into normal mode
        call feedkeys("\<c-\>\<c-n>\<esc>", 'n')

        " and undo the text vim enters if necessary
        call feedkeys(":call matchup#text_obj#undo("
              \ .undotree().seq_cur.")\<cr>:\<c-c>", 'n')
      endif
      return
    endif

    " no way to specify an empty region so we need to use some tricks
    let l:epos = [l:open.lnum, l:open.cnum]
    let l:epos[1] += matchup#delim#end_offset(l:open)
    if !a:visual && a:is_inner
          \ && matchup#pos#equal(l:close, matchup#pos#next(l:epos))

      " TODO: cpo-E
      if v:operator ==# 'c'
        " this is apparently the most reliable way to handle
        " the 'c' operator, although it raises a TextChangedI
        " and fills registers with a space (from targets.vim)
        call matchup#pos#set_cursor(l:close)
        silent! execute "normal! i \<esc>v"
      elseif !count('<>', v:operator)
        call feedkeys(l:close.lnum.'gg', 'n')
        call feedkeys(l:close.cnum.'|', 'n')
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

    " whether the pair has at least one line in between them
    let l:line_count = l:l2 - l:l1 + 1

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
      let l:sol = (l:c2 <= 1)
      let [l:l2, l:c2] = matchup#pos#prev(l:l2, l:c2)[1:2]

      " don't select only indent at close
      while matchup#util#in_indent(l:l2, l:c2)
        let l:c2 = 1
        let [l:l2, l:c2] = matchup#pos#prev(l:l2, l:c2)[1:2]
        let l:sol = 1
      endwhile

      " include the line break if we had wrapped around
      if a:visual && l:sol
        let l:c2 = strlen(getline(l:l2))+1
      endif

      if !a:visual
        " otherwise adjust end pos
        if l:sol
          let [l:l2, l:c2] = matchup#pos#next(l:l2, l:c2)[1:2]
        endif

        " toggle exclusive: difference between di% and dvi%
        let l:inclusive = 0
        if !l:sol && matchup#pos#smaller_or_equal(
              \ [l:l1, l:c1], [l:l2, l:c2])
          let l:inclusive = 1
        endif
        if l:forced ==# 'v'
          let l:inclusive = !l:inclusive
        endif

        " sometimes operate in visual line motion (re-purpose force)
        " cf src/normal.c:1824
        if empty(g:v_motion_force)
              \ && l:c2 <= 1 && l:line_count > 1 && !l:inclusive
          let l:l2 -= 1
          if l:c1 <= 1 || matchup#util#in_indent(l:l1, l:c1-1)
            let l:forced = 'V'
            let l:inclusive = 1
          else
            " end_adjusted
            let l:c2 = strlen(getline(l:l2)) + 1
            if l:c2 > 1
              let l:c2 -= 1
              let l:inclusive = 1
            endif
          endif
        endif

        if !l:inclusive
          let [l:l2, l:c2] = matchup#pos#prev(l:l2, l:c2)[1:2]
        endif
      endif

      " check for the line-wise special case
      if l:line_count > 2 && l:linewise_op && strlen(l:close.match) > 1
        if l:c1 != 1
          let l:l1 += 1
          let l:c1 = 1
        endif
        let l:l2 = l:close.lnum - 1
        let l:c2 = strlen(getline(l:l2))+1
      endif

      " if this would be an empty selection..
      if !a:visual && (l:l2 < l:l1 || l:l1 == l:l2 && l:c1 > l:c2)
        if v:operator ==# 'c'
          call matchup#pos#set_cursor(l:l1, l:c1)
          silent! execute "normal! i \<esc>v"
        elseif !count('<>', v:operator)
          call feedkeys(l:l1.'gg', 'n')
          call feedkeys(l:c1.'|', 'n')
        endif
        return
      endif
    else
      let l:c2 += matchup#delim#end_offset(l:close)

      " special case for delete operator
      if !a:visual && v:operator ==# 'd'
            \ && strpart(getline(l:l2), l:c2) =~# '^\s*$'
            \ && strpart(getline(l:l2), 0, l:c1-1) =~# '^\s*$'
        let l:c1 = 1
        let l:c2 = strlen(getline(l:l2))+1
      endif
    endif

    " in visual line mode, force new selection to not be smaller
    " (only check line numbers)
    if a:visual && visualmode() ==# 'V'
          \ && (l:l1 > l:selection[0] || l:l2 < l:selection[2])
      continue
    endif

    " in other visual modes, try again if we did not reach a
    " `bigger' selection
    " TODO this logic is vim compatible but is pretty weird
    if a:visual && (l:selection == [l:l1, l:c1, l:l2, l:c2]
          \ || (!matchup#pos#smaller([l:l1, l:c1], l:selection[0:1])
          \     && !matchup#pos#smaller(l:selection[2:3], [l:l2, l:c2])))
      continue
    endif

    break
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

function! matchup#text_obj#undo(seq)
  if undotree().seq_cur > a:seq
    silent! undo
  endif
endfunction

" }}}1
function! matchup#text_obj#double_click() " {{{1
  let [l:open, l:close] = [{}, {}]

  call matchup#perf#timeout_start(0)
  let l:delim = matchup#delim#get_current('all', 'both_all')
  if !empty(l:delim)
    let l:matches = matchup#delim#get_matching(l:delim, 1)
    if len(l:matches) > 1 && has_key(l:delim, 'links')
      let [l:open, l:close] = [l:delim.links.open, l:delim.links.close]
    endif
  endif

  if empty(l:open) || empty(l:close)
    execute "normal! \<2-LeftMouse>"
    return
  endif

  let [l:lnum, l:cnum] = [l:close.lnum, l:close.cnum]
  let l:cnum += matchup#delim#end_offset(l:close)

  if &selection ==# 'exclusive'
    let [l:lnum, l:cnum] = matchup#pos#next_eol(l:lnum, l:cnum)[1:2]
  endif

  call matchup#pos#set_cursor(l:open)
  normal! v
  call matchup#pos#set_cursor(l:lnum, l:cnum)
  if l:delim.side ==# 'close'
    normal! o
  endif
endfunction

" }}}1

let &cpo = s:save_cpo

" vim: fdm=marker sw=2

