" ttoc.vim -- A regexp-based ToC of the current buffer
" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-07-09.
" @Last Change: 2007-09-29.
" @Revision:    0.2.385
" GetLatestVimScripts: 2014 0 ttoc.vim

if &cp || exists("loaded_ttoc")
    finish
endif
if !exists('loaded_tlib') || loaded_tlib < 14
    echoerr 'tlib >= 0.14 is required'
    finish
endif
let loaded_ttoc = 2

let s:save_cpo = &cpo
set cpo&vim


" Markers as used by vim and other editors. Can be also buffer-local. 
" This rx is added to the filetype-specific rx.
" Values:
"   0      ... disable
"   1      ... use &foldmarker
"   2      ... use &foldmarker only if &foldmethod == marker
"   string ... use as rx
TLet g:ttoc_markers = 1


" By default, assume that everything at the first column is important.
TLet g:ttoc_rx = '^\w.*'

" TLet g:ttoc_markers = '.\{-}{{{.*'


" Filetype-specific rx "{{{2

" :doc:
" Some filetype-specific regexps. If you don't like the default values, 
" set these variables in ~/.vimrc.

TLet g:ttoc_rx_bib    = '^@\w\+\s*{\s*\zs\S\{-}\ze\s*,'
TLet g:ttoc_rx_c      = '^[[:alnum:]#].*'
TLet g:ttoc_rx_cpp    = g:ttoc_rx_c
TLet g:ttoc_rx_html   = '\(<h\d.\{-}</h\d>\|<\(html\|head\|body\|div\|script\|a\s\+name=\).\{-}>\|<.\{-}\<id=.\{-}>\)'
TLet g:ttoc_rx_perl   = '^\([$%@]\|\s*\(use\|sub\)\>\).*'
TLet g:ttoc_rx_php    = '^\(\w\|\s*\(class\|function\|var\|require\w*\|include\w*\)\>\).*'
TLet g:ttoc_rx_python = '^\s*\(import\|class\|def\)\>.*'
TLet g:ttoc_rx_rd     = '^\(=\+\|:\w\+:\).*'
TLet g:ttoc_rx_ruby   = '\C^\(if\>\|\s*\(class\|module\|def\|require\|private\|public\|protected\|module_functon\|alias\|attr\(_reader\|_writer\|_accessor\)\?\)\>\|\s*[[:upper:]_]\+\s*=\).*'
TLet g:ttoc_rx_scheme = '^\s*(define.*'
TLet g:ttoc_rx_sh     = '^\s*\(\(export\|function\|while\|case\|if\)\>\|\w\+\s*()\s*{\).*'
TLet g:ttoc_rx_tcl    = '^\s*\(source\|proc\)\>.*'
TLet g:ttoc_rx_tex    = '\C\\\(label\|\(sub\)*\(section\|paragraph\|part\)\)\>.*'
TLet g:ttoc_rx_viki   = '^\(\*\+\|\s*#\l\).*'
TLet g:ttoc_rx_vim    = '\C^\(fu\%[nction]\|com\%[mand]\|if\|wh\%[ile]\)\>.*'

" TLet g:ttoc_rx_vim    = '\C^\(\(fu\|if\|wh\).*\|.\{-}\ze\("\s*\)\?{{{.*\)'
" TLet g:ttoc_rx_ocaml  = '^\(let\|module\|\s*let .\{-}function\).*'


" :nodefault:
" ttoc-specific |tlib#input#ListD| configuration.
" Customizations should be done in ~/.vimrc/after/plugin/ttoc.vim
" E.g. in order to split horizontally, use: >
"     let g:ttoc_world.scratch_vertical = 0
TLet g:ttoc_world = {
                \ 'type': 'm',
                \ 'query': 'Select entry',
                \ 'pick_last_item': 0,
                \ 'scratch': '__ttoc__',
                \ 'retrieve_eval': 'TToCCollect(world, 0)',
                \ 'return_agent': 'tlib#agent#GotoLine',
                \ 'key_handlers': [
                    \ {'key': 16, 'agent': 'tlib#agent#PreviewLine',  'key_name': '<c-p>', 'help': 'Preview'},
                    \ {'key':  7, 'agent': 'tlib#agent#GotoLine',     'key_name': '<c-g>', 'help': 'Jump (don''t close the TOC window)'},
                    \ {'key': 60, 'agent': 'tlib#agent#GotoLine',     'key_name': '<',     'help': 'Jump (don''t close the TOC window)'},
                    \ {'key':  5, 'agent': 'tlib#agent#DoAtLine',     'key_name': '<c-e>', 'help': 'Run a command on selected lines'},
                \ ],
            \ }
            " \ 'scratch_vertical': (&lines > &co),


" If true, split vertical.
TLet g:ttoc_vertical = '&lines < &co'
" TLet g:ttoc_vertical = -1

" Vim code that evaluates to the desired window width/heigth.
TLet g:ttoc_win_size = '((&lines > &co) ? &lines : &co) / 2'
" TLet g:ttoc_win_size = '((&lines > &co) ? winheight(0) : winwidth(0)) / 2'


" :def: function! TToCCollect(world, return_index, ?additional_lines=0)
function! TToCCollect(world, return_index, ...) "{{{3
    TVarArg ['additional_lines', 0]
    " TLogVAR additional_lines
    let pos = getpos('.')
    let s:accum = []
    let s:table  = []
    let s:current_line = line('.')
    let s:line_format  = '%0'. len(line('$')) .'d'
    let s:current_index = 0
    let s:additional_lines = additional_lines
    let s:rx = a:world.ttoc_rx
    let rs  = @/
    let s:next_line = 1

    try
        exec 'keepjumps g /'. escape(a:world.ttoc_rx, '/') .'/call s:ProcessLine()'
    finally
        let @/ = rs
    endtry

    call setpos('.', pos)
    " let a:world.index_table = s:table
    if a:return_index
        return [s:accum, s:current_index]
    else
        return s:accum
    endif
endf


function! s:ProcessLine() "{{{3
    let l = line('.')
    if l >= s:next_line

        let t = [matchstr(getline(l), s:rx)]
        if exists('*TToC_GetLine_'.&filetype)
            let s:next_line = TToC_GetLine_{&filetype}(l, t)
        else
            let s:next_line = l + 1
        endif

        if s:additional_lines > 0
            let next_line = s:next_line + s:additional_lines
            for i in range(s:next_line, next_line - 1)
                " TLogVAR i
                let lt = getline(i)
                if lt =~ '\S'
                    call add(t, lt)
                endif
            endfor
            let s:next_line = next_line
        endif

        let i = printf(s:line_format, l) .': '. substitute(join(t, ' | '), '\s\+', ' ', 'g')
        " let i = substitute(join(t, ' | '), '\s\+', ' ', 'g')
        call add(s:accum, i)
        " call add(s:table, l)
        if l <= s:current_line
            let s:current_index += 1
        endif

    endif
endf


" function! TToC_GetLine_vim(lnum, acc) "{{{3
"     let l = a:lnum
"     while 1
"         let l -= 1
"         let t = getline(l)
"         if !empty(t) && t =~ '^\s*"'
"             let t = matchstr(t, '"\s*\zs.*')
"             TLogVAR t
"             call insert(a:acc, t, 1)
"         else
"             break
"         endif
"     endwh
"     return l
" endf


function! TToC_GetLine_viki(lnum, acc) "{{{3
    let l = a:lnum
    while 1
        let l += 1
        let t = getline(l)
        if !empty(t)
            if t[0] == '#'
                call add(a:acc, t)
            elseif t =~ '\s\+::\s\+'
                call add(a:acc, t)
            else
                break
            end
        else
            break
        endif
    endwh
    return l
endf


function! s:ViewToC(rx, ...) "{{{3
    TVarArg ['partial_rx', 0], ['v_count', 0], ['p_count', 0]
    let additional_lines = v_count ? v_count : p_count ? p_count : 0
    " TLogVAR additional_lines, v_count, p_count

    if empty(a:rx)
        let rx = tlib#var#Get('ttoc_rx_'. &filetype, 'wbg')
        if empty(rx)
            let rx = tlib#var#Get('ttoc_rx', 'wbg')
        endif
        let marker = tlib#var#Get('ttoc_markers', 'wbg')
        if !empty(marker)
            if type(marker) == 0
                if marker == 1 || (marker == 2 && &foldmethod == 'marker')
                    let [open,close] = split(&foldmarker, ',', 1)
                    if !empty(open)
                        let rx  = printf('\(%s\|.\{-}%s.*\)', rx, tlib#rx#Escape(open))
                    endif
                endif
            else
                let rx = printf('\(%s\|%s\)', rx, marker)
            endif
        endif
    else
        let rx = a:rx
        if partial_rx
            let rx = '^.\{-}'. rx .'.*$'
        end
    endif

    if empty(rx)
        echoerr 'TToC: No regexp given'
    else
        " TLogVAR ac
        let w = copy(g:ttoc_world)
        let w.ttoc_rx = rx
        let [ac, ii] = TToCCollect(w, 1, additional_lines)
        " TLogVAR ac
        let w.initial_index = ii
        let w.base = ac
        let win_size = tlib#var#Get('ttoc_win_size', 'wbg')
        if !empty(win_size)
            " TLogDBG tlib#cmd#UseVertical('TToC')
            let use_vertical = eval(g:ttoc_vertical)
            if use_vertical == 1 || (use_vertical == -1 && tlib#cmd#UseVertical('TToC'))
                let w.scratch_vertical = 1
                if get(w, 'resize_vertical', 0) == 0
                    let w.resize_vertical = eval(win_size)
                endif
            else
                if get(w, 'resize', 0) == 0
                    let w.resize = eval(win_size)
                endif
            endif
        endif
        " TLogVAR w.resize_vertical, w.resize
        call tlib#input#ListD(w)
    endif
endf


" :display: [COUNT]TToC[!] [REGEXP]
" EXAMPLES: >
"   TToC                   ... use standard settings
"   TToC foo.\{-}\ze \+bar ... show this rx (don't include 'bar')
"   TToC! foo.\{-}bar      ... show lines matching this rx 
"   3TToC! foo.\{-}bar     ... show lines matching this rx + 3 extra lines
command! -nargs=? -bang -count TToC call s:ViewToC(<q-args>, !empty("<bang>"), v:count, <count>)


let &cpo = s:save_cpo

finish
CHANGES:
0.1
- Initial release

0.2
- Require tlib 0.14
- <c-e> Run a command on selected lines.
- g:ttoc_world can be a normal dictionary.
- Use tlib#input#ListD() instead of tlib#input#ListW().

