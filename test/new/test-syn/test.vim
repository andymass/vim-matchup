set nocompatible
source ../common/bootstrap.vim

if !has('nvim-0.9.0') && $MODE
  call matchup#test#finished()
endif

if $MODE == 'ts-with-syntax'
  let g:matchup_treesitter_config = { 'additional_vim_regex_highlighting': v:true }
endif

silent edit example.rb
sleep 50m

if $MODE == 'ts-with-syntax'
  call assert_false(empty(&syntax))
endif

" if syntax is not available, we should use ts-based skip
if empty(&syntax)
  call assert_true(b:matchup_delim_skip =~# 'ts_syntax')
endif

function! s:match_test(pos, check) abort
  call matchup#delim#skip()
  call matchup#pos#set_cursor(a:pos)
  normal %
  let l:curpos = matchup#pos#get_cursor()[1:2]
  call matchup#test#assert_equal(a:check, l:curpos)
endfunction

call s:match_test([7, 1], [1, 17])
call s:match_test([6, 3], [2, 22])
call s:match_test([5, 5], [3, 15])

call matchup#test#finished()
