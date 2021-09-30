set nocompatible
source ../common/bootstrap.vim

if !$TESTS_ENABLE_TREESITTER && $MODE > 0
  call matchup#test#finished()
endif

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
endif

silent edit example.rb

function! s:match_test(pos, check) abort
  call matchup#pos#set_cursor(a:pos)
  normal %
  let l:curpos = matchup#pos#get_cursor()[1:2]
  call matchup#test#assert_equal(a:check, l:curpos)
endfunction

call s:match_test([7, 1], [1, 17])
call s:match_test([6, 3], [2, 22])
call s:match_test([5, 5], [3, 15])

call matchup#test#finished()
