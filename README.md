# vim-antidote

## Description

This plugin interfaces Vim with [Antidote.app][Antidote] and/or [TeXtidote][TeXtidote] for efficient spellcheking from inside Vim.

It provides a new :Antidote and :TeXtidote family of commands and (recommended) mappings.

WARNING: this version of `vim-antidote` is a Mac only plugin, so you will not benefit
from using `vim-antidote` on Linux nor Windows. It can be installed on those systems
however, but it will not load.

## Installation

Install using your favorite package manager, or use Vim's built-in package
support:

    mkdir -p ~/.vim/pack/PatrBal/start
    cd ~/.vim/pack/PatrBal/start
    git clone https://github.com/PatrBal/vim-antidote
    vim -u NONE -c "helptags vim-antidote/doc" -c q


## Usage
 - :[range]Antidote :[range]TeXtidote

## Features
 - Spellcheck of either the entire buffer or part of it.
 - Validated corrections in Antidote are reimported in Vim.
 - Corrections of TeXtidote are displayed in the default brower.
 - Show definition in Antidote of the current word.

## Open tasks
 - [ ] Add support for Windows and Linux
 - [ ] Highlight grammar and spelling mistakes of TeXtidote in the current buffer and populate the location list, as does the plugin [Vim-LanguageTool] for LanguageTool.


## License

Copyright (c) Patrick Ballard.  Distributed under the same terms as Vim itself.
See `:help license`.

[Antidote]: https://www.antidote.info/en
[TeXtidote]: https://sylvainhalle.github.io/textidote
[Vim-LanguageTool]: https://github.com/dpelle/vim-LanguageTool

