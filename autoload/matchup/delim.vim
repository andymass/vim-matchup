" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:save_cpo = &cpo
set cpo&vim

function! matchup#delim#init_module() " {{{1

  " nnoremap <silent><buffer> <plug>(matchup-delim-delete)
  "       \ :call matchup#delim#delete()<cr>

       " <silent> XXX
  inoremap <plug>(matchup-delim-close)
        \ <c-r>=matchup#delim#close()<cr>

  augroup matchup_filetype
    au!
    autocmd FileType * call matchup#delim#init_buffer()
  augroup END

  call matchup#delim#init_buffer()

endfunction

" }}}1
function! matchup#delim#init_buffer() " {{{1
  " initialize lists of delimiter pairs and regular expressions
  " this is the data obtained from parsing b:match_words
  let b:matchup_delim_lists = s:init_delim_lists()

  " this is the combined set of regular expressions used for matching
  " its structure is matchup_delim_re[type][open,close,both,mid,both_all]
  let b:matchup_delim_re = s:init_delim_regexes()

  " enable/disable for this buffer
  let b:matchup_delim_enabled = 1
endfunction

" }}}1

function! matchup#delim#close() " {{{1
  let l:save_pos = matchup#pos#get_cursor()
  let l:pos_val_cursor = matchup#pos#val(l:save_pos)

  let l:lnum = l:save_pos[1] + 1
  while l:lnum > 1
    let l:open = matchup#delim#get_prev('all', 'open',
          \ { 'syn_exclude' : 'Comment' })
    if empty(l:open)
      break
    endif

    let l:close = matchup#delim#get_matching(l:open)
    if empty(l:close.match)
      call matchup#pos#set_cursor(l:save_pos)
      return l:open.corr
    endif

    let l:pos_val_try = matchup#pos#val(l:close) + strlen(l:close.match)
    if l:pos_val_try > l:pos_val_cursor
      call matchup#pos#set_cursor(l:save_pos)
      return l:open.corr
    else
      let l:lnum = l:open.lnum
      call matchup#pos#set_cursor(matchup#pos#prev(l:open))
    endif
  endwhile

  call matchup#pos#set_cursor(l:save_pos)
  return ''
endfunction

" }}}1

function! matchup#delim#get_next(type, side, ...) " {{{1
  return s:get_delim(extend({
        \ 'direction' : 'next',
        \ 'type' : a:type,
        \ 'side' : a:side,
        \}, get(a:, '1', {})))
endfunction

" }}}1
function! matchup#delim#get_prev(type, side, ...) " {{{1
  return s:get_delim(extend({
        \ 'direction' : 'prev',
        \ 'type' : a:type,
        \ 'side' : a:side,
        \}, get(a:, '1', {})))
endfunction

" }}}1
function! matchup#delim#get_current(type, side, ...) " {{{1
  return s:get_delim(extend({
        \ 'direction' : 'current',
        \ 'type' : a:type,
        \ 'side' : a:side,
        \}, get(a:, '1', {})))
endfunction

" }}}1
function! matchup#delim#get_matching(delim, ...) " {{{1
  if empty(a:delim) || !has_key(a:delim, 'lnum') | return {} | endif

  "PP a:delim.regextwo

  " get the matching position(s)
  let l:matches = []
  for l:down in {'open': [1], 'close': [0], 'mid': [0,1]}[a:delim.side]
    let l:save_pos = matchup#pos#get_cursor()
    call matchup#pos#set_cursor(a:delim)
    if !empty(l:matches)
      call add(l:matches, [])
    endif
    call extend(l:matches, a:delim.get_matching(l:down))
    call matchup#pos#set_cursor(l:save_pos)
  endfor

  if a:delim.side ==# 'open'
    call insert(l:matches, [])
  endif
  if a:delim.side ==# 'close'
    call add(l:matches, [])
  endif

  " echo '$' l:matches

  " create the match result(s)
  let l:matching_list = []
  for l:i in range(len(l:matches))
    if empty(l:matches[l:i])
      call add(l:matching_list, a:delim)
      continue
    end

    let [l:match, l:lnum, l:cnum] = l:matches[l:i]

    let l:matching = deepcopy(a:delim)
    let l:matching.lnum = l:lnum
    let l:matching.cnum = l:cnum
    let l:matching.match = l:match
    let l:matching.side = l:i == 0 ? 'open'
        \ : l:i == len(l:matches)-1 ? 'close' : 'mid'
    let l:matching.corr  = a:delim.match
    let l:matching.rematch = a:delim.regextwo[l:matching.side]

    " defunct, remove
    let l:matching.is_open = !a:delim.is_open
    " let l:matching.re.corr = a:delim.re.this
    " let l:matching.re.this = a:delim.re.mids
    if l:matching.type ==# 'delim'
      " let l:matching.corr_delim = a:delim.delim
      " let l:matching.corr_mod = a:delim.mod
      " let l:matching.delim = a:delim.corr_delim
    else
    endif

    call add(l:matching_list, l:matching)
  endfor
 
 " PP l:matching_list 

  for l:i in range(len(l:matching_list))
    let l:c = l:matching_list[l:i]
    if !has_key(l:c, 'links')
      let l:c.links = {}
    endif
    let l:c.links.next = l:matching_list[(l:i+1) % len(l:matching_list)]
    let l:c.links.prev = l:matching_list[l:i-1]
    let l:c.links.open = l:matching_list[0]
    let l:c.links.close = l:matching_list[-1]
  endfor

  if a:0 
    return l:matching_list
  else
    " return a:delim.links.next
    return a:delim.side ==# 'open' ? l:matching_list[-1]
       \ : l:matching_list[0]
  endif

endfunction

" }}}1
function! matchup#delim#get_surrounding(type) " {{{1
  let l:save_pos = matchup#pos#get_cursor()
  let l:pos_val_cursor = matchup#pos#val(l:save_pos)
  let l:pos_val_last = l:pos_val_cursor
  let l:pos_val_open = l:pos_val_cursor - 1

  while l:pos_val_open < l:pos_val_last
    let l:open  = matchup#delim#get_prev(a:type, 'open')
    if empty(l:open) | break | endif
    " echo l:open.lnum l:open.cnum
    let l:close = matchup#delim#get_matching(l:open)
    let l:pos_val_try = matchup#pos#val(l:close)
        \ + strdisplaywidth(l:close.match) - 1
    if l:pos_val_try >= l:pos_val_cursor
      call matchup#pos#set_cursor(l:save_pos)
      return [l:open, l:close]
    else
      call matchup#pos#set_cursor(matchup#pos#prev(l:open))
      let l:pos_val_last = l:pos_val_open
      let l:pos_val_open = matchup#pos#val(l:open)
    endif
  endwhile

  call matchup#pos#set_cursor(l:save_pos)
  return [{}, {}]
endfunction

" }}}1

function! s:get_delim(opts) " {{{1
  " Arguments: {{{2
  "   opts = {
  "     'direction'   : 'next' | 'prev' | 'current'
  "     'type'        : 'delim_tex'
  "                   | 'delim_all'
  "                   | 'all'
  "     'side'        : 'open'
  "                   | 'close'
  "                   | 'both'
  "                   | 'mid'
  "                   | 'both_all'
  "     'syn_exclude' :  don't match in given syntax
  "  }
  "  
  "  }}}2
  " Returns: {{{2
  "   delim = {
  "     type    : 'delim'
  "     lnum    : line number
  "     cnum    : column number
  "     match   : the actual text match
  "     side    : 'open' | 'close' | 'mid'
  "     regex  : regular expression which matched
  "     regextwo : regular expressions for corresponding
  "   }
  "
  " }}}2

  if !get(b:, 'matchup_delim_enabled', 0)
    return {}
  endif

  let l:time_start = reltime()

  " if col('.') < indent(line('.'))
  "     let l:elapsed_time = 1000*reltimefloat(reltime(l:time_start))
  "     echo 'nothing' l:elapsed_time
  " endif

  let l:save_pos = matchup#pos#get_cursor()

  " this contains all the patterns for the specified type and side
  let l:re = b:matchup_delim_re[a:opts.type][a:opts.side]

  let l:cursorpos = col('.') - (mode() ==# 'i' ? 1 : 0) 
  let l:re .= '\%>'.(l:cursorpos).'c'   
  " let l:re .= '\%>'.(col('.')).'c'   
  " let g:re = l:re

  " use the 'c' cpo flag to allow overlapping matches
  let l:save_cpo = &cpo
  noautocmd set cpo-=c 

  " in the first pass, we get matching line and column numbers
  " this is intended to be as fast as possible, with no capture groups
  " we look for a match on this line (if direction == current)
  " or forwards or backwards (if direction == next or prev)
  " for current, we actually search leftwards from the cursor
  while 1
    let [l:lnum, l:cnum] = a:opts.direction ==# 'next'
          \ ? searchpos(l:re, 'cnW', line('.') + s:stopline)
          \ : a:opts.direction ==# 'prev'
          \   ? searchpos(l:re, 'bcnW', max([line('.') - s:stopline, 1]))
          \   : searchpos(l:re, 'bcnW', line('.'))
    if l:lnum == 0 | break | endif

    " if invalid match, move cursor and keep looking
    " TODO this function should never be called 
    "   in 'current' mode, but we should be more explicit
    if matchup#util#in_comment(l:lnum, l:cnum)
        \ || matchup#util#in_string(l:lnum, l:cnum)

      " TODO support next too
      call matchup#pos#set_cursor(matchup#pos#prev(l:lnum, l:cnum))
      continue
    endif

    " TODO support b:match_skip, syn_exclude 
    " if has_key(a:opts, 'syn_exclude')
    "       \ && matchup#util#in_syntax(a:opts.syn_exclude, l:lnum, l:cnum)
    "   call matchup#pos#set_cursor(matchup#pos#prev(l:lnum, l:cnum))
    "   continue
    " endif
  " we prefer matches containing the cursor
  " loop through all the 

    break
  endwhile

  " restore cpo
  " note: this messes with cursor position
  noautocmd let &cpo = l:save_cpo

  " restore cursor
  call matchup#pos#set_cursor(l:save_pos)

  if l:lnum == 0
    let l:elapsed_time = 1000*reltimefloat(reltime(l:time_start)) 
    echo 'X' l:elapsed_time
   " v:vim_did_enter
  endif
 
  " nothing found, leave now
  if l:lnum == 0 | return {} | endif

  " now we get more data about the match in this position
  " there may be capture groups which need to be stored

  " result stub, to be filled by the parser when there is a match
  let l:result = {
        \ 'type'     : '',
        \ 'lnum'     : l:lnum,
        \ 'cnum'     : l:cnum,
        \ 'match'    : '',
        \ 'groups'   : '',
        \ 'side'     : '',
        \ 'is_open'  : '',
        \ 'regexone' : '',
        \ 'regextwo' : '',
        \}

  for l:type in s:types[a:opts.type]
    let l:parser_result = l:type.parser(l:lnum, l:cnum, a:opts)
    if !empty(l:parser_result)
      let l:result = extend(l:parser_result, l:result, 'keep')
      break
    endif
  endfor

  " PP l:result
  return empty(l:result.type) ? {} : l:result

  return {}

  " echo l:result.type
    " let l:sides = ['open', 'close', 'mid']
    " for l:rbr in b:matchup_delim_lists[a:opts.type].regex_backref
    "   for l:s in l:sides
    "     " xxx must use matchstrpos and compare column (?)
    "     " echo l:s l:rbr[l:s] l:cnum l:matches
    "     if l:cnum + strdisplaywidth(l:match)
    "         \ + (mode() ==# 'i' ? 1 : 0) > col('.')
    "       let l:found = 1
    "     endif

    "     if l:found | break | endif
    "   endfor
    "   if l:found | break | endif
    " endfor

    " if l:found
    "   " echo l:matches | sleep 200m
    " endif
  " endif

" return {}

    " let l:realside = l:line =~# b:matchup_delim_re[a:opts.type].open
    "   \ ? 'open'
    "   \ : l:line =~# b:matchup_delim_re[a:opts.type].close
    "   \   ? 'close'
    "   \   : 'mid'
    " let l:idx = s:parser_delim_find_regexp(getline(l:lnum), l:realside)
    " echo l:realside l:lnum l:line l:idx | sleep 100m

  "     " echo l:reb[l:s] | sleep 500m
  "   endfor
  " endfor
  " echo l:idx

  " let l:matches = matchlist(getline(l:lnum), '^' . l:re, l:cnum-1)
  " let l:match = l:matches[0]
  " echo l:re l:lnum l:cnum-1

  " let l:match = matchstr(getline(l:lnum), '^' . l:re, l:cnum-1)
  let l:match = l:matches[0]

  " echo l:lnum l:cnum-1 l:match

  " check that the cursor is inside the match
  if a:opts.direction ==# 'current'
        \ && l:cnum + strdisplaywidth(l:match)
        \  + (mode() ==# 'i' ? 1 : 0) <= col('.')
    let l:match = ''
    let l:lnum = 0
    let l:cnum = 0
  endif


  " get some more info about the match
  " the parser figures out what side the match it was
  let l:types = [
      \ {
      \   'regex' : b:matchup_delim_re.delim_all.both_all,
      \   'parser' : function('s:parser_delim'),
      \ },
      \]
  for l:type in l:types
    if l:match =~# '^' . l:type.regex
      let l:result = extend(
            \ l:type.parser(l:match, l:lnum, l:cnum,
            \   a:opts.side, a:opts.type, a:opts.direction),
            \ l:result, 'keep')
      break
    endif
  endfor

  return empty(l:result.type) ? {} : l:result
endfunction

" }}}1

function! s:parser_delim_new(lnum, cnum, opts) " {{{1
  let l:time_start = reltime()

  let l:cursorpos = col('.') - (mode() ==# 'i' ? 1 : 0) 

  if a:opts.direction ==# 'current'
    let l:found = 0

    let l:sides = s:sidedict[a:opts.side]
    let l:rebrs = b:matchup_delim_lists[a:opts.type].regex_backref

    " loop through all (index, side) pairs match pairs,
    " finding the first match which the cursor is inside
    let l:ns = len(l:sides)
    let l:found = 0
    for l:i in range(len(l:rebrs)*l:ns)
      let l:side = l:sides[ l:i % l:ns ]
      let l:re = l:rebrs[ l:i / l:ns ][l:side]
      if empty(l:re) | continue | end

      " prepend the column number and append 
      " the cursor column to anchor match
      " we don't use {start} for matchlist because there may 
      " be zero-width look behinds
      " XXX does \%<Nc work properly with tabs?
      " let l:re = '\%'.l:cnum.'c\%(' . l:re .'\)'
      "   \ . '\%>'.(col('.')).'c'   
      let l:re2 = '\%'.a:cnum.'c\%(' . l:re .'\)'
        \ . '\%>'.(l:cursorpos).'c'   
      " xxx is this index right?

      " echo l:re | sleep 6

      let l:matches = matchlist(getline(a:lnum), l:re2)

      if empty(l:matches) | continue | endif

      let l:match = l:matches[0]

      " echo localtime() l:re l:matches 'lc' l:lnum l:cnum
      "     \ l:cnum+strdisplaywidth(l:match) col('.') | sleep 1

      let l:found = 1
      break
    endfor

    let l:elapsed_time = 1000*reltimefloat(reltime(l:time_start)) 

    if l:found 
      let l:list = b:matchup_delim_lists[a:opts.type]
      let l:result = {
            \ 'type'         : 'delim',
            \ 'match'        : l:match,
            \ 'groups'       : l:matches,
            \ 'side'         : l:side,
            \ 'is_open'      : (l:side ==# 'open') ? 1 : 0,
            \ 'get_matching' : function('s:get_matching_delims'),
            \ 'regexone'     : l:list.regex[l:i / l:ns],
            \ 'regextwo'     : l:list.regex_backref[l:i / l:ns],
            \ 'rematch'      : l:re,
            \}

      "echo l:matches 'lc' a:lnum a:cnum l:elapsed_time
    endif

    if !l:found
        echo l:elapsed_time
        return {}
    endif
  endif

  return l:result
endfunction
" }}}1

function! s:parser_delim(match, lnum, cnum, ...) " {{{1
  let result = {}
  let result.type = 'delim'
  let result.side = a:match =~# b:matchup_delim_re.delim_all.open
    \ ? 'open'
    \ : a:match =~# b:matchup_delim_re.delim_all.close
    \   ? 'close'
    \   : 'mid'
  let result.get_matching = function('s:get_matching_delims')

  let result.is_open = result.side ==# 'open'  " xxx remove

  let l:type = 'delim_all'

  " find corresponding delimiter and the regexps
  let d1 = a:match

  let l:idx = s:parser_delim_find_regexp(a:match, result.side)
  let l:re1 = b:matchup_delim_lists[l:type].regex[l:idx][result.side]

  let l:rex = b:matchup_delim_lists[l:type].regex[l:idx]
  " echo l:result.side l:rex

  " let l:re1 = b:matchup_delim_lists[l:type].re[l:idx][result.is_open ? 0 : -1]

  " echo l:idx l:re1
  " let [re1, idx] = s:parser_delim_get_regexp(a:match, result.is_open ? 0 : -1)

  " let d2 = s:parser_delim_get_corr(a:match)
  " let [re2, idx] = s:parser_delim_get_regexp(d2, result.is_open ? -1 : 0)

  " ending delimiter *DEPRECATE THIS
  let d2 = b:matchup_delim_lists[l:type].name[l:idx][result.is_open ? -1 : 0]
  let re2 = b:matchup_delim_lists[l:type].re[l:idx][result.is_open ? -1 : 0]

  " middle set
  let d3 = b:matchup_delim_lists[l:type].name[l:idx][1:-2]
  let re3 = join(b:matchup_delim_lists[l:type].re[l:idx][1:-2], '\|')

  " echo 'd1' d1 're1' re1 'd2' d2 're2' re2 | sleep 400m

  let result.regex = re1
  let result.regextwo = b:matchup_delim_lists[l:type].regex[l:idx]

  " xxx we really don't need the rest of these
  " let result.links = {
  "       \ 'open'   : {},
  "       \ 'prev'   : {},
  "       \ 'next'   : {},
  "       \ 'close'  : {},
  "       \}
  let result.delim = d1
  let result.mod = ''       " xxx defunct
  let result.corr = 'FIXME2'
  let result.corr_delim = d2
  let result.corr_mod = ''  " xxx defunct
  let result.mids_ = 'FIXME3'     " xxx unused?
  let result.regextwo.this = re1
  let result.re = {
        \ 'this'  : re1,
        \ 'corr'  : re2,
        \ 'open'  : result.is_open ? re1 : re2,
        \ 'close' : result.is_open ? re2 : re1,
        \ 'mids'  : re3,
        \}

  return result
endfunction

" }}}1
function! s:parser_delim_find_regexp(delim, side, ...) " {{{1
  let l:type = a:0 > 0 ? a:1 : 'delim_all'

  let l:index = index(map(copy(b:matchup_delim_lists[l:type].regex),
        \ 'a:delim =~# v:val.' . a:side), 1)

  return l:index
endfunction

" }}}1
function! s:parser_delim_get_regexp(delim, side, ...) " {{{1
   " DEPRECATED REMOVE
  let l:type = a:0 > 0 ? a:1 : 'delim_all'

  let l:index = index(map(copy(b:matchup_delim_lists[l:type].re),
        \   'a:delim =~# v:val[' . a:side . ']'), 1)

  return [l:index >= 0
        \ ? b:matchup_delim_lists[l:type].re[l:index][a:side]
        \ : '', l:index]
endfunction

" }}}1
function! s:parser_delim_get_corr(delim, ...) " {{{1
  let l:type = a:0 > 0 ? a:1 : 'delim_all'

  for l:pair in b:matchup_delim_lists[l:type].re
    if a:delim =~# l:pair[0]
      return l:pair[-1]
    elseif a:delim =~# l:pair[-1]
      return l:pair[0]
    endif
  endfor
endfunction

" }}}1

function! s:get_matching_delims(down) dict " {{{1
  let [l:re, l:flags, l:stopline] = a:down
      \ ? [self.regextwo.close,  'zW', line('.') + s:stopline]
      \ : [self.regextwo.open,  'zbW', max([line('.') - s:stopline, 1])]

  " echo self.side

  " return [['', 0, 0]]

  " XXX
  let l:skip = 'matchup#util#in_comment() || matchup#util#in_string()'

  " remove capture groups
  " xxx spin off function
  let l:sub_grp = '\(\\\@<!\(\\\\\)*\)\@<=\\('
  let l:open = substitute(self.regextwo.open, l:sub_grp, '\\%(', 'g')
  let l:close = substitute(self.regextwo.close, l:sub_grp, '\\%(', 'g')
  let l:mids = substitute(self.regextwo.mid, l:sub_grp, '\\%(', 'g')

  " insert captured groups
  " XXX do this

  " this is the corresponding of an open:close pair
  let [l:lnum_corr, l:cnum_corr] = searchpairpos(l:open, '', l:close,
        \ 'n'.l:flags, l:skip, l:stopline)

  let l:match = matchstr(getline(l:lnum_corr), '^' . l:re, l:cnum_corr-1)

  " l:re might have back references
  " let l:match = l:matches[0]

  " echo self.regextwo
  " echo l:open l:close
  " echo a:down ? 'down' : 'up' l:lnum_corr l:cnum_corr l:match

  if empty(l:mids)
    return [[l:match, l:lnum_corr, l:cnum_corr]]
  endif

  let l:re .= '\|'.l:mids 

  " echo l:re

  let l:list = []
  while 1
    let [l:lnum, l:cnum] = searchpairpos(l:open, l:mids, l:close,
      \ l:flags, l:skip, l:lnum_corr)
    if l:lnum <= 0 | break | endif

" echo l:lnum l:cnum | sleep 500m
    if stridx(l:flags, 'b') >= 0
      if l:lnum < l:lnum_corr && l:cnum < l:cnum_corr | break | endif
    else
      if l:lnum > l:lnum_corr && l:cnum > l:cnum_corr | break | endif
    endif

    " XXX check lnum cnum vs lnum_corr cnum_corr

    let l:match = matchstr(getline(l:lnum), '^' . l:re, l:cnum-1)
    " echo l:lnum l:match | sleep 1
    call add(l:list, [l:match, l:lnum, l:cnum])
  endwhile

  if empty(l:list) | return [['', 0, 0]] | endif

  if !a:down
    call reverse(l:list)
  endif

  return l:list
endfunction
" }}}1

function! s:get_matching_delim() dict " {{{1
  let [re, flags, stopline] = self.is_open
        \ ? [self.re.close,  'nW', line('.') + s:stopline]
        \ : [self.re.open,  'bnW', max([line('.') - s:stopline, 1])]

  " xxx spin-off
  let l:open =  substitute(self.re.open,
    \ '\(\\\@<!\(\\\\\)*\)\@<=\\(', '\\%(', 'g')
  let l:close =  substitute(self.re.close,
    \ '\(\\\@<!\(\\\\\)*\)\@<=\\(', '\\%(', 'g')

  let [lnum, cnum] = searchpairpos(l:open, '', l:close,
        \ flags, '', stopline)
  let match = matchstr(getline(lnum), '^' . re, cnum-1)

  return [match, lnum, cnum]
endfunction
" }}}1

function! s:init_delim_lists() " {{{1
  let l:lists = { 'delim_tex': { 'name': [], 're': [], 
    \ 'regex': [], 'regex_backref': [] } }

 " let b:match_words = '\(\(foo\)\(bar\)\):\3\2:end\1'
 " let b:match_words = '\(foo\)\(bar\):more\1:and\2:end\1\2' 

  " parse matchpairs and b:match_words
  let l:mps = escape(&matchpairs, '[$^.*~\\/?]')
  let l:match_words = get(b:, 'match_words', '') . ','.l:mps
  let s:notslash = '\\\@<!\%(\\\\\)*'
  let l:sets = split(l:match_words, s:notslash.',')

  let l:seen = {}
  for l:s in l:sets
    if has_key(l:seen, l:s) | continue | endif
    let l:seen[l:s] = 1

    let l:words = split(l:s, s:notslash.':')

    " resolve backrefs to produce two sets of words,
    " one with \(foo\)s and one with \1s
    " XXX there is a counting problem: when substituting \(\) 
    " must increment the capture groups-it is very subtle.
    let l:words_backref = copy(l:words)
    let l:capture_groups = []

    for l:i in range(1, len(l:words)-1)
      " find the groups like \(foo\) in the previous set of words
      let l:cg = s:get_delim_capture_groups(l:words_backref[l:i-1])

      " substitute \1 with the found groups
      let l:words_backref[l:i] = substitute(l:words_backref[l:i],
        \ s:notslash.'\\'.'\(\d\)',
        \ '\=get(get(l:cg, submatch(1), {}), "str")', 'g')

      call add(l:capture_groups, l:cg)
    endfor

    " now replace the original capture groups with equivalent \1
    function! s:capture_group_sort(cg, a, b) dict
      return a:cg[a:b].depth - a:cg[a:a].depth
    endfunction

    for l:i in range(len(l:words)-1)
      let l:cg = l:capture_groups[l:i]
      if empty(l:cg) | continue | end

      " this must be done deepest to shallowest
      let l:order = sort(keys(l:cg), 'n')
      call sort(l:order, function('s:capture_group_sort', l:cg))
      for l:j in l:order
        let l:words[l:i] = strpart(l:words[l:i], 0, l:cg[l:j].pos[0])
              \ .('\'.l:j).strpart(l:words[l:i], l:cg[l:j].pos[1])
      endfor
    endfor

    call add(l:lists.delim_tex.regex, {
      \ 'open'     : l:words[0],
      \ 'close'    : l:words[-1],
      \ 'mid'      : join(l:words[1:-2], '\|'),
      \ 'mid_list' : l:words[1:-2],
      \})

    call add(l:lists.delim_tex.regex_backref, {
      \ 'open'     : l:words_backref[0],
      \ 'close'    : l:words_backref[-1],
      \ 'mid'      : join(l:words_backref[1:-2], '\|'),
      \ 'mid_list' : l:words_backref[1:-2],
      \ 'capgrps'  : l:capture_groups,
      \})

    call add(l:lists.delim_tex.re, deepcopy(l:words)) " xxx deprecated

    " xxx deprecate
    call add(l:lists.delim_tex.name, 
      \ map(l:words, '"m_".substitute(v:val, ''\\'', "", "g")'))
  endfor

  " get user defined lists
  " call extend(l:lists, get(g:, 'matchup_delim_list', {}))

  " generate corresponding regexes if necessary
  " for l:type in values(l:lists)
  "   if !has_key(l:type, 're') && has_key(l:type, 'name')
  "     let l:type.re = map(deepcopy(l:type.name),
  "           \ 'map(v:val, ''escape(v:val, ''''\$[]'''')'')')
  "   endif
  " endfor

  " generate combined lists
  let l:lists.delim_all = {}
  let l:lists.all = {}
  for k in ['name', 're', 'regex', 'regex_backref']
    let l:lists.delim_all[k] = l:lists.delim_tex[k]
    let l:lists.all[k] = l:lists.delim_all[k]
  endfor

  return l:lists
endfunction

" }}}1
function! s:init_delim_regexes() " {{{1
  let l:re = {}
  let l:re.delim_all = {}
  let l:re.all = {}

  let l:re.delim_tex = s:init_delim_regexes_generator('delim_tex')

  for l:k in ['open', 'close', 'both', 'mid', 'both_all']
    let l:re.delim_all[l:k] = l:re.delim_tex[l:k]
    let l:re.all[l:k] = l:re.delim_all[l:k]
  endfor

  " for l:type in values(l:re)
  "   for l:side in keys(l:type)
  " endfor

  " be explicit about regex mode (set magic mode)
  for l:type in values(l:re)
    for l:side in keys(l:type)
      let l:type[l:side] = '\m' . l:type[l:side]
    endfor
  endfor

  return l:re
endfunction

" }}}1
function! s:init_delim_regexes_generator(list_name) " {{{1
  let l:list = b:matchup_delim_lists[a:list_name].regex_backref

  " build the full regex strings: order matters here
  let l:regexes = {}
  for [l:key, l:sidelist] in items(s:sidedict)
    let l:relist = []

    for l:set in l:list
      for l:side in l:sidelist
        if strlen(l:set[l:side])
          call add(l:relist, l:set[l:side])
        endif
      endfor
    endfor

    let l:regexes[l:key] = s:remove_capture_groups(
          \ '\%(' . join(l:relist, '\|') . '\)')
  endfor

  " let l:open  = join(map(copy(l:list), 'v:val.open'), '\|')
  " let l:close = join(map(copy(l:list), 'v:val.close'), '\|')
  " let l:mids  = join(filter(map(copy(l:list), 'v:val.mid'),
  "                       \ '!empty(v:val)'), '\|')
  " let l:open = join(map(copy(l:list.re), 'v:val[0]'), '\|')
  " let l:close = join(map(copy(l:list.re), 'v:val[-1]'), '\|')
  " let l:mids = map(copy(l:list.re), 'join(v:val[1:-2], ''\|'')')
  " call filter(l:mids, '!empty(v:val)')
  " let l:mids = join(l:mids, '\|')

        " \ 'open' : '\%(' . l:open . '\)',
        " \ 'close' : '\%(' . l:close . '\)',
        " \ 'both' : '\%(' . l:open . '\|' . l:close . '\)',
        " \ 'mid' : strlen(l:mids) ? '\%(' . l:mids . '\)' : '',
        " \}

  " if strlen(l:mids)
    " let l:regexes.both_all = '\%(' . l:open . '\|' . l:close
        "                  \ . '\|' . l:mids . '\)'
  " else
    " let l:regexes.both_all = l:regexes.both
  " endif

  return l:regexes
endfunction

" }}}1
function! s:get_delim_capture_groups(str) " {{{1
  let l:pat = s:notslash.'\zs\(\\(\|\\)\)'

  let l:start = 0

  let l:brefs = {}
  let l:stack = []
  let l:counter = 0
  while 1
    let l:match = matchstrpos(a:str, l:pat, l:start)
    if l:match[1] < 0 | break | endif
    let l:start = l:match[2]

    if l:match[0] ==# '\('
      let l:counter += 1
      call add(l:stack, l:counter)
      let l:brefs[l:counter] = {
        \ 'str': '', 'depth': len(l:stack),
        \ 'pos': [l:match[1], 0],
        \}
    else
      if empty(l:stack) | break | endif
      let l:i = remove(l:stack, -1)
      let l:j = l:brefs[l:i].pos[0]
      let l:brefs[l:i].str = strpart(a:str, l:j, l:match[2]-l:j)
      let l:brefs[l:i].pos[1] = l:match[2]
    endif
  endwhile

  call filter(l:brefs, 'has_key(v:val, "str")')

  return l:brefs
endfunction
 
" }}}1

function! s:remove_capture_groups(re) "{{{
  let l:sub_grp = '\(\\\@<!\(\\\\\)*\)\@<=\\('
  return substitute(a:re, l:sub_grp, '\\%(', 'g')
endfunction

"}}}
function! s:mod(i, n) " {{{1
    return ((a:i % a:n) + a:n) % a:n
endfunction
" }}}1

" initialize script variables
let s:stopline = get(g:, 'matchup_delim_stopline', 500)
let s:notslash = '\\\@<!\%(\\\\\)*'

" xxx consider using instead
let s:not_bslash =  '\v%(\\@<!%(\\\\)*)@<='

let s:sidedict = {
      \ 'open'     : ['open'],
      \ 'mid'      : ['mid'],
      \ 'close'    : ['close'],
      \ 'both'     : ['open', 'close'],
      \ 'both_all' : ['open', 'close', 'mid'],
      \}
  
let s:basetypes = {
      \ 'delim_tex': {
      \   'parser' : function('s:parser_delim_new'),
      \ },
      \}

let s:types = {
      \ 'all'       : [ s:basetypes.delim_tex ],
      \ 'delim_all' : [ s:basetypes.delim_tex ],
      \ 'delim_tex' : [ s:basetypes.delim_tex ],
      \}

let &cpo = s:save_cpo

" vim: fdm=marker sw=2
