" Description: Spellcheck with either Antidote.app or TeXtidote from Vim
" Author: Patrick Ballard <patrick.ballard.paris@gmail.com>
" License: MIT


function! textidote#CommandTeXtidote(line_start, line_end)
	if &modified == 1
		echo "Buffer has unsaved changes. Please, save before spellchecking!"
		return
	endif
	" first make the name of the tempfile (keeping the extension of the original file to inform Antidote)
	let currentDir = expand('%:p:h')
	let currentExt = expand('%:e')
	if currentExt != ''
		let currentExt = "." .  currentExt
	endif	  
	let tempName = currentDir . "/tempfile" .  currentExt
	let tempNameBis = currentDir . "/tempfileBis.html"
	" load selection in a list of lines
	let lines = getline(a:line_start, a:line_end)
	if len(lines) == 0
		echo "Houston, we have a problem which should not exist!"
		return
	endif
	" counting the number of trailing newlines in the selection
	let trailingNewline = 0
	while trailingNewline < len(lines) && len(lines[-1-trailingNewline]) == 0
		let trailingNewline += 1
	endwhile
	if len(lines) == trailingNewline 
		echo "Please, spellcheck something!"
		return
	endif
	" writing selection in temporary file
	call writefile(lines, tempName, 'b')
	if &spelllang == "en"
		exe '!java -jar ' . g:textidote_application . ' --check en --firstlang fr --output html > ' . tempNameBis . ' "%:p"'
	elseif &spelllang == "fr"
		exe '!java -jar ' . g:textidote_application . ' --check fr --output html > ' . tempNameBis . ' "%:p"'
	else
		exe '!java -jar ' . g:textidote_application . ' --check ' . &spelllang . ' --firstlang fr --output html > ' . tempNameBis . ' "%:p"'
	endif
	exe '!sleep 1'
	exe '!open -a ' . g:defaultBrowser . ' ' . tempNameBis
	exe '!sleep 1'
	exe "silent !rm " . tempName
	exe "silent !rm " . tempNameBis
endfunction

function! textidote#NormalTeXtidote()
	if &modified == 1
		echo "Buffer has unsaved changes. Please, save before spellcheck!"
		return
	endif
	let currentDir = expand('%:p:h')
	let tempNameBis = currentDir . "/tempfileBis.html"
	execute '!java -jar ' . g:textidote_application . ' --check ' . &spelllang . g:textidote_first_language_option . ' --output html > ' . tempNameBis . ' ' . tempName
	execute 'silent !sleep 1'
	exe 'silent !sleep 1'
	" This python script open the html report in a new tab in the default browser
	python3 << EOL
import vim
import webbrowser
url = 'file://' + vim.eval('tempNameBis')
webbrowser.open_new_tab(url)
EOL
	" exe '!open -a ' . g:defaultBrowser . ' ' . tempNameBis
	exe 'silent !sleep 10'
	exe "silent !rm " . tempNameBis
endfunction

function! textidote#VisualTeXtidote()
	if &modified == 1
		echo "Buffer has unsaved changes. Please, save before spellchecking!"
		return
	endif
	" first make the name of the tempfile (keeping the extension of the original file to inform Antidote)
	let currentDir = expand('%:p:h')
	let currentExt = expand('%:e')
	if currentExt != ''
		let currentExt = "." .  currentExt
	endif	  
	let tempName = currentDir . "/tempfile" .  currentExt
	let tempNameBis = currentDir . "/tempfileBis.html"
	" load selection in a list of lines
	let [line_start, column_start] = getpos("'<")[1:2]
	let [line_end, column_end] = getpos("'>")[1:2]
	let lines = getline(line_start, line_end)
	if len(lines) == 0
		echo "Houston, we have a problem which should not exist!"
		return
	endif
	" counting the number of trailing newlines in the selection
	let trailingNewline = 0
	while trailingNewline < len(lines) && len(lines[-1-trailingNewline]) == 0
		let trailingNewline += 1
	endwhile
	if len(lines) == trailingNewline 
		echo "Please, spellcheck something!"
		return
	endif
	" writing selection in temporary file
	let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
	let lines[0] = lines[0][column_start - 1:]
	call writefile(lines, tempName, 'b')
	execute '!java -jar ' . g:textidote_application . ' --check ' . &spelllang . g:textidote_first_language_option . ' --output html > ' . tempNameBis . ' ' . tempName
	execute 'silent !sleep 1'
	" This python script open the html report in a new tab in the default browser
	python3 << EOL
import vim
import webbrowser
url = 'file://' + vim.eval('tempNameBis')
webbrowser.open_new_tab(url)
EOL
	" exe '!open -a ' . g:defaultBrowser . ' ' . tempNameBis
	execute 'silent !sleep 10'
	execute "silent !rm " . tempName
	execute "silent !rm " . tempNameBis
endfunction
