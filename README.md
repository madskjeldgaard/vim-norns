# vim-norns
![norns in action](norns-in-action.jpg)

A nvim plugin for working remotely with the monome [norns platform](https://monome.org/docs/norns/). It makes use of the websocketed REPL available in [maiden](https://monome.org/docs/norns/maiden/) and a bunch of nice unix tools to make communication between norns and host computer super easy. 

When working on projects, it works by syncing a local folder on your computer to an equivalent folder on the norns and allowing you to execute code remotely.

It also has features to make it easy to work with the norns file system from your host computer. From within vim you can ssh into the norns, you can easily download files from it to your host computer etcetera.

Heavily inspired by  simonvanderveldt's work in atom:
https://github.com/monome/norns/issues/1067

And David Granstöm's scnvim:
github.com/davidgranstrom/scnvim

## Installation

Using [vim-plug](https://github.com/junegunn/vim-plug):
`Plug 'madskjeldgaard/vim-norns'`

## Dependencies
The plugin was made for NVIM

Unfortunately, this plugin has a lot of dependencies:

- rlwrap
- websocat
- sshpass
- rsync

Optional:
- Fzf / vim-fzf

Fortunately, if you are on Arch Linux or Manjaro, they are easy to install using yay: 
`yay -S rlwrap websocat sshpass rsync fzf`

## Usage
See `:h norns` for information on usage

### Commands
`:NornsStart` 	
Open the REPL and establish contact

`:NornsFind` 	
Find your Norns on the local network and set global ip for it in vim

`:NornsRun` 	
Run the current project

`:NornsSync` 	
Manually sync local project with folder on Norns (normally not needed)

`:NornsSSH` 	
Open terminal split ssh'ing into the norns

`:NornsReference` 	
Open reference in browser

`:NornsStudies` 	
Open Norns studies in browser

`:NornsEngineCommands` 	
List all commands for the currently selected engine

`:NornsGreet` 	
Display greeting on Norns

`:NornsGetTapes` 	
Download tapes from norns to this computer (will be put in "~/Downloads" by default, this can be changed by setting `let g:norns_download_destination = "~/Downloads/"`)

`:NornsGetReels` 	
Same as above but for the reels folder

### IP
The plugin expect norns to be on your local network as `norns.local` but this can be overwritten by setting the variable `g:norns_ip` to something else, like: `let g:norns_ip="192.168.0.70"`

The plugin comes with a helper function to aid in doing this: `:NornsFind`. This will display a list of all ip addresses on your network and by choosing one of these, the variable is set.
