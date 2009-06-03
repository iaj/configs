if !exists('loaded_snippet') || &cp
  finish
endif

Snippet trigger My name is <{forename}> <{surname}>. Call me <{forename}>.

"substitute(@a,'\(..\)\(..\)\(..\)','\1\.\2\.\3','g')
"
"
"+-------------+
"|Abendseminare|
"+-------------+
Snippet as <tr><CR><td valign="top">###error_Abendseminar<{ttmmyy}>###<CR><input type="checkbox" name="Abendseminar<{ttmmyy}>" value="JA" ###checked_Abendseminar<{ttmmyy}>_JA### /></td><CR><td width="117" valign="top"><{ttmmyy:substitute(@z,'\(..\)\(..\)\(.*\)','\1\.\2\.20\3','g')}></td><CR><td width="161" valign="top">nls® Abendseminar</td><CR><td width="93" valign="top"><{ort}></td><CR><td width="115" valign="top">€ 0,00 + MwSt.</td><CR></tr>
