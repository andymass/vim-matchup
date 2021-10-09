set nocompatible
source ../common/bootstrap.vim

if !$TESTS_ENABLE_TREESITTER
  call matchup#test#finished()
endif

function! s:assert_ts_active()
  call assert_true(index(
              \ b:matchup_active_engines.delim_all, 'tree_sitter') > -1)
endfunction

" python
silent edit example.py

call s:assert_ts_active()

0go
norm %
call assert_equal([3, 10], getcurpos()[1:2])
norm 2%
call assert_equal([10, 12], getcurpos()[1:2])

" ruby
silent edit example.rb

call s:assert_ts_active()

0go
norm %
call assert_equal([3, 4], getcurpos()[1:2])
norm 2%
call assert_equal([1, 1], getcurpos()[1:2])

call matchup#test#finished()
