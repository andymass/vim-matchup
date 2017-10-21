" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

function! matchup#matchparen#init_module() " {{{1
  if !g:matchup_matchparen_enabled | return | endif

  call matchup#matchparen#enable()
endfunction

" }}}1

function! matchup#matchparen#enable() " {{{1
  augroup matchup_matchparen
    autocmd!
    autocmd CursorMoved  * call s:matchparen.highlight()
    autocmd CursorMovedI * call s:matchparen.highlight()
    autocmd BufLeave * call s:matchparen.clear()
  augroup END

  call s:matchparen.highlight()
endfunction

" }}}1
function! matchup#matchparen#disable() " {{{1
  call s:matchparen.clear()
  autocmd! matchup_matchparen
endfunction

" }}}1

let s:matchparen = {}

function! s:matchparen.clear() abort dict " {{{1
  silent! call matchdelete(w:matchup_match_id1)
  silent! call matchdelete(w:matchup_match_id2)
  if exists('w:matchup_match_id_list')
    for l:id in w:matchup_match_id_list
      silent! call matchdelete(l:id)
    endfor
    unlet! w:matchup_match_id_list
  endif
  unlet! w:matchup_match_id1
  unlet! w:matchup_match_id2

  if exists('w:matchup_oldecho')
    echo ''
    unlet w:matchup_oldecho
  endif
  
  if exists('w:matchup_oldstatus')
    let &statusline = w:matchup_oldstatus
    unlet w:matchup_oldstatus
  endif
endfunction
" }}}1

function! s:matchparen.highlight() abort dict " {{{1
  if !g:matchup_matchparen_enabled | return | endif

  call matchup#perf#tic('matchparen.highlight')

  let l:time_start = reltime()

  call self.clear()

  if matchup#util#in_comment() || matchup#util#in_string()
    return
  endif

  let l:current = matchup#delim#get_current('all', 'both_all')
  if empty(l:current) | return | endif

  let l:corrlist = matchup#delim#get_matching(l:current, 1)
  if empty(l:corrlist) | return | endif

  " echo map(deepcopy(l:corrlist), 'v:val.lnum')

  " for l:c in l:corrlist
  "   echom l:c.match
  " endfor
  " echo map(l:corrlist, 'get(v:val,"match","")')
  " PP map(l:corrlist, 'has_key'

  " set up links: assume [open, mid.., close]
  " let l:open = l:corrlist[0]
  " let l:close = l:corrlist[-1]

  " let l:toremove = -1
  " for l:i in range(len(l:corrlist))
  "   let l:c = l:corrlist[l:i]
  "   if empty(l:c)
  "     let l:corrlist[l:i] = l:current
  "     let l:toremove = l:i
  "     else
  "   endif
  "     " open prev next close 
  " endfor
  " if l:toremove > -1
  "   call remove(l:corrlist, l:toremove)
  " endif
  " let l:current.links = l:links

  " let l:corresponding = l:corrlist[-1]
  " let [l:open, l:close] = [l:corrlist[0], l:corrlist[-1]]

  " let [l:open, l:close] = l:current.is_open
  "       \ ? [l:current, l:corresponding]
  "       \ : [l:corresponding, l:current]

  " let l:mids = matchup#delim#get_middle(l:open, l:close)

  " let w:matchup_match_id1 = matchadd('MatchParen',
  "       \ '\%' . l:open.lnum . 'l\%' . l:open.cnum
  "       \ . 'c' . l:open.re.this)
  " let w:matchup_match_id2 = matchadd('MatchParen',
  "       \ '\%' . l:close.lnum . 'l\%' . l:close.cnum
  "       \ . 'c' . l:close.re.this)


  " elseif exists('w:matchup_oldstatus')
  "   let &statusline = w:matchup_oldstatus
  "   unlet w:matchup_oldstatus
  " endif
    " if get(w:, 'matchup_oldecho', [])
      " \ . (l:linenr < line('.') ? '%*%=(↑)' : ''
 
  if g:matchup_matchparen_status_offscreen
    call matchup#matchparen#offscreen(l:current)
  endif

      " echo printf('%'.(&numberwidth-1).'s %s',
      "       \ l:close.lnum, l:close.match)
      " echo printf('%'.(l:nw).'s %s', l:open.lnum, l:open.match)
      " let l:offset = screencol() - wincol()
      " echo printf('%'.(l:offset).'s %d', 'l', l:offscreen.lnum)
      " echom screencol()
    " else
    "   echo getline(l:offscreen.lnum)
    "   " echo l:open.match
    " endif
    " let w:matchup_oldecho = 1

  if !exists('w:matchup_match_id_list')
    let w:matchup_match_id_list = []
  elseif
  endif


  " echo map(l:corrlist, 'v:val.lnum." ".v:val.re.this')
" echo '^' l:corrlist
   " echo map(l:corrlist, 'v:val')

  for l:corr in l:corrlist
    " echo l:corr.lnum l:corr.rematch | sleep 1

    call add(w:matchup_match_id_list, matchadd('MatchParen',
       \   '\%' . l:corr.lnum . 'l'
       \ . '\%' . l:corr.cnum . 'c'
       \ . '\%(' . l:corr.rematch . '\)'))

    " echo \ '\%' . l:corr.lnum . 'l\%' . l:corr.cnum
    "    \ . 'c' . l:corr.re.this))
    " echo '\%' . l:corr.lnum . 'l\%' . l:corr.cnum
    "   \ . 'c\%(' . l:corr.regex . '\)' | sleep 1
  endfor

  " echo '\%' . l:open.lnum . 'l\%' . l:open.cnum . 'c' . l:open.re.this
    " \ '\%' . l:close.lnum . 'l\%' . l:close.cnum . 'c' . l:close.re.this

  let g:matchup_hi_time = 1000*reltimefloat(reltime(l:time_start))

  call matchup#perf#toc('matchparen.highlight', 'end')

endfunction

" }}}1
function! matchup#matchparen#offscreen(current) " {{{ 1
  let l:offscreen = {}
  if a:current.links.close.lnum > line('w$')
    let l:offscreen = a:current.links.close
  endif
  if a:current.links.open.lnum < line('w0')
    let l:offscreen = a:current.links.open
  endif

  if empty(l:offscreen) | return | endif

  let w:matchup_oldstatus = &statusline
  if &number
    let l:nw = max([strlen(line('$')), &numberwidth-1])
    let l:linenr = l:offscreen.lnum
    if &relativenumber
      let l:linenr = l:linenr-line('.')
    endif

    let l:sl = printf('%'.(l:nw).'s', l:linenr)
    if l:linenr < line('.')
      let l:sl = '%#Search#' . l:sl . '∆%*'
    else
      let l:sl .= ' '
    endif

    let l:line = getline(l:offscreen.lnum)

    let l:lasthi = ''
    for l:idx in range(min([winwidth(0), strchars(l:line)]))
      let l:c = strlen(strcharpart(l:line, 0, l:idx))
      " echo l:idx l:c | sleep 1
    endfor

    for l:c in range(min([winwidth(0), strlen(l:line)]))
      if l:offscreen.cnum <= l:c+1 && l:c+1 <= l:offscreen.cnum
            \ - 1 + strlen(l:offscreen.match)
        let l:curhi = 'MatchParen'
      else
        let l:curhi = synIDattr(
              \ synID(l:offscreen.lnum, l:c+1, 1), 'name')
      endif
      let l:sl .= (l:curhi !=# l:lasthi ? '%#'.l:curhi.'#' : '')
      if l:line[l:c] == "\t"
        let l:sl .= repeat(' ', strdisplaywidth(strpart(l:line, 0, 1+l:c))
              \ - strdisplaywidth(strpart(l:line, 0, l:c)))
      else
        let l:sl .= l:line[l:c]
      endif
      let l:lasthi = l:curhi
    endfor

    " let l:sl .= '%*' . strpart(l:line, 0, l:offscreen.cnum-1)
    "       \ . '%#MatchParen#'.(l:offscreen.match).'%*'
    "       \ . strpart(l:line, l:offscreen.cnum - 1
    "       \     + strlen(l:offscreen.match))

    let &statusline = l:sl
  else
    let &statusline = getline(l:offscreen.lnum)
  endif

endfunction

" }}}1

" vim: fdm=marker sw=2
