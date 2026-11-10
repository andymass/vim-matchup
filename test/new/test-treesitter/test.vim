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

" skip nodes are cached until the buffer, query or cursor window changes
lua <<LUA
  local internal = require'treesitter-matchup.internal'
  local get_matches = internal.get_matches
  vim.g.matchup_test_queries = 0
  internal.get_matches = function(...)
    vim.g.matchup_test_queries = vim.g.matchup_test_queries + 1
    return get_matches(...)
  end
  vim.treesitter.query.set('ruby', 'matchup', '(if_modifier) @skip.modifier')
LUA

function! s:skips() abort
  return luaeval(
        \ 'vim.tbl_count(require"treesitter-matchup.syntax".get_skips(0))')
endfunction

let g:matchup_treesitter_stopline = 3
silent %delete _
call setline(1, ['unless false', '  return', 'end', '', '', '', '',
      \ 'x = 1 if y'])

" the modifier is outside of the rows around the cursor
call cursor(1, 1)
call assert_equal(0, s:skips())
call assert_equal(1, g:matchup_test_queries)
call cursor(2, 1)
call assert_equal(0, s:skips())
call assert_equal(1, g:matchup_test_queries)

" moving the cursor outside of the cached rows queries again
call cursor(8, 1)
call assert_equal(1, s:skips())
call assert_equal(2, g:matchup_test_queries)
call assert_equal(1, s:skips())
call assert_equal(2, g:matchup_test_queries)

" editing the buffer
call setline(8, 'x = 1')
call assert_equal(0, s:skips())
call assert_equal(3, g:matchup_test_queries)
call setline(8, 'x = 1 if y')
call assert_equal(1, s:skips())
call assert_equal(4, g:matchup_test_queries)

" changing the query
lua vim.treesitter.query.set('ruby', 'matchup', '(unless_modifier) @skip.modifier')
call assert_equal(0, s:skips())
call assert_equal(5, g:matchup_test_queries)

call matchup#test#finished()
