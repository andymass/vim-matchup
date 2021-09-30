set nocompatible
source ../common/bootstrap.vim

autocmd BufNewFile,BufRead *.ext let b:match_words = '\<\(\(foo\)\(bar\)\):\3\2:end\1'|set mps=
" setlocal filetype=matchuptest

silent edit example.ext

" result of successively replacing (in reverse) capture groups in the open
" pattern, '\(\(foo\)\(bar\)\)', with their corresponding backrefs
call matchup#test#assert_equal({
      \ '0': '\<\(\(foo\)\(bar\)\)',
      \ '1': '\<\1',
      \ '2': '\<\(\2\3\)',
      \ '3': '\<\(\(foo\)\3\)'
      \},
      \ b:matchup_delim_lists.delim_tex.regex[0].augments)

let s:cap = b:matchup_delim_lists.delim_tex.regex_capture[0]

" for match_words \3\2, we get the following capture pattern
call matchup#test#assert_equal('\(bar\)\(foo\)', s:cap.mid_list[0])

" for example, from text 'barfoo', we build string \(foobar\) by mapping
"   group 1 (bar) -> group 3
"   group 2 (foo) -> group 2
" finally, str group 1 -> open group 1
"
call matchup#test#assert_equal([{
      \ 'str': '\<\(\2\3\)',
      \ 'inputmap': {'1': '3', '2': '2'}, 
      \ 'outputmap': {'1': '1'}
      \}],
      \ s:cap.aug_comp[1])

" for match_words end\1 we get the following capture pattern
call matchup#test#assert_equal('end\(\(foo\)\(bar\)\)', s:cap.close)

" for example, from text 'endfoobar', we build two possible strings
"   1. \1 where
"       group 1 (foobar) -> group 1
"       group 2 (foo) -> group 2 (actually ignored)
"       group 3 (bar) -> group 3 (actually ignored)
"   2. \(\2\3\) where
"       group 2 (foo) -> group 2
"       group 3 (bar) -> group 3
"       and str group 1 -> open group 1
"
call matchup#test#assert_equal([{
      \ 'str': '\<\1',
      \ 'inputmap': {'1': '1', '2': '2', '3': '3'},
      \ 'outputmap': {}
      \},{
      \ 'str': '\<\(\2\3\)',
      \ 'inputmap': {'2': '2', '3': '3'},
      \ 'outputmap': {'1': '1'}
      \}],
      \ s:cap.aug_comp[2])

" test captured groups and augment
call matchup#perf#timeout_start(0)

normal! 1G
let s:cur = matchup#delim#get_current('all', 'both')

call matchup#test#assert_equal('foobar', s:cur.match)
call matchup#test#assert_equal({'1': 'foobar', '2': 'foo', '3': 'bar'}, s:cur.groups)
call matchup#test#assert_equal({}, s:cur.augment)

normal! 2G
let s:cur = matchup#delim#get_current('all', 'both_all')

" in this case, group 1 cannot be captured and is unresolved
call matchup#test#assert_equal('barfoo', s:cur.match)
call matchup#test#assert_equal({'2': 'foo', '3': 'bar'}, s:cur.groups)
call matchup#test#assert_equal(
      \ {'str': '\<\(\Vfoo\m\Vbar\m\)', 'unresolved': {'1': '1'}},
      \ s:cur.augment)

let s:matching = matchup#delim#get_matching(s:cur)

normal! 3G
let s:cur = matchup#delim#get_current('all', 'both')

call matchup#test#assert_equal('endfoobar', s:cur.match)
call matchup#test#assert_equal({'1': 'foobar', '2': 'foo', '3': 'bar'}, s:cur.groups)
call matchup#test#assert_equal(
      \ {'str': '\<\Vfoobar\m', 'unresolved': {}},
      \ s:cur.augment)

call matchup#test#finished()
