" The text report produced by TeXtidote is processed to match the format of
" the XML report produced by LanguageTool so that large parts of the code of
" vim-LanguageTool can be reused. 

" Reformat last field to extract 'contextoffset' and 'errorlength'
%print
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
write /dev/stdout
quit'
