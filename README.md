# vim-textidote

## Description

This plugin interfaces Vim with the [TeXtidote][TeXtidote] grammar checker.  TeXtidote is an open source spelling, grammar and style checker for multiple languages based on LanguageTool.  TeXtidote is built on top of LanguageTool and is able to remove LaTeX and Markdown markup before grammar checking, while keeping track of the relative position of words between the original and "clean text". In short, TeXtidote is a version of LanguageTool made blind to LaTeX and Markdown markup.

The plugin [vim-LanguageTool][vim-LanguageTool] is a full-featured interface of LanguageTool with Vim.  This plugin offers the same clean interface based on TeXtidote instead of LanguageTool. As a consquence, all the errors based on LaTeX or Markdown markup are skipped.


## Installation

Download the latest `textidote.jar` from [TeXtidote][TeXtidote] and make sure that you have Java version 8 or later installed on your system.

Install `vim-textidote` using your favorite package manager, or use Vim's built-in package support:

    mkdir -p ~/.vim/pack/PatrBal/start
    cd ~/.vim/pack/PatrBal/start
    git clone https://github.com/PatrBal/vim-textidote
    vim -u NONE -c "helptags vim-textidote/doc" -c q


## Usage
`:[range]TeXtidoteToggle`  
By default `[range]` is the whole buffer, except in the case where there is a visual selection which is then taken as the default `[range]`.


## Features
 - Spell, grammar and style checking of either the entire buffer or part of it.
 - A scratch buffer shows up, listing all the errors.  Pressing <Enter> on an error in the error scratch buffer will jump to that error.
 - The location-list is populated, so that you can use location-list Vim commands such as `:lopen` to open the location-list window, `:lne` to jump to the next error, etc.
 - Optionally, a full html report of TeXtidote analysis can be displayed in the default brower.


## License

Copyright (c) Patrick Ballard.  Distributed under the same terms as Vim itself.
See `:help license`.


## Credit

This plugin is strongly based on the excellent [vim-LanguageTool][vim-LanguageTool].  Large parts of its code have been reused.


[TeXtidote]: https://sylvainhalle.github.io/textidote
[vim-LanguageTool]: https://github.com/dpelle/vim-LanguageTool
