" Description: Grammar checker of LaTeX files with TeXtidote from Vim
" Author:      Patrick Ballard <patrick.ballard.paris@gmail.com>
" Last Change: 13/11/2022


" Guess language from 'a:lang' (either 'spelllang' or 'v:lang')
function s:FindLanguage(lang) "{{{1
	" This replaces things like en-gb with en_UK as expected by TeXtidote,
	" only for languages that support variants in TeXtidote.
	let l:language = substitute(substitute(a:lang,
	\  '\(\a\{2,3}\)\(_\a\a\)\?.*',
	\  '\=tolower(submatch(1)) . toupper(submatch(2))', ''),
	\  '-', '_', '')
	if l:language ==? 'en_GB'
		let l:language = 'en_UK'
	endif
	
	" All supported languages (with variants) by TeXtidote.
	let l:supportedLanguages =  {
	\  'de'    : 1,
	\  'de_AT' : 1,
	\  'de_CH' : 1,
	\  'en'    : 1,
	\  'en_CA' : 1,
	\  'en_UK' : 1,
	\  'es'    : 1,
	\  'fr'    : 1,
	\  'nl'    : 1,
	\  'pl'    : 1,
	\  'pt'    : 1,
	\}

	if has_key(l:supportedLanguages, l:language)
		return l:language
	endif
	
	" Removing the region (if any) and trying again.
	let l:language = substitute(l:language, '_.*', '', '')
	return has_key(l:supportedLanguages, l:language) ? l:language : ''
endfunction

" Return a regular expression used to highlight a grammatical error
" at line a:line in text.  The error starts at character a:start in
" context a:context and its length in context is a:len.
function s:TeXtidoteHighlightRegex(line, context, start, len)  "{{{1
	let l:start_idx     = byteidx(a:context, a:start)
	let l:end_idx       = byteidx(a:context, a:start + a:len) - 1
	let l:start_ctx_idx = byteidx(a:context, a:start + a:len)
	let l:end_ctx_idx   = byteidx(a:context, a:start + a:len + 5) - 1
	
	" The substitute allows matching errors which span multiple lines.
	" The part after \ze gives a bit of context to avoid spurious
	" highlighting when the text of the error is present multiple
	" times in the line.
	return '\V'
	\     . '\%' . a:line . 'l'
	\     . substitute(escape(a:context[l:start_idx : l:end_idx], "'\\"), ' ', '\\_\\s', 'g')
	\     . '\ze'
	\     . substitute(escape(a:context[l:start_ctx_idx : l:end_ctx_idx], "'\\"), ' ', '\\_\\s', 'g')
endfunction

" Unescape XML special characters in a:text.
function s:XmlUnescape(text) "{{{1
	" Change XML escape char such as &quot; into "
	" Substitution of &amp; must be done last or else something
	" like &amp;quot; would get first transformed into &quot;
	" and then wrongly transformed into "  (correct is &quot;)
	let l:escaped = substitute(a:text,    '&quot;', '"',  'g')
	let l:escaped = substitute(l:escaped, '&apos;', "'",  'g')
	let l:escaped = substitute(l:escaped, '&gt;',   '>',  'g')
	let l:escaped = substitute(l:escaped, '&lt;',   '<',  'g')
	let l:escaped = substitute(l:escaped, '&#x9;',  '	', 'g')
	return          substitute(l:escaped, '&amp;',  '\&', 'g')
endfunction

" Parse a xml attribute such as: ruleId="FOO" in line a:line.
" where ruleId is the key a:key, and FOO is the returned value corresponding
" to that key.
function s:ParseKeyValue(key, line) "{{{1
	return s:XmlUnescape(matchstr(a:line, '\<' . a:key . '="\zs[^"]*\ze"'))
endfunction

" Set up configuration.
" Returns 0 if success, < 0 in case of error.
function s:TeXtidoteSetUp() "{{{1
	let s:textidote_dictionary = exists('g:textidote_dictionary')
	\ ? g:textidote_dictionary : ''
	let s:textidote_replacements = exists('g:textidote_replacements')
	\ ? g:textidote_replacements : ''
	let s:textidote_ignore_rules = exists('g:textidote_ignore_rules')
	\ ? g:textidote_ignore_rules : ''
	let s:textidote_ignore_environments = exists('g:textidote_ignore_environments')
	\ ? g:textidote_ignore_environments : ''
	let s:textidote_ignore_macros = exists('g:textidote_ignore_macros')
	\ ? g:textidote_ignore_macros : ''
	let s:textidote_win_height = exists('g:textidote_win_height')
	\ ? g:textidote_win_height
	\ : 14
	let s:textidote_encoding = &fileencoding ? &fileencoding : &encoding
	
	if s:textidote_dictionary ==# ''
		let s:textidote_dictionary_option = ''
	else
		let s:textidote_dictionary_option = ' --dict ' . s:textidote_dictionary
	endif
	if s:textidote_replacements ==# ''
		let s:textidote_replacements_option = ''
	else
		let s:textidote_replacements_option = ' --replace ' . s:textidote_replacements
	endif
	if s:textidote_ignore_rules ==# ''
		let s:textidote_ignore_rules_option = ''
	else
		let s:textidote_ignore_rules_option = ' --ignore ' . s:textidote_ignore_rules
	endif
	if s:textidote_ignore_environments ==# ''
		let s:textidote_ignore_environments_option = ''
	else
		let s:textidote_ignore_environments_option = ' --remove ' . s:textidote_ignore_environments
	endif
	if s:textidote_ignore_macros ==# ''
		let s:textidote_ignore_macros_option = ''
	else
		let s:textidote_ignore_macros_option = ' --remove-macros ' . s:textidote_ignore_macros
	endif
	
	" Setting up language...
	if exists('g:textidote_lang')
		let s:textidote_lang = g:textidote_lang
	else
		" Trying to guess language from 'spelllang' or 'v:lang'.
		let s:textidote_lang = s:FindLanguage(&spelllang)
		if s:textidote_lang ==# ''
			let s:textidote_lang = s:FindLanguage(v:lang)
			if s:textidote_lang ==# ''
				echoerr 'Failed to guess language from spelllang=['
				\ . &spelllang . '] or from v:lang=[' . v:lang . ']. '
				\ . 'Defauling to US English (en). '
				\ . 'See ":help TeXtidote" regarding setting g:textidote_lang.'
				let s:textidote_lang = 'en'
			endif
		endif
	endif
	
	if !exists('g:textidote_first_language')
		let g:textidote_first_language = ''
	endif
	let g:textidote_first_language = s:FindLanguage(g:textidote_first_language)
	if g:textidote_first_language ==# ''
		let s:textidote_first_language_option = ''
	else
		let s:textidote_first_language_option = ' --firstlang ' . g:textidote_first_language
	endif
	
	let s:textidote_jar = exists('g:textidote_jar')
	\ ? g:textidote_jar
	\ : $HOME . '/.vim/textidote.jar'
	
	if !exists('g:textidote_cmd') && !filereadable(s:textidote_jar)
		" Hmmm, can't find the jar file.  Try again with expand() in case user
		" set it up as: let g:textidote_jar = '$HOME/.vim/textidote.jar'
		let l:textidote_jar = expand(s:textidote_jar)
		if !filereadable(expand(l:textidote_jar))
			echomsg 'TeXtidote cannot be found at: ' . s:textidote_jar
			echomsg 'You need to install TeXtidote and/or set up g:textidote_jar'
			echomsg 'to indicate the location of the textidote.jar file.'
			return -1
		endif
		let s:textidote_jar = l:textidote_jar
	endif

	" Storing &completefunc and nmap of <Tab> to restore them after grammar check
	let s:completefunc_orig = &completefunc
	if !empty(maparg('<Tab>', 'n'))
		let s:mapTab_orig = maparg('<Tab>', 'n')
	endif
	if !empty(maparg(']', 'n'))
		let s:mapForward_orig = maparg(']', 'n')
	endif
	if !empty(maparg('[', 'n'))
		let s:mapBackward_orig = maparg('[', 'n')
	endif
	if !empty(maparg('¶', 'n'))
		let s:mapAux_orig = maparg('¶', 'n')
	endif

	return 0
endfunction

" Jump to a grammar mistake (called when pressing <Enter>
" on a particular error in scratch buffer).
function <sid>JumpToCurrentError() "{{{1
	let l:save_cursor = getpos('.')
	normal! $
	if search('^Error:\s\+', 'beW') > 0
		let l:error_idx = expand('<cword>')
		let l:error = s:errors[l:error_idx - 1]
		let l:line = l:error['fromy']
		let l:col  = l:error['fromx']
		let l:rule = l:error['ruleId']
		call setpos('.', l:save_cursor)
		if exists('*win_gotoid')
			call win_gotoid(s:textidote_text_winid)
		else
			execute s:textidote_text_winid . ' wincmd w'
		endif
		execute 'normal! ' . l:line . 'G0'
		if l:col > 0
			execute 'normal! ' . (l:col  - 1) . 'l'
		endif
		
		echon 'Jump to error ' . l:error_idx . '/' . len(s:errors)
		\ . ' ' . l:rule . ' @ ' . l:line . 'L ' . l:col . 'C'

		" Open the folds to reveal the cursor line and display that line in
		" the middle of the window
		normal! zv
		normal! zz

		" Populate the suggestion list and setup the completion trigger by
		" <Tab>
		if !empty(l:error['replacements'])
			let s:col = l:col - 1
			let s:colStart = l:error['fromx']
			let s:colEnd = l:error['tox']
			let s:lineStart = l:error['fromy']
			let s:lineEnd = l:error['toy']
			let l:suggestions = substitute(l:error['replacements'], '^\(.\{-}\)\s*$', '\1', '')
			let s:suggestions_list = split(l:suggestions,', ')
			setlocal completefunc=textidote#Suggestions
			" nmap <buffer> <Tab> ¶ea<C-X><C-U>
			nmap <buffer> <Tab> ¶ea<C-R>"
			" Quick fix <Tab> should be one-shot
			" autocmd InsertLeave * ++once call textidote#unmapTab()
		else
			" call textidote#unmapTab()
		endif
	else
		call setpos('.', l:save_cursor)
	endif
endfunction

" The following two functions enable navigation of errors in original buffer
function! textidote#MoveForwardOrigBuffer()
	let s:cursorPosOrigBuffer = getpos('.')
	let l:test = 0
	let l:i = 1
	while l:test == 0
		if l:i <= len(s:errors)
			if get(get(s:errors,l:i-1,0),'toy',0) < get(s:cursorPosOrigBuffer,1,0)
				let l:test = 0
			else
				if get(get(s:errors,l:i-1,0),'toy',0) == get(s:cursorPosOrigBuffer,1,0) && get(get(s:errors,l:i-1,0),'tox',0) < get(s:cursorPosOrigBuffer,2,0)
					let l:test = 0
				else
					if get(get(s:errors,l:i-1,0),'toy',0) == get(s:cursorPosOrigBuffer,1,0) && get(get(s:errors,l:i-1,0),'fromx',0) <= get(s:cursorPosOrigBuffer,2,0)
						let l:test = 0
					else
						let l:test = 1
					endif
				endif
			endif
		else
			let l:test = 1
		endif
		let l:i += 1
	endwhile
	let l:indNextError = l:i - 1
	if l:indNextError > len(s:errors)
		let l:indNextError = 1
	endif
	drop [TeXtidote]
	call search('^Error:\s\+' . string(l:indNextError) . '/')
	normal! zt
	call <sid>JumpToCurrentError()
endfunction

function! textidote#MoveBackwardOrigBuffer()
	let s:cursorPosOrigBuffer = getpos('.')
	let l:test = 0
	let l:i = len(s:errors)
	while l:test == 0
		if l:i >= 1
			if get(get(s:errors,l:i-1,0),'fromy',0) > get(s:cursorPosOrigBuffer,1,0)
				let l:test = 0
			else
				if get(get(s:errors,l:i-1,0),'fromy',0) == get(s:cursorPosOrigBuffer,1,0) && get(get(s:errors,l:i-1,0),'fromx',0) > get(s:cursorPosOrigBuffer,2,0)
					let l:test = 0
				else
					if get(get(s:errors,l:i-1,0),'fromy',0) == get(s:cursorPosOrigBuffer,1,0) && get(get(s:errors,l:i-1,0),'tox',0) >= get(s:cursorPosOrigBuffer,2,0)
						let l:test = 0
					else
						let l:test = 1
					endif
				endif
			endif
		else
			let l:test = 1
		endif
		let l:i -= 1
	endwhile
	let l:indPrevError = l:i + 1
	if l:indPrevError < 1
		let l:indPrevError = len(s:errors)
	endif
	drop [TeXtidote]
	call search('^Error:\s\+' . string(l:indPrevError) . '/', 'b')
	normal! zt
	call <sid>JumpToCurrentError()
endfunction

function! textidote#QuickFix()
	let s:cursorPosOrigBuffer = getpos('.')
	let l:test = 0
	let l:i = 1
	while l:test == 0
		if l:i <= len(s:errors)
			if get(get(s:errors,l:i-1,0),'toy',0) < get(s:cursorPosOrigBuffer,1,0)
				let l:test = 0
			else
				if get(get(s:errors,l:i-1,0),'toy',0) == get(s:cursorPosOrigBuffer,1,0) && get(get(s:errors,l:i-1,0),'tox',0) < get(s:cursorPosOrigBuffer,2,0)
					let l:test = 0
				else
					if get(get(s:errors,l:i-1,0),'toy',0) == get(s:cursorPosOrigBuffer,1,0) && get(get(s:errors,l:i-1,0),'fromx',0) <= get(s:cursorPosOrigBuffer,2,0)
						let l:test = 0
					else
						let l:test = 1
					endif
				endif
			endif
		else
			let l:test = 1
		endif
		let l:i += 1
	endwhile
	let l:indNextError = l:i - 1
	let l:indCurrentError = l:indNextError - 1
	if l:indNextError > len(s:errors)
		let l:indNextError = 1
	endif
	if l:indCurrentError < 1
		let l:indCurrentError = len(s:errors)
	endif
	let l:test = 0
	if get(get(s:errors,l:indCurrentError-1,0),'toy',0) < get(s:cursorPosOrigBuffer,1,0) || get(get(s:errors,l:indCurrentError,0),'fromy',0) > get(s:cursorPosOrigBuffer,1,0)
		let l:test = 0
	else
		if get(get(s:errors,l:indCurrentError,0),'fromy',0) == get(s:cursorPosOrigBuffer,1,0) && get(get(s:errors,l:indCurrentError,0),'fromx',0) > get(s:cursorPosOrigBuffer,2,0)
			let l:test = 0
		else
			if get(get(s:errors,l:indCurrentError-1,0),'toy',0) == get(s:cursorPosOrigBuffer,1,0) && get(get(s:errors,l:indCurrentError,0),'tox',0) < get(s:cursorPosOrigBuffer,2,0)
				let l:test = 0
			else
				let l:text = 1
			endif
		endif
	endif
	echom 'indCurrentError: ' . l:indCurrentError
	echom 'Cursor: ' . get(s:cursorPosOrigBuffer,1,0) . ', ' . get(s:cursorPosOrigBuffer,2,0)
	echom 'StartError: ' . get(get(s:errors,l:indCurrentError,0),'fromy',0) . ', ' . get(get(s:errors,l:indCurrentError,0),'fromx',0)
	if l:test == 1
		" The cursor is on error l:indCurrentError
		drop [TeXtidote]
		call search('^Error:\s\+' . string(l:indCurrentError) . '/')
		normal! zt
		call <sid>JumpToCurrentError()
		let @" = "\<C-X>\<C-U>"
	else
		" The cursor is not on an error
		let s:cursorLineOrigBuffer = get(s:cursorPosOrigBuffer,1,0)
		let s:cursorColOrigBuffer = get(s:cursorPosOrigBuffer,2,0)
		let @" = "\<Esc>:call cursor(" . s:cursorLineOrigBuffer . "," . s:cursorColOrigBuffer . ")\<CR>lh"
	endif
endfunction

" The following two functions enable navigation of errors in scratch buffer
function! textidote#MoveForwardScratchBuffer()
	call search('^Error:\s\+')
	normal! zt
endfunction

function! textidote#MoveBackwardScratchBuffer()
	call search('^Error:\s\+', 'b')
	normal! zt
endfunction

" This function provides the completion with the suggestion list for the
" current error
function! textidote#Suggestions(findstart, base)
	if a:findstart
		return s:col
	else
		" let l:currentCol = col('.')
		let l:currentLine = line('.')
		if l:currentLine >= s:lineStart && l:currentLine <= s:lineEnd " && l:currentCol >= s:colStart && l:currentCol <= s:colEnd
			return s:suggestions_list
		else
			return []
		endif
	endif
endfunction

" This function restore <Tab> to its original mapping (if any).
function! textidote#unmapTab()
	let &completefunc = s:completefunc_orig
	if exists('s:mapTab_orig')
		execute 'nnoremap <buffer> <Tab> ' . s:mapTab_orig
	else
		silent!nunmap <buffer> <Tab>
	endif
endfunction

function textidote#Check(line1, line2) "{{{1
	if s:TeXtidoteSetUp() < 0
		return -1
	endif

	" Store full path of current file
	let s:current_file = expand('%:p')

	call textidote#Clear()

	echon 'Calling TeXtidote...'

	" Using window ID is more reliable than window number.
	let s:textidote_text_winid = win_getid()

	" Creating temporary files
	let s:tmp_filename = tempname()
	let s:tmp_output = tempname()
	let s:tmp_error    = tempname()

	let l:range = a:line1 . ',' . a:line2
	silent execute l:range . 'w!' . s:tmp_filename
	let s:line1 = a:line1
	let s:line2 = a:line2

	" Check if 'begin{document}' is in file, and otherwise set '--read-all' option
	if match(readfile(s:tmp_filename) , 'begin{document}')!=-1
		let l:option = ' --no-color --check '
	else
		let l:option = ' --no-color --read-all --check '
	endif 

	let l:textidote_cmd = exists('g:textidote_cmd')
	\ ? g:textidote_cmd
	\ : 'java -jar ' . s:textidote_jar

	let l:textidote_cmd_txt = l:textidote_cmd . l:option .
			\ s:textidote_lang . s:textidote_first_language_option .
			\ ' --encoding ' . s:textidote_encoding . s:textidote_dictionary_option .
			\ s:textidote_ignore_rules_option . s:textidote_ignore_environments_option .
			\ s:textidote_ignore_macros_option . s:textidote_replacements_option
	let s:textidote_cmd_txt_name = l:textidote_cmd_txt  . ' --output plain ' . s:current_file 
	let s:textidote_cmd_txt_complete = l:textidote_cmd_txt  . ' --output plain ' .
			\ s:tmp_filename . ' > ' . s:tmp_output . ' 2> ' . s:tmp_error

	" Handle the optional additional html report.
	if g:textidote_html_report == 1
		let s:tmp_output_html = tempname()
		let s:tmp_output_html = s:tmp_output_html . '.html'
		let s:tmp_error_html = tempname()
		let s:textidote_cmd_html = l:textidote_cmd_txt . ' --output html ' . s:tmp_filename .
			\ ' > ' . s:tmp_output_html . ' 2> ' . s:tmp_error_html
	endif

	" Start the TeXtidote calls asynchroneusly
	let s:textidote_output = ''
	if has('nvim')
		let s:callbacks = {
		  \ 'on_stdout': funcref('textidote#JobHandlerNVim'),
		  \ 'on_exit': funcref('textidote#JobHandlerNVim')
		  \ }
		let s:id = jobstart(s:textidote_cmd_txt_complete, s:callbacks )

		if g:textidote_html_report == 1
			let s:callbackshtml = {
			  \ 'on_stdout': funcref('textidote#JobHandlerHtmlNVim'),
			  \ 'on_exit': funcref('textidote#JobHandlerHtmlNVim')
			  \ }
			let s:idhtml = jobstart(s:textidote_cmd_html, s:callbackshtml )
		endif
	else
		" We are in regular Vim
		let s:callbacks = {
				\ 'out_io': 'file',
				\ 'out_name': s:tmp_output,
				\ 'err_io': 'file',
				\ 'err_name': s:tmp_error,
				\ 'exit_cb': funcref('textidote#JobHandlerVim')
		  \ }
		let s:id = job_start(s:textidote_cmd_txt_name, s:callbacks )

		if g:textidote_html_report == 1
			let s:textidote_cmd_html = l:textidote_cmd_txt . ' --output html ' . s:tmp_filename
			let s:callbackshtml = {
				\ 'out_io': 'file',
				\ 'out_name': s:tmp_output_html,
				\ 'err_io': 'file',
				\ 'err_name': s:tmp_error_html,
				\ 'exit_cb': funcref('textidote#JobHandlerHtmlVim')
				\ }
			let s:idhtml = job_start(s:textidote_cmd_html, s:callbackshtml )
		endif
	endif
endfunction

function! textidote#JobHandlerNVim(id, data, event) abort dict
	if a:event ==# 'stdout'
		return
	endif
	let s:textidote_exit = a:data
	let s:textidote_output_list = readfile(s:tmp_output)
	let s:textidote_output = join(s:textidote_output_list, "\n")
	call textidote#Display(s:textidote_output,s:textidote_exit)
endfunction

function! textidote#JobHandlerVim(job, status) abort
	let s:textidote_exit = a:status
	let s:textidote_output_list = readfile(s:tmp_output)
	let s:textidote_output = join(s:textidote_output_list, "\n")
	call textidote#Display(s:textidote_output,s:textidote_exit)
endfunction

function! textidote#JobHandlerHtmlNVim(id, data, event) abort dict
	if a:event ==# 'stdout'
		return
	endif
	let s:textidote_exit_html = a:data
	call textidote#Browser(s:textidote_exit_html)
endfunction

function! textidote#JobHandlerHtmlVim(job, status) abort
	let s:textidote_exit_html = a:status
	call textidote#Browser(s:textidote_exit_html)
endfunction

" This function highlights grammar mistakes in current buffer and opens
" a scratch window with all errors found.  It also populates the location-list
" of the window with all errors.
" s:line1 and s:line2 parameters are the first and last line number of
" the range of line to check.
function textidote#Display(data,code)
	if a:code == 255
		echoerr 'Command [' . s:textidote_cmd_txt_complete . '] failed with error: '
		\      . a:code
		if filereadable(s:tmp_error)
			echoerr string(readfile(s:tmp_error))
		endif
		call delete(s:tmp_error)
		call textidote#Clear()
		return -1
	endif
	call delete(s:tmp_error)

	execute 'drop ' . s:current_file
	botright new
	set modifiable
	let s:textidote_error_buffer = bufnr('%')
	silent execute 'put! =a:data'
	silent execute '%print'

	" The text report produced by TeXtidote is processed to match the format of
	" the XML report produced by LanguageTool so that large parts of the code of
	" vim-LanguageTool can be reused. 

	" Reformat last field to extract 'contextoffset' and 'errorlength'
	silent! %substitute/\v\C^( *)(\^+)$/\1,\2,trucdeouf/
	silent! %!awk -F"," '{ if ($3=="trucdeouf")  print "contextoffset=\""length($1)"\" errorlength=\""length($2)"\"/>"; else print $0 }'
	" Beginning of 'context' reformat. Adjust 'contextoffset' appropriately
	silent! %global/\m\Ccontextoffset/-1s/\m^/context=/
	silent! %global/\m\C^context=  /execute "normal! j^1\<C-A>"
	silent! %global/\m\C^context=  \t/execute "normal! j^2\<C-X>"
	silent! %substitute/\m\C^context=  \t/context=  /
	" Escape special characters
	silent! %vglobal/\m\C^contextoffset=/substitute/\V&/\&amp;/g
	silent! %vglobal/\m\C^contextoffset=/substitute/\m\t/\&#x9;/g
	silent! %vglobal/\m\C^contextoffset=/substitute/\V</\&lt;/g
	silent! %vglobal/\m\C^contextoffset=/substitute/\V>/\&gt;/g
	silent! %vglobal/\m\C^contextoffset=/substitute/\V'/\&apos;/g
	silent! %vglobal/\m\C^contextoffset=/substitute/\V"/\&quot;/g
	" Format start and end of each field
	silent! %substitute/\v\C\* L([0-9]*)C([0-9]*)-L([0-9]*)C([0-9]*) /\1,\2,<error fromy="\1" fromx="\2" toy="\3" tox="\4" msg="/
	" Finish context formatting
	silent! %substitute/\m\C^context=  \(.*\)/context="...\1..." /
	" Remove indenting spaces, join and sort
	silent! %substitute/\m\C^  //
	silent! %global/\m\C,<error fromy/ .,/\/>$/ join
	silent! %!sort -t, -k 1n,1 -k 2n,2 
	silent! %substitute/\m\C^[0-9]*,[0-9]*,<error/<error/
	" Final formatting
	silent! %substitute/\m\C. Suggestions: \[\([^]]*\)\]/" replacements="\1/
	silent! %substitute/\m\C\(([0-9]*)\|\.\) \(\[[^]]*\]\)/" ruleId="\2"/
	silent! %!cat

	" Loop on all errors in XML output and collect information about all errors
	" in list s:errors
	let s:errors = []
	while search('^<error ', 'eW') > 0
		let l:l = getline('.')
		" The fromx and tox given by LanguageTool are not reliable.
		" They are even sometimes negative!

		let l:error= {}
		for l:k in [ 'fromy', 'fromx', 'toy', 'tox',
		\           'msg', 'replacements', 'ruleId',
		\            'context', 'contextoffset', 'errorlength' ]
			let l:error[l:k] = s:ParseKeyValue(l:k, l:l)
		endfor

		let l:error['fromy'] += s:line1 - 1
		let l:error['toy']   += s:line1 - 1

		call add(s:errors, l:error)
	endwhile

	if s:textidote_win_height >= 0
		" Reformat the output (XML is not human friendly) and
		" set up syntax highlighting in the buffer which shows all errors.
		%d
		call append(0, '# ' . s:textidote_cmd_txt_name)
		set buftype=nofile
		setlocal nospell
		syn clear
		call matchadd('TeXtidoteCmd',        '\%1l.*')
		call matchadd('TeXtidoteErrorCount', '^Error:\s\+\d\+/\d\+')
		call matchadd('TeXtidoteLabel',      '^\(Context\|Message\|Correction\):')

		let l:i = 1
		for l:error in s:errors
			call append('$', 'Error:      '
			\ . l:i . '/' . len(s:errors)
			\ . ' '  . l:error['ruleId']
			\ . ' @ ' . l:error['fromy'] . 'L ' . l:error['fromx'] . 'C')
			call append('$', 'Message:    '     . l:error['msg'])
			call append('$', 'Context:    ' . l:error['context'])
			let l:re =
			\   '\%'  . line('$') . 'l\%9c'
			\ . '.\{' . (4 + l:error['contextoffset']) . '}\zs'
			\ . '.\{' .     (l:error['errorlength']) . '}'
			if l:error['ruleId'] =~# 'HUNSPELL_RULE\|HUNSPELL_NO_SUGGEST_RULE\|MORFOLOGIK_RULE_\|_SPELLING_RULE\|_SPELLER_RULE'
				call matchadd('TeXtidoteSpellingError', l:re)
			else
				call matchadd('TeXtidoteGrammarError', l:re)
			endif
			if !empty(l:error['replacements'])
				call append('$', 'Correction: ' . l:error['replacements'])
			endif
			call append('$', '')
			let l:i += 1
		endfor
		execute 'normal! z' . s:textidote_win_height . "\<CR>"
		0
		nnoremap <buffer><silent> <CR> :call <sid>JumpToCurrentError()<CR>
		nmap <buffer><silent><nowait> ] :call textidote#MoveForwardScratchBuffer()<CR>
		nmap <buffer><silent><nowait> [ :call textidote#MoveBackwardScratchBuffer()<CR>

		file [TeXtidote]
		setlocal scrolloff=1
		call search('^Error:\s\+')
		redraw
		echom 'Press <Enter> on error in [TeXtidote] buffer to jump its location'
		execute 'drop ' . s:current_file
	else
		" Negative s:textidote_win_height -> no scratch window.
		bdelete!
		unlet! s:textidote_error_buffer
	endif

	" Also highlight errors in original buffer and populate location list.
	setlocal errorformat=%f:%l:%c:%m
	for l:error in s:errors
		let l:re = s:TeXtidoteHighlightRegex(l:error['fromy'],
		\                                       l:error['context'],
		\                                       l:error['contextoffset'],
		\                                       l:error['errorlength'])
		if l:error['ruleId'] =~# 'HUNSPELL_RULE\|HUNSPELL_NO_SUGGEST_RULE\|MORFOLOGIK_RULE_\|_SPELLING_RULE\|_SPELLER_RULE'
			call matchadd('TeXtidoteSpellingError', l:re)
		else
			call matchadd('TeXtidoteGrammarError', l:re)
		endif
		laddexpr expand('%') . ':'
		\ . l:error['fromy'] . ':'  . l:error['fromx'] . ':'
		\ . l:error['ruleId'] . ' ' . l:error['msg']
	endfor

	redraw
	" Set move forward and backward mapping in original buffer
	nmap <buffer><nowait> ] :call textidote#MoveForwardOrigBuffer()<CR>
	nmap <buffer><nowait> [ :call textidote#MoveBackwardOrigBuffer()<CR>
	nmap <buffer><nowait> ¶ :call textidote#QuickFix()<CR>
	
	drop [TeXtidote]
	echom 'Press <Enter> on error in [TeXtidote] buffer to jump its location'

	call delete(s:tmp_filename)
	call delete(s:tmp_output)
	let g:textidote_indicator = 1
	return 0
endfunction

" This function open the optional htmpl report in the default browser 
function textidote#Browser(code)
	if a:code == 255
		echoerr 'Command [' . s:textidote_cmd_html . '] failed with error: '
		\      . a:code
		if filereadable(s:tmp_error_html)
			echoerr string(readfile(s:tmp_error_html))
		endif
		call delete(s:tmp_error_html)
		call textidote#Clear()
		return -1
	endif
	call delete(s:tmp_error_html)

	" Open html report in default browser
	sleep 1000m
	let l:start_default_browser_command = ''
	if has('win32') || has('win64')
		let l:start_default_browser_command = '!start '
	elseif has('win32unix')
		let l:start_default_browser_command = '!cygstart '
	else
		if has('unix')
			let s:uname = system('uname')
			if s:uname =~# 'Darwin'
				let l:start_default_browser_command = '!open '
			else
				let l:start_default_browser_command = '!xdg-open '
			endif
		endif
	endif
	silent execute l:start_default_browser_command . 'file://' . s:tmp_output_html
	sleep 8000m
	call delete(s:tmp_output_html)
endfunction

" This function clears syntax highlighting created by TeXtidote plugin
" and removes the scratch window containing grammar errors.
function textidote#Clear() "{{{1
	if exists('s:textidote_error_buffer')
		if bufexists(s:textidote_error_buffer)
			silent! execute 'bdelete! ' . s:textidote_error_buffer
		endif
	endif
	if exists('s:textidote_text_winid')
		let l:win = winnr()
		" Using window ID is more reliable than window number.
		call win_gotoid(s:textidote_text_winid)
		call setmatches(filter(getmatches(), 'v:val["group"] !~# "TeXtidote.*Error"'))
		lexpr ''
		lclose
		execute l:win . ' wincmd w'
	endif
	unlet! s:textidote_error_buffer
	unlet! s:textidote_text_winid

	execute 'drop' s:current_file
	let &completefunc = s:completefunc_orig
	if exists('s:mapTab_orig')
		execute 'nnoremap <buffer> <Tab> ' . s:mapTab_orig
	else
		silent!nunmap <buffer> <Tab>
	endif
	if exists('s:mapForward_orig')
		execute 'nnoremap <buffer> ] ' . s:mapForward_orig
	else
		silent!nunmap <buffer> ]
	endif
	if exists('s:mapBackward_orig')
		execute 'nnoremap <buffer> [ ' . s:mapBackward_orig
	else
		silent!nunmap <buffer> [
	endif
	if exists('s:mapAux_orig')
		execute 'nnoremap <buffer> ¶' . s:mapAux_orig
	else
		silent!nunmap <buffer> ¶
	endif

	let g:textidote_indicator = 0
endfunction

function textidote#Toggle(line1, line2) "{{{1
	if g:textidote_indicator
		call textidote#Clear()
	else
		call textidote#Check(a:line1,a:line2)
	endif
endfunction
