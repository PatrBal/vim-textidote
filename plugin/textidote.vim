" LanguageTool: Grammar checker in Vim for English, French, German, etc.
" Maintainer:   Dominique Pellé <dominique.pelle@gmail.com>
" Screenshots:  http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_en.png
"               http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_fr.png
" Last Change:  2020/10/30
"
" Long Description: {{{1
"
" This plugin integrates the LanguageTool grammar checker into Vim.
" Current version of LanguageTool can check grammar in many languages:
" ar ast, be, br, ca, da, de, el, en, eo, es, fa, fr, ga, gl, it, ja,
" km, nl, pl, pt, ro, ru, sk, sl, sk, sv, ta, tl, uk, zh.
"
" See doc/LanguageTool.txt for more details about how to use the
" LanguageTool plugin.
"
" See http://www.languagetool.org/ for more information about LanguageTool.
"
" License: {{{1
"
" The VIM LICENSE applies to LanguageTool.vim plugin
" (see ":help copyright" except use "LanguageTool.vim" instead of "Vim").
"
" Plugin set up {{{1
if &cp || exists("g:loaded_textidote")
 finish
endif
let g:loaded_textidote = "1"

if !exists('g:textidote_first_language')
	let g:textidote_first_language = ''
endif

  " All supported languages (with variants) by TeXtidote.
  let l:supportedLanguages =  {
  \  'de'    : 1,
  \  'de_AT' : 1,
  \  'de_CH' : 1,
  \  'en'    : 1,
  \  'en_CA' : 1,
  \  'en_GB' : 1,
  \  'es'    : 1,
  \  'fr'    : 1,
  \  'nl'    : 1,
  \  'pl'    : 1,
  \  'pt'    : 1,
  \}

if g:textidote_first_language == ''
	let g:textidote_first_language_option = ''
elseif has_key(l:supportedLanguages, g:textidote_first_language)
	let g:textidote_first_language_option = ' --firstlang ' . g:textidote_first_language
else
	echom 'Unknown first language!'
	finish
endif


hi def link TeXtidoteCmd           Comment
hi def link TeXtidoteErrorCount    Title
hi def link TeXtidoteLabel         Label
hi def link TeXtidoteUrl           Underlined
hi def link TeXtidoteGrammarError  Error
hi def link TeXtidoteSpellingError WarningMsg

" Menu items {{{1
if has("gui_running") && has("menu") && &go =~# 'm'
  amenu <silent> &Plugin.TeXtidote.Chec&k :TeXtidoteCheck<CR>
  amenu <silent> &Plugin.TeXtidote.Clea&r :TeXtidoteClear<CR>
endif

" Defines commands {{{1
com! -nargs=0          TeXtidoteClear :call textidote#Clear()
com! -nargs=0 -range=% TeXtidoteCheck :call textidote#Check(<line1>,
                                                                \ <line2>)
" vim: fdm=marker
