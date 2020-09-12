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

let g:norns_download_destination = "~/Downloads/"
let g:norns_split_direction="t" " v(ertical), h(orizontal), t(ab)

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
command! NornsReboot call norns#reboot()
command! NornsRestart call norns#restart()
command! NornsHalt call norns#halt()
command! NornsReference call norns#openReference()
command! NornsStudies call norns#learn()
command! NornsEngineCommands call norns#listEngineCommands()
command! NornsFind call norns#findNorns()
command! NornsSync call norns#syncToNorns()
command! NornsGreet call norns#greeting()
command! NornsSSH call norns#ssh()
command! NornsGetTapes call norns#getTapes()
command! NornsGetReels call norns#getReels()

"""""""""""""""""""""""
"  remote os control  "
"""""""""""""""""""""""
fun! norns#sshpass()
	return printf('sshpass -p %s', g:norns_ssh_pass)	
endf

fun! norns#remotely_execute(command)
	let cmd = printf("! %s ssh we@%s '%s'", norns#sshpass(), g:norns_ip, a:command)
	execute cmd
endf

fun! norns#restart()
	let cmd = "bash /home/we/norns/stop.sh; sleep 5 && bash /home/we/norns/start.sh"
	call norns#remotely_execute(cmd)
endf

fun! norns#reboot()
	call norns#remotely_execute("sudo reboot")
endf

fun! norns#halt()
	call norns#remotely_execute("sudo halt")
endf

"""""""""""""""""""""""""""""""""""
"  Syncronizing and running code  "
"""""""""""""""""""""""""""""""""""
fun! norns#getNornsProjectDir()
	let g:norns_project_path = expand("%:p:h")	
	let g:norns_project_basename = expand("%:p:h:t")	
endf

fun! norns#syncToNorns()
	call norns#getNornsProjectDir()
	let cmd = printf('%s rsync -a --delete --exclude=".*" --delete-excluded %s we@%s:/home/we/dust/code/', norns#sshpass(), g:norns_project_path, g:norns_ip)
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

	" The base command for the remote repl in maiden
	let cmd = printf("rlwrap websocat --protocol bus.sp.nanomsg.org ws://%s:5555", g:norns_ip)

	" Create split for terminal
	if g:norns_split_direction == "v"
		execute ":vnew"	
	elseif g:norns_split_direction == "h"
		execute ":hnew"	
	else
		execute ":tabnew"
	endif

	" Open terminal and save buffer id in global variable
	let g:norns_chan_id = termopen(cmd)

	" Display greeting on norns
	call norns#greeting()
endf
""""""""""""""
"  Download  "
""""""""""""""
fun! norns#download(nornsFolder)
	let cmd = printf("%s scp -v -r we@%s:%s %s", norns#sshpass(), g:norns_ip, a:nornsFolder, g:norns_download_destination)

	" Create split for terminal
	if g:norns_split_direction == "v"
		execute ":vnew"	
	elseif g:norns_split_direction == "h"
		execute ":hnew"	
	else
		execute ":tabnew"
	endif

	execute ":terminal " . cmd
endf

fun! norns#getTapes()
	call norns#download("/home/we/dust/audio/tape")
endf

fun! norns#getReels()
	call norns#download("/home/we/dust/audio/reels")
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
		silent execute cmd
	else
		echoe("norns help browser not set")
	endif
endf

fun! norns#openNornsUrl(key)
	let url = g:norns_urls[a:key]
	let browser = "firefox"
	exe printf("! " . browser . " %s", url)
endf

fun! norns#learn()
	call fzf#run({'sink': function('norns#openNornsUrl'), 'source': sort(keys(g:norns_urls))})
endf

let g:norns_urls = {
	\'norns scripting faq': 'https://monome.org/docs/norns/faq/',
	\'norns scripting reference': 'https://monome.org/docs/norns/script-reference/',
	\'norns study 1: many tomorrows (variables, simple maths, keys + encoders)': 'https://monome.org/docs/norns/study-1/',
	\'norns study 2: patterning (screen drawing, for/while loops, tables)': 'https://monome.org/docs/norns/study-2/',
	\'norns study 3: spacetime (functions, parameters, time)': 'https://monome.org/docs/norns/study-3/',
	\'norns study 4: physical (grids+midi)': 'https://monome.org/docs/norns/study-4/',
	\'norns study 5: streams (system polls, osc, file storage)': 'https://monome.org/docs/norns/study-5/',
	\'softcut studies': 'https://monome.org/docs/norns/softcut/',
	\'clock studies': 'https://monome.org/docs/norns/clocks/',
	\'neaunoire norns tutorial': 'https://llllllll.co/t/norns-tutorial/23241',
	\'Programming in lua (first edition)': 'https://www.lua.org/pil/contents.html',
	\'learn lua in 15 minutes': 'http://tylerneylon.com/a/learn-lua/', 
	\'llllllll.co': 'https://llllllll.co/tag/norns',
	\'norns supercollider and lua part 1': 'https://medium.com/@kidsputnik/monome-norns-supercollider-and-lua-part-1-d97646306973'
	\}

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
	let cmd = printf("%s ssh we@%s", norns#sshpass(), g:norns_ip)
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
