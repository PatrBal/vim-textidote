" Description: Grammar checker with TeXtidote from Vim
" Author:      Patrick Ballard <patrick.ballard.paris@gmail.com>
" Last Change: 05/01/2022


" Guess language from 'a:lang' (either 'spelllang' or 'v:lang')
function s:FindLanguage(lang) "{{{1
  " This replaces things like en-gb en_GB as expected by TeXtidote,
  " only for languages that support variants in TeXtidote.
  let l:language = substitute(substitute(a:lang,
  \  '\(\a\{2,3}\)\(_\a\a\)\?.*',
  \  '\=tolower(submatch(1)) . toupper(submatch(2))', ''),
  \  '-', '_', '')

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
  let s:textidote_dictionary = exists("g:textidote_dictionary")
  \ ? g:textidote_dictionary : ''
  let s:textidote_ignore_rules = exists("g:textidote_ignore_rules")
  \ ? g:textidote_ignore_rules : ''
  let s:textidote_ignore_environments = exists("g:textidote_ignore_environments")
  \ ? g:textidote_ignore_environments : ''
  let s:textidote_ignore_macros = exists("g:textidote_ignore_macros")
  \ ? g:textidote_ignore_macros : ''
  let s:textidote_win_height = exists("g:textidote_win_height")
  \ ? g:textidote_win_height
  \ : 14
  let s:textidote_encoding = &fenc ? &fenc : &enc

  if s:textidote_dictionary == ''
	let s:textidote_dictionary_option = ''
  else
	let s:textidote_dictionary_option = ' --dict ' . s:textidote_dictionary
  endif
  if s:textidote_ignore_rules == ''
	let s:textidote_ignore_rules_option = ''
  else
	let s:textidote_ignore_rules_option = ' --ignore ' . s:textidote_ignore_rules
  endif
  if s:textidote_ignore_environments == ''
	let s:textidote_ignore_environments_option = ''
  else
	let s:textidote_ignore_environments_option = ' --remove ' . s:textidote_ignore_environments
  endif
  if s:textidote_ignore_macros == ''
	let s:textidote_ignore_macros_option = ''
  else
	let s:textidote_ignore_macros_option = ' --remove-macros ' . s:textidote_ignore_macros
  endif

  " Setting up language...
  if exists("g:textidote_lang")
    let s:textidote_lang = g:textidote_lang
  else
    " Trying to guess language from 'spelllang' or 'v:lang'.
    let s:textidote_lang = s:FindLanguage(&spelllang)
    if s:textidote_lang == ''
      let s:textidote_lang = s:FindLanguage(v:lang)
      if s:textidote_lang == ''
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
  if g:textidote_first_language == ''
	let s:textidote_first_language_option = ''
  else
	let s:textidote_first_language_option = ' --firstlang ' . g:textidote_first_language
  endif

  let s:textidote_jar = exists("g:textidote_jar")
  \ ? g:textidote_jar
  \ : $HOME . '/.vim/textidote.jar'

  if !exists("g:textidote_cmd") && !filereadable(s:textidote_jar)
    " Hmmm, can't find the jar file.  Try again with expand() in case user
    " set it up as: let g:textidote_jar = '$HOME/.vim/textidote.jar'
    let l:textidote_jar = expand(s:textidote_jar)
    if !filereadable(expand(l:textidote_jar))
      echomsg "TeXtidote cannot be found at: " . s:textidote_jar
      echomsg "You need to install TeXtidote and/or set up g:textidote_jar"
      echomsg "to indicate the location of the textidote.jar file."
      return -1
    endif
    let s:textidote_jar = l:textidote_jar
  endif
  return 0
endfunction

" Jump to a grammar mistake (called when pressing <Enter>
" on a particular error in scratch buffer).
function <sid>JumpToCurrentError() "{{{1
  let l:save_cursor = getpos('.')
  norm! $
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
      exe s:textidote_text_winid . ' wincmd w'
    endif
    exe 'normal! ' . l:line . 'G0'
    if l:col > 0
      execute 'normal! ' . (l:col  - 1) . 'l'
    endif

    echon 'Jump to error ' . l:error_idx . '/' . len(s:errors)
    \ . ' ' . l:rule . ' @ ' . l:line . 'L ' . l:col . 'C'
    normal! zz
  else
    call setpos('.', l:save_cursor)
  endif
endfunction

" This function performs grammar checking of text in the current buffer.
" It highlights grammar mistakes in current buffer and opens a scratch
" window with all errors found.  It also populates the location-list of
" the window with all errors.
" a:line1 and a:line2 parameters are the first and last line number of
" the range of line to check.
" Returns 0 if success, < 0 in case of error.
function textidote#Check(line1, line2) "{{{1
  if s:TeXtidoteSetUp() < 0
    return -1
  endif
  call textidote#Clear()

  echon 'Thinking...'

  " Using window ID is more reliable than window number.
  " But win_getid() does not exist in old version of Vim.
  let s:textidote_text_winid = exists('*win_getid')
  \                             ? win_getid() : winnr()
  sil %y
  botright new
  set modifiable
  let s:textidote_error_buffer = bufnr('%')
  sil put!

  " TeXtidote/LanguageTool somehow gives incorrect line/column numbers when
  " reading from stdin so we need to use a temporary file to get
  " correct results.
  let l:tmpfilename = tempname()
  let l:tmperror    = tempname()

  let l:range = a:line1 . ',' . a:line2
  silent execute l:range . 'w!' . l:tmpfilename

  " Check if 'begin{document}' is in file, and otherwise set '--read-all' option
  if match(readfile(l:tmpfilename) , "begin{document}")!=-1
	  let l:option = ' --check '
  else
	  let l:option = ' --read-all --check '
  endif 

  let l:textidote_cmd = exists("g:textidote_cmd")
  \ ? g:textidote_cmd
  \ : 'java -jar ' . s:textidote_jar

  let l:textidote_cmd_txt = l:textidote_cmd . l:option . s:textidote_lang . s:textidote_first_language_option . ' --encoding ' . s:textidote_encoding . s:textidote_ignore_rules_option . s:textidote_ignore_environments_option . s:textidote_ignore_macros_option . ' --output plain ' . l:tmpfilename . ' 2> ' . l:tmperror
  silent execute '%!' . l:textidote_cmd_txt

  if v:shell_error && v:shell_error != 102 && v:shell_error != 13 && v:shell_error != 72
    echoerr 'Command [' . l:textidote_cmd_txt . '] failed with error: '
    \      . v:shell_error
    if filereadable(l:tmperror)
      echoerr string(readfile(l:tmperror))
    endif
    call delete(l:tmperror)
    call textidote#Clear()
    return -1
  endif
  call delete(l:tmperror)

  " The text report produced by TeXtidote is processed to match the format of
  " the XML report produced by LanguageTool

  " Filter RichTextFormat markup
  silent! %!sed -r "s/\x1B\[(([0-9]{1,2})?(;)?([0-9]{1,2})?)?[m,K,H,f,J]//g"
  " Reformat last field to extract 'contextoffset' and 'errorlength'
  silent! %substitute/\v\C^( *)(\^+)$/\1,\2,trucdeouf/
  silent! %!awk -F"," '{ if ($3=="trucdeouf")  print "contextoffset=\""length($1)"\" errorlength=\""length($2)"\"/>"; else print $0 }'
  " Beginning of 'context' reformat. Adjust 'contextoffset' appropriately
  silent! %global/\m\Ccontextoffset/-1s/\m^/context=/
  silent! %global/\m\C^context=  /execute "normal j^1\<C-A>"
  silent! %global/\m\C^context=  \t/execute "normal j^2\<C-X>"
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

  " Loop on all errors in XML output of LanguageTool and
  " collect information about all errors in list s:errors
  let s:errors = []
  while search('^<error ', 'eW') > 0
    let l:l = getline('.')
    " The fromx and tox given by LanguageTool are not reliable.
    " They are even sometimes negative!

    let l:error= {}
    for l:k in [ 'fromy', 'fromx', 'toy', 'tox',
    \            'msg', 'replacements', 'ruleId',
    \            'context', 'contextoffset', 'errorlength' ]
      let l:error[l:k] = s:ParseKeyValue(l:k, l:l)
    endfor

    let l:error['fromy'] += a:line1 - 1
    let l:error['toy']   += a:line1 - 1

    call add(s:errors, l:error)
  endwhile

  if s:textidote_win_height >= 0
    " Reformat the output of LanguageTool (XML is not human friendly) and
    " set up syntax highlighting in the buffer which shows all errors.
    %d
    call append(0, '# ' . l:textidote_cmd_txt)
    set bt=nofile
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
        call matchadd('LanguageToolSpellingError', l:re)
      else
        call matchadd('LanguageToolGrammarError', l:re)
      endif
      if !empty(l:error['replacements'])
        call append('$', 'Correction: ' . l:error['replacements'])
      endif
      call append('$', '')
      let l:i += 1
    endfor
    exe "norm! z" . s:textidote_win_height . "\<CR>"
    0
    map <silent> <buffer> <CR> :call <sid>JumpToCurrentError()<CR>
    redraw
    echom 'Press <Enter> on error in scratch buffer to jump its location'
    execute "normal! \<C-W>\<C-P>"
  else
    " Negative s:textidote_win_height -> no scratch window.
    bd!
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

  echon 'Press <Enter> on error in scratch buffer to jump its location'
  
  " Handle the optional additional html report.
  if g:textidote_html_report == 1
    let l:tmphtml = tempname()
	let l:tmphtml = l:tmphtml . '.html'
    let l:textidote_cmd_html = l:textidote_cmd . l:option . s:textidote_lang . s:textidote_first_language_option . ' --encoding ' . s:textidote_encoding . s:textidote_ignore_rules_option . s:textidote_ignore_environments_option . s:textidote_ignore_macros_option . ' --output html ' . l:tmpfilename . ' > ' . l:tmphtml . ' 2> ' . l:tmperror
	silent execute '!' . l:textidote_cmd_html

	if v:shell_error && v:shell_error != 102 && v:shell_error != 13 && v:shell_error != 72
      echoerr 'Command [' . l:textidote_cmd_html . '] failed with error: '
      \      . v:shell_error
      if filereadable(l:tmperror)
        echoerr string(readfile(l:tmperror))
      endif
      call delete(l:tmperror)
      call textidote#Clear()
      return -1
    endif
    call delete(l:tmperror)
    
	sleep 1000m
	silent execute '!open ' . 'file://' . l:tmphtml
	sleep 8000m
	call delete(l:tmphtml)
  endif

  call delete(l:tmpfilename)
  let g:textidote_indicator = 1
  return 0
endfunction

" This function clears syntax highlighting created by TeXtidote plugin
" and removes the scratch window containing grammar errors.
function textidote#Clear() "{{{1
  if exists('s:textidote_error_buffer')
    if bufexists(s:textidote_error_buffer)
      sil! exe "bd! " . s:textidote_error_buffer
    endif
  endif
  if exists('s:textidote_text_winid')
    let l:win = winnr()
    " Using window ID is more reliable than window number.
    " But win_getid() does not exist in old version of Vim.
    if exists('*win_gotoid')
      call win_gotoid(s:textidote_text_winid)
    else
      exe s:textidote_text_winid . ' wincmd w'
    endif
    call setmatches(filter(getmatches(), 'v:val["group"] !~# "TeXtidote.*Error"'))
    lexpr ''
    lclose
    exe l:win . ' wincmd w'
  endif
  unlet! s:textidote_error_buffer
  unlet! s:textidote_text_winid
  let g:textidote_indicator = 0
endfunction

function textidote#Toggle(line1, line2) "{{{1
  if g:textidote_indicator
	call textidote#Clear()
  else
	call textidote#Check(a:line1,a:line2)
  endif
endfunction
