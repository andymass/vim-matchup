set nocompatible
source ../common/bootstrap.vim

if !$TESTS_ENABLE_TREESITTER && $MODE > 0
  call matchup#test#finished()
endif

let s:expect_ts_engine = +$TESTS_ENABLE_TREESITTER

if $MODE == 1
  lua <<EOF
  require'nvim-treesitter.configs'.setup {
    highlight = { enable = true },
    matchup   = { enable = true }
  }
EOF
elseif $MODE == 2
  lua <<EOF
  require'nvim-treesitter.configs'.setup {
    highlight = { enable = true },
    matchup   = {
      enable = true,
      additional_vim_regex_highlighting = true
    }
  }
EOF
elseif $MODE == 3
  lua <<EOF
  require'nvim-treesitter.configs'.setup {
    highlight = { enable = true },
    matchup   = { enable = false }
  }
EOF

  let s:expect_ts_engine = 0
endif

silent edit example.rb

" manually reload match-up for the buffer since the tree-sitter
" configuration may not have been initialized properly before
call matchup#loader#init_buffer()

if s:expect_ts_engine
  call assert_equal(2, len(b:matchup_active_engines.delim_all))
else
  call assert_equal(1, len(b:matchup_active_engines.delim_all))
endif

if $MODE == 2
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
