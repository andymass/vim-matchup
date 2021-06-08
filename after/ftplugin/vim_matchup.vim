" vim match-up - even better matching
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

if !exists('g:loaded_matchup') || !exists('b:did_ftplugin')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

let b:match_skip = 's:comment\|string\|vimSynReg'
      \ . '\|vimSet\|vimFuncName\|vimNotPatSep'
      \ . '\|vimVar\|vimFuncVar\|vimFBVar\|vimOperParen'
      \ . '\|vimUserFunc'

if matchup#util#check_match_words('9071a9a')
  " fix broken b:match_words provided by upstream
  let b:match_words
        \ = '\<\%(fu\%[nction]\|def\)!\=\s\+\S\+(:\<retu\%[rn]\>'
        \   . ':\<\%(endf\%[unction]\|enddef\)\>,'
        \ . '\<\(wh\%[ile]\|for\)\>:\<brea\%[k]\>:\<con\%[tinue]\>'
        \   . ':\<end\(w\%[hile]\|fo\%[r]\)\>,'
        \ . '\<if\>:\<el\%[seif]\>:\<en\%[dif]\>,'
        \ . '{:},'
        \ . '\<try\>:\<cat\%[ch]\>:\<fina\%[lly]\>:\<endt\%[ry]\>,'
        \ . '\<aug\%[roup]\s\+\%(END\>\)\@!\S:\<aug\%[roup]\s\+END\>,'
endif

call matchup#util#patch_match_words(
      \ '\<aug\%[roup]\s\+\%(END\>\)\@!\S:',
      \ '\<aug\%[roup]\ze\s\+\%(END\>\)\@!\S:'
      \)

call matchup#util#patch_match_words(
      \ '\|def\)!\=\s\+',
      \ '\|\%(export\s\+\)\@<!def\|export\s\+def\)\ze!\=\s\+',
      \)

let &cpo = s:save_cpo

" vim: fdm=marker sw=2
