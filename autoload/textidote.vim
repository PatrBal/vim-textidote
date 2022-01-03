" Description: Spellcheck with either Antidote.app or TeXtidote from Vim
" Author: Patrick Ballard <patrick.ballard.paris@gmail.com>
" License: MIT


function! antidote#VisualAntidote()
	if &modified == 1
		echo "Buffer has unsaved changes. Please, save before spellchecking!"
		return
	endif
	" first make the name of the tempfile (keeping the extension of the original file to inform Antidote)
	let currentDir = expand('%:p:h')
	let currentExt = expand('%:e')
	if currentExt != ''
		let currentExt = "." . currentExt
	endif	  
	let tempName = currentDir . "/tempfile" . currentExt
	" load selection in a list of lines
	let [line_start, column_start] = getpos("'<")[1:2]
	let [line_end, column_end] = getpos("'>")[1:2]
	let lines = getline(line_start, line_end)
	if len(lines) == 0
		echo "Houston, we have a problem which should not exist!"
		return
	endif
	" Total number of lines
	let totalLines = line('$')
	" counting the number of trailing newlines in the selection
	let trailingNewline = 0
	while trailingNewline < len(lines) && len(lines[-1-trailingNewline]) == 0
		let trailingNewline += 1
	endwhile
	if len(lines) == trailingNewline 
		echo "Please, spellcheck something!"
		return
	endif
	if len(lines[-1] ) < column_end || trailingNewline > 0
		let trailingNewline += 1
	endif
	let trailingNewline -= 1
	" does the last character of selection precede newline?
	if len(lines[-1] ) < column_end + 1
		let lastChar = "true"
	else
		let lastChar = "false"
	endif
	" writing selection in temporary file
	let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
	let lines[0] = lines[0][column_start - 1:]
	call writefile(lines, tempName, 'b')
	" Reselect the original selection
	exe "cal cursor( " . line_start . " , " .  column_start . ")"
	normal v
	exe "cal cursor( " . line_end . " , " .  column_end . ")"
	" start Antidote and start corrector
	call system("osascript -e \'tell application \"" . g:antidote_antidote_application . "\" to quit\' ;
					\ sleep 1 ;
					\ open -a \"" . g:antidote_antidote_application . "\" " . tempName . " ; 
					\ sleep 2 ;
					\ osascript -e \'tell application \"System Events\"\' 
					\ 			-e \'keystroke (ASCII character 29)\' 
					\ 			-e \'keystroke \"k\" using command down\' 
					\ 			-e \'delay 1\' 
					\ 			-e \'keystroke \"k\" using command down\' 
					\ 			-e \'end tell\'")
	echo "Type <Enter> to apply spellcheck, and anything else to discard it: "
	let char = getchar()
	if nr2char(char) ==# ''
		" paste the corrected text in the original selection. Special attention must be paid to the boundaries. 
		" paste corrected text in to register x
		exe 'let @x = join(readfile("' . tempName . '"), "\n")'
		if trailingNewline >= 0
			let @x = @x . "\n"
			if trailingNewline >= 1
				let @x = @x . "\n"
			endif
		endif
		" paste register x into  the buffer. Different scenarii for the boundaries must be considered
		if trailingNewline < 0 
			normal! d
			normal! "xP
		else
			if column_start <= 1
				normal! d
				normal! "xP
			else
				normal! "xpkgJ
			endif
		endif
		" If corrected text reaches the end of file, then delete added blank line
		if lastChar == "true" && totalLines == line_end
			normal! Gdd
		endif
		exe "silent !rm " . tempName
		exe "cal cursor( " . line_end . " , " .  column_end . ")"
		redraw!
		echom "Spellchek applied successfully!"
		return 
	else
		" discard corrected text
		exe "normal! \<Esc>"
		exe "silent !rm " . tempName
		redraw!
		echom "Spellchek discarded!"
		return
	endif	
endfunction

function! antidote#NormalAntidote()
	if &modified == 1
		echo "Buffer has unsaved changes. Please, save before spellcheck!"
		return
	endif
	let currentDir = expand('%:p:h')
	let currentExt = expand('%:e')
	if currentExt != ''
		let currentExt = "." . currentExt
	endif	  
	let tempName = currentDir . "/tempfile" . currentExt
	exe "silent w " . tempName
	call system("osascript -e \'tell application \"" . g:antidote_antidote_application . "\" to quit\' ;
					\ sleep 1 ;
					\ open -a \"" . g:antidote_antidote_application . "\" " . tempName . " ; 
					\ sleep 2 ;
					\ osascript -e \'tell application \"System Events\"\' 
					\ 			-e \'keystroke (ASCII character 29)\' 
					\ 			-e \'keystroke \"k\" using command down\' 
					\ 			-e \'delay 1\' 
					\ 			-e \'keystroke \"k\" using command down\' 
					\ 			-e \'end tell\'")
	echo "Type <Enter> to apply spellcheck, and anything else to discard it: "
	let char = getchar()
	if nr2char(char) == ""
		exe "silent %d|0r " . tempName
		silent $d
		exe "silent !rm " . tempName
		redraw!
		echom "Spellchek successfully applied!"
		return
	else
		exe "silent !rm " . tempName
		redraw!
		echom "Spellchek discarded!"
		return
	endif
endfunction

function! antidote#CommandAntidote(line_start, line_end)
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
	" load selection in a list of lines
	let lines = getline(a:line_start, a:line_end)
	if len(lines) == 0
		echo "Houston, we have a problem which should not exist!"
		return
	endif
	" Total number of lines
	let totalLines = line('$')
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
	" Reselect the original selection
	exe "cal cursor( " . a:line_start . " , " . "1 )"
	normal! V
	exe "cal cursor( " . a:line_end . " , " . "1 )"
	" start Antidote and start corrector
	call system("osascript -e \'tell application \"" . g:antidote_antidote_application . "\" to quit\' ;
					\ sleep 1 ;
					\ open -a \"" . g:antidote_antidote_application . "\" " . tempName . " ; 
					\ sleep 2 ;
					\ osascript -e \'tell application \"System Events\"\' 
					\ 			-e \'keystroke (ASCII character 29)\' 
					\ 			-e \'keystroke \"k\" using command down\' 
					\ 			-e \'delay 1\' 
					\ 			-e \'keystroke \"k\" using command down\' 
					\ 			-e \'end tell\'")
	echo "Type <Enter> to apply spellcheck, and anything else to discard it: "
	let char = getchar()
	if nr2char(char) == ""
		" paste the corrected text in the original selection. Special attention must be paid to the boundaries. 
		" paste corrected text in to register x
		exe 'let @x = join(readfile("' . tempName . '"), "\n")'
		if trailingNewline >= 0
			let @x = @x . "\n"
			if trailingNewline >= 1
				let @x = @x . "\n"
			endif
		endif
		" paste register x into  the buffer. Different scenarii for the boundaries must be considered
		normal! d
		normal! "xP
		" If corrected text reaches the end of file, then delete added blank line
		if totalLines == a:line_end
			normal! Gdd
		endif
		exe "silent !rm " . tempName
		exe "cal cursor( " . a:line_end . " , 1 )"
		redraw!
		echom "Spellchek applied successfully!"
		return 
	else
		" discard corrected text
		exe "normal! \<Esc>"
		exe "silent !rm " . tempName
		exe "cal cursor( " . a:line_end . " , 1 )"
		redraw!
		echom "Spellchek discarded!"
		return
	endif	
endfunction


function! antidote#CommandTeXtidote(line_start, line_end)
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
		exe '!java -jar ' . g:antidote_textidote_application . ' --check en --firstlang fr --output html > ' . tempNameBis . ' ' . tempName
	elseif &spelllang == "fr"
		exe '!java -jar ' . g:antidote_textidote_application . ' --check fr --output html > ' . tempNameBis . ' ' . tempName
	else
		exe '!java -jar ' . g:antidote_textidote_application . ' --check ' . &spelllang . ' --firstlang fr --output html > ' . tempNameBis . ' ' . tempName
	endif
	exe '!sleep 1'
	exe '!open -a ' . g:defaultBrowser . ' ' . tempNameBis
	exe '!sleep 1'
	exe "silent !rm " . tempName
	exe "silent !rm " . tempNameBis
endfunction

function! antidote#NormalTeXtidote()
	if &modified == 1
		echo "Buffer has unsaved changes. Please, save before spellcheck!"
		return
	endif
	let currentDir = expand('%:p:h')
	let tempNameBis = currentDir . "/tempfileBis.html"
	if &spelllang == "en"
		exe '!java -jar ' . g:antidote_textidote_application . ' --check en --firstlang fr --output html > ' . tempNameBis . ' "%:p"'
	elseif &spelllang == "fr"
		exe '!java -jar ' . g:antidote_textidote_application . ' --check fr --output html > ' . tempNameBis . ' "%:p"'
	else
		exe '!java -jar ' . g:antidote_textidote_application . ' --check ' . &spelllang . ' --firstlang fr --output html > ' . tempNameBis . ' "%:p"'
	endif
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

function! antidote#VisualTeXtidote()
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
	exe '!java -jar ' . g:antidote_textidote_application . ' --check ' . &spelllang . g:antidote_textidote_first_language_option . ' --output html > ' . tempNameBis . ' ' . tempName
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
	exe "silent !rm " . tempName
	exe "silent !rm " . tempNameBis
endfunction
