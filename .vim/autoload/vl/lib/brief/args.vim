"|fld   description : get additional args
"|fld   keywords : "shorten vimscript" 
"|fld   initial author : Marc Weber marco-oweber@gmx.de
"|fld   mantainer : author
"|fld   started on : 2006 Nov 06 21:31:32
"|fld   version: 0.0
"|fld   contributors : <+credits to+>
"|fld   tested on os : <+credits to+>
"|fld   maturity: stable
"|
"|H1__  Documentation
"|

"|p     returns optional argument or default value
"|p     Example usage:
"|code  function! F(...)
"|        exec GetOptionalArg('optional_arg',string('no optional arg given'))
"|        exec GetOptionalArg('snd_optional_arg',string('no optional arg given'),2)
"|        echo 'optional arg is '.string(optional_arg)
"|      endfunction
function! vl#lib#brief#args#GetOptionalArg( name, default, ...)
  if a:0 == 1
    let idx = a:1
  else
    let idx = 1
  endif
  if type( a:default) != 1
    throw "wrong type: default parameter of vl#lib#brief#args#GetOptionalArg must be a string, use string(value)"
  endif
  let script = [ "if a:0 >= ". idx
	     \ , "  let ".a:name." = a:".idx
	     \ , "else"
	     \ , "  let ".a:name." = ".a:default
	     \ , "endif"
	     \ ]
  return join( script, "\n")
endfunction

"|func    creates a dict out of it'arguments arguments are given as key:value
"|+       where you can omit key when specifying default keys as list
"|        meant to be used with commands (See contextcompletion.vim where it
"|        is used)
"| 
"| example :
"|pre    command -nargs=* Command call FunctionWhichTakesDict(vl#lib#brief#args#CommandArgsAsDict(['a','b','c'], <f-args> ))
"|       Command a:a c:c b:b
"|       Command a b c
"|       Command a:a b c
"|       will all result in
"|       {'a':'a', 'b':'b', 'c':'c'}
"|       
"|       drawback: you can only pass strings
function! vl#lib#brief#args#CommandArgsAsDict( defaultkeys, ... )
  let dict = {}
  let key_idx = 0
  let dk = deepcopy(a:defaultkeys)
  for arg in a:000
    let pos=-1
    while pos < strlen(arg)
      let pos = stridx(arg, ':', pos+1)
      if arg[pos-1] != '\'
        break
      endif
    endwhile
    if pos == -1
      let dict[vl#lib#listdict#list#Pop(dk,'superfluous')] = arg
      let key_idx = key_idx +1
    else
      let key = strpart(arg, 0, pos)
      let dict[ key ] = strpart(arg, pos+1)
      call filter(dk, 'v:val != '.string(key) )
    endif
  endfor
  return dict
endfunction
