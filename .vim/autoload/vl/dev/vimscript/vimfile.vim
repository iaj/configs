"|fld   description : scan a vim file and provide some information (currently only which functions are defined), fix autload functions, user function completion
"|fld   keywords : autoload 
"|fld   initial author : Marc Weber marco-oweber@gmx.de
"|fld   mantainer : author
"|fld   started on : Sun Sep 17 19:20:01 CEST 2006
"|fld   version: 0.3
"|fld   dependencies: vl.vim plugin becauso of s:vl_regex settings
"|fld   contributors : <+credits to+>
"|fld   tested on os : linux
"|fld   maturity: unusable, experimental
"|
"|H1__  Documentation
"|
"|H2    FixPrefixesOfAutoloadFunctions
"|ftp   command! -buffer -nargs=0 FixPrefixesOfAutoloadFunctions :call vl#dev#vimscript#vimfile#FixPrefixesOfAutoloadFunctions()<cr>
"|p     This command does two different things.
"|p     1) just type 
"|code  function a#YourFunction() 
"|p     to replace a with the correct function
"|+     location. When the file is located in autoload/a/foo.vim it will
"|+     become
"|code  function a#foo#YourFunction() 
"|
"|p     2) If you're using an autoload function you can write:
"|code  call Load()
"|p     and FixPrefixesOfAutoloadFunctions will lookup the right prefix for
"|      you. Thus it will look like:
"|code  call vl#lib#vimscript#scriptsettings#Load()
"|P     You have to know that everything looking like a#b#c#Func( will be
"|+     treated as beeing a autoload function call. This is not perfect but
"|+     works well in practise.
"|
"|H2    Function completion
"|ftp   inoremap <buffer> <c-m-f> <c-r>=vl#lib#completion#useCustomFunctionNonInteracting#GetInsertModeMappingText('omnifunc','vl#dev#vimscript#vimfile#CompleteFunction',"\<c-x>\<c-o>")<cr>
"|
"|p     another tip: use 
"|code  syn match Tag '\%(\%(\w\+#\)*\|s:\|g:\)\zs\u\a*\ze' containedin=ALL 
"|p     in your .vim/after/syntax/vim.vim to highlight function names with s:, g: or
"|      autoload prefix
"|
"|TODO: implement gf handler to jump to the definition of used files
"|      recognize these references as well as used autoload functions:
"|code   function('vl#dev#vimscript#vimfile#ScanVimFile')
"|H2__ roadmap
"|rm   There is a lot which can be done: also parse commands, ..


" script  internal variables
let s:vl_regex = {}
let s:vl_regex['fap']='\%(\w\+#\)\+' " match function autoload prefix ( blah#foo#)
let s:vl_regex['ofp']='\%(\w\+#\)*' " optional match function location prefix ( blah#foo#)
let s:vl_regex['fp']='\%('.s:vl_regex['ofp'].'\|s:\|g:\)' " match any (or no function prefix)
let s:vl_regex['Fn']='\w*'  " match function name
let s:vl_regex['uFn']='\u\w*'  " match user function name
let s:vl_regex['function']='^\s*fun\%(ction\)\=!\=\s\+'
" match function declaration and get function name / doesn't match fun s:Name
let s:vl_regex['fn_decl']=s:vl_regex['function'].'\zs'.s:vl_regex['fp'].s:vl_regex['uFn'].'\ze('
call vl#lib#completion#quick_match_functions#AdvancedCamelCaseMatching('')
let s:quick_match_expr = vl#lib#vimscript#scriptsettings#Load('dev.vimscript.function_quick_match',
   \ function('vl#lib#completion#quick_match_functions#AdvancedCamelCaseMatching'))

"|func scan vim file (is used with ScanIfNewer()
"|     returns (to be extended ?)
"|     dictionary { 'declared functions' : list
"|                , 'declared autoload functions' : list
"|                , 'used user functions' : list
"|                , 'used autoload functions' : list
"|                }
"|    
function! vl#dev#vimscript#vimfile#ScanVimFile(file_lines)
  let declared_functions = vl#dev#vimscript#vimfile#GetAllDeclaredFunctions(
				      \ a:file_lines)
  let declared_autoload_functions = filter(deepcopy(declared_functions),
	      \ 'v:key =~ '.string(s:vl_regex['fap'].s:vl_regex['uFn']))
  let used_user_functions = vl#dev#vimscript#vimfile#GetAllUsedUserFunctions(
				      \ a:file_lines)
  let used_autoload_functions = filter(deepcopy(used_user_functions),
	      \ 'v:key =~ '.string(s:vl_regex['fap'].s:vl_regex['uFn']))
  let g:c = s:vl_regex['fap'].s:vl_regex['uFn']
  return { 'declared functions' : declared_functions
       \ , 'declared autoload functions' : declared_autoload_functions
       \ , 'used autoload functions' : used_autoload_functions
       \ , 'used user functions' : used_user_functions
       \ }
endfunction

" takes a file and subdir and tries to locate file in &runtimepath/subdir
" file has to be expanded.
" [ 1, [ runtimepath, file ] ] on success
" [ 0, "not <file> not found"] on failure
function! vl#dev#vimscript#vimfile#FileInDirOfRuntimePath(file, subdir)
  let filepath = a:file
  for path in split(&runtimepath,',')
    if has('windows')
      let ignore_case = '\c'
    else
      let ignore_case = ''
    endif
    let rest = matchstr(filepath, ignore_case.
	    \ substitute(expand(path),'\\','\\\\','g').a:subdir.'[/\\]\zs.*\ze')
    if rest != ""
      return [1, [path, rest] ]
    endif
  endfor
  return [ 0, "file ".a:file." in directory ".a:subdir." not found in any runtimepath "]
endfunction

function! s:HR(result)
  if a:result[0] == 1 
    return a:result[1][1]
  else
    return ""
  endif
endfunction

"|func returns the file part after autoload if the file is in a autoload directory
"|     in runtimepath "" else
function! vl#dev#vimscript#vimfile#FileInAutoloadDir(file)
  return s:HR(vl#dev#vimscript#vimfile#FileInDirOfRuntimePath(a:file, '[/\\]autoload'))
endfunction

"|func the same for runtimepath
function! vl#dev#vimscript#vimfile#FileInRuntimePath(file)
  return s:HR(vl#dev#vimscript#vimfile#FileInDirOfRuntimePath(a:file, ''))
endfunction

"| tries to locate file rel_filepath in runtimepath
"| FindFileInRuntimePath('autoload/vl/dev/vimscript/vimfile.vim')
"| should find this file
function! vl#dev#vimscript#vimfile#FindFileInRuntimePath(rel_filepath)
  for path in split(&runtimepath,',')
    let fn = expand(path.'/'.a:rel_filepath)
    if exists(fn)
     return fn
   endif
 endfor
 return ""
endfunction

"|func calculates the autoloadprefix of file based on runtimepath
function! vl#dev#vimscript#vimfile#GetPrefix(file)
  "let filepath = substitute(a:file,'\%(/\|\\\)[^/\\]*$','','')
  let filepath = expand(substitute(a:file,'.vim$','',''))
  " file is not in a autoloaddir, return it without change
  return substitute( substitute(vl#dev#vimscript#vimfile#FileInAutoloadDir(a:file),'/\|\\','#','g')
		   \ , '.vim$','','')
endfunction

" returns dictionary { "<functionname>" : <line_nr> , ... }
function! vl#dev#vimscript#vimfile#GetAllDeclaredFunctions(file_as_string_list)
  let functions = {}
  let line_nr = 1
  for l in a:file_as_string_list
    let function = matchstr(l,s:vl_regex['fn_decl'])
      if function !=  ""
	let functions[function] = line_nr
      endif
    let line_nr = line_nr + 1
  endfor
  return functions
endfunction


" returns a dictionary { "function name": linenr, ...}
" thus the last occurence will be listed
function! vl#dev#vimscript#vimfile#GetAllUsedUserFunctions(file_as_string_list)
  let file = a:file_as_string_list
  let result = {}
  let line_nr=1
  for l in file
    if l =~ '^\s*"' || l =~ s:vl_regex['fn_decl']
      let line_nr = line_nr + 1
      continue " simple comment handling.. can be improved much
	       " also continue on function declarations
    endif
    let matches = map(split(l,s:vl_regex['fp'].s:vl_regex['uFn'].'(\zs\ze'),"matchstr(v:val,'".s:vl_regex['fp'].s:vl_regex['uFn']."(')")
    for m in map(matches,"substitute(v:val,'($','','')")
      if m == ""
	continue
      endif
      if !exists("result['".m."']")
	let result[m] = line_nr
      endif
    endfor
    let line_nr = line_nr+1
  endfor
  return result
endfunction

" returns list of all used autoload files
" If you have 2 autoload/file.vim files
" the one beeing first in runtimepath will be used
" returns dictionary { "prefix": "file", ... }
" file autoload/blah/ehh.vim results in prefix
" blah#
function! vl#dev#vimscript#vimfile#ListOfAutoloadFiles()
  let files = {}
  for path in reverse(split(&runtimepath,','))
    for file in split(globpath(expand(path.'/autoload'),"**/*.vim"),"\n")
      let prefix = vl#dev#vimscript#vimfile#GetPrefix(file)
      let files[prefix] = file
    endfor
  endfor
  return files
endfunction

" corrects all function blah#foo# in funciton declarations
" corrects all prefixes in applied autoload functions such like a#b#C(
" commands are not yet recognized because the ( is missing there.
function! vl#dev#vimscript#vimfile#FixPrefixesOfAutoloadFunctions()
  echo "press Ctrl-c to abort. This command may still be buggy. "
     \ ." You have to wait some seconds when invoking this command the first time because vim has to scan all autload files. " 
     \ ."Use undo/ redo to show see changes or log which will be echoed"
  let log = {} " dictionary used to to get uniq values
  let prefix_curr = vl#dev#vimscript#vimfile#GetPrefix(expand('%:p'))
  let autofile_list = vl#dev#vimscript#vimfile#ListOfAutoloadFiles()
  "call filter(autofile_list, 'v:val =~ "test"')
  let fix_to_death_count = {}

  " correct prefix of function declarations:
  let curr_file = vl#dev#vimscript#vimfile#ScanVimFile(getline(1,line('$')))
  let df = curr_file['declared functions']
  for key in keys(df)
    let match = matchstr(key,'\zs.*\ze#')
    if match != '' && match != prefix_curr " fix it automatically. Here is nothing which can be done wrong
      let line_nr = df[key]
      let line = getline(line_nr)
      call setline(line_nr, substitute(line , s:vl_regex['fap'],  prefix_curr.'#', ''))
      let log["line ".line_nr." wrong prefix of function declaration '".line."' corrected"] = 0
    endif
  endfor
  let ok = 0
  let result = "define to cause no error on unlet"
  while !ok
    let ok = 1
    let used_functions = curr_file['used user functions']
    for f in keys(used_functions)
      unlet result
      let result = vl#dev#vimscript#vimfile#DoesAutoloadFunctionExist(autofile_list, f)
      let line_nr = used_functions[f]
      if exists("fix_to_death_count['".line_nr."']") &&  fix_to_death_count[line_nr] > 10
	continue
      endif
      if type(result) == 0 && result == 1
	continue
      endif
      if type(result) == 3
	if exists("fix_to_death_count['".line_nr."']")
	  let fix_to_death_count[line_nr] += 1
	  if fix_to_death_count[line_nr] > 10
	    let log[ "line ".used_functions[f]." internal script error. tried to fix this line more than 10 times and still not correct."] = 0
	  endif
	else
	  let fix_to_death_count[line_nr] = 1
	endif
	let ok = 0 " this can be fixed, try again because only the last occurence of the wrong function is stored in curr_file
	let use_func = vl#ui#userSelection#LetUserSelectIfThereIsAChoice(
	      \ 'There is more than one matching function, choose the one you like:', result)
	let line = getline(line_nr)
	let new_line = substitute(line , f.'(', use_func.'(', 'g')
	call setline(line_nr,new_line) 
	let log[ "line ".used_functions[f].": '".line."' replaced with '".new_line."'"] = 0
      else
	let log[ "function application ".f." line: ".used_functions[f]." not found, can't fix." ] =  0
      endif
    endfor
    " rescan the file  after each correction because only the last application
    " is listed
    if ok == 0
     let curr_file = vl#dev#vimscript#vimfile#ScanVimFile(getline(1,line('$')))
    endif
  endwhile 
  if len(log) == 0
    echo "nothing found to be corrected"
  else
    echo "log :\n".join(keys(log),"\n")
  endif
endfunction

" returns either
" 1: exists
" 0: doesn't exist
" ["location"]: does exist in another file with different prefix
" function: typically a#b#file#Func
" files: list of files to check (get file list using ListOfAutoloadFiles()
function! vl#dev#vimscript#vimfile#DoesAutoloadFunctionExist(files, function)
  let file = substitute(a:function,'#[^#]*$','','') " blah#foo value
  if exists("a:files['".file."']") 
    let file_content = vl#lib#files#scan_and_cache_file#ScanIfNewer(
	  \ a:files[file], 1, s:ScanVimFile)
    if exists("file_content['declared functions']['".a:function."']")
      return 1
    endif
  endif
  " search the function in all files
  let matches = []
  for f in keys(a:files)
    let file_content = vl#lib#files#scan_and_cache_file#ScanIfNewer(
	  \ a:files[f],1,  s:ScanVimFile)
    let function = substitute(a:function,'.*#','','')
    for f in keys(file_content['declared functions'])
      if f =~ '\<'.function.'$'
	call add(matches, f)
      endif
    endfor
  endfor
  if len(matches) > 0
    return matches
  endif
return 0
endfunction

let s:ScanVimFile = function('vl#dev#vimscript#vimfile#ScanVimFile')

function! vl#dev#vimscript#vimfile#CompleteFunction(findstart,base)
  if a:findstart
    " locate the start of the word
    let [bc,ac] = vl#lib#buffer#splitlineatcursor#SplitCurrentLineAtCursor()
    return len(bc)-len(matchstr(bc,'\%(\a\|\.\|\$\|\^\)*$'))
  else
    let prefix = matchstr(a:base,'.*\.')
    let func = substitute(a:base,'.*\.','','')
    " matching patterns
    let quick_pattern = s:quick_match_expr(func)
    let g:q = quick_pattern
    let pattern = '^'.func
    let regex = substitute('\%('.pattern.'\)\|\%('.quick_pattern.'\)', '\^', '^'.substitute(s:vl_regex['fp'],'\\','\\\\','g'),'g')
    let g:regex = regex

    " take functions from this file
    let curr_file = vl#dev#vimscript#vimfile#ScanVimFile(getline(1,line('$')))
    let functions = keys(curr_file['declared functions'])
    call filter(functions ,'v:val =~ '.string(regex))
    for f in functions
      call complete_add(f)
    endfor
    "if complete_check()
      "return []
    "endif
    " take functions from autoload directories
    let autoload_functions = vl#dev#vimscript#vimfile#ListOfAutoloadFiles()
    for file  in values(autoload_functions)
      "if complete_check()
	"return []
      "endif
      let file_content = vl#lib#files#scan_and_cache_file#ScanIfNewer(
	  \ file, 1,  s:ScanVimFile)
      let g:f = file
      let functions = keys(file_content['declared autoload functions'])
      call filter(functions ,'v:val =~ '.string(regex))
      for f in functions
	call complete_add(f)
      endfor
    endfor
    return []
  endif
endfunction

"|func only works with autoload functions 
"|     is intended to be used with gfHandler to jump to files.
"|     limitation: only finds first match (because FileInDirOfRuntimePath does so)
"|     returns either [[filename, linenr]]
"|     or [filename]. in case that function does not exist (than you can jump to the file and add it manually)
function! vl#dev#vimscript#vimfile#GetFuncLocation()
  let [b,a] = vl#lib#buffer#splitlineatcursor#SplitCurrentLineAtCursor()
  let func = matchstr(b,'\zs[#a-zA-Z0-9]*\ze$').matchstr(a,'^\zs[#a-zA-Z0-9]*\ze(')
  let results = []
  let autofile_list = vl#dev#vimscript#vimfile#ListOfAutoloadFiles()
  let keys = keys(autofile_list)
  for file in keys
    let functions = vl#lib#files#scan_and_cache_file#ScanIfNewer(
	  \ autofile_list[file], 1, s:ScanVimFile)['declared functions']
    if vl#lib#listdict#dict#HasKey(functions, func)
      let line = functions[func]
	call add(results, [autofile_list[file], line])
    endif
  endfor
  if len(results) == 0
    let file = substitute(func,'#[^#]*$','','') 
    if vl#lib#listdict#dict#HasKey(autofile_list, file)
      return [autofile_list[file]]
    endif
  endif
  return results
endfunction


"|func can be used instead of function.
"|     difference: this function sources the file if the function doesn't exsist
"|     yet
"|     doesn't work that well
function! vl#dev#vimscript#vimfile#Function(name)
  if !exists(a:name)
    let files = vl#dev#vimscript#vimfile#ListOfAutoloadFiles()
    let file_prefix = substitute(a:name,'#[^#]*$','','')
    if vl#lib#listdict#dict#HasKey(files, file_prefix)
      exec 'source '.files[file_prefix]
      return function(a:name)
    endif
  endif
endfunction
