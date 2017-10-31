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

" }}}1
function! matchup#text_obj#delimited(is_inner, visual, type) " {{{1
  if a:visual
    let l:selection = getpos("'<")[1:2] + getpos("'>")[1:2]
    call matchup#pos#set_cursor(getpos("'>"))
  endif

  let [l:open, l:close] = matchup#delim#get_surrounding(a:type)

  if empty(l:open)
    if a:visual
      normal! gv
    endif
    return
  endif

  let [l:l1, l:c1, l:l2, l:c2] = [l:open.lnum,  l:open.cnum,
                                \ l:close.lnum, l:close.cnum]

  " Determine if operator is linewise
 let l:linewise = index(g:matchup_text_obj_linewise_operators,
       \ v:operator) >= 0
 let l:linewise = 1

  " Adjust the borders
  if a:is_inner
    let c1 += len(l:open.match)
    let c2 -= 1

    let l:is_inline = (l:l2 - l:l1) > 1 ? 1 : 0

          " \ && match(strpart(getline(l1), c1   ), '^\s*$') >= 0
          " \ && match(strpart(getline(l2), 0, c2), '^\s*$') >= 0

    if l:is_inline
      let l1 += 1
      let c1 = strlen(matchstr(getline(l1), '^\s*')) + 1
      let l2 -= 1
      let c2 = strlen(getline(l2))
      if c2 == 0 && !l:linewise
        let l2 -= 1
        let c2 = len(getline(l2)) + 1
      endif
    elseif c2 == 0
      let l2 -= 1
      let c2 = len(getline(l2)) + 1
    endif
  else
    let c2 += len(l:close.match) - 1
  endif

    " select next pair if we reached the same selection
    if a:visual && l:selection == [l1, c1, l2, c2]
      echo 'foobar' | sleep 1
      call matchup#pos#set_cursor(matchup#pos#next([l2, c2]))
      let [l:open, l:close] = matchup#delim#get_surrounding(a:type)
      if empty(l:open)
        normal! gv
        return
      endif
      let [l1, c1, l2, c2] = [l:open.lnum, l:open.cnum,
            \ l:close.lnum, l:close.cnum + len(l:close.match) - 1]
    endif

    let l:is_inline = (l2 - l1) > 1
          \ && match(strpart(getline(l1), 0, c1-1), '^\s*$') >= 0
          \ && match(strpart(getline(l2), 0, c2),   '^\s*$') >= 0

  " Determine the select mode
  let l:select_mode = l:is_inline && l:linewise ? 'V'
        \ : (v:operator ==# ':') ? visualmode() : 'v'

  echo l:is_inline l:linewise v:operator visualmode()
        \ l:l2 l:l1 l:l2-l:l1  | sleep 1

  " Apply selection
  execute 'normal!' l:select_mode
  call matchup#pos#set_cursor(l1, c1)
  normal! o
  call matchup#pos#set_cursor(l2, c2)
endfunction

" }}}1

let &cpo = s:save_cpo

" vim: fdm=marker sw=2

