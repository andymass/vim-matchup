" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:save_cpo = &cpo
set cpo&vim

function! matchup#init()
  call s:init_options()
  call s:init_modules()
  call s:init_default_mappings()
endfunction

function! s:init_options()
  call s:init_option('matchup_matchparen_enabled',
    \ !(&t_Co < 8 && !has('gui_running')))
  call s:init_option('matchup_matchparen_status_offscreen', 1)
  call s:init_option('matchup_matchparen_singleton', 0)
  call s:init_option('matchup_matchparen_deferred', 0)
  call s:init_option('matchup_matchparen_deferred_show_delay', 50)
  call s:init_option('matchup_matchparen_deferred_hide_delay', 700)
  call s:init_option('matchup_matchparen_stopline', 400)

  call s:init_option('matchup_matchparen_timeout',
    \ get(g:, 'matchparen_timeout', 300))
  call s:init_option('matchup_matchparen_insert_timeout',
    \ get(g:, 'matchparen_insert_timeout', 60))

  call s:init_option('matchup_delim_count_fail', 0)
  call s:init_option('matchup_delim_noskips', 0)

  call s:init_option('matchup_motion_enabled', 1)
  call s:init_option('matchup_motion_cursor_end', 1)
  call s:init_option('matchup_motion_override_Npercent', 6)

  call s:init_option('matchup_text_obj_enabled', 1)
  call s:init_option('matchup_text_obj_linewise_operators', ['d', 'y'])

  call s:init_option('matchup_transmute_enabled', 0)

  call s:init_option('matchup_imap_enabled', 0)

  call s:init_option('matchup_complete_enabled', 0)
endfunction

function! s:init_option(option, default)
  let l:option = 'g:' . a:option
  if !exists(l:option)
    let {l:option} = a:default
  endif
endfunction

function! s:init_modules()
  for l:mod in s:modules
    if index(get(g:, 'matchup_disabled_modules', []), l:mod) >= 0
      continue
    endif

    try
      call matchup#{l:mod}#init_module()
    catch /E117.*#init_/
    endtry
  endfor
endfunction

let g:v_motion_force = ''
function! s:force(wise)
  let g:v_motion_force = a:wise
  " let g:v_operator = v:operator
  return ''
endfunction

function! s:init_default_mappings()
  if !get(g:,'matchup_mappings_enabled', 1) | return | endif

  function! s:map(mode, lhs, rhs, ...)
    if !hasmapto(a:rhs, a:mode)
          \ && ((a:0 > 0) || (maparg(a:lhs, a:mode) ==# ''))
      silent execute a:mode . 'map <silent> ' a:lhs a:rhs
    endif
  endfunction

  for l:opforce in ['', 'v', 'V', '<c-v>']
    call s:map('onore', '<expr> <plug>(matchup-o_'.l:opforce.')',
          \ '<sid>force('''.l:opforce.''')')
  endfor

  " these won't conflict since matchit should not be loaded at this point
  if get(g:, 'matchup_motion_enabled', 0)
    call s:map('n', '%',  '<plug>(matchup-%)' )
    call s:map('n', 'g%', '<plug>(matchup-g%)')

    call s:map('x', '%',  '<plug>(matchup-%)' )
    call s:map('x', 'g%', '<plug>(matchup-g%)')

    call s:map('n', ']%', '<plug>(matchup-]%)')
    call s:map('n', '[%', '<plug>(matchup-[%)')

    call s:map('x', ']%', '<plug>(matchup-]%)')
    call s:map('x', '[%', '<plug>(matchup-[%)')

    call s:map('n', 'z%', '<plug>(matchup-z%)')
    call s:map('x', 'z%', '<plug>(matchup-z%)')

    for l:opforce in ['', 'v', 'V', '<c-v>']
      call s:map('o', l:opforce.'%',
            \ '<plug>(matchup-o_'.l:opforce.')<plug>(matchup-%)')
      call s:map('o', l:opforce.'g%',
            \ '<plug>(matchup-o_'.l:opforce.')<plug>(matchup-g%)')
      call s:map('o', l:opforce.']%',
            \ '<plug>(matchup-o_'.l:opforce.')<plug>(matchup-]%)')
      call s:map('o', l:opforce.'[%',
            \ '<plug>(matchup-o_'.l:opforce.')<plug>(matchup-[%)')
      call s:map('o', l:opforce.'z%',
            \ '<plug>(matchup-o_'.l:opforce.')<plug>(matchup-z%)')
    endfor
  endif

  if get(g:, 'matchup_text_obj_enabled', 0)
    call s:map('x', 'i%', '<plug>(matchup-i%)')
    call s:map('x', 'a%', '<plug>(matchup-a%)')
    for l:opforce in ['', 'v', 'V', '<c-v>']
      call s:map('o', l:opforce.'i%',
            \ '<plug>(matchup-o_'.l:opforce.')<plug>(matchup-i%)')
      call s:map('o', l:opforce.'a%',
            \ '<plug>(matchup-o_'.l:opforce.')<plug>(matchup-a%)')
    endfor
  endif

  if get(g:, 'matchup_imap_enabled', 0)
    " call s:map('i', '<c-x><cr>',  '<plug>(matchup-delim-close)')
    " XXX other maps..?
  endif

  if get(g:, 'matchup_mouse_enabled', 1)
    call s:map('n', '<2-LeftMouse>', '<plug>(matchup-double-click)')
  endif
endfunction

let s:modules = map(
      \ glob(fnamemodify(expand('<sfile>'), ':r') . '/*.vim', 0, 1),
      \ 'fnamemodify(v:val, '':t:r'')')

let &cpo = s:save_cpo

" vim: fdm=marker sw=2

