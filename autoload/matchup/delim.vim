" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:save_cpo = &cpo
set cpo&vim

function! matchup#delim#init_module() " {{{1
  " nnoremap <silent> <plug>(matchup-delim-delete)
  "       \ :call matchup#delim#delete()<cr>
  " inoremap <silent> <plug>(matchup-delim-close)
  "       \ <c-r>=matchup#delim#close()<cr>

  augroup matchup_filetype
    au!
    autocmd FileType * call matchup#delim#init_buffer()
    autocmd BufWinEnter * call matchup#delim#bufwinenter()
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
endfunction

" }}}1
function! matchup#delim#bufwinenter() " {{{1
  if get(b:, 'matchup_delim_enabled', 0)
    return
  endif
  call matchup#delim#init_buffer()
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

  let l:opts = a:0 && type(a:1) == type({}) ? a:1 : {}
  let l:stopline = get(l:opts, 'stopline', s:stopline)

  " get all the matching position(s)
  " *important*: in the case of mid, we search up before searching down
  " this gives us a context object which we use for the other side
  " TODO: what if no open is found here?
  let l:matches = []
  for l:down in {'open': [1], 'close': [0], 'mid': [0,1]}[a:delim.side]
    let l:save_pos = matchup#pos#get_cursor()
    call matchup#pos#set_cursor(a:delim)

    " second iteration: [] refers to the current match
    if !empty(l:matches)
      call add(l:matches, [])
    endif

    let l:res = a:delim.get_matching(l:down, l:stopline)
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
    let l:matching.is_open = !a:delim.is_open
    let l:matching.class[1] = 'FIXME'
    let l:matching.corr  = a:delim.match
    let l:matching.rematch = a:delim.regextwo[l:matching.side]
    let l:matching.match_index = l:i

    call add(l:matching_list, l:matching)
  endfor

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
    " old syntax: open->close, close->open
    if !len(l:matching_list) | return {} | endif
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

  let l:delimopts = {}
  let s:invert_skip = 0   " TODO: this logic is still bad
  if matchup#delim#skip() " TODO: check for insert mode (?)
    let l:delimopts.check_skip = 0
  endif

  " keep track of the outermost pair found so far
  " returned when g:matchup_delim_count_fail = 1
  let l:best = []

  while l:pos_val_open < l:pos_val_last
    let l:open = matchup#delim#get_prev(a:type,
          \ l:local ? 'open_mid' : 'open', l:delimopts)
    if empty(l:open) | break | endif

    let l:matches = matchup#delim#get_matching(l:open, 1)

    if len(l:matches)
      let l:close = l:local ? l:open.links.next : l:open.links.close
      let l:pos_val_try = matchup#pos#val(l:close)
          \ + matchup#delim#end_offset(l:close)
    endif

    if len(l:matches) && l:pos_val_try >= l:pos_val_cursor
      if l:counter <= 1
        " restore cursor and accept
        call matchup#pos#set_cursor(l:save_pos)
        call matchup#perf#toc('delim#get_surrounding', 'accept')
        return [l:open, l:close]
      endif
      call matchup#pos#set_cursor(matchup#pos#prev(l:open))
      let l:counter -= 1
      let l:best = [l:open, l:close]
    else
      call matchup#pos#set_cursor(matchup#pos#prev(l:open))
      let l:pos_val_last = l:pos_val_open
      let l:pos_val_open = matchup#pos#val(l:open)
    endif
  endwhile

  if !empty(l:best) && g:matchup_delim_count_fail
    call matchup#pos#set_cursor(l:save_pos)
    call matchup#perf#toc('delim#get_surrounding', 'bad_count')
    return l:best
  endif

  " restore cursor and return failure
  call matchup#pos#set_cursor(l:save_pos)
  call matchup#perf#toc('delim#get_surrounding', 'fail')
  return [{}, {}]
endfunction

" }}}1

function! matchup#delim#jump_target(delim) " {{{1
  let l:save_pos = matchup#pos#get_cursor()

  " unicode note: technically wrong, but works in practice
  " since the cursor snaps back to start of multi-byte chars
  let l:column = a:delim.cnum
  let l:column += strlen(a:delim.match) - 1

  if strlen(a:delim.match) < 2
    return l:column
  endif

  for l:tries in range(strlen(a:delim.match)-1)
    call matchup#pos#set_cursor(a:delim.lnum, l:column)

    let l:delim_test = matchup#delim#get_current('all', 'both_all')
    if l:delim_test.class[0] ==# a:delim.class[0]
      break
    endif

    let l:column -= 1
  endfor

  call matchup#pos#set_cursor(l:save_pos)
  return l:column
endfunction

" }}}1
function! matchup#delim#end_offset(delim) " {{{1
  return max([0, match(a:delim.match, '.$')])
endfunction

" }}}1

function! s:get_delim(opts) " {{{1
  " arguments: {{{2
  "   opts = {
  "     'direction'   : 'next' | 'prev' | 'current'
  "     'type'        : 'delim_tex'
  "                   | 'delim_all'
  "                   | 'all'
  "     'side'        : 'open'     | 'close'
  "                   | 'both'     | 'mid'
  "                   | 'both_all' | 'open_mid'
  "  }
  "
  "  }}}2
  " returns: {{{2
  "   delim = {
  "     type     : 'delim'
  "     lnum     : line number
  "     cnum     : column number
  "     match    : the actual text match
  "     augment  : how to match a corresponding open
  "     groups   : dict of captured groups
  "     side     : 'open' | 'close' | 'mid'
  "     is_open  : side == 'open'
  "     class    : [ c1, c2 ] identifies the kind of match_words
  "     regexone : the regex item, like \1foo
  "     regextwo : the regex_backref item, like \(group\)foo
  "     rematch  : regular expression to use in match highlight
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

  let l:cursorpos = col('.')

  let l:insertmode = get(a:opts, 'insertmode', 0)
  if l:cursorpos > 1 && l:insertmode
    let l:cursorpos -= 1
  endif

  let s:invert_skip = 0

  if a:opts.direction ==# 'current'
    let l:check_skip = get(a:opts, 'check_skip',
          \ g:matchup_delim_noskips >= 2)
    if l:check_skip && matchup#delim#skip(line('.'), l:cursorpos)
      return {}
    endif
  else
    " check skip if cursor is not currently in skip
    let l:check_skip = get(a:opts, 'check_skip',
          \ !matchup#delim#skip(line('.'), l:cursorpos)
          \ || g:matchup_delim_noskips >= 2)
  endif

  let a:opts.cursorpos = l:cursorpos

  " for current, we want to find matches that end after the cursor
  " note: we expect this to give false-positives with \ze
  if a:opts.direction ==# 'current'
    let l:re .= '\%>'.(l:cursorpos).'c'
  "  let l:re = '\%<'.(l:cursorpos+1).'c' . l:re
  endif

  " allow overlapping delimiters (replaces cpo-=c)
  " without this, the > in <tag> would not be found
  let l:re .= '\&'

  " use b:match_ignorecase
  call s:ignorecase_start()

  " move cursor one left for searchpos if necessary
  let l:need_restore_cursor = 0
  if l:insertmode
    call matchup#pos#set_cursor(line('.'), col('.')-1)
    let l:need_restore_cursor = 1
  endif

  " stopline may depend on the current action
  let l:stopline = get(a:opts, 'stopline', s:stopline)

  " in the first pass, we get matching line and column numbers
  " this is intended to be as fast as possible, with no capture groups
  " we look for a match on this line (if direction == current)
  " or forwards or backwards (if direction == next or prev)
  " for current, we actually search leftwards from the cursor
  while 1
    let [l:lnum, l:cnum] = a:opts.direction ==# 'next'
          \ ? searchpos(l:re, 'cnW', line('.') + l:stopline)
          \ : a:opts.direction ==# 'prev'
          \   ? searchpos(l:re, 'bcnW', max([line('.') - l:stopline, 1]))
          \   : searchpos(l:re, 'bcnW', line('.'))
    if l:lnum == 0 | break | endif

    let l:wordish_skip = g:matchup_delim_noskips == 1
          \ && getline(l:lnum)[l:cnum-1] =~ '[^[:punct:]]'
    if a:opts.direction ==# 'current' && l:wordish_skip
      return {}
    endif

    " note: the skip here should not be needed
    " in 'current' mode, but be explicit
    if a:opts.direction !=# 'current'
          \ && (l:check_skip || l:wordish_skip)
          \ && matchup#delim#skip(l:lnum, l:cnum)

      " invalid match, move cursor and keep looking
      call matchup#pos#set_cursor(a:opts.direction ==# 'next'
            \ ? matchup#pos#next(l:lnum, l:cnum)
            \ : matchup#pos#prev(l:lnum, l:cnum))
      let l:need_restore_cursor = 1
      continue
    endif

    break
  endwhile

  " reset ignorecase
  call s:ignorecase_end()

  " restore cursor
  if l:need_restore_cursor
    call matchup#pos#set_cursor(l:save_pos)
  endif

  call matchup#perf#toc('s:get_delim', 'first_pass')

  " nothing found, leave now
  if l:lnum == 0
    call matchup#perf#toc('s:get_delim', 'nothing_found')
    return {}
  endif

  let l:skip_state = l:check_skip ? 0
        \ : matchup#delim#skip(l:lnum, l:cnum)

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
        \ 'is_open'  : '',
        \ 'class'    : [],
        \ 'regexone' : '',
        \ 'regextwo' : '',
        \ 'rematch'  : '',
        \ 'skip'     : l:skip_state,
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
  if exists('s:save_ic') || exists('s:save_scs')
    return
  endif
  if exists('b:match_ignorecase') && b:match_ignorecase !=# &ignorecase
    let s:save_ic = &ignorecase
    noautocmd let &ignorecase = b:match_ignorecase
  endif
  if &smartcase
    let s:save_scs = &smartcase
    noautocmd let &smartcase = 0
  endif
endfunction

"}}}1
function! s:ignorecase_end() " {{{1
  " restore ignorecase
  if exists('s:save_ic')
    noautocmd let &ignorecase = s:save_ic
    unlet s:save_ic
  endif
  if exists('s:save_scs')
    noautocmd let &smartcase = s:save_scs
    unlet s:save_scs
  endif
endfunction

"}}}1

function! s:parser_delim_new(lnum, cnum, opts) " {{{1
  let l:cursorpos = a:opts.cursorpos
  let l:found = 0

  let l:sides = s:sidedict[a:opts.side]
  let l:rebrs = b:matchup_delim_lists[a:opts.type].regex_backref

  " use b:match_ignorecase
  call s:ignorecase_start()

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

    " if pattern may contain \zs, extra processing is required
    let l:has_zs = l:rebrs[l:i / l:ns].has_zs

    let l:mid_id = 0
    for l:re in l:res
      let l:mid_id += 1

      " prepend the column number and append the cursor column
      " to anchor the match; we don't use {start} for matchlist
      " because there may be zero-width look behinds
      let l:re_anchored = s:anchor_regex(l:re, a:cnum, l:has_zs)

      " for current we want the first match which the cursor is inside
      if a:opts.direction ==# 'current'
        let l:re_anchored .= '\%>'.(l:cursorpos).'c'
      endif

      let l:matches = matchlist(getline(a:lnum), l:re_anchored)
      if empty(l:matches) | continue | endif

      " reject matches which the cursor is outside of
      " this matters only for \ze
      if a:opts.direction ==# 'current'
          \ && a:cnum + strlen(l:matches[0]) <= l:cursorpos
        continue
      endif

      " if pattern contains \zs we need to re-check the starting column
      if l:has_zs && match(getline(a:lnum), l:re_anchored) != a:cnum-1
        continue
      endif

      let l:found = 1
      break
    endfor

    if !l:found | continue | endif

    break
  endfor

  " reset ignorecase
  call s:ignorecase_end()

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

    " fill in augment pattern
    " TODO all the augment patterns should match,
    " but checking might be too slow
    let l:aug = l:thisrebr.aug_comp[l:id][0]
    " let l:augment.str = substitute(l:aug.str,
    "       \ g:matchup#re#backref,
    "       \ '\=l:groups[submatch(1)]', 'g')
    let l:augment.str = matchup#delim#fill_backrefs(
          \ l:aug.str, l:groups, 0)
    let l:augment.unresolved = deepcopy(l:aug.outputmap)
  endif

  let l:result = {
        \ 'type'         : 'delim',
        \ 'match'        : l:match,
        \ 'augment'      : l:augment,
        \ 'groups'       : l:groups,
        \ 'side'         : l:side,
        \ 'is_open'      : (l:side ==# 'open') ? 1 : 0,
        \ 'class'        : [(l:i / l:ns), l:id],
        \ 'get_matching' : function('s:get_matching_delims'),
        \ 'regexone'     : l:thisre,
        \ 'regextwo'     : l:thisrebr,
        \ 'rematch'      : l:re,
        \}

  return l:result
endfunction
" }}}1

function! s:get_matching_delims(down, stopline) dict " {{{1
  " called as:   a:delim.get_matching(...)
  " called from: matchup#delim#get_matching <- matchparen, motion
  "   from: matchup#delim#get_surrounding <- matchparen, motion, text_obj
  "   from: matchup#delim#close <- delim

  call matchup#perf#tic('get_matching_delims')

  " first, we figure out what the furthest match is, which will be
  " either the open or close depending on the direction
  let [l:re, l:flags, l:stopline] = a:down
      \ ? [self.regextwo.close, 'W', line('.') + a:stopline]
      \ : [self.regextwo.open, 'bW', max([line('.') - a:stopline, 1])]

  " these are the anchors for searchpairpos
  let l:open = self.regexone.open     " TODO is this right? BADLOGIC
  let l:close = self.regexone.close

  " if we're searching up, we anchor by the augment, if it exists
  if !a:down && !empty(self.augment)
    let l:open = self.augment.str
  endif

  " TODO temporary workaround for BADLOGIC
  if a:down && self.side ==# 'mid'
    let l:open = self.regextwo.open
  endif

  " turn \(\) into \%(\) for searchpairpos
  let l:open  = s:remove_capture_groups(l:open)
  let l:close = s:remove_capture_groups(l:close)

  " fill in back-references
  " TODO: BADLOGIC2: when going up we don't have these groups yet..
  " the second anchor needs to be mid/self for mid self
  let l:open = matchup#delim#fill_backrefs(l:open, self.groups, 0)
  let l:close = matchup#delim#fill_backrefs(l:close, self.groups, 0)

  let s:invert_skip = self.skip
  let l:skip = 'matchup#delim#skip0()'

  if matchup#perf#timeout_check() | return [['', 0, 0]] | endif

  " improves perceptual performance in insert mode
  if mode() ==# 'i' || mode() ==# 'R'
    sleep 1m
  endif

  " use b:match_ignorecase
  call s:ignorecase_start()

  let [l:lnum_corr, l:cnum_corr] = searchpairpos(l:open, '', l:close,
        \ 'n'.l:flags, l:skip, l:stopline, matchup#perf#timeout())

  call matchup#perf#toc('get_matching_delims', 'initial_pair')

  " if nothing found, bail immediately
  if l:lnum_corr == 0
    " reset ignorecase
    call s:ignorecase_end()

    return [['', 0, 0]]
  endif

  " get the match and groups
  let l:has_zs = self.regextwo.has_zs
  let l:re_anchored = s:anchor_regex(l:re, l:cnum_corr, l:has_zs)
  let l:matches = matchlist(getline(l:lnum_corr), l:re_anchored)
  let l:match_corr = l:matches[0]

  " reset ignorecase
  call s:ignorecase_end()

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
  let l:mids = matchup#delim#fill_backrefs(l:mids, self.groups, 1)

  " if there are no mids, we're done
  if empty(l:mids)
    return [[l:match_corr, l:lnum_corr, l:cnum_corr]]
  endif

  let l:re = l:mids

  " use b:match_ignorecase
  call s:ignorecase_start()

  let l:list = []
  while 1
    if matchup#perf#timeout_check() | break | endif

    let [l:lnum, l:cnum] = searchpairpos(l:open, l:mids, l:close,
      \ l:flags, l:skip, l:lnum_corr, matchup#perf#timeout())
    if l:lnum <= 0 | break | endif

    if a:down
      if l:lnum > l:lnum_corr || l:lnum == l:lnum_corr
          \ && l:cnum >= l:cnum_corr | break | endif
    else
      if l:lnum < l:lnum_corr || l:lnum == l:lnum_corr
          \ && l:cnum <= l:cnum_corr | break | endif
    endif

    let l:re_anchored = s:anchor_regex(l:re, l:cnum, l:has_zs)
    let l:matches = matchlist(getline(l:lnum), l:re_anchored)
    let l:match = l:matches[0]

    call add(l:list, [l:match, l:lnum, l:cnum])
  endwhile

  " reset ignorecase
  call s:ignorecase_end()

  call add(l:list, [l:match_corr, l:lnum_corr, l:cnum_corr])

  if !a:down
    call reverse(l:list)
  endif

  return l:list
endfunction
" }}}1

function! s:init_delim_lists() " {{{1
  let l:lists = { 'delim_tex': { 'regex': [], 'regex_backref': [] } }

  " very tricky examples:
  " good: let b:match_words = '\(\(foo\)\(bar\)\):\3\2:end\1'
  " bad:  let b:match_words = '\(foo\)\(bar\):more\1:and\2:end\1\2'

  " *subtlety*: there is a huge assumption in matchit:
  "   ``It should be possible to resolve back references
  "     from any pattern in the group.''
  " we don't explicitly check this, but the behavior might
  " be unpredictable if such groups are encountered.. (ref-1)

  if exists('g:matchup_hotfix_'.&filetype)
    call call(g:matchup_hotfix_{&filetype}, [])
  endif

  " parse matchpairs and b:match_words
  let l:mps = escape(&matchpairs, '[$^.*~\\/?]')
  let l:match_words = get(b:, 'match_words', '')
  if !empty(l:match_words) && l:match_words !~# ':'
    echohl ErrorMsg
    echo 'match-up: function b:match_words not supported'
    echohl None
    let l:match_words = ''
  endif
  if !get(b:, 'matchup_delim_nomatchpairs', 0) && !empty(l:mps)
    let l:match_words .= ','.l:mps
  endif
  let l:sets = split(l:match_words, g:matchup#re#not_bslash.',')

  " do not duplicate whole groups of match words
  let l:seen = {}
  for l:s in l:sets
    " very special case, escape bare [:]
    " TODO: the bare [] bug might show up in other places too
    if l:s ==# '[:]' || l:s ==# '\[:\]'
      let l:s = '\[:]'
    endif

    if has_key(l:seen, l:s) | continue | endif
    let l:seen[l:s] = 1

    if l:s =~# '^\s*$' | continue | endif

    let l:words = split(l:s, g:matchup#re#not_bslash.':')

    if len(l:words) < 2 | continue | endif

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

    " TODO this logic might be bad BADLOGIC
    " should we not fill groups that aren't needed?
    " dragons: create the augmentation operators from the
    " open pattern- this is all super tricky!!
    " TODO we should be building the augment later, so
    " we can remove augments that can never be filled

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

        " complicated: need to count the number of inserted groups
        let l:prev_max = max(keys(l:cg2))
        let l:cg2 = matchup#delim#get_capture_groups(l:words_backref[l:i])

        for l:cg2_i in sort(keys(l:cg2), s:Nsort)
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

      " mostly a sanity check
      if matchup#util#has_duplicate_str(values(l:group_renumber[l:i]))
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
        let l:in_grp_l = keys(filter(
              \ deepcopy(l:group_renumber[l:i]), 'v:val == l:j'))

        if empty(l:in_grp_l) | continue | endif
        let l:in_grp = l:in_grp_l[0]

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

        " output map turns remaining group numbers into 'open' numbers
        let l:counter = 1
        for l:out_grp in sort(keys(l:remaining_out), s:Nsort)
          let l:augment_comp[l:i][0].outputmap[l:counter] = l:out_grp
          let l:counter += 1
        endfor
      endfor

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

    " strip out unneeded groups in output maps
    for l:i in keys(l:augment_comp)
      for l:aug in l:augment_comp[l:i]
        call filter(l:aug.outputmap,
              \ 'has_key(l:all_needed_groups, v:key)')
      endfor
    endfor

    " TODO should l:words[0] actually be used? BADLOGIC
    " the last element in the order gives the most augmented string
    " this includes groups that might not actually be needed elsewhere
    " as a concrete example,
    " l:augments = { '0': '\<\(wh\%[ile]\|for\)\>', '1': '\<\1\>'}
    " l:words[0] = \<\1\> (bad)
    " instead, get the furthest out needed augment.. Heuristic TODO
    for l:g in add(reverse(copy(l:order)), 0)
      if has_key(l:all_needed_groups, l:g)
        let l:words[0] = l:augments[l:g]
        break
      endif
    endfor

    " this is the original set of words plus the set of augments
    " TODO this should probably be renamed
    call add(l:lists.delim_tex.regex, {
      \ 'open'     : l:words[0],
      \ 'close'    : l:words[-1],
      \ 'mid'      : join(l:words[1:-2], '\|'),
      \ 'mid_list' : l:words[1:-2],
      \ 'augments' : l:augments,
      \})

    " this list has \(groups\) and we also stuff recapture data
    " TODO this should probably be renamed
    call add(l:lists.delim_tex.regex_backref, {
      \ 'open'     : l:words_backref[0],
      \ 'close'    : l:words_backref[-1],
      \ 'mid'      : join(l:words_backref[1:-2], '\|'),
      \ 'mid_list' : l:words_backref[1:-2],
      \ 'need_grp' : l:all_needed_groups,
      \ 'grp_renu' : l:group_renumber,
      \ 'aug_comp' : l:augment_comp,
      \ 'has_zs'   : match(l:words_backref, g:matchup#re#zs) >= 0,
      \})
  endfor

  " generate combined lists
  let l:lists.delim_all = {}
  let l:lists.all = {}
  for l:k in ['regex', 'regex_backref']
    let l:lists.delim_all[l:k] = l:lists.delim_tex[l:k]
    let l:lists.all[l:k] = l:lists.delim_all[l:k]
  endfor

  return l:lists
endfunction

function! s:capture_group_sort(a, b) dict
  return self[a:b].depth - self[a:a].depth
endfunction

function! matchup#delim#capture_group_replacement_order(cg)
  let l:order = reverse(sort(keys(a:cg), s:Nsort))
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

  return l:regexes
endfunction

" }}}1

function! matchup#delim#get_capture_groups(str, ...) " {{{1
  let l:allow_percent = a:0 ? a:1 : 0
  let l:pat = g:matchup#re#not_bslash . '\(\\%(\|\\(\|\\)\)'

  let l:start = 0

  let l:brefs = {}
  let l:stack = []
  let l:counter = 0
  while 1
    let l:match = s:matchstrpos(a:str, l:pat, l:start)
    if l:match[1] < 0 | break | endif
    let l:start = l:match[2]

    if l:match[0] ==# '\(' || (l:match[0] ==# '\%(' && l:allow_percent)
      let l:counter += 1
      call add(l:stack, l:counter)
      let l:cgstack = filter(copy(l:stack), 'v:val > 0')
      let l:brefs[l:counter] = {
        \ 'str': '',
        \ 'depth': len(l:cgstack),
        \ 'parent': (len(l:cgstack) > 1 ? l:cgstack[-2] : 0),
        \ 'pos': [l:match[1], 0],
        \}
    elseif l:match[0] ==# '\%('
      call add(l:stack, 0)
    else
      if empty(l:stack) | break | endif
      let l:i = remove(l:stack, -1)
      if l:i < 1 | continue | endif
      let l:j = l:brefs[l:i].pos[0]
      let l:brefs[l:i].str = strpart(a:str, l:j, l:match[2]-l:j)
      let l:brefs[l:i].pos[1] = l:match[2]
    endif
  endwhile

  call filter(l:brefs, 'has_key(v:val, "str")')

  return l:brefs
endfunction

" compatibility
function! s:matchstrpos(expr, pat, start) abort
  if exists('*matchstrpos')
    return matchstrpos(a:expr, a:pat, a:start)
  else
    return [matchstr(a:expr, a:pat, a:start),
          \ match(a:expr, a:pat, a:start),
          \ matchend(a:expr, a:pat, a:start)]
  endif
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
          \ 'r': l:preline."=~?'".l:syn."'",
          \ 'R': l:preline."!~?'".l:syn."'",
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
    return matchup#util#in_comment_or_string(l:lnum, l:cnum)
          \ ? !s:invert_skip : s:invert_skip
  endif

  let s:eff_curpos = [l:lnum, l:cnum]
  execute 'return' (s:invert_skip ? '!(' : '(') b:matchup_delim_skip ')'
endfunction

function! matchup#delim#skip0()
  if empty(b:matchup_delim_skip)
    return matchup#util#in_comment_or_string(line('.'), col('.'))
          \ ? !s:invert_skip : s:invert_skip
  endif

  let s:eff_curpos = [line('.'), col('.')]
  execute 'return' (s:invert_skip ? '!(' : '(') b:matchup_delim_skip ')'
endfunction

let s:invert_skip = 0
let s:eff_curpos = [1, 1]

" effective column/line
function! s:effline(expr)
  return a:expr ==# '.' ? s:eff_curpos[0] : line(a:expr)
endfunction

function! s:effcol(expr)
  return a:expr ==# '.' ? s:eff_curpos[1] : col(a:expr)
endfunction

function! s:geteffline(expr)
  return a:expr ==# '.' ? getline(s:effline(a:expr)) : getline(a:expr)
endfunction

" }}}1

function! s:remove_capture_groups(re) "{{{1
  let l:sub_grp = '\(\\\@<!\(\\\\\)*\)\@<=\\('
  return substitute(a:re, l:sub_grp, '\\%(', 'g')
endfunction

"}}}1
function! matchup#delim#fill_backrefs(re, groups, warn) " {{{1
  return substitute(a:re, g:matchup#re#backref,
        \ '\=s:get_backref(a:groups, submatch(1), a:warn)', 'g')
        " \ '\=get(a:groups, submatch(1), "")', 'g')
endfunction

function! s:get_backref(groups, bref, warn)
  if !has_key(a:groups, a:bref)
    if a:warn
      echohl WarningMsg
      echo 'match-up: requested invalid backreference \'.a:bref
      echohl None
    endif
    return ''
  endif
  return '\V'.escape(get(a:groups, a:bref), '\').'\m'
endfunction

"}}}1

function! s:anchor_regex(re, cnum, method) " {{{1
  if a:method
    " trick to re-match at a particular column
    " handles the case where pattern contains \ze, \zs, and assertions
    " but doesn't work with overlapping matches and is possibly slower
    return '\%<'.(a:cnum+1).'c\%('.a:re.'\)\%>'.(a:cnum).'c'
  else
    " fails to match with \zs
    return '\%'.(a:cnum).'c\%('.a:re.'\)'
  endif
endfunction

" }}}1

function! s:Nsort_func(a, b) " {{{1
  let l:a = type(a:a) == type('') ? str2nr(a:a) : a:a
  let l:b = type(a:b) == type('') ? str2nr(a:b) : a:b
  return l:a == l:b ? 0 : l:a > l:b ? 1 : -1
endfunction

" }}}1

" initialize script variables
let s:stopline = get(g:, 'matchup_delim_stopline', 1500)

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

" in case the 'N' sort flag is not available (compatibility for 7.4.898)
let s:Nsort = has('patch-7.4.951') ? 'N' : 's:Nsort_func'

let &cpo = s:save_cpo

" vim: fdm=marker sw=2

