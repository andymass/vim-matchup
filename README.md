# matchup.vim

:warning: warning :warning: this plugin is unfinished and under heavy
active development. It is not ready for use yet!

match-up is a replacement for the venerable vim plugin [matchit.vim]
match-up aims to replicate all of matchit's features, fix a number of its
deficiencies and bugs, and add a few totally new features.  It also
replaces the standard plugin [matchparen], allowing all of matchit's words
to be highlighted along with the `matchpairs` (`(){}[]`).

[matchit.vim]: http://ftp.vim.org/pub/vim/runtime/macros/matchit.txt
[matchparen]: http://ftp.vim.org/pub/vim/runtime/doc/pi_paren.txt

<img src='https://github.com/andymass/matchup.vim/wiki/images/teaser.jpg' width='300px' alt='and in this corner...'>

A major goal of this project is to keep a modern and modular code base.
Contributions are welcome!

## Table of contents

  * [Overview](#overview)
  * [Installation](#installation)
  * [Features](#features)
  * [Options](#options)
  * [FAQ](#faq)
  * [Interoperability](#interoperability)
  * [Acknowledgements](#acknowledgements)
  * [Development](#development)

## Overview

This plugin

- Extends vim's `%` motion to language-words like `if`, `else`, `endif`.
- Adds motions `g%`, `[%`, `]%`, and `z%`.
- Combines these motions into convenient text objects `i%` and `a%`.
- Highlights symbols and words under the cursor which `%` can work on,
  and highlights matching symbols and words.  Now you can easily tell
  where `%` will jump to.

Planned features:

- Adds auto-completion for words and symbols- for example you could 
  automatically insert corresponding a `)` or `endif`.

## Installation

If you use vim-plug, then add the following line to your vimrc file:

```vim
Plug 'andymass/matchup.vim'
```

Or use some other plugin manager:

  - vundle
  - neobundle
  - pathogen

## Features

|         | feature                          | __match-up__  | matchit       | matchparen    |
| ------- | -------------------------------- | ------------- | ------------- | ------------- |
| ([a.1]) | jump between matching words      | :thumbsup:    | :thumbsup:    | :x:           |
| ([a.2]) | jump to open & close words       | :thumbsup:    | :question:    | :x:           |
| ([a.3]) | jump inside                      | :thumbsup:    | :x:           | :x:           |
| ([b.1]) | full set of text objects         | :thumbsup:    | :question:    | :x:           |
| ([c.1]) | highlight `()`, `[]`, & `{}`     | :thumbsup:    | :x:           | :thumbsup:    |
| ([c.2]) | highlight _all_ matches          | :thumbsup:    | :x:           | :x:           |
| ([c.3]) | display matches off-screen       | :thumbsup:    | :x:           | :x:           |
| ([d.1]) | auto-insert open, close, & mid   | :construction:| :x:           | :x:           |
| ([d.2]) | completion                       | :construction:| :x:           | :x:           |
| ([d.3]) | parallel transmutation           | :thumbsup:    | :x:           | :x:           |
| ([d.4]) | split & join                     | :construction:| :x:           | :x:           |
| ([e.1]) | modern, modular coding style     | :thumbsup:    | :x:           | :x:           |
| ([e.2]) | actively developed               | :thumbsup:    | :x:           | :x:           |

[a.1]: #a1-jump-between-matching-words
[a.2]: #a2-jump-to-open-and-close-words
[a.3]: #a3-jump-inside
[b.1]: #b1-full-set-of-text-objects
[c.1]: #c1-highlight-
[c.2]: #c2-highlight-all-matches
[c.3]: #c3-display-matches-off-screen
[d.1]: #d1-auto-insert-open-close-and-mid
[d.2]: #d2-completion
[d.3]: #d3-parallel-transmutation
[d.4]: #d4-split-and-join
[e.1]: #e1-modern-modular-coding-style
[e.2]: #e2-actively-developed
[inclusive]: #inclusive-and-exclusive-motions
[exclusive]: #inclusive-and-exclusive-motions

Legend: :thumbsup: supported. :construction: TODO, planned, or in progress.
:question: poorly implemented, broken, or uncertain.  :x: not possible.

### Detailed feature documentation

What do we mean by open, close, mid?  Here is a vim-script example:

```vim
if l:x == 1
  call one()
else
  call two()
elseif
  call three()
endif
```

match-up understands the words `if`, `else`, `elseif`, `endif` and that
they form a sequential construct in the vim-script language.  The
"open" word is `if`, the "close" word is `endif`, and the "mid"
words are `else` and `elseif`.  The `if`/`endif` pair is called an
"open-to-close" block and the `if`/`else`, `else`/`elsif`, and
`elseif`/`endif` are called "any" blocks.

#### (a.1) jump between matching words
  - `%` go forwards to next matching word.  If at a close word,
  cycle back to the corresponding open word.
  - `{count}%` forwards `{count}` times.  Requires
  `let g:matchup_override_Npercent = 1`.
  By default, `{count}%` goes to the `{count}` percentage in the file.
  - `g%` go backwards to `[count]`th previous matching word.  If at an
  open word, cycle around to the corresponding close word.

#### (a.2) jump to open and close words
  - `[%` go to `[count]`th previous unmatched open word.  Allows
  navigation to the start of surrounding blocks.  This is similar to vim's
  built-in `[(` and `[{` and is an [exclusive] motion.
  - `]%` go to `[count]`th next unmatched close word.  This is an
  [exclusive] motion.

#### (a.3) jump inside
  - `z%` go to inside `[count]`th nearest inner contained block.  This
  is an [inclusive] motion.

#### (b.1) full set of text objects
  - `i%` the inside of an open to close block
  - `1i%` the inside of an any block
  - `{count}i%` If count is not 1, the inside open-to-close block

  - `a%` an open-to-close block.
  - `1a%` an any block.  Includes mids but does not include open and close.
  - `{count}a%` if `{count}` is greater than 1, the `{count}` surrounding open-to-close block.

  Note: by default objects involving `matchpairs` such as `(){}[]` are
performed character-wise, while `matchwords` such as `if`/`endif` are
performed line-wise.
The -wise can be forced using "v", "V", or `^V`
Let `g:matchup_all_charwise`.
XXX inclusive, exclusive
XXX need () characterwise, others linewise except QUIRKS.

#### (c.1) highlight `()`, `[]`, and `{}`

match-up emulates vim's matchparen to highlight the symbols contained
in the `matchpairs` setting.

#### (c.2) highlight _all_ matches          

To disable match highlighting `let g:matchup_matchparen_enabled = 0`.
If this option is set before the plugin is loaded, it will not disable
the matchparen plugin (_Planned_).  To disable highlighting entirely
do not load matchparen.

#### (c.3) display matches off screen

If a open or close which would have been highlighted is on a line
positioned outside the current window, the match is shown in the
status line.  If both the open and close match are off-screen, the
close match is preferred.

#### (d.1) auto-insert open, close, and mid

_Planned_.

- end-wise style completion: typing `CTRL-X <cr>` will insert the 
corresponding end word.

- automatic block insertion: typing `CTRL-X CTRL-B` to produce
block skeletons.

#### (d.2) auto-completion

_Planned_. 

Typing `CTRL-X M` will give a menu of possible words.

#### (d.3) parallel transmutations

In insert mode, after changing text inside a word, matching words will
be changed in parallel.
As an example,

```html
<pre>
  text
</pre>
```

Changing `pre` to `div` and leaving insert mode will produce:

```html
<div>
  text
</div>
```

This must be done before leaving insert mode.  A corresponding normal mode
command is planned.

_Planned_: `g:matchup_auto_transmute`, `CTRL-G %` mapping.

#### (d.4) split and join

_Planned_.

### Inclusive and exclusive motions

In vim, character motions following operators (such as `d` for delete
and `c` for change) are either _inclusive_ or _exclusive_.  This means
they either include the ending position or not.  match-up is designed so
that `d]%` inside a set of parenthesis behaves exactly like `d])`.  For
other words, exclusive motions will not include the close word.  In this
example, where `█` is the cursor position,

    if █| continue | endif

pressing `d]%` will produce    

    if endif

To include the close word, use either `dv]%` or `vd]%`.  This is vim
compatible.

## Options



## FAQ

- match-up doesn't work

The plugin requires a fairly recent version of vim.  Please tell me your
vim version and error messages.  Try updating vim and see if the problem
persists.

- Why does jumping not work for construct X in language Y?

Please open a new issue 

- Highlighting is not correct for construct X

match-up uses matchit's filetype-specific data, which may not give enough
information to create proper highlights.  To fix this, you may need to add
a highlight quirk.

For help, please open a new issue and be a specific as possible.

- I'm having performance problems

match-up aims to be as fast as possible.  If you see any performance
issues, please open a new issue and report `g:matchup#perf#times`.

- How can I contribute?

Read the [contribution guidelines](CONTRIBUTING.md) and
[issue template](ISSUE_TEMPLATE.md).  Be as precise and detailed
as possible when submitting issues and pull requests.

## Interoperability

  - match-up is not compatible with [vimtex](https://github.com/lervag/vimtex)
  and will be disabled automatically when vimtex is detected.
  - the end-completion maps conflict with [vim-endwise](https://github.com/tpope/vim-endwise).
  - matchit.vim should not be loaded.  If it is loaded, it must be loaded
  before match-up (in this case, matchit is disabled).
  - match-up loads matchparen if it is not already loaded.

## Acknowledgments 

### Origins

match-up was originally based on [@lervag](https://github.com/lervag)'s
[vimtex](github.com/lervag/vimtex).  The concept and style of this plugin
and its development are heavily influenced by vimtex.

### Other inspirations

- [matchit](http://ftp.vim.org/pub/vim/runtime/macros/matchit.txt)
- [matchparen](http://ftp.vim.org/pub/vim/runtime/doc/pi_paren.txt)
- [vim-endwise](https://github.com/tpope/vim-endwise)
- [auto-pairs](https://github.com/jiangmiao/auto-pairs)
- [delimitMate](https://github.com/Raimondi/delimitMate)
- [splitjoin.vim](https://github.com/AndrewRadev/splitjoin.vim)
- [vim-surround](https://github.com/tpope/vim-surround)
- [vim-sandwich](https://github.com/machakann/vim-sandwich)
- [MatchTagAlways](https://github.com/Valloric/MatchTagAlways)

## license

Totally new features

  - parallel transformations (transmutation)
     (need to cache matches and see if they change)
    - polymorphic / smart -> if:end,while:end
  - native split/join
  - quirks
  - auto insert

Definitions

  Matchword
    A matchword is an regular expression which defines interesting items
    to matchup matchup treats specially.  For instance, by default ( and ) are 
    paired matchwords.
    is on the matched to buffer text,
    becomes a matched word, 

  Matched word
    A matched word is an instance of buffer text which matches

Variables

  matchup understands the following variables
    b:match_words        a set of 
    b:match_ignorecase
    b:match_skip
    loaded_matchit

Existing matchit features, made better:

% v_%       between matches
g% v_g%     backwards between matches
[% ]%       to nearest unmatched
o_a% o_i%   delimited text object

Features in matchparen:

  matchup emulates matchparen's highlighting for matchpairs
  Echo invisible pairs 

Features not in matchit:

  Auto-completion
    ctrl-x <CR> shift <CR>
    completes the nearest unmatched matchword.  When n-tuple matchwords are used
    the last one is inserted.

  Highlighting general
    matchup highlights matches for b:match_words

  Jump into
    z[]% go to the center of the next group of matchwords

## Development

### TODO

- vim proper doc/
- Add screenshots

