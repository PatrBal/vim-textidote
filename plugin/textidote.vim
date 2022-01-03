" Description: Grammar check with TeXtidote from Vim
" Author: Patrick Ballard <patrick.ballard.paris@gmail.com>
" License: MIT


if !exists('g:textidote_application')
	let g:textidote_application = '~/.vim/textidote.jar'
endif

if !exists('g:textidote_first_language')
	let g:textidote_first_language = ''
endif

if g:textidote_first_language == ''
	let g:textidote_first_language_option = ''
elseif g:textidote_first_language == 'de' || g:textidote_first_language == 'de_AT' || g:textidote_first_language == 'de_CH' || g:textidote_first_language == 'en' || g:textidote_first_language == 'de_UK' || g:textidote_first_language == 'de_CA' || g:textidote_first_language == 'es' || g:textidote_first_language == 'fr' || g:textidote_first_language == 'nl' || g:textidote_first_language == 'pt' || g:textidote_first_language == 'pl'
	let g:textidote_first_language_option = ' --firstlang ' . g:textidote_first_language
else
	echom 'Unknown first language!'
	finish
endif

if !has('python3')
	echomsg "Vim-Antidote unavailable: unable to load Python." |
	finish
endif

let g:scriptPath = fnamemodify(resolve(expand('<sfile>:p')), ':h') . '/openBrowser.py'

" TeXtidote spellchecking
vnoremap <silent> <Leader>te :<C-U>call textidote#VisualTeXtidote()<CR>
nnoremap <silent> <Leader>te :call textidote#NormalTeXtidote()<CR>
command -range=% TeXtidote call textidote#CommandTeXtidote(<line1>,<line2>)

