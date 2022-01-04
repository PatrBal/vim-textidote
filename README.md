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


## Développement

Pour voir la sortie XML le LanguageTool qui sert de base au plugin vim-LanguageTool, lancer dans le terminal la commande :

`java -jar /Users/patrick.ballard/Desktop/LanguageTool-5.2/languagetool-commandline.jar -c utf-8 -d WHITESPACE_RULE,EN_QUOTES -l en --api /Users/patrick.ballard/Documents/Science/Articles/SteadyFriction-HalfSpace/NewIntroRef.tex 2> LT-report.txt`

La sortie texte de TeXtidote s'obtient par :

`java -jar ~/.vim/textidote.jar --check en --output plain /Users/patrick.ballard/Documents/Science/Articles/SteadyFriction-HalfSpace/NewIntroRef.tex > ~/Desktop/TeX-report.txt`

C'est du RTF. On peut le nettoyer en faisant :

`sed -r "s/\x1B\[(([0-9]{1,2})?(;)?([0-9]{1,2})?)?[m,K,H,f,J]//g" TeX-report.txt > pure-TeX-report.txt`

Il s'agit donc d'obtenir toutes les informations que vim-LanguageTool extrait de la sortie XML à partir de la sortie texte nettoyée de TeXtidote.  Le plus simple semble de reconstituer le format du fichier XML utilisé par 
vim-LanguageTool.

Voici un one-liner :

`cat pure-TeX-report.txt | sed -E 's/^( *)(\^+)$/\1,\2,trucdeouf/' | awk -F"," '{ if ($3=="trucdeouf")  print "contextoffset=\""length($1)"\" errorlength=\""length($2)"\"/>"; else print $0 }' | sed -E 's/\* L([0-9]*)C([0-9]*)-L([0-9]*)C([0-9]*)/<error fromy="\1" fromx="\2" toy="\3" tox="\4"/'`

qui transforme

```
* L77C70-L77C79 Do not use 'in [X]': the syntax of a sentence should not be
  changed by the removal of a citation. [sh:c:noin]
  lem was first proved in \cite{Jarusek} (see also \
                       ^^^^^^^^^^
```
en
```
<error fromy="77" fromx="70" toy="77" tox="79" Do not use 'in [X]': the syntax of a sentence should not be
  changed by the removal of a citation. [sh:c:noin]
  lem was first proved in \cite{Jarusek} (see also \
contextoffset="23" errorlength="10"/>
```





