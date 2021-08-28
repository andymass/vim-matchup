set packpath-=~/.vim packpath-=~/.vim/after
set packpath-=~/.config/nvim packpath-=~/.config/nvim/after
let &rtp = '../../..,' . &rtp
let &rtp = &rtp . ',../../../after'

profile start /tmp/vim-profile.txt
profile! file */matchup/*.vim

if has('nvim-0.5.0')
  let s:path = simplify(expand('<sfile>:h').'/../../..')
  let &rtp = s:path.'/test/vader/plugged/nvim-treesitter,' . &rtp
  let &rtp .= ','.s:path.'/test/vader/plugged/nvim-treesitter/after'

  lua <<EOF
  require'nvim-treesitter.configs'.setup {
    matchup = {
      enable = true
    }
  }
EOF

  runtime! plugin/nvim-treesitter.vim
endif

filetype plugin indent on
syntax enable

set notimeout

let g:matchup_override_vimtex = 1

runtime! plugin/matchup.vim

nnoremap q :qall!<cr>
