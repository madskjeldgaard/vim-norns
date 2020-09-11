"""""""""""""""""""""""""""""""""""""""""""""
" vim-norns plugin by Mads Kjeldgaard
"
" Heavily inspired by  simonvanderveldt's work in atom:
" https://github.com/monome/norns/issues/1067
" And David Granstöm's scnvim:
" github.com/davidgranstrom/scnvim
"
" External dependencies:
" rlwrap
" websocat
" sshpass
" rsync
"
" Install on arch using yay: 
" yay -S rlwrap websocat sshpass rsync
"
"""""""""""""""""""""""""""""""""""""""""""""

if exists('g:norns_vim_loaded')
  finish
endif
let g:norns_vim_loaded = 1

" augroup to be used w/ ftplugin
augroup norns
  autocmd!
augroup END

" Global variables
let g:norns_ip = "norns.local" " TODO: Find a way to do this dynamically
let g:norns_project_path = ""
let g:norns_project_basename = ""
let g:norns_greeting='Hello. Are you ready?'
let g:norns_ssh_pass="sleep"

" Set help browser
if exists('$BROWSER')
	let g:norns_help_browser=$BROWSER
elseif executable('firefox')
	let g:norns_help_browser="firefox"
elseif executable('chrome')
	let g:norns_help_browser="chrome"
elseif executable('chromium')
	let g:norns_help_browser="chromium"
elseif executable('brave')
	let g:norns_help_browser="brave"
elseif executable('safari')
	let g:norns_help_browser="safari"
endif

" Commands
command! GetNornsProjectDir call norns#getNornsProjectDir()
command! SyncToNorns call norns#syncToNorns()
command! RunOnNorns call norns#runThis()
command! NornsStart call norns#replStart()
command! NornsReference call norns#openReference()

fun! norns#getNornsProjectDir()
	let g:norns_project_path = expand("%:p:h")	
	let g:norns_project_basename = expand("%:p:h:t")	
endf

fun! norns#openReference()
	let url = 'https://monome.org/docs/norns/script-reference/'
	let cmd = printf("! %s %s", g:norns_help_browser, url)

	if exists('g:norns_help_browser')
		execute cmd
	else
		echoe("norns help browser not set")
	endif
endf

" TODO
fun! norns#findPi()
	let cmd = 'sudo arp-scan --localnet --interface=wlo1 | grep Pi | awk "{print $1}"'
	let g:norns_pi_addresses = systemlist(cmd)
endf

fun! norns#syncToNorns()
	call norns#getNornsProjectDir()
	let cmd = printf('sshpass -p %s rsync -a --delete --exclude=".*" --delete-excluded %s we@%s:/home/we/dust/code/', g:norns_ssh_pass, g:norns_project_path, g:norns_ip)
	execute printf("! %s", cmd)
endf

fun! norns#runThis()
	let luacmd = printf("norns.script.load(\"code/%s/%s.lua\")", g:norns_project_basename, g:norns_project_basename)

	" Make sure REPL has been started
	if !exists('g:norns_chan_id')
		call norns#replStart()	
	endif

	" Send files to Pi
	call norns#syncToNorns()

	" Tell Pi to load this file / project
	call norns#sendToRepl(luacmd)
endf

fun! norns#replStart()
	" Heavily inspired by: https://github.com/monome/norns/issues/1067 
	"
	call norns#getNornsProjectDir()

	let cmd = printf("rlwrap websocat --protocol bus.sp.nanomsg.org ws://%s:5555", g:norns_ip)
	
	" Open terminal and save buffer id in global variable
	execute ":new"	
	let g:norns_chan_id = termopen(cmd)

	call norns#sendToRepl("print(\"" . g:norns_greeting . "\")" . "\<cr>")
endf

" Convert to chansend-able raw data
" Stolen from scnvim
fun! norns#sendToRepl(data)
	let code = printf("%s\x0c", a:data)
	call chansend(g:norns_chan_id, code . "\<cr>")
endf

" From SCNVIM
" https://github.com/davidgranstrom/scnvim/blob/2c51ad41aaae8abee43113fd13326b9461c67eed/autoload/scnvim.vim
" function! s:get_visual_selection() abort
"   let [lnum1, col1] = getpos("'<")[1:2]
"   let [lnum2, col2] = getpos("'>")[1:2]
"   if &selection ==# 'exclusive'
"     let col2 -= 1
"   endif
"   let lines = getline(lnum1, lnum2)
"   let lines[-1] = lines[-1][:col2 - 1]
"   let lines[0] = lines[0][col1 - 1:]
"   return {
"         \ 'text': join(lines, "\n"),
"         \ 'line_start': lnum1,
"         \ 'line_end': lnum2,
"         \ 'col_start': col1,
"         \ 'col_end': col2,
"         \ }
" endfunction

" function! Nornssend_line(start, end) abort
"   let is_single_line = a:start == 0 && a:end == 0
"   if is_single_line
"     let line = line('.')
"     let str = getline(line)
"     call Nornssend_line(str)
"   else
"     let lines = getline(a:start, a:end)
"     let last_line = lines[-1]
"     let end_paren = match(last_line, ')')
"     " don't send whatever happens after block closure
"     let lines[-1] = last_line[:end_paren]
"     let str = join(lines, "\n")
"     call norns#sendToRepl(str)
"   endif
" endfunction

" function! Nornssend_selection() abort
"   let obj = s:get_visual_selection()
"   call norns#sendToRepl(obj.text)
" endfunction

" function! Nornssend_block() abort
"   let [start, end] = s:get_block()
"   if start > 0 && end > 0 && start != end
"     call Nornssend_line(start, end)
"   else
"     call Nornssend_line(0, 0)
"   endif
" endfunction

