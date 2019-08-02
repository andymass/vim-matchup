if !exists('b:did_ftplugin')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

call matchup#util#patch_match_words('retry', 'retry\|return')

let b:match_midmap = [
      \ ['rubyRepeat', 'next'],
      \ ['rubyDefine', 'return'],
      \]
let b:undo_ftplugin .= '| unlet! b:match_midmap'

let &cpo = s:save_cpo

