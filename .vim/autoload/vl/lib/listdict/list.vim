"" brief-description : Some util functions processing lists
"" keywords : list 
"" author : Marc Weber marco-oweber@gmx.de
"" started on :2006 Oct 02 05:42:31
"" version: 0.0

"|func returns last value of list or value_if_empty if list is empty
function! vl#lib#listdict#list#Last(list, value_if_empty)
  let len = len(a:list) 
  if len == 0
    return a:value_if_empty
  else
    return a:list[len-1]
  endif
endfunction

function! vl#lib#listdict#list#MaybeIndex(list, index, default)
  if a:index>=0 && a:index < len(a:list)
    return a:list[a:index]
  else
    return a:default
  endif
endfunction

function! vl#lib#listdict#list#ListContains(list, value)
  for v in a:list
    if v == a:value
      return 1
    endif
  endfor
  return 0
endfunction

function! vl#lib#listdict#list#AddUnique(list, value)
  if !vl#lib#listdict#list#ListContains(a:list, a:value)
    return add(a:list, a:value)
  else
    return a:list
  endif
endfunction

function! vl#lib#listdict#list#Unique(list)
  let result = {}
  for v in a:list
    let result[v]=0 " this will add the value only once
  endfor
  return keys(result)
endfunction

"|func joins the list of list ( [[1,2],[3,4]] -> [1,2,3,4] )
function! vl#lib#listdict#list#JoinLists(list_of_lists)
  let result = []
  for l in a:list_of_lists
    call extend(result, l)
  endfor
  return result
endfunction

"func this is used only in scriptsettings to merge global and buffer opts
function! vl#lib#listdict#list#Concat(...)
  return vl#lib#listdict#list#JoinLists(a:000)
endfunction

" is there a better way to do this?
" using remove?
function! vl#lib#listdict#list#TrimListCount(list, count)
  let c = 0
  let result = []
  for i in a:list
    if c >= a:count 
      break
    endif
    call add(result, i)
    let c = c+1
  endfor
  return result
endfunction

" the sme as map but returns the result of the map operation
" You have to use Val instead of v:val
" tip: You can also use things like
" call vl#lib#listdict#list#MapCopy(['A'], ' exec "command ".Val." ".Val)
function! vl#lib#listdict#list#MapCopy(listOrDict, expr)
  let result = []
  for Val in a:listOrDict
    exec 'call add(result, '.a:expr.')'
  endfor
  return result
endfunction

" combination of map and filter
function! vl#lib#listdict#list#MapIf(list, pred, expr)
  let result = []
  for Val in a:list
    exec 'let p = ('.a:pred.')'
    exec 'if p | call add(result, '.a:expr.')|endif'
  endfor
  return result
endfunction

function! vl#lib#listdict#list#Zip(...)
  let a = a:000
  let c = min( vl#lib#listdict#list#MapCopy(a,'len(Val)'))
  let r = range(0,a:0-1)
  let result = []
  for i in range(0,c-1)
    let l = []
    for j in r
      call add(l,a[j][i])
    endfor
    call add(result,l)
  endfor
  return result
endfunction

function! vl#lib#listdict#list#Transpose(a)
  let max_len = max( vl#lib#listdict#list#MapCopy(a:a, 'len(Val)')
  let result = []
  for i in range(0, max_len - 1)
    let l = []
    for j in len(a:a)
      call add(result,a:a[j][i])
    endfor
    call add(result, l)
  endfor
  return result
endfunction

"func 
"pre  ['a','bbbbb','c']
"     ['AAAAaa','B','C']
"/pre is aligned this way:
"pre  ['a     ','bbbbb','c']
"     ['AAAAaa','B    ','C']
"/pre this way
"p    Example usage: AlignByChar 
function! vl#lib#listdict#list#AlignToSameIndent(a)
  call vl#lib#ide#logging#Log('align by char called with '.string(a:a))
  "let result = a:a
  "call map(result,"map(v:val,'substitute(v:val,\"^\\s*\\|\\s*$\",\"\",\"g\")')")
  let result = []
  for i in range(0, len(a:a) -1 )
    let l = []
      for j in range(0, len(a:a[i]) -1 )
      call add(l, substitute(a:a[i][j],'^\s*\|\s*$','','g'))
    endfor
    call add(result, l)
  endfor
  let max_len = max( vl#lib#listdict#list#MapCopy(result, 'len(Val)'))
  for i in range(0, max_len -1)
    let max = -1
    for j in range(0, len(result)-1)
      let c = strlen(vl#lib#listdict#list#MaybeIndex(result[j] , i,''))
      if c > max
        let max = c
      endif
    endfor
    for j in range(0, len(result) -1)
      if i < len(result[j])
        let v = result[j][i]
        let result[j][i] = repeat(' ',max-strlen(v)) . v
      endif
    endfor
  endfor
  return result
endfunction

"func tries to give these characters the same indent
function! vl#lib#listdict#list#AlignByChar(char) range
  let lines = getline(a:firstline, a:lastline)
  call map(lines,"split(v:val,".string('\s*'.a:char.'\s*').",1)")
  call vl#lib#ide#logging#Log('lines '.string(lines))
  let lists = vl#lib#listdict#list#AlignToSameIndent(lines)
  call vl#lib#ide#logging#Log('lists '.string(lists))
  call map(lists, "join(v:val,".string(a:char).")")
  call vl#lib#ide#logging#Log('lists joined '.string(lists))
  for i in range(0, len(lists) - 1)
    call setline(a:firstline+i, lists[i])
  endfor
endfunction

"func removes the last element from the list and returns it
"     as push simply use call add(list,item)
function! vl#lib#listdict#list#PopLast(list)
  return remove(a:list,len(a:list)-1)[0]
endfunction

function! vl#lib#listdict#list#Pop(list, ...)
  if len(a:list) == 0
    exec vl#lib#brief#args#GetOptionalArg('default',string('empty list'))
    return default
  else
    return remove(a:list,0,0)[0]
  endif
endfunction

function! vl#lib#listdict#list#Union(...)
  let result = {}
  for l in a:000
    for item in l
      let result[item] = 1
    endfor
  endfor
  return keys(result)
endfunction

" returns the items beeing contained only in and not in b (might be slow)
function! vl#lib#listdict#list#Difference(a,b)
  let result = []
  for i in a:a
    if !vl#lib#listdict#list#ListContains(a:b, i)
      call add(result, i)
    endif
  endfor
  return result
endfunction

" element must be contained in both (might be slow)
function! vl#lib#listdict#list#Intersection(a,b)
  let result = []
  for i in a:a
    if vl#lib#listdict#list#ListContains(a:b, i)
      call add(result, i)
    endif
  endfor
  return result
endfunction

" returns true if all list items satisfy pred
function! vl#lib#listdict#list#All(l,pred)
  for Val in a:l
    exec 'let p = ('.a:pred.')'
    if !p
      echo Val
      return 0
    endif
  endfor
  return 1
endfunction

" returns true if at least one item satisfies pred
function! vl#lib#listdict#list#Any(l,pred)
  for Val in a:l
    exec 'let res = '.a:pred
    if res
      return 1
    endif
  endfor
  return 0
endfunction
" this dosen't work for some unkown reason:
  "for val in a:l
    "exec 'if ('.a:pred.')| return 1|endif'
  "endfor

function! vl#lib#listdict#list#ToList(a)
  if type(a:a) == 3
    return a:a
  else
    return [a:a]
  endif
endfunction

function! vl#lib#listdict#list#ForEach(l, toExecute)
  for Val in a:l 
    exec a:toExecute
  endfor
endfunction
