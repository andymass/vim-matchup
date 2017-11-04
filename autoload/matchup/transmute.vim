" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

function! matchup#transmute#init_module() " {{{1
  if !g:matchup_transmute_enabled | return | endif

  call matchup#transmute#enable()
endfunction

" }}}1

function! matchup#transmute#enable() " {{{1
  augroup matchup_transmute
    autocmd!
    autocmd InsertEnter * call s:transmute.setup()
    autocmd InsertLeave * call s:transmute.commit()
    autocmd TextChanged * call s:transmute.textchanged()
  augroup END
endfunction

" }}}1
function! matchup#transmute#disable() " {{{1
  autocmd! matchup_transmute
endfunction

" }}}1

let s:transmute = {}

" let s:cancel_next = 0
function! s:transmute.textchanged() abort dict " {{{1
  " if exists('w:matchparen_current')
  "   echo w:matchparen_current.links.close.match
  " endif
  " if s:cancel_next
  "   return
  "   let s:cancel_next = 0
  " endif

  call s:transmute.setup()
  call s:transmute.commit()

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

  if !g:matchup_transmute_enabled | return | endif
  if !exists('w:transmute_state') | return | endif

  " TODO ensure cursor position
  let l:current = matchup#delim#get_current('all', 'both_all')

  let l:corrlist = w:transmute_state.corrlist
  let l:prior = w:transmute_state.prior

 " echo l:current.match l:prior.match

  if empty(l:current) | return | endif
  "let l:threshold = l:prior.cnum + 

  let l:delta = strdisplaywidth(l:current.match)
        \ - strdisplaywidth(l:prior.match)

  for l:i in range(len(l:corrlist))
    if l:i == l:prior.match_index | continue | endif

    let l:corr = l:corrlist[l:i]
    let l:line = getline(l:corr.lnum)

    let l:column = l:corr.cnum
    if l:corr.lnum == l:current.lnum && l:i > l:prior.match_index
      let l:column += l:delta
    endif

    let l:re_anchored = '\%'.(l:column).'c'
          \ . '\%('.(l:corr.regexone[l:corr.side]).'\)'

    let l:groups = copy(l:corr.groups)
    for l:grp in keys(l:groups)
      let l:count = len(split(l:re_anchored, s:notslash.'\\'.l:grp))-1
      if l:count == 0 | continue | endif

      if l:current.groups[l:grp] ==# l:groups[l:grp]
        continue
      endif

      for l:dummy in range(len(l:count))
        let l:pattern = substitute(l:re_anchored,
              \ s:notslash.'\\'.l:grp,
              \ '\=''\zs'.(l:groups[l:grp]).'\ze''', '')
        let l:pattern = matchup#delim#fill_backrefs(l:pattern,
              \ l:groups)
        let l:string = l:current.groups[l:grp]
        let l:line = substitute(l:line, l:pattern,
              \ '\='''.l:string."'", '')

        " echo l:current.cnum l:pattern
      endfor

      let l:groups[l:grp] = l:current.groups[l:grp]
    endfor
    if getline(l:corr.lnum) !=# l:line
      call setline(l:corr.lnum, l:line)
    endif
  endfor

endfunction

let s:notslash = '\\\@<!\%(\\\\\)*'

" }}}1

" vim: fdm=marker sw=2

