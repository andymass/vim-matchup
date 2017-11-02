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

  " process match_skip
  let b:matchup_delim_skip = s:init_delim_skip()

  " enable/disable for this buffer
  let b:matchup_delim_enabled = 1

  " surround? XXX
  " let b:surround_37 = b:matchup_delim_re.all.open
  "   \ . '\r' . b:matchup_delim_re.all.close

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

  " get all the matching position(s)
  " *important*: in the case of mid, we search up before searching down
  " this gives us a context object which we use for the other side
  let l:matches = []
  for l:down in {'open': [1], 'close': [0], 'mid': [0,1]}[a:delim.side]
    let l:save_pos = matchup#pos#get_cursor()
    call matchup#pos#set_cursor(a:delim)

    " second iteration: [] refers to the current match
    if !empty(l:matches)
      call add(l:matches, [])
    endif

    let l:res = a:delim.get_matching(l:down)
    if l:res[0][1] > 0
      call extend(l:matches, l:res)
    endif
    call matchup#pos#set_cursor(l:save_pos)
  endfor

  if a:delim.side ==# 'open'
    call insert(l:matches, [])
  endif
  if a:delim.side ==# 'close'
    call add(l:matches, [])
  endif

"  echo '$' l:matches

  " create the match result(s)
  let l:matching_list = []
  for l:i in range(len(l:matches))
    if empty(l:matches[l:i])
      let a:delim.match_index = l:i
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
    let l:matching.class[1] = 'FIXME'
    let l:matching.corr  = a:delim.match
    let l:matching.rematch = a:delim.regextwo[l:matching.side]
    let l:matching.match_index = l:i

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

  " set up links between matches
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
    " XXX old syntax: open-close, close-open
    return a:delim.side ==# 'open' ? l:matching_list[-1]
       \ : l:matching_list[0]
  endif

endfunction

" }}}1
function! matchup#delim#get_surrounding(type, ...) " {{{1
  call matchup#perf#tic('delim#get_surrounding')

  let l:save_pos = matchup#pos#get_cursor()
  let l:pos_val_cursor = matchup#pos#val(l:save_pos)
  let l:pos_val_last = l:pos_val_cursor
  let l:pos_val_open = l:pos_val_cursor - 1

  let l:count = a:0 >= 1 ? a:1 : 1
  let l:counter = l:count

  " provided count == 0 refers to local any block
  let l:local = l:count == 0 ? 1 : 0

  while l:pos_val_open < l:pos_val_last
    let l:open = matchup#delim#get_prev(a:type,
          \ l:local ? 'open_mid' : 'open')
    if empty(l:open) | break | endif

    let l:match = matchup#delim#get_matching(l:open, 1)
    let l:close = l:local ? l:open.links.next : l:open.links.close

    let l:pos_val_try = matchup#pos#val(l:close)
        \ + strdisplaywidth(l:close.match) - 1
    if l:pos_val_try >= l:pos_val_cursor
      if l:counter <= 1
        " restore cursor and accept
        call matchup#pos#set_cursor(l:save_pos)
        call matchup#perf#toc('delim#get_surrounding', 'accept')
        return [l:open, l:close]
      endif
      call matchup#pos#set_cursor(matchup#pos#prev(l:open))
      let l:counter -= 1
    else
      call matchup#pos#set_cursor(matchup#pos#prev(l:open))
      let l:pos_val_last = l:pos_val_open
      let l:pos_val_open = matchup#pos#val(l:open)
    endif
  endwhile

  " restore cursor and return failure
  call matchup#pos#set_cursor(l:save_pos)
  call matchup#perf#toc('delim#get_surrounding', 'fail')
  return [{}, {}]
endfunction

" }}}1
function! matchup#delim#jump_target(delim) "{{{1
  let l:save_pos = matchup#pos#get_cursor()

  let l:column = a:delim.cnum
  let l:column += strdisplaywidth(a:delim.match) - 1

  for l:tries in range(strdisplaywidth(a:delim.match)-2)
    call matchup#pos#set_cursor(a:delim.lnum, l:column)

    let l:delim_test = matchup#delim#get_current('all', a:delim.side)
    if l:delim_test.class[0] ==# a:delim.class[0]
      break
    endif

    let l:column -= 1
  endfor

  call matchup#pos#set_cursor(l:save_pos)
  return l:column
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

  call matchup#perf#tic('s:get_delim')

  let l:save_pos = matchup#pos#get_cursor()

  " this contains all the patterns for the specified type and side
  let l:re = b:matchup_delim_re[a:opts.type][a:opts.side]

  "   if c_col > 1 && (mode() == 'i' || mode() == 'R')
  "     let before = strlen(c_before)
  "     let c = c_before

  let l:cursorpos = col('.')
  if l:cursorpos > 1 && (mode() ==# 'i' || mode() ==# 'R')
    let l:cursorpos -= 1 
  endif 
  " echo l:cursorpos mode() v:insertmode expand('<amatch>')

  let a:opts.cursorpos = l:cursorpos

  " TODO XXX does this even make any sense?
  "
  " for current, we want to find matches that end after the cursor
  if a:opts.direction ==# 'current'
    let l:re .= '\%>'.(l:cursorpos).'c'
  endif
 
  " let l:re .= '\%>'.(col('.')).'c'   
  " let g:re = l:re

  " use the 'c' cpo flag to allow overlapping matches
  let l:save_cpo = &cpo
  noautocmd set cpo-=c 

  " use b:match_ignorecase
  call s:ignorecase_start()

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

  "  echo l:re l:lnum l:cnum | sleep 1
" echo l:lnum l:cnum line('.')-s:stopline a:opts.direction | sleep 1
"echo l:lnum l:re a:opts.direction ==# 'prev' | sleep 1
"  echo l:lnum l:cnum | sleep 1

    " if matchup#util#in_comment(l:lnum, l:cnum)
    "     \ || matchup#util#in_string(l:lnum, l:cnum)

  " XXX get rid of this..
  call matchup#pos#set_cursor([l:lnum, l:cnum])

    " note: this function should never be called 
    " in 'current' mode, but be explicit
    if a:opts.direction !=# 'current'
          \ && matchup#delim#skip(l:lnum, l:cnum)

      " echo 'rejct'

      " if invalid match, move cursor and keep looking
      call matchup#pos#set_cursor(a:opts.direction ==# 'next'
            \ ? matchup#pos#next(l:lnum, l:cnum)
            \ : matchup#pos#prev(l:lnum, l:cnum))
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

  " reset ignorecase
  call s:ignorecase_end()

  " restore cursor
  call matchup#pos#set_cursor(l:save_pos)

  call matchup#perf#toc('s:get_delim', 'first_pass')

  " nothing found, leave now
  if l:lnum == 0
    call matchup#perf#toc('s:get_delim', 'nothing_found')
    return {}
  endif

  " now we get more data about the match in this position
  " there may be capture groups which need to be stored

  " result stub, to be filled by the parser when there is a match
  let l:result = {
        \ 'lnum'     : l:lnum,
        \ 'cnum'     : l:cnum,
        \ 'type'     : '',
        \ 'match'    : '',
        \ 'augment'  : '',
        \ 'groups'   : '',
        \ 'side'     : '',
        \ 'class'    : [],
        \ 'is_open'  : '',
        \ 'regexone' : '',
        \ 'regextwo' : '',
        \ 'rematch'  : '',
        \}

  for l:type in s:types[a:opts.type]
    let l:parser_result = l:type.parser(l:lnum, l:cnum, a:opts)
    if !empty(l:parser_result)
      let l:result = extend(l:parser_result, l:result, 'keep')
      break
    endif
  endfor

  call matchup#perf#toc('s:get_delim', 'got_results')

  return empty(l:result.type) ? {} : l:result
endfunction

" }}}1

function! s:ignorecase_start() " {{{1
  " enforce b:match_ignorecase, if necessary
  if exists('s:save_ic')
    return
  endif
  if exists('b:match_ignorecase') && b:match_ignorecase !=# &ignorecase
    let l:save_ic = &ignorecase
    noautocmd let &ignorecase = b:match_ignorecase
  endif
endfunction

"}}}1
function! s:ignorecase_end() " {{{1
  " restore ignorecase
  if exists('s:save_ic')
    noautocmd let &ignorecase = s:save_ic
    unlet s:save_ic
  endif
endfunction

"}}}1

function! s:parser_delim_new(lnum, cnum, opts) " {{{1
  let l:time_start = reltime()

  let l:cursorpos = a:opts.cursorpos
  " XXX TODO stuff this in opts instead
  " let l:cursorpos = col('.') - (mode() ==# 'i' ? 1 : 0) 

  if 1 " a:opts.direction ==# 'current'
    let l:found = 0

    let l:sides = s:sidedict[a:opts.side]
    let l:rebrs = b:matchup_delim_lists[a:opts.type].regex_backref

    " loop through all (index, side) pairs,
    let l:ns = len(l:sides)
    let l:found = 0
    for l:i in range(len(l:rebrs)*l:ns)
      let l:side = l:sides[ l:i % l:ns ]

      if l:side ==# 'mid'
        let l:res = l:rebrs[l:i / l:ns].mid_list
        if empty(l:res) | continue | end
      else
        let l:res = [ l:rebrs[l:i / l:ns][l:side] ]
        if empty(l:res[0]) | continue | end
      endif

      let l:mid_id = 0
      for l:re in l:res
        let l:mid_id += 1

        " prepend the column number and append the cursor column 
        " to anchor the match; we don't use {start} for matchlist
        " because there may be zero-width look behinds

        " XXX TODO does \%<Nc work properly with tabs?
        let l:re_anchored = '\%'.a:cnum.'c\%(' . l:re .'\)'

    " for current we want the first match which the cursor is inside
        if a:opts.direction ==# 'current'
          let l:re_anchored .= '\%>'.(l:cursorpos).'c'
        endif


        let l:matches = matchlist(getline(a:lnum), l:re_anchored)
        if empty(l:matches) | continue | endif

       " echo l:re_anchored l:matches

        let l:found = 1
        break
      endfor

      if !l:found | continue | endif

      break
    endfor

    if !l:found
        return {}
    endif

    let l:match = l:matches[0]

    let l:list = b:matchup_delim_lists[a:opts.type]
    let l:thisre   = l:list.regex[l:i / l:ns]
    let l:thisrebr = l:list.regex_backref[l:i / l:ns]

    let l:augment = {}

    " these are the capture groups indexed by their 'open' id
    let l:groups = {}
    let l:id = 0

    if l:side ==# 'open'
      " XXX we might as well store all the groups...
      "for l:br in keys(l:thisrebr.need_grp)
      for l:br in range(1,9)
        if empty(l:matches[l:br]) | continue | endif
        let l:groups[l:br] = l:matches[l:br]
      endfor
    else
      let l:id = (l:side ==# 'close')
            \ ? len(l:thisrebr.mid_list)+1
            \ : l:mid_id

      for [l:br, l:to] in items(l:thisrebr.grp_renu[l:id])
        let l:groups[l:to] = l:matches[l:br]
      endfor

      " echo l:groups l:thisrebr.grp_renu[l:id]
      " echo l:thisrebr.aug_comp[l:id][0]

      " fill in augment pattern
      " TODO all the augment patterns should match,
      " but checking might be too slow
      let l:aug = l:thisrebr.aug_comp[l:id][0]
      let l:augment.str = substitute(l:aug.str,
            \ g:matchup#re#backref,
            \ '\=l:groups[submatch(1)]', 'g')
      let l:augment.unresolved = deepcopy(l:aug.outputmap)
    endif

    " echo l:re l:groups 
    " echo l:thisrebr.aug_comp[l:id]
    " echo l:re l:augment l:groups l:thisrebr.need_grp

    let l:result = {
          \ 'type'         : 'delim',
          \ 'match'        : l:match,
          \ 'augment'      : l:augment,
          \ 'groups'       : l:groups,
          \ 'side'         : l:side,
          \ 'class'        : [(l:i / l:ns), l:id],
          \ 'is_open'      : (l:side ==# 'open') ? 1 : 0,
          \ 'get_matching' : function('s:get_matching_delims'),
          \ 'regexone'     : l:thisre,
          \ 'regextwo'     : l:thisrebr,
          \ 'rematch'      : l:re,
          \}

    " echo l:re
    "echo l:matches 'lc' a:lnum a:cnum l:elapsed_time

    return l:result

  endif

  return {}
endfunction
" }}}1

function! s:get_matching_delims(down) dict " {{{1
  " called as:   a:delim.get_matching(...)
  " called from: matchup#delim#get_matching <- matchparen, motion
  "   from: matchup#delim#get_surrounding <- matchparen, motion, text_obj
  "   from: matchup#delim#close <- delim

  call matchup#perf#tic('get_matching_delims')

  " first, we figure out what the furthest match is, which will be
  " either the open or close depending on the direction
  let [l:re, l:flags, l:stopline] = a:down
      \ ? [self.regextwo.close, 'zW', line('.') + s:stopline]
      \ : [self.regextwo.open, 'zbW', max([line('.') - s:stopline, 1])]

  " these are the anchors for searchpairpos
  let l:open = self.regexone.open     " XXX is this right? BADLOGIC
  let l:close = self.regexone.close

  " if we're searching up, we anchor by the augment, if it exists
  if !a:down && !empty(self.augment)
    let l:open = self.augment.str
  endif

  "echo '% op' l:open 'cl' l:close 're' l:re '|' self.groups 'a' self.augment

  " XXX temporary workaround for BADLOGIC
  if a:down && self.side ==# 'mid'
    let l:open = self.regextwo.open
  endif

  " turn \(\) into \%(\) for searchpairpos
  let l:open  = s:remove_capture_groups(l:open)
  let l:close = s:remove_capture_groups(l:close)

  " fill in backreferences
  " let l:re = matchup#delim#fill_backrefs(l:re, self.groups)
  let l:open = matchup#delim#fill_backrefs(l:open, self.groups)
  let l:close = matchup#delim#fill_backrefs(l:close, self.groups)

  " XXX echo l:open l:re l:close self.augment
" echo l:open l:re l:close self.augment self.groups

  " TODO: support match_skip
  " let l:skip = 'matchup#util#in_comment() || matchup#util#in_string()'
  " let l:skip = b:matchup_delim_skip
  let l:skip = 'matchup#delim#skip()'

  " XXX timeout
   " XXX use s: mode flag
  " let l:timeout = (mode() ==# 'i')
  "       \ ? g:matchup_matchparen_insert_timeout
  "       \ : g:matchup_matchparen_timeout

  if matchup#perf#timeout_check() | return [['', 0, 0]] | endif

  " this is the corresponding part of an open:close pair
   " if !exists('s:foo') | let s:foo = 1 | endif
   " echo s:foo | sleep 1
   " let s:foo+= 1

   " improves perceptual performance
   " XXX use s: mode flag
   if mode() ==# 'i'
     sleep 1m
   endif

  " use b:match_ignorecase
  call s:ignorecase_start()


"  call matchup#perf#tic('q7')
"  TODO support timeout
  let [l:lnum_corr, l:cnum_corr] = searchpairpos(l:open, '', l:close,
        \ 'n'.l:flags, l:skip, l:stopline, matchup#perf#timeout())
"  call matchup#perf#toc('q7', 'q8')
  call matchup#perf#toc('get_matching_delims', 'initial_pair')

  " reset ignorecase
  call s:ignorecase_end()

  " echo l:lnum_corr l:open l:close self.groups self.regexone.close
  " echo self.regexone.open self.regextwo.open
  " if a:down
  "   echo '^^' a:down l:lnum_corr l:cnum_corr l:open
  "         \ l:close l:stopline " self.augment.str
  " endif

  " if nothing found, bail immediately
  if l:lnum_corr == 0 | return [['', 0, 0]] | endif

  " get the match and groups
  let l:re_anchored = '\%'.l:cnum_corr.'c\%(' . l:re .'\)'
  let l:matches = matchlist(getline(l:lnum_corr), l:re_anchored)
  let l:match_corr = l:matches[0]

  " echo a:down self.groups | sleep 1

  " store these in these groups
  if a:down
    " let l:id = len(self.regextwo.mid_list)+1
    " for [l:from, l:to] in items(self.regextwo.grp_renu[l:id])
    "   let self.groups[l:to] = l:matches[l:from]
    " endfor
  else
    for l:to in range(1,9)
      if !has_key(self.groups, l:to) && !empty(l:matches[l:to])
        let self.groups[l:to] = l:matches[l:to]
      endif
    endfor
  endif

  call matchup#perf#toc('get_matching_delims', 'get_matches')

  " fill in additional groups
  let l:mids = s:remove_capture_groups(self.regexone.mid)
  let l:mids = matchup#delim#fill_backrefs(l:mids, self.groups)

  " echo a:down self.regexone self.groups
  " echo a:down self.groups l:matches | sleep 1

  " if there are no mids, we're done
  if empty(l:mids)
    return [[l:match_corr, l:lnum_corr, l:cnum_corr]]
  endif

  let l:re = l:mids 

  " if !a:down
  "   " echo l:re
  " endif

  " echo 'x' self.regexone self.regextwo
  " echo 'x' l:re
  " let l:match = matchstr(getline(l:lnum_corr), '^' . l:re, l:cnum_corr-1)

  " echo self.groups | sleep 1

  " XXX XXX!
  " there may be backrefs that need to be filled out
  " let l:re = s:fill_backrefs(l:re, self.groups)
  " XXX

  " echo self.side
  " return [['', 0, 0]]

  " if !a:down
  "   echo self.regexone | sleep 1
  " endif

  " turn \(\) into \%(\)
  " let l:open  = s:remove_capture_groups(self.regexone.open) 
  " let l:close = s:remove_capture_groups(self.regexone.close) 

  " " fill out backreferences
  " let l:open  = s:fill_backrefs(l:open,  self.groups)
  " let l:close = s:fill_backrefs(l:close, self.groups)

  " XXX XXX XXX we need to distinguish between
  " filled (resolved) and unfilled
  " capture groups, interpolating without valid data won't work
  " XXX also need to escape to form regex, or \V...\m
  " if !a:down
  "   " echo l:re '|' l:open '|' l:close | sleep 1
  " endif

  " xxx spin off function
  " insert captured groups
  " XXX do this

  " l:re might have back references
  " let l:match = l:matches[0]

  " echo self.regextwo
  " echo l:open l:close
  " echo a:down ? 'down' : 'up' l:lnum_corr l:cnum_corr l:match
  " echo l:re
  
  " use b:match_ignorecase
  call s:ignorecase_start()

  let l:list = []
  while 1

    if matchup#perf#timeout_check() | break | endif

    let [l:lnum, l:cnum] = searchpairpos(l:open, l:mids, l:close,
      \ l:flags, l:skip, l:lnum_corr, matchup#perf#timeout())
    if l:lnum <= 0 | break | endif

    " echo '>' l:lnum l:cnum | sleep 500m

    " if stridx(l:flags, 'b') >= 0

    if a:down
      if l:lnum >= l:lnum_corr && l:cnum >= l:cnum_corr | break | endif
    else
      if l:lnum <= l:lnum_corr && l:cnum <= l:cnum_corr | break | endif
    endif

    " XXX check lnum cnum vs lnum_corr cnum_corr

    " TODO: can this step be removed?
    " XXX

   let l:re_anchored = '\%'.l:cnum.'c\%(' . l:re .'\)'
   let l:matches = matchlist(getline(l:lnum), l:re_anchored)
   let l:match = l:matches[0]


    " echo '%' a:down l:lnum l:matches l:re_anchored | sleep 600m
    " echo '%' self.regexone.mid self.groups l:re_anchored

    " let l:match = matchstr(getline(l:lnum), '^' . l:re, l:cnum-1)
    " echo l:lnum l:match | sleep 1

    call add(l:list, [l:match, l:lnum, l:cnum])
  endwhile

  " reset ignorecase
  call s:ignorecase_end()

  call add(l:list, [l:match_corr, l:lnum_corr, l:cnum_corr])

 " if empty(l:list) | return [['', 0, 0]] | endif

  if !a:down
    call reverse(l:list)
  endif

  " echo a:down l:list | sleep 1

  return l:list
endfunction
" }}}1

function! s:init_delim_lists() " {{{1
  let l:lists = { 'delim_tex': { 'name': [], 're': [],
        \ 'regex': [], 'regex_backref': [] } }

  " very tricky examples:
  " good: let b:match_words = '\(\(foo\)\(bar\)\):\3\2:end\1'
  " bad:  let b:match_words = '\(foo\)\(bar\):more\1:and\2:end\1\2'

  " *subtlety*: there is a huge assumption in matchit:
  "   ``It should be possible to resolve back references
  "     from any pattern in the group.''
  " we don't explicitly check this, but the behavior might
  " be unpredictable if such groups are encountered.. (ref-1)

  " parse matchpairs and b:match_words
  let l:mps = escape(&matchpairs, '[$^.*~\\/?]')
  let l:match_words = get(b:, 'match_words', '')
  if !empty(l:match_words) && l:match_words !~# ':'
    echohl ErrorMsg
    echo 'match-up: function b:match_words not supported'
    echohl None
    let l:match_words = ''
  endif
  let l:match_words .= ','.l:mps
  let l:sets = split(l:match_words, g:matchup#re#not_bslash.',')

  " do not duplicate whole groups of match words
  let l:seen = {}
  for l:s in l:sets
    if has_key(l:seen, l:s) | continue | endif
    let l:seen[l:s] = 1

    let l:words = split(l:s, g:matchup#re#not_bslash.':')

    " we will resolve backrefs to produce two sets of words,
    " one with \(foo\)s and one with \1s, along with a set of
    " bookkeeping structures
    let l:words_backref = copy(l:words)

    " *subtlety*: backref numbers refer to the capture groups
    " in the 'open' pattern so we have to carefully keep track
    " of the group renumbering
    let l:group_renumber = {}
    let l:augment_comp = {}
    let l:all_needed_groups = {}

    " *subtlety*: when replacing things like \1 with \(...\)
    " the insertion could possibly contain back references of
    " its own; this poses a very difficult bookkeeping problem,
    " so we just disallow it.. (ref-2)

    " get the groups like \(foo\) in the 'open' pattern
    let l:cg = matchup#delim#get_capture_groups(l:words[0])

    " if any of these contain \d raise a warning
    " and substitute it out (ref-2)
    for l:cg_i in keys(l:cg)
      if l:cg[l:cg_i].str =~# g:matchup#re#backref
        echohl WarningMsg
        echom 'match-up: capture group' l:cg[l:cg_i].str
              \ 'should not contain backrefs (ref-2)'
        echohl None
        let l:cg[l:cg_i].str = substitute(l:cg[l:cg_i].str,
              \ g:matchup#re#backref, '', 'g')
      endif
    endfor

    " for the 'open' pattern, create a series of replacements
    " of the capture groups with \9, \8, ..., \1
    " this must be done deepest to shallowest
    let l:augments = {}
    let l:order = matchup#delim#capture_group_replacement_order(l:cg)

    let l:curaug = l:words[0]
    " TODO: \0 should match the whole pattern..
    " augments[0] is the original words[0] with original capture groups
    let l:augments[0] = l:curaug " XXX does putting this in 0 make sense?
    for l:j in l:order
      " these indexes are not invalid because we work backwards
      let l:curaug = strpart(l:curaug, 0, l:cg[l:j].pos[0])
            \ .('\'.l:j).strpart(l:curaug, l:cg[l:j].pos[1])
      let l:augments[l:j] = l:curaug
    endfor

    " XXX todo this logic might be bad BADLOGIC
    " should we not fill groups that aren't needed?
"    echo l:order l:augments
    " l:words[0] should never be used

    " the last element in the order gives the most augmented string
    " this includes groups that might not actually be needed elsewhere
    if !empty(l:order)
      let l:words[0] = l:augments[l:order[-1]]
    endif

    " as a concrete example,
    " l:augments = { '0': '\<\(wh\%[ile]\|for\)\>', '1': '\<\1\>'}
    " l:words[0] = \<\1\>

  " echo l:augments l:words[0]

    " now for the rest of the words...
    for l:i in range(1, len(l:words)-1)

      " first get rid of the capture groups in this pattern
      let l:words_backref[l:i] = s:remove_capture_groups(
            \ l:words_backref[l:i])

      " get the necessary \1, \2, etc back-references
      let l:needed_groups = []
      call substitute(l:words_backref[l:i], g:matchup#re#backref,
            \ '\=len(add(l:needed_groups, submatch(1)))', 'g')
      call filter(l:needed_groups,
            \ 'index(l:needed_groups, v:val) == v:key')

      " warn if the back-referenced groups don't actually exist
      for l:ng in l:needed_groups
        if has_key(l:cg, l:ng)
          let l:all_needed_groups[l:ng] = 1
        else
          echohl WarningMsg
          echom 'match-up: backref \' l:ng 'requested but no '
                \ . 'matching capture group provided'
          echohl None
        endif
      endfor

      " substitute capture groups into the backrefs and keep
      " track of the mapping to the original backref number
      let l:group_renumber[l:i] = {}

      let l:cg2 = {}
      for l:bref in l:needed_groups

        " turn things like \1 into \(...\)
        " replacement is guaranteed to exist and not contain \d
        let l:words_backref[l:i] = substitute(l:words_backref[l:i],
              \ g:matchup#re#backref,
              \ '\='''.l:cg[l:bref].str."'", '')    " not global!!
        " \ s:notslash.'\\'.l:bref,

        " echo '#'.l:i '%' '\'.l:bref l:words_backref[l:i] l:cg[l:bref]

        let l:prev_max = max(keys(l:cg2))
        let l:cg2 = matchup#delim#get_capture_groups(l:words_backref[l:i])

        " echo l:i '%' l:bref l:words_backref[l:i] l:cg2

        for l:cg2_i in sort(keys(l:cg2), 'N')
          if l:cg2_i > l:prev_max
            " maps capture groups to 'open' back reference numbers
            let l:group_renumber[l:i][l:cg2_i] = l:bref
                  \ + (l:cg2_i - 1 - l:prev_max)
          endif
        endfor

        " if any backrefs remain, replace with re-numbered versions
        let l:words_backref[l:i] = substitute(l:words_backref[l:i],
              \ g:matchup#re#not_bslash.'\\'.l:bref,
              \ '\\\=l:group_renumber[l:i][submatch(1)]', 'g')
      endfor

    " echo ' ->' l:words[l:i] l:words_backref[l:i] l:group_renumber[l:i]
    " echo l:words[l:i] '->' l:words_backref[l:i]

      if len(uniq(sort(values(l:group_renumber[l:i]))))
            \ != len(l:group_renumber[l:i])
          echohl ErrorMsg
          echom 'match-up: duplicate bref in set ' l:s ':' l:i
          echohl None
      endif

      " compile the augment list for this set of backrefs, going
      " deepest first and combining as many steps as possible
      let l:resolvable = {}
      let l:dependency = {}

      let l:instruct = []
      for l:j in l:order
        " the in group is the local number from this word pattern
        let l:in_grp = keys(filter(
              \ deepcopy(l:group_renumber[l:i]), 'v:val == l:j'))

        " echo '!' l:i l:in_grp l:group_renumber[l:i]

        if empty(l:in_grp) | continue | endif
        let l:in_grp = l:in_grp[0]

        " if anything depends on this, flush out the current resolvable
        if has_key(l:dependency, l:j)
          call add(l:instruct, copy(l:resolvable))
          let l:dependency = {}
        endif

        " walk up the tree marking any new dependency
        let l:node = l:j
        for l:dummy in range(11)
          let l:node = l:cg[l:node].parent
          if l:node == 0 | break | endif
          let l:dependency[l:node] = 1
        endfor

        " mark l:j as resolvable
        let l:resolvable[l:j] = l:in_grp
      endfor

      if !empty(l:resolvable)
        call add(l:instruct, copy(l:resolvable))
      endif

      " echo l:augments
      " echo '[' l:words[0] l:words_backref[l:i] l:instruct
      " echo l:instruct

      " *note*: recall that l:augments[2] is the result of augments
      " up to and including 2

      " this is a set of instructions of which brefs to resolve
      let l:augment_comp[l:i] = []
      for l:instr in l:instruct
        " the smallest key is the greediest, due to l:order
        let l:minkey = min(keys(l:instr))
        call insert(l:augment_comp[l:i], {
              \ 'inputmap': {},
              \ 'outputmap': {},
              \ 'str': l:augments[l:minkey],
              \})

        let l:remaining_out = {}
        for l:out_grp in keys(l:cg)
          let l:remaining_out[l:out_grp] = 1
        endfor

        " input map turns this word pattern numbers into 'open' numbers
        for [l:out_grp, l:in_grp] in items(l:instr)
          let l:augment_comp[l:i][0].inputmap[l:in_grp] = l:out_grp
          if has_key(l:remaining_out, l:out_grp)
            call remove(l:remaining_out, l:out_grp)
          endif
        endfor

        " echo l:words[l:i] l:instr l:augment_comp[l:i][0].inputmap
        " echo l:words[l:i] l:words[0] l:remaining_out

        " output map turns remaining group numbers into 'open' numbers
        let l:counter = 1
        for l:out_grp in sort(keys(l:remaining_out), 'N')
          let l:augment_comp[l:i][0].outputmap[l:counter] = l:out_grp
          let l:counter += 1
        endfor
      endfor

      " echo l:augment_comp
      " echo l:order l:i l:words_backref[l:i]
      " echo 'q' l:words[l:i] l:words_backref[l:i] l:augment_comp[l:i]

        " echo l:instr
      " echo ']' l:words[0] l:words_backref[l:i] l:augment_comp[l:i]
      "       \ l:needed_groups
      " echo l:instr l:augment_comp[l:i]

      " if l:instruct was empty, there are no constraints
      if empty(l:instruct) && !empty(l:augments)
        let l:augment_comp[l:i] = [{
              \ 'inputmap': {},
              \ 'outputmap': {},
              \ 'str': l:augments[0],
              \}]
        for l:cg_i in keys(l:cg)
          let l:augment_comp[l:i][0].outputmap[l:cg_i] = l:cg_i
        endfor
      endif
    endfor

    " remove augments that can never be filled
   " echo l:words l:augments l:order l:all_needed_groups
    " XXX should really be building augment here?

    " strip out unneeded groups in output maps
    for l:i in keys(l:augment_comp)
      for l:aug in l:augment_comp[l:i]
        call filter(l:aug.outputmap,
              \ 'has_key(l:all_needed_groups, v:key)')
      endfor
    endfor

    " echo l:words
    " echo l:augment_comp
    " echo l:augment_comp
    " echo l:order l:augment_comp[l:i]
    " echo l:words[l:i] l:instruct l:augment_comp[l:i]

      " for l:bref in sort(values(l:group_renumber[l:i]))
      " let l:breakpoints = []
        " let l:bref = l:augments[l:j]

      " keys(l:group_renumber[l:i])[l:cg2_i] = l:bref
      " let l:aug_comp = []

      " xxx verify (ref-1)
      " function! s:process_recapture(cg, sm)
      "   return get(get(a:cg, a:sm, {}), "str")', 'g')
      " endfunction

      " let l:words_backref[l:i] = substitute(l:words_backref[l:i],
      "       \ s:notslash.'\\'.'\(\d\)',
      "       \ 's:process_recapture(l:cg, submatch(1)), 'g')

        " \ '\=get(get(l:cg, submatch(1), {}), "str")', 'g')

      " for l:ng in l:needed_groups
        " if has_key(l:seen_group, l:ng)
          " let l:group_enforce[l:i] = 
        " else
          " let l:seen_group[l:ng] = 1
        " endif
      " endfor
      " let l:group_renumber[l:i] = {}

      " dragons: create the augmentation operators from the 
      " open pattern- this is all super tricky!!
      " for all the mentioned \2, \3, etc 
      " call add(l:capture_groups, l:cg)
    " now replace the original capture groups with equivalent \1
    " for l:i in range(len(l:words)-1)
    "   let l:cg = l:capture_groups[l:i]
    "   if empty(l:cg) | continue | end
    " endfor

    " this is the original set of words plus the set of augments
    " XXX this should probably be renamed
    call add(l:lists.delim_tex.regex, {
      \ 'open'     : l:words[0],
      \ 'close'    : l:words[-1],
      \ 'mid'      : join(l:words[1:-2], '\|'),
      \ 'mid_list' : l:words[1:-2],
      \ 'augments' : l:augments,
      \})

    " this list has \(groups\) and we also stuff recapture data
    " XXX this should probably be renamed
    call add(l:lists.delim_tex.regex_backref, {
      \ 'open'     : l:words_backref[0],
      \ 'close'    : l:words_backref[-1],
      \ 'mid'      : join(l:words_backref[1:-2], '\|'),
      \ 'mid_list' : l:words_backref[1:-2],
      \ 'need_grp' : l:all_needed_groups,
      \ 'grp_renu' : l:group_renumber,
      \ 'aug_comp' : l:augment_comp,
      \})

    " xxx deprecate
    call add(l:lists.delim_tex.re, deepcopy(l:words)) " xxx deprecated
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

function! s:capture_group_sort(a, b) dict
  return self[a:b].depth - self[a:a].depth
endfunction

function! matchup#delim#capture_group_replacement_order(cg)
  let l:order = reverse(sort(keys(a:cg), 'N'))
  call sort(l:order, 's:capture_group_sort', a:cg)
  return l:order
endfunction

" }}}1

function! s:init_delim_regexes() " {{{1
  let l:re = {}
  let l:re.delim_all = {}
  let l:re.all = {}

  let l:re.delim_tex = s:init_delim_regexes_generator('delim_tex')

  for l:k in keys(s:sidedict) 
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

function! matchup#delim#get_capture_groups(str, ...) " {{{1
  let l:allow_percent = a:0 ? a:1 : 0
  let l:pat = g:matchup#re#not_bslash . '\zs\('
        \ . (l:allow_percent ? '\\%(\|' : '') . '\\(\|\\)\)'

  let l:start = 0

  let l:brefs = {}
  let l:stack = []
  let l:counter = 0
  while 1
    let l:match = matchstrpos(a:str, l:pat, l:start)
    if l:match[1] < 0 | break | endif
    let l:start = l:match[2]

    if l:match[0] ==# '\(' || l:match[0] ==# '\%('
      let l:counter += 1
      call add(l:stack, l:counter)
      let l:brefs[l:counter] = {
        \ 'str': '',
        \ 'depth': len(l:stack),
        \ 'parent': (len(l:stack) > 1 ? l:stack[-2] : 0),
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

function! s:init_delim_skip() "{{{1
  let l:skip = get(b:, 'match_skip', '')
  if empty(l:skip) | return '' | endif

  " s:foo becomes (current syntax item) =~ foo
  " S:foo becomes (current syntax item) !~ foo
  " r:foo becomes (line before cursor) =~ foo
  " R:foo becomes (line before cursor) !~ foo
  let l:cursyn = "synIDattr(synID(s:effline('.'),s:effcol('.'),1),'name')"
  let l:preline = "strpart(s:geteffline('.'),0,s:effcol('.'))"

  if l:skip =~# '^[sSrR]:'
    let l:syn = strpart(l:skip, 2)

    let l:skip = {
          \ 's': l:cursyn."=~?'".l:syn."'",
          \ 'S': l:cursyn."!~?'".l:syn."'",
          \ 'r': l:cursyn."=~?'".l:syn."'",
          \ 'R': l:cursyn."!~?'".l:syn."'",
          \}[l:skip[0]]
  endif

  for [l:pat, l:str] in [
        \ [ '\<col\ze(', 's:effcol'   ],
        \ [ '\<line\ze(', 's:effline' ],
        \ [ '\<getline\ze(', 's:geteffline' ],
        \]
    let l:skip = substitute(l:skip, l:pat, l:str, 'g')
  endfor

  return l:skip
endfunction

"}}}1
function! matchup#delim#skip(...) " {{{1
  if a:0 >= 2
    let [l:lnum, l:cnum] = [a:1, a:2]
  else
    let [l:lnum, l:cnum] = matchup#pos#get_cursor()[1:2]
  endif

  if empty(get(b:, 'matchup_delim_skip', ''))
    return matchup#util#in_comment(l:lnum, l:cnum)
        \ || matchup#util#in_string(l:lnum, l:cnum)
  endif

  " call s:set_effective_curpos(l:lnum, l:cnum)
  " call matchup#pos#set_cursor([l:lnum, l:cnum])

  execute 'return (' b:matchup_delim_skip ')'
endfunction

function! s:set_effective_curpos(lnum, cnum)
endfunction

" effective column/line
function! s:effcol(expr)
  return col(a:expr)
endfunction

function! s:effline(expr)
  return line(a:expr)
endfunction

function! s:geteffline(expr)
  return getline(a:expr)
endfunction

" }}}1

function! s:remove_capture_groups(re) "{{{1
  let l:sub_grp = '\(\\\@<!\(\\\\\)*\)\@<=\\('
  return substitute(a:re, l:sub_grp, '\\%(', 'g')
endfunction

"}}}1
function! matchup#delim#fill_backrefs(re, groups) " {{{
  return substitute(a:re, g:matchup#re#backref,
        \ '\=get(a:groups, submatch(1), "")', 'g')
endfunction

"}}}

function! s:mod(i, n) " {{{1
    return ((a:i % a:n) + a:n) % a:n
endfunction
" }}}1

" initialize script variables
let s:stopline = get(g:, 'matchup_delim_stopline', 400)

" whether we're behaving like in insert mode; changes
"   1) effective cursor position for highlight
"   2) which is timeout used
"   XXX should really be in matchparen
let s:insertmode = 0

let s:sidedict = {
      \ 'open'     : ['open'],
      \ 'mid'      : ['mid'],
      \ 'close'    : ['close'],
      \ 'both'     : ['close', 'open'],
      \ 'both_all' : ['close', 'mid', 'open'],
      \ 'open_mid' : ['mid', 'open'],
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

