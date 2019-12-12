" Silly game to show off new features in Vim 8.2.
" Last Update: 2019 Dec 7
"
" Requirements:
" - feature +textprop
" - feature +sound or command "afplay", "paplay" or "cvlc".
" - Vim patch level 8.1.1705
" - terminal with at least 45 lines
"
" :KillKillKill  start game
"	      l  move cannon right
"	      h  move cannot left
"	<Space>  fire
"	  <Esc>  exit game
"
" By default plays .ogg files on Unix, .mp3 files on MS-Windows.
" Set g:killersheep_sound_ext to overrule, e.g.:
"   let g:killersheep_sound_ext = '.mp3'
"
" Thanks to my colleagues Greg, Martijn and Shannon for the sounds!
"

if get(g:, 'loaded_killersheep', 0)
  finish
endif
let g:loaded_killersheep = 1

let s:dir = expand('<sfile>:h')

command KillKillKill call s:StartKillerSheep()

func s:StartKillerSheep()
  " Check features before loading the autoload file to avoid error messages.
  if !has('patch-8.1.1705')
    call s:Sorry('Sorry, This build of Vim is too old, you need at least 8.1.1705')
    return
  endif
  if !has('textprop')
    call s:Sorry('Sorry, This build of Vim is lacking the +textprop feature')
    return
  endif
  if &lines < 45
    call s:Sorry('Need at least a terminal height of 45 lines')
    return
  endif

  " The implementation is in an autoload file, so that this plugin doesn't
  " take much time when not being used.
  call killersheep#Start(s:dir)
endfunc

func s:Sorry(msg)
  echohl WarningMsg
  echo a:msg
  echohl None
endfunc
