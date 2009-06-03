" script-purpose: provide some useful file functions I did need yet
" author: Marc Weber

" can't use load setting here here (would be  recursive as ReadFile is defined here)
let s:wine_root='z:/'
" returns the directory which contains this folder/ file
" expand('%:p:h') doesn't work here
fun! vl#lib#files#filefunctions#FileDir(file)
  "return substitute(a:file,'\%(/\|\\\)[^/\\]*$','','')
  return matchstr(a:file, '^\zs.*\ze[/\\]' )
endfun

" returns the name of this file
fun! vl#lib#files#filefunctions#FileName(file)
  return substitute(a:file,'.*\%(/\|\\\)','','')
endfun

fun! vl#lib#files#filefunctions#RelativeFileComponent(dir, file)
  return substitute(a:file, '^'.expand(a:dir).'\%(/\|\\\)\=','','')
endfun

function! vl#lib#files#filefunctions#PathAbsolute(p)
  return strpart(a:p,0,1) == "/" || a:p =~ '[a-zA-Z]:\\'
endfunction

fun! vl#lib#files#filefunctions#JoinPaths(a,b)
  if vl#lib#files#filefunctions#PathAbsolute(a:b)
    return a:b
  elseif a:a==''
    return a:b
  else
    return substitute(a:a,'[/\\]$','','').'/'.substitute(a:b,'^[/\\]','','')
  endif
  "let a = copy(a:000)
  "call map(a, "substitute(v:val,'\%(^[/\\]\)\|\%([/\\]$\)','','g')")
  "return join(a,'/')
endfun

" returns 1 if directory has been created
fun! vl#lib#files#filefunctions#EnsureDirectoryExists(dir)
  let d = expand(a:dir)
  if !isdirectory(d)
    call mkdir(d,'p')
    return 1
  endif
  return 0
endfun

"|func replaces non word characters with _. Thus the os should accept this as
"|     filename
fun! vl#lib#files#filefunctions#FileHashValue(file)
  "return substitute(a:file,'\.\|#\|''\|(\|)\|/\|\\\|{\|}\|\$\|:','_','g')
  return substitute(a:file,'\W','_','g')
endfun

" expands filename and supports a default value in case file doesn't exist
function! vl#lib#files#filefunctions#ReadFile(filename, default)
  let  fn = expand(a:filename)
  if filereadable(fn)
    return readfile(fn)
  else
    return a:default
  endif
endfunction

" expands filename and ensures that the directory is created
function! vl#lib#files#filefunctions#WriteFile(list, filename)
  let  fn = expand(a:filename)
  let fd = vl#lib#files#filefunctions#FileDir(fn)
  call vl#lib#files#filefunctions#EnsureDirectoryExists(fd)
  call writefile(a:list,fn)
endfunction

"|func This implementation only works on unix by now
function! vl#lib#files#filefunctions#RemoveDirectoryRecursively(directory)
  if !has('unix')
    echo "Please remove ".a:directory." manually:"
    echoe "vl#lib#files#filefunctions#RemoveDirectoryRecursively() has to be implemented for none unix vim versions"
  else
    call system("rm -fr ".expand(a:directory))
  endif
endfunction

"| add trailing / or \ on windows if not present
function! vl#lib#files#filefunctions#AddTrailingDelimiter(path)
  return substitute(a:path,'[^/\\]\zs\ze$',expand('/'),'')
endfunction

"| if you pass dir a/b/c ["a/b/c","a/b","a"] will be returned
function! vl#lib#files#filefunctions#WalkUp(path)
  let sep='\zs.*\ze[/\\].*'
  let result = [a:path]
  let path = a:path
  while 1
    let path=matchstr(path, sep)
    if path==""
      break
    endif
    call add(result, path)
  endwhile
  return result
endfunction

"func usage: WalkUpAndFind("mydir","tags")
"let tags=vl#lib#files#filefunctions#WalkUpAndFind(a:path,"glob(vl#lib#files#filefunctions#JoinPaths(path,'tags'))",1)
" consider using findfile of vim
" optional arg: 1 : continue even if a file was found
" "all" to return all visited pathes as well
function! vl#lib#files#filefunctions#WalkUpAndFind(path,f_as_text,...)
  exec vl#lib#brief#args#GetOptionalArg("option",string(0))
  let matches = []
  for path in vl#lib#files#filefunctions#WalkUp(a:path)
    exec 'let item = '.a:f_as_text
    if (len(item) >0 )
      call add(matches, item)
      if option == 0
	break
      endif
    elseif option == "all" && type(option) == type("all")
      call add(matches, path)
    endif
  endfor
  if option == "all"
    return matches
  else
    if len(matches) > 0 
      if option == 1
        return matches
      else
        return matches[0]
      endif
    else
      return []
    endif
  endif
endfunction

function! vl#lib#files#filefunctions#PathToWine(path)
  if has('unix')
    return s:wine_root.substitute(a:path,'^[/\\]','','')
  else
    return a:path
  endif
endfunction
