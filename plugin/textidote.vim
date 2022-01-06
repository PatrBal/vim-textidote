" Description: Grammar checker with TeXtidote from Vim
" Author:      Patrick Ballard <patrick.ballard.paris@gmail.com>
" Last Change: 05/01/2022
"
" Long Description: {{{1
"
" This plugin integrates the TeXtidote grammar checker into Vim.
" Current version of TeXtidote can check grammar in many languages:
" de, en, es, fr, nl, pl, pt.
"
" See doc/TeXtidote.txt for more details about how to use the
" TeXtidote plugin.
"
" See https://sylvainhalle.github.io/textidote/ for more information about TeXtidote.
"
" License: {{{1
"
" The VIM LICENSE applies to LanguageTool.vim plugin
" (see ":help copyright" except use "textidote.vim" instead of "Vim").
"
" Plugin set up {{{1
if &cp || exists("g:loaded_textidote")
 finish
endif
let g:loaded_textidote = "1"

if !exists('g:textidote_indicator')
	let g:textidote_indicator = 0
endif

if !exists('g:textidote_html_report')
	let g:textidote_html_report = 0
endif

""" Example of configuration
" let g:textidote_first_language = 'fr'
" let g:textidote_html_report = 0
" let g:textidote_ignore_rules = 'lt:en:EN_REPEATEDWORDS,sh:c:noin'
" let g:textidote_ignore_environments = 'tikzpicture,equation'
" let g:textidote_ignore_macros = 'array'
" vnoremap <silent> <Leader>te :'<,'>TeXtidoteToggle<CR>
" nnoremap <silent> <Leader>te :TeXtidoteToggle<CR>


hi def link TeXtidoteCmd           Comment
hi def link TeXtidoteErrorCount    Title
hi def link TeXtidoteLabel         Label
hi def link TeXtidoteUrl           Underlined
hi def link TeXtidoteGrammarError  Error
hi def link TeXtidoteSpellingError WarningMsg

" Menu items {{{1
if has("gui_running") && has("menu") && &go =~# 'm'
  amenu <silent> &Plugin.TeXtidote.Togg&le :TeXtidoteToggle<CR>
endif

" Defines commands {{{1
command! -nargs=0          TeXtidoteClear :call textidote#Clear()
command! -nargs=0 -range=% TeXtidoteCheck :call textidote#Check(<line1>,<line2>)
command! -nargs=0 -range=% TeXtidoteToggle :call textidote#Toggle(<line1>,<line2>)

