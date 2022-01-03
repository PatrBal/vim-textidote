" Description: Spellcheck with either Antidote.app or TeXtidote from Vim
" Author: Patrick Ballard <patrick.ballard.paris@gmail.com>
" License: MIT


if !exists('g:antidote_antidote_application')
	let g:antidote_antidote_application = '/Applications/Antidote/Antidote 11.app'
endif

if !exists('g:antidote_textidote_application')
	let g:antidote_textidote_application = '~/.vim/textidote.jar'
endif

if !exists('g:antidote_textidote_first_language')
	let g:antidote_textidote_first_language = ''
endif

if g:antidote_textidote_first_language == ''
	let g:antidote_textidote_first_language_option = ''
elseif g:antidote_textidote_first_language == 'de' || g:antidote_textidote_first_language == 'de_AT' || g:antidote_textidote_first_language == 'de_CH' || g:antidote_textidote_first_language == 'en' || g:antidote_textidote_first_language == 'de_UK' || g:antidote_textidote_first_language == 'de_CA' || g:antidote_textidote_first_language == 'es' || g:antidote_textidote_first_language == 'fr' || g:antidote_textidote_first_language == 'nl' || g:antidote_textidote_first_language == 'pt' || g:antidote_textidote_first_language == 'pl'
	let g:antidote_textidote_first_language_option = ' --firstlang ' . g:antidote_textidote_first_language
else
	echom 'Unknown first language!'
	finish
endif

if empty(glob(g:antidote_antidote_application)) && empty(glob(g:antidote_textidote_application))
	finish
endif

if !has('unix') " macOS's vim, nvim and MacVim have this feature
	finish
endif

if !has('python3')
	echomsg "Vim-Antidote unavailable: unable to load Python." |
	finish
endif

" Get default browser
" let g:defaultBrowser = system("defaults read ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure | awk -F\'\"\' \'/http;/{print window[(NR)-1]}{window[NR]=$2}\'")
" if g:defaultBrowser =~ 'safari' || g:defaultBrowser == ''
" 	"if Safari is the only Browser installed or if another Browser is installed and has never had a default Browser set, then by default nothing will be returned by the "defaults ..." command, and this means Safari is the default Browser
" 	let g:defaultBrowser = 'Safari'
" elseif g:defaultBrowser =~ 'chrome'
" 	let g:defaultBrowser = 'Google Chrome'
" elseif g:defaultBrowser =~ 'firefox'
" 	let g:defaultBrowser = 'Firefox'
" else
" 	echom "Unknown default browser."
" 	finish
" endif

let g:scriptPath = fnamemodify(resolve(expand('<sfile>:p')), ':h') . '/openBrowser.py'

" Antidote spellchecking
vnoremap <silent> <Leader>an :<C-U>call antidote#VisualAntidote()<CR>
nnoremap <silent> <Leader>an :call antidote#NormalAntidote()<CR>
command -range=% Antidote call antidote#CommandAntidote(<line1>,<line2>)

" TeXtidote spellchecking
vnoremap <silent> <Leader>te :<C-U>call antidote#VisualTeXtidote()<CR>
nnoremap <silent> <Leader>te :call antidote#NormalTeXtidote()<CR>
command -range=% TeXtidote call antidote#CommandTeXtidote(<line1>,<line2>)


function! AntidoteDict(word)
	call system("osascript -e \'tell application \"AgentAntidoteConnect\" to lance module dictionnaires ouvrage definitions mot \"" . a:word . "\"\'")
	redraw!
endfunction

function! AntidoteConjug(word)
	call system("osascript -e \'tell application \"AgentAntidoteConnect\" to lance module dictionnaires ouvrage conjugaison mot \"" . a:word . "\"\'")
	redraw!
endfunction

scriptencoding utf-8

" Enable "C-@" to call the definition of the current word in normal and visual modes
" (oddly "C-@" is referred to a <C-Space> in Vim)
nnoremap <C-Space> "dyiw:call AntidoteDict(@d)<CR>
vnoremap <C-Space> "dy:call AntidoteDict(@d)<CR>

" Enable "alt-@" to call the definition of the current word in normal and visual modes
" nnoremap • "dyiw:call AntidoteDict(@d)<CR>
" vnoremap • "dy:call AntidoteDict(@d)<CR>
" Enable "alt-shift-@" to call the conjugation of the current word in normal and visual modes
" nnoremap Ÿ "dyiw:call AntidoteConjug(@d)<CR>
" vnoremap Ÿ "dy:call AntidoteConjug(@d)<CR>
