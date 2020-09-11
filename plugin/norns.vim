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

""""""""""""""
"  Commands  "
""""""""""""""
command! NornsRun call norns#runThis()
command! NornsStart call norns#replStart()
command! NornsReference call norns#openReference()
command! NornsStudies call norns#openStudies()
command! NornsEngineCommands call norns#listEngineCommands()
command! NornsFind call norns#findNorns()
command! NornsSync call norns#syncToNorns()
command! NornsGreet call norns#greeting()
command! NornsSSH call norns#ssh()

"""""""""""""""""""""""""""""""""""
"  Syncronizing and running code  "
"""""""""""""""""""""""""""""""""""
fun! norns#getNornsProjectDir()
	let g:norns_project_path = expand("%:p:h")	
	let g:norns_project_basename = expand("%:p:h:t")	
endf

fun! norns#syncToNorns()
	call norns#getNornsProjectDir()
	let cmd = printf('sshpass -p %s rsync -a --delete --exclude=".*" --delete-excluded %s we@%s:/home/we/dust/code/', g:norns_ssh_pass, g:norns_project_path, g:norns_ip)
	silent execute printf("! %s", cmd)
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

" Convert to chansend-able raw data
" Stolen from scnvim
fun! norns#sendToRepl(data)
	let code = printf("%s\x0c", a:data)
	call chansend(g:norns_chan_id, code . "\<cr>")
endf

fun! norns#replStart()
	" Heavily inspired by: https://github.com/monome/norns/issues/1067 
	call norns#getNornsProjectDir()

	let cmd = printf("rlwrap websocat --protocol bus.sp.nanomsg.org ws://%s:5555", g:norns_ip)

	" Open terminal and save buffer id in global variable
	execute ":new"	
	let g:norns_chan_id = termopen(cmd)

	" Display greeting on norns
	call norns#greeting()
endf

""""""""""""""
"  Niceties  "
""""""""""""""
fun! norns#listEngineCommands()
	call norns#sendToRepl("engine.list_commands()")
endf

fun! norns#listAvailableEngines()
	call norns#sendToRepl("tab.print(engine.names)") 
endf

fun! norns#greeting()
	call norns#sendToRepl("function redraw()" . "\<cr>")
	call norns#sendToRepl("screen.clear()" . "\<cr>")
	call norns#sendToRepl("screen.level(15)" . "\<cr>")
	call norns#sendToRepl("screen.move(0,40)" . "\<cr>")
	call norns#sendToRepl("screen.text(\" Vim says:\")" . "\<cr>")
	call norns#sendToRepl("screen.move(0,60)" . "\<cr>")
	call norns#sendToRepl("screen.text(\"Hello. Are you ready? \")" . "\<cr>")
	call norns#sendToRepl("screen.update()" . "\<cr>")
	call norns#sendToRepl("end" . "\<cr>")
endf

"""""""""""""""""""""""""""""""
"  Help files and references  "
"""""""""""""""""""""""""""""""
fun! norns#openReference()
	let url = printf("%s/doc/", g:norns_ip)
	let cmd = printf("! %s %s", g:norns_help_browser, url)

	if exists('g:norns_help_browser')
		execute cmd
	else
		echoe("norns help browser not set")
	endif
endf

fun! norns#openStudies()
	let url = 'https://monome.org/docs/norns/studies-landing/'
	let cmd = printf("! %s %s", g:norns_help_browser, url)

	if exists('g:norns_help_browser')
		execute cmd
	else
		echoe("norns help browser not set")
	endif
endf

"""""""""""""""""""
"  Network stuff  "
"""""""""""""""""""

" Find all devices on network
fun! norns#findNorns()
	if exists("*fzf#run")		
		let cmd = "arp -a| awk '{print $2}'| sed 's/(//g'| sed 's/)//g'"
		call fzf#run({'sink': function('norns#saveNornsAddr'), 'source': cmd})
	else
		echoe("fzf not installed!")
	endif
endf

" Save address
fun! norns#saveNornsAddr(ipaddr)
	let g:norns_ip = a:ipaddr
endf

fun! norns#ssh()
	let cmd = printf("sshpass -p %s ssh we@%s", g:norns_ssh_pass, g:norns_ip)
	:split
	execute ":terminal " . cmd
endf

""""""""""""""
"  Mappings  "
""""""""""""""
" if !hasmapto('<Plug>(scnvim-send-line)', 'ni')
" 	nmap <buffer> <M-e> <Plug>(scnvim-send-line)
" 	imap <buffer> <M-e> <c-o><Plug>(scnvim-send-line)
" endif

" if !hasmapto('<Plug>(scnvim-send-selection)', 'x')
" 	xmap <buffer> <C-e> <Plug>(scnvim-send-selection)
" endif
fun! norns#defaultMappings()
	if !hasmapto(':NornsStart', 'ni')
		nmap <buffer> <F1> :NornsStart<cr>
		imap <buffer> <F1> <esc>:NornsStart<cr>
	endif

	if !hasmapto(':NornsFind', 'ni')
		nmap <buffer> <F2> :NornsFind<cr>
		imap <buffer> <F2> <esc>:NornsFind<cr>
	endif

	if !hasmapto(':NornsReference', 'ni')
		nmap <buffer> <F3> :NornsReference<cr>
		imap <buffer> <F3> <esc>:NornsReference<cr>
	endif

	if !hasmapto(':NornsGreet', 'ni')
		nmap <buffer> <F4> :NornsGreet<cr>
		imap <buffer> <F4> <esc>:NornsGreet<cr>
	endif

	if !hasmapto(':NornsGreet', 'ni')
		nmap <buffer> <F4> :NornsGreet<cr>
		imap <buffer> <F4> <esc>:NornsGreet<cr>
	endif

	if !hasmapto(':NornsRun', 'ni')
		nmap <buffer> <C-e> :NornsRun<cr>
		imap <buffer> <C-e> <esc>:NornsRun<cr>

		nmap <buffer> <F5> :NornsRun<cr>
		imap <buffer> <F5> <esc>:NornsRun<cr>
	endif

	if !hasmapto(':NornsSSH', 'ni')
		nmap <buffer> <F6> :NornsSSH<cr>
		imap <buffer> <F6> <esc>:NornsSSH<cr>
	endif
endf

augroup NornsMappingGroup
    autocmd!
	autocmd FileType lua call norns#defaultMappings()
augroup END
