# vim-norns
![norns in action](norns-in-action.jpg)

A rough (and work in progress) plugin for working remotely on scripts/projects for the monome [norns platform](https://monome.org/docs/norns/). It makes use of the websocketed REPL available in [maiden](https://monome.org/docs/norns/maiden/)

Heavily inspired by  simonvanderveldt's work in atom:
https://github.com/monome/norns/issues/1067

And David Granstöm's scnvim:
github.com/davidgranstrom/scnvim

## Dependencies
Unfortunately, this plugin has a lot of dependencies:

- rlwrap
- websocat
- sshpass
- rsync

Fortunately, if you are on Arch Linux or Manjaro, they are easy to install using yay: 
`yay -S rlwrap websocat sshpass rsync`

## Usage
Run the command `:NornsStart` to start the connection and REPL

Then, when you make a change to your files you can run `:RunOnNorns` to sync your project to the one on norns.

These can of course be mapped to keys like so:
```
fun! NornsMappings()
	nnoremap <C-e> :RunOnNorns<cr>
	nnoremap <F1> :NornsStart<cr>
endf

augroup nornslua
    autocmd!
    autocmd FileType lua call LuaStuff()
augroup end
```

### IP
The plugin expect norns to be on your local network as `norns.local` but this can be overwritten by setting the variable `g:norns_ip` to something else, like: `let g:norns_ip="192.168.0.70"`

At some point, this will be automated somehow.


