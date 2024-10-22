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

function! s:has_plugin(plug)
  return !empty(filter(split(&rtp,','), 'v:val =~? ''\<'.a:plug.'\>'''))
endfunction

let s:not_bslash = '\v%(\\@<!%(\\\\)*)@4<=\m'

function! s:get_match_words()
  " left and right modifiers, any delimiters
  let l:delim = '\%(\\\w\+\>\|\\[|{}]\|.\)'
  let l:match_words = '\\left\>'.l:delim
        \ .':\\middle\>'.l:delim
        \ .':\\right\>'.l:delim
  let l:match_words .= ',\(\\[bB]igg\?\)l\>'.l:delim
        \ . ':\1m\>'.l:delim
        \ . ':\1r\>'.l:delim

  " un-sided sized, left and right delimiters
  let l:mod = '\(\\[bB]igg\?\)'
  let l:wdelim = '\%(angle\|floor\|ceil\|[vV]ert\|brace\)\>'
  let l:ldelim = '\%(\\l'.l:wdelim.'\|\\[lu]lcorner\>\|(\|\[\|\\{\)'
  let l:mdelim = '\%(\\vert\>\||\|\\|\)'
  let l:rdelim = '\%(\\r'.l:wdelim.'\|\\[lu]rcorner\>\|)\|]\|\\}\)'
  let l:mtopt = '\%(\%(\w\[\)\@2<!\|\%(\\[bB]igg\?\[\)\@6<=\)'
  let l:match_words .= ','.l:mod.l:ldelim
        \ . ':\1'.l:mdelim
        \ . ':'.l:mtopt.'\1'.l:rdelim

  " unmodified delimiters
  let l:nomod = '\%(\\left\|\\right\|\[\@1<!\\[bB]igg\?[lr]\?\)\@6<!'
  for l:pair in [['\\{', '\\}'], ['\[', ']'], ['(', ')'],
        \ ['\\[lu]lcorner', '\\[lu]rcorner']]
    let l:match_words .= ','.l:nomod.s:not_bslash.l:pair[0]
          \ . ':'.l:nomod.s:not_bslash.l:pair[1]
  endfor
  let l:match_words .= ','.l:nomod.s:not_bslash.'\\l\('.l:wdelim.'\)'
        \ . ':'.l:nomod.s:not_bslash.'\\r\1\>'

  " the curly braces
  let l:match_words .= ',{:}'

  " latex equation markers
  let l:match_words .= ',\\(:\\),'.s:not_bslash.'\\\[:\\]'

  " latex3 file i/o
  let l:match_words .= ',\\ior_open\:NnT\?F\?\s*\\\([^\s]*\):\\ior_close\:N\s*\\\1'
  let l:match_words .= ',\\ior_open\:cnT\?F\?\s*{\s*\([^\s\\}]*\)\s*}:\\ior_close\:c\s*{\s*\1\s*}'
  let l:match_words .= ',\\iow_open\:Nn\s*\\\([^\s]*\):\\iow_close\:N\s*\\\1'
  let l:match_words .= ',\\iow_open\:cn\s*{\s*\([^\s\\}]*\)\s*}:\\iow_close\:c\s*{\s*\1\s*}'

  " simple blocks
  let l:match_words .= ',\\if\%(\:w\|\%(\w\|@\)*\)\>:\\else\:\?\>:\\fi\:\?\>'
  let l:match_words .= ',\\if_\%(true\|false\)\::\\else\::\\fi\:'
  let l:match_words .= ',\\if_mode_\%(horizontal\|vertical\|math\|inner\)\::\\else\::\\fi\:'
  let l:match_words .= ',\\if_\%(charcode\|catcode\|dim\)\:w:\\else\::\\fi\:'
  let l:match_words .= ',\\if_cs_exist\:w:\\cs_end\::\\else\::\\fi\:'
  let l:match_words .= ',\\if_cs_exist\:N:\\else\::\\fi\:'
  let l:match_words .= ',\\if_[hv]box\:N:\\else\::\\fi\:'
  let l:match_words .= ',\\if_box_empty\:N:\\else\::\\fi\:'
  let l:match_words .= ',\\cs\:w:\\cs_end\:'
  let l:match_words .= ',\\makeatletter:\\makeatother'
  let l:match_words .= ',\\ExplSyntaxOn:\\ExplSyntaxOff'
  let l:match_words .= ',\\debug_suspend\::\\debug_resume\:'
  let l:match_words .= ',\\begingroup:\\endgroup,\\bgroup:\\egroup'
  let l:match_words .= ',\\group_begin\::\\group_end\:'
  let l:match_words .= ',\\group_align_safe_begin\::\\group_align_safe_end\:'
  let l:match_words .= ',\\color_group_begin\::\\color_group_end\:'
  let l:match_words .= ',\\cctab_begin\:[Nc]:\\cctab_end\:'
  let l:match_words .= ',\\exp\:w:\\exp_end\(_continue_f\:n\?w\|\:\)'

  " environments
  let l:match_words .= ',\\begin{tabular}'
        \ . ':\\toprule\>:\\midrule\>:\\bottomrule\>'
        \ . ':\\end{tabular}'

  " enumerate, itemize
  let l:match_words .= ',\\begin\s*{\(enumerate\*\=\|itemize\*\=\)}'
        \ . ':\\item\>:\\end\s*{\1}'

  " generic environment
  if matchup#util#matchpref('relax_env', 0)
    let l:match_words .= ',\\begin\s*{\([^}]*\)}:\\end\s*{\([^}]*\)}'
  else
    let l:match_words .= ',\\begin\s*{\([^}]*\)}:\\end\s*{\1}'
  endif

  " dollar sign math
  if exists('b:vimtex')
    let l:match_words .= ',\$:\$\g{syn;!texMathZoneTI}'
  else
    let l:match_words .= ',\$:\$\g{syn;!texMathZoneX}'
  endif

  return l:match_words
endfunction

function! s:setup_match_words()
  setlocal matchpairs=(:),{:},[:]
  let b:matchup_delim_nomatchpairs = 1
  let b:match_words = s:get_match_words()

  " the syntax method is too slow for latex
  let b:match_skip = 'r:\\\@<!\%(\\\\\)*%'

  " the old regexp engine is a bit faster '\%#=1'
  let b:matchup_regexpengine = 1

  let b:undo_ftplugin =
        \ (exists('b:undo_ftplugin') ? b:undo_ftplugin . '|' : '')
        \ . 'unlet! b:matchup_delim_nomatchpairs b:match_words'
        \ . ' b:match_skip b:matchup_regexpengine'
endfunction

if get(g:, 'vimtex_enabled',
      \ s:has_plugin('vimtex') || exists('*vimtex#init'))
  if get(g:, 'matchup_override_vimtex', 0)
    silent! nunmap <buffer> %
    silent! xunmap <buffer> %
    silent! ounmap <buffer> %

    " lervag/vimtex/issues/1051
    let g:vimtex_matchparen_enabled = 0
    silent! call vimtex#matchparen#disable()

    call s:setup_match_words()
  else
    let b:matchup_matchparen_enabled = 0
    let b:matchup_matchparen_fallback = 0
  endif
else
  call s:setup_match_words()
endif

let &cpo = s:save_cpo

" vim: fdm=marker sw=2

