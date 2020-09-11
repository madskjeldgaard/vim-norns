function! s:check_fzf() abort
	if executable('fzf') 
		call health#report_ok('fzf is installed')
	else
		call health#report_error('FZF executable not found')
	endif
endfunction

function! s:check_rlwrap() abort
	if executable('rlwrap') 
		call health#report_ok('rlwrap is installed')
	else
		call health#report_error('rlwrap executable not found')
	endif
endfunction

function! s:check_websocat() abort
	if executable('websocat') 
		call health#report_ok('websocat is installed')
	else
		call health#report_error('websocat executable not found')
	endif
endfunction

function! s:check_sshpass() abort
	if executable('sshpass') 
		call health#report_ok('sshpass is installed')
	else
		call health#report_error('sshpass executable not found')
	endif
endfunction

function! s:check_rsync() abort
	if executable('rsync') 
		call health#report_ok('rsync is installed')
	else
		call health#report_error('rsync executable not found')
	endif
endfunction

function! s:check_sed() abort
	if executable('sed') 
		call health#report_ok('sed is installed')
	else
		call health#report_error('sed executable not found')
	endif
endfunction

function! s:check_awk() abort
	if executable('awk') 
		call health#report_ok('awk is installed')
	else
		call health#report_error('awk executable not found')
	endif
endfunction

function! health#norns#check() abort
	call health#report_start('norns')
	call s:check_fzf()
	call s:check_rlwrap()
	call s:check_websocat()
	call s:check_sshpass()
	call s:check_rsync()
	call s:check_sed()
	call s:check_awk()
endfunction


