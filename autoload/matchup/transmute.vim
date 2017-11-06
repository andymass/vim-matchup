" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:save_cpo = &cpo
set cpo&vim

function! matchup#transmute#init_module() " {{{1
  if !g:matchup_transmute_enabled | return | endif

  call matchup#transmute#enable()
endfunction

" }}}1

function! matchup#transmute#enable() " {{{1
  augroup matchup_transmute
    autocmd!
    " autocmd InsertEnter * call s:transmute.setup()
    " autocmd InsertLeave * call s:transmute.commit()
    autocmd TextChanged,TextChangedI * call s:transmute.textchanged()
  augroup END
endfunction

" }}}1
function! matchup#transmute#disable() " {{{1
  autocmd! matchup_transmute
endfunction

" }}}1

let s:transmute = {}

function! matchup#transmute#tick(insertmode, entering_insert)

  if changenr() > get(w:, 'matchup_transmute_last_changenr', 0)
        \ && !empty('w:matchup_matchparen_context.prior')
    let w:matchup_transmute_last_changenr = changenr()

    return s:transmute.dochange(
          \ w:matchup_matchparen_context.prior.corrlist,
          \ w:matchup_matchparen_context.prior.current,
          \ w:matchup_matchparen_context.normal.current)
  endif

    " \ changenr()

    return 0

endfunction

" let s:cancel_next = 0
function! s:transmute.textchanged() abort dict " {{{1

  if !g:matchup_transmute_enabled | return | endif

  " if exists('w:matchparen_current')
  "   echo w:matchparen_current.links.close.match
  " endif
  " if s:cancel_next
  "   return
  "   let s:cancel_next = 0
  " endif

  " call s:transmute.setup()
  " call s:transmute.commit()
  
  if !exists('w:matchup_matchparen_context')
    return
  endif

  " echo w:matchup_matchparen_context.normal.singleton.match
  "       \ w:matchup_matchparen_context.insert.singleton.match
  " echo w:matchup_matchparen_context.counter
  "   \ w:matchup_matchparen_context.normal.current.match
  "       \ w:matchup_matchparen_context.prior.current.match

endfunction

" }}}1
function! s:transmute.setup() abort dict " {{{1
  if !g:matchup_transmute_enabled | return | endif

  " XXX  doesnt work because text changed already
  " let l:corrlist = matchup#delim#get_matching(l:prior, 1)
  " echo getline('.') | sleep 1
  " echo l:prior | redraw! | sleep 1

  if exists('w:transmute_state')
    unlet w:transmute_state
  endif

  let l:prior = deepcopy(get(w:, 'matchparen_current', {}))
  let l:corrlist = deepcopy(get(w:, 'matchparen_corrlist', []))

  if empty(l:prior) || empty(l:corrlist)
    return
  endif

  let w:transmute_state = {
        \ 'corrlist': l:corrlist,
        \ 'prior': l:prior
        \}
endfunction

" }}}1

function! s:transmute.commit() abort dict " {{{1
  "echo 'commit' reltime() | sleep 1

endfunction

" }}} 1

function! s:transmute.dochange(list, pri, cur) abort dict " {{{1
  " if !g:matchup_transmute_enabled | return | endif
  " echo 'doing change' a:pri.class a:cur.class

  if empty(a:list) || empty(a:pri) || empty(a:cur) | return 0 | endif

  " so far only same-class changes are supported
  if a:pri.class[0] != a:cur.class[0]
    return 0
  endif

  let l:num_changes = 0

  let l:delta = strdisplaywidth(a:cur.match)
        \ - strdisplaywidth(a:pri.match)

  for l:i in range(len(a:list))
    if l:i == a:pri.match_index | continue | endif

    let l:corr = a:list[l:i]
    let l:line = getline(l:corr.lnum)

    let l:column = l:corr.cnum
    if l:corr.lnum == a:cur.lnum && l:i > a:pri.match_index
      let l:column += l:delta
    endif

    let l:re_anchored = '\%'.(l:column).'c'
          \ . '\%('.(l:corr.regexone[l:corr.side]).'\)'

    let l:groups = copy(l:corr.groups)
    for l:grp in keys(l:groups)
      let l:count = len(split(l:re_anchored,
        \ g:matchup#re#not_bslash.'\\'.l:grp))-1
      if l:count == 0 | continue | endif

      if a:cur.groups[l:grp] ==# l:groups[l:grp]
        continue
      endif

      for l:dummy in range(len(l:count))
        let l:pattern = substitute(l:re_anchored,
              \ g:matchup#re#not_bslash.'\\'.l:grp,
              \ '\=''\zs'.(l:groups[l:grp]).'\ze''', '')
        let l:pattern = matchup#delim#fill_backrefs(l:pattern,
              \ l:groups, 0)
        let l:string = a:cur.groups[l:grp]
        let l:line = substitute(l:line, l:pattern,
              \ '\='''.l:string."'", '')
      endfor

      let l:groups[l:grp] = a:cur.groups[l:grp]
    endfor

    if getline(l:corr.lnum) !=# l:line
      " TODO break undo option
      " exe "normal! a\<c-g>u"
      call setline(l:corr.lnum, l:line)
      let l:num_changes += 1
    endif
  endfor

  return l:num_changes

endfunction

" }}}1

let &cpo = s:save_cpo

" vim: fdm=marker sw=2

