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
    let l:p3 = empty(l:opt) ? ')<cr>' : ',''' . l:opt . ''')<cr>'
    execute 'x' . l:p1 . 'i' . l:p2 . '(1, 1' . l:p3
    execute 'x' . l:p1 . 'a' . l:p2 . '(0, 1' . l:p3
    execute 'o' . l:p1 . 'i' . l:p2 . '(1, 0' . l:p3
    execute 'o' . l:p1 . 'a' . l:p2 . '(0, 0' . l:p3
  endfor
endfunction

" MAXCOL is probably a lot bigger in actuality, but we don't want
" to support such long lines
let s:MAXCOL = 0x7fff

" }}}1
function! matchup#text_obj#delimited(is_inner, visual, type) " {{{1
  " get the current selection, move to end of range
  if a:visual
    let l:selection = getpos("'<")[1:2] + getpos("'>")[1:2]
    call matchup#pos#set_cursor(getpos("'>"))
  endif

  " determine if operator is able to act line-wise (i.e., for inner)
  let l:linewise = index(g:matchup_text_obj_linewise_operators,
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

    let l:is_multiline = (l:l2 - l:l1) > 1 ? 1 : 0

    " special case: if inner and the current selection coincides
    " with the open and close positions, try for a second time
    " this allows vi% in [[   ]] to work
    if a:visual && a:is_inner && l:selection == [l:l1, l:c1, l:l2, l:c2]
      continue
    endif

    " adjust the borders
    if a:is_inner
      let l:c1 += len(l:open.match)
      let l:c2 -= 1

      if l:is_multiline
        let l:l1 += 1
        let l:c1 = strlen(matchstr(getline(l:l1), '^\s*')) + 1
        let l:l2 -= 1
        let l:c2 = strlen(getline(l:l2))
        if l:c2 == 0 && !l:linewise
          let l:l2 -= 1
          let l:c2 = len(getline(l:l2)) + 1
        endif
      elseif l:c2 == 0
        let l:l2 -= 1
        let l:c2 = len(getline(l2)) + 1
      endif
    else
      let l:c2 += len(l:close.match) - 1
    endif

    " TODO: there is still a bug here in V mode
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

  " determine the proper select mode
  let l:select_mode = l:is_multiline && l:linewise ? 'V'
        \ : (v:operator ==# ':') ? visualmode() : 'v'

  " apply selection
  execute 'normal!' l:select_mode
  call matchup#pos#set_cursor(l1, c1)
  normal! o
  call matchup#pos#set_cursor(l2, c2)
endfunction

" }}}1

let &cpo = s:save_cpo

" vim: fdm=marker sw=2

