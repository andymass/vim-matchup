set packpath-=~/.vim packpath-=~/.vim/after
set packpath-=~/.config/nvim packpath-=~/.config/nvim/after
let &rtp = '../../..,' . &rtp
let &rtp = &rtp . ',../../../after'

if $TESTS_ENABLE_TREESITTER
  let s:path = simplify(expand('<sfile>:h').'/../../..')
  let &rtp = s:path.'/test/vader/plugged/nvim-treesitter,' . &rtp
  let &rtp .= ','.s:path.'/test/vader/plugged/nvim-treesitter/after'

  runtime! plugin/nvim-treesitter.vim
  runtime! plugin/nvim-treesitter.lua

  lua <<EOF
  require'nvim-treesitter.configs'.setup {
    matchup = {
      enable = true
    }
  }
EOF
endif

filetype plugin indent on
syntax enable

set notimeout

let g:matchup_override_vimtex = 1

runtime! plugin/matchup.vim

nnoremap q :qall!<cr>
