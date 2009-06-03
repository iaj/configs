"|fld   description : shows a list with matching files glob: **yourtext*
"|fld   keywords : open file 
"|fld   initial author : Marc Weber
"|fld   mantainer : author
"|fld   started on : 2007 Nov 22 22:19:42
"|fld   version: 0.0
"|
"|H1__  Documentation


let g:globMatchFilters = ['v:val !~ '.string('\.o$\|\.hi$\|\.svn'),'!isdirectory(v:val)']

function! vl#ui#openFileFromList#FileByGlobCurrentDir(glob, ...)
  exec vl#lib#brief#args#GetOptionalArg('caption', string('Choose a file'))
  let files = split(glob('**/*'.a:glob.'*'),"\n")

  for nom in g:globMatchFilters
    echo nom
    call filter(files,nom)
  endfor

  " TODO! 
  if len(files) > 20
    echoe "more than 20 files - would be to slow. Open the file in another way"
  else
    call filter(files, 'v:val !~ "_darcs" ')
    return vl#ui#userSelection#LetUserSelectIfThereIsAChoice(
      \ caption, files)
  endif
endfunction

function! vl#ui#openFileFromList#UI()
  Noremap <m-g><m-o> :exec 'e '.vl#ui#openFileFromList#FileByGlobCurrentDir(input('glob open '))<cr>
endfunction
