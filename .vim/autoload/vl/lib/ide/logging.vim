"|fld   description : provides logging messages in a buffer
"|fld   keywords : logging vimscript 
"|fld   initial author : Marc Weber marco-oweber@gmx.de
"|fld   mantainer : author
"|fld   started on : 2007 Apr 20 05:03:31
"|fld   version: 0.0
"|fld   maturity: unusable, experimental
"|
"|H1__  Documentation
"|H2_   settings
"|      You can choose log_target (see source) to log to "['echom','file://<file>','buffer']
"|p     file:// isn't implemented yet
"|H2_   Example usage:
"|pre
"|      call vl#lib#ide#logging#Enter('my sect')
"|      call vl#lib#ide#logging#Log("text -important",10)
"|      call vl#lib#ide#logging#Leave()
"|      call vl#lib#ide#logging#LogWindowAction('show')
"|H3_   importance
"|      0 - 2 debug (not logged by default)
"|      3 - 4 notice (logged by default)
"|      >= 5 viewed causes log window popup by default
"|      5 - 7  experienced users don't have to see it (eg "direcotry xy created" messages)
"|      8 - 10 user should see them (eg. operation failed ..)
"|TODO  testing/ highlighting ? rewrite using resultBuffer.vim
"
" There is some trouble somewhere - thats why I've switched it off by using
" log_level 20

" using echom may make some scripts no longer work as they depend on no output
" (because vim else will show a "press enter" which catches <cr> which should
" have gone somewhere else (TODO: fix that somehow) Examples which might fail:
" include dependend c completion)
let s:log_targets=vl#lib#vimscript#scriptsettings#Load('vl.lib.ide.logging.log_targets',
  \ ['buffer','file'])

" if log_targets contains 'file' log to this file
let s:log_file=vl#lib#vimscript#scriptsettings#Load('vl.lib.ide.logging.log_file',
  \ g:store_vl_stuff.'/vl.log')

" pop up the log window if the importance of the logged message is greater
" than this value (typicallly bewtween 0 - 10)
let g:vl_pop_up_log_window=vl#lib#vimscript#scriptsettings#Load('vl.lib.ide.logging.pop_up_log_window',
  \ 6 )

" log everything more important or equal to this value - default 2
let g:vl_log_level=vl#lib#vimscript#scriptsettings#Load('vl.lib.ide.logging.vl_log_level',
  \ 20 )

" you can loose most logging messages without beeing harmed
let s:set_unmodified=vl#lib#vimscript#scriptsettings#Load('vl.lib.ide.logging.',
  \ 1 )
let s:indent = 0
" log time_stamp and importance
let s:add_header = 0

" TODO: log to file ?
let s:known_log_targets = { 
 \   'echom'  : 'for msgline in msg | echom msgline | endfor'
 \ , 'buffer' : 'call vl#lib#ide#logging#LogWindowAction("add message", msg, importance)'
 \ , 'file'   : 'call writefile(extend(vl#lib#files#filefunctions#ReadFile(s:log_file,[]), msg),s:log_file)'
 \ }

let s:log_window_name = '__log_window__'

let s:time_format = vl#lib#vimscript#scriptsettings#Load('vl.lib.ide.logging.log_targets',
  \ "[%= strftime('%y-%b-%d %X') %]")

" see Enter Leave
let s:sections = []

"func make the logfile public
function! vl#lib#ide#logging#LogFile()
  return s:log_file
endfunction

"func log a message
"     optinal argument: importance.
function! vl#lib#ide#logging#Log(msg,...)
  exec vl#lib#brief#args#GetOptionalArg('importance',string(5))
  if importance < g:vl_log_level
    return
  endif
  if type(a:msg) == 1
    let msg = [a:msg]
  else
    let msg = a:msg
  endif
  if s:add_header
    let header = printf("== %2d, %s" importance
     \ , vl#lib#template#template#SimplePreprocessTemplateText(s:time_format))
    let msg = extend([header], msg)
  endif
  let indent = repeat(s:indent, '  ')
  call map(msg, string(indent).'.v:val')
  for i in s:log_targets
    exec s:known_log_targets[i]
  endfor
endfunction

function! vl#lib#ide#logging#Enter(section)
  let s:indent = s:indent+1
  call vl#lib#ide#logging#Log('entering section '.a:section)
  call add(s:sections, a:section)
endfunction

function! vl#lib#ide#logging#Leave()
  call vl#lib#ide#logging#Log('leaving section '
   \ . vl#lib#listdict#list#PopLast(s:sections) )

  let s:indent = s:indent-1
endfunction

"func  actions: 
" 'add message': params msg, optional importance (default 5), will be scrolled down
" 'show': (focus will be set to logging window)
" 'hide': hide the window
function! vl#lib#ide#logging#LogWindowAction(action, ...)
  let current_buf = bufnr('%')
  let current_window = winnr()
  let reset_window_focus = 1

  let was_visible = bufwinnr(bufnr(s:log_window_name)) >= 0
  silent! let new = bufnr(s:log_window_name) == -1
   
  let buf_nr = bufnr(s:log_window_name,1)

  if buf_nr < 0
    " create logging window (using preview is the only way I know
    silent! exec 'sp '.s:log_window_name
    setlocal buftype=nofile
    setlocal noswapfile
    setlocal noreadonly
    call vl#lib#ide#logging#LogWindowAction('add message', '" use Ctrl-w z to close this logging window')
    let is_visible = 1
  else
    let is_visible = was_visible
  endif

  if new
    " make visible
    silent! exec 'sp '.s:log_window_name
    exec bufwinnr(bufnr(s:log_window_name)).' wincmd w'
    call append(getline('$'), [
	  \   '============= logging window ========================================='
	  \ , ' see file autoload/l/lib/ide/logging.vim to customize logging behaviour'
          \ , ' press <cr> to hide' ] )
    noremap <buffer> <cr> :hide<cr>
    let is_visible = 1
  endif

  let hide_lw = !was_visible

  if a:action == 'add message'
    exec vl#lib#brief#args#GetOptionalArg('msg', string('no message passed ??'),1)
    exec vl#lib#brief#args#GetOptionalArg('importance', string(5) ,2)
    if !is_visible
      " make visible
      silent! exec 'sp '.s:log_window_name
    endif
    " set focus
    exec bufwinnr(bufnr(s:log_window_name)).' wincmd w'
    " add lines
    call append(line('$'), msg)
    normal G
    if s:set_unmodified
      set nomodified
    endif
    let hide_lw = !was_visible && importance < g:vl_pop_up_log_window
  elseif a:action == 'show'
    if !is_visible
      exec 'sp '.s:log_window_name
    endif
    " set focus
    exec bufwinnr(bufnr(s:log_window_name)).' wincmd w'
    let hide_lw = 0
    let reset_window_focus = 0
  elseif a:action == 'hide'
    if was_visible
      let hide_lw = 1
    endif
  endif

  if hide_lw
    " set focus
    exec bufwinnr(bufnr(s:log_window_name)).' wincmd w'
    hide
  endif

  " switch to buffer which had focus before again
  if reset_window_focus
    exec current_window.' wincmd w'
  endif
endfunction

function! vl#lib#ide#logging#AddUICommands()
  command! LogWindow call vl#lib#ide#logging#LogWindowAction('show')
  command! LogShowAll let g:vl_pop_up_log_window=0 <bar> let g:vl_log_level = 0
  command! Log call vl#lib#ide#logging#Log(<f-args>)
endfunction

