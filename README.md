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
  * [FAQ](#faq)
  * [Interoperability](#interoperability)
  * [Development](#development)

## Overview

This plugin

- Extends vim's `%` motion to language-words like `if`, `else`, `endif`.
- Combines these motions into convenient text objects `i%` and `a%`.
- Highlights symbols and words under the cursor which `%` works on,
  and highlights matching symbols and words.  Now you can tell where
  `%` will jump to.
- Adds auto-completion for words and symbols- for example you can 
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

|       | feature                          | __match-up__  | matchit       | matchparen    |
| ----- | -------------------------------- | ------------- | ------------- | ------------- |
| (a.1) | jump between matching constructs | :thumbsup:    | :thumbsup:    | :x:           |
| (a.2) | jump to open, close              | :thumbsup:    | :question:    | :x:           |
| (a.3) | jump inside                      | :thumbsup:    | :question:    | :x:           |
| (b.1) | full set of text objects         | :thumbsup:    | :x:           | :x:           |
| (c.1) | auto-insert open, close, and mid | :thumbsup:    | :x:           | :x:           |
| (c.2) | auto-completion                  | :thumbsup:    | :x:           | :x:           |
| (c.3) | parallel transmutations :star2:  | :thumbsup:    | :x:           | :x:           |
| (c.4) | split and join                   | :thumbsup:    | :x:           | :x:           |
| (d.1) | highlight ()[]{}                 | :thumbsup:    | :x:           | :thumbsup:    |
| (d.2) | highlight _all_ matches          | :thumbsup:    | :x:           | :x:           |
| (e.1) | modern, modular coding style     | :thumbsup:    | :x:           | :x:           |
| (e.2) | actively developed               | :thumbsup:    | :x:           | :x:           |

Legend: :thumbsup: supported. :construction: TODO, planned, or in progress.
:question: poorly implemented, broken, or uncertain.  :x: not possible.

### Detailed feature documentation

What do we mean by open, close, mid?  Here is an example:

```vim
if l:x == 1
  call one()
else
  call two()
elseif
  call three()
endif
```

The words `if`, `else`, `elseif`, `endif` are called "constructs." The
open construct is `if`, the close construct is `endif`, and the mid
constructs are `else` and `elseif`.  The `if`/`endif` pair is called an
"open-to-close" block and the `if`/`else`, `else`/`elsif`, and
`elseif`/`endif` are called "any" blocks.

#### (a.1) jump between matching constructs
  - `%` go forwards matching construct `[count]` times
  - `{count}%` forwards `{count}` times.  Requires
      `let g:matchup_override_Npercent = 1`
  - `g%` go backwards matching construct `[count]` times

#### (a.2) jump to open and close
  - `[%` go to `[count]` previous unmatched open construct
  - `]%` go to `[count]` next unmatched close construct

#### (a.3) jump inside
  - `z%` go to inside nearest `[count]`th inner contained block.  

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

- (c.1) auto-insert open, close, and mid
  - end-wise completion: typing `CTRL-X <cr>` will insert the 
  corresponding end construct.
  
  - automatic block insertion:
  _Planned_. Typing `CTRL-X CTRL-B` to produce block skeletons.

- (c.2) auto-completion
  _Planned_. Typing `CTRL-X %` to give a menu of possible constructs.

- (c.3) parallel transmutations

  In insert mode, after changing text inside a construct, typing
  `CTRL-G %` will change any matching constructs in parallel.
  As an example,

```html
<pre>
  text
</pre>
```

Changing `pre` to `div` and typing `CTRL-G %` will produce:

```html
<div>
  text
</div>
```

This must be done before leaving insert mode.  A corresponding normal mode
command is planned.

_Planned_: `g:matchup_auto_transmute` 

- (c.4) split and join

_Planned_.

- (d.1) highlight ()[]{}
- (d.2) highlight _all_ matches          

  To disable match highlighting `let g:matchup_matchparen_enabled = 0`.
  If this option is set before the plugin is loaded, it will not disable
  the matchparen plugin (_Planned_).  To disable highlighting entirely
  do not load matchparen.

### Line-wise, exclusive, and inclusive motions


### Options


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

