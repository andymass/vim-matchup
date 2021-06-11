set packpath-=~/.vim packpath-=~/.vim/after
set packpath-=~/.config/nvim packpath-=~/.config/nvim/after
let &rtp = '../../..,' . &rtp
let &rtp = &rtp . ',../../../after'

profile start /tmp/vim-profile.txt
profile! file */matchup/*.vim

filetype plugin indent on
syntax enable

let g:matchup_override_vimtex = 1

runtime! plugin/matchup.vim

nnoremap q :qall!<cr>
