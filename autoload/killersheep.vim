" Implementation of the silly game
" Use :KillKillKill to start
"
" Last Update: 2019 Dec 7

let s:did_init = 0
let s:sound_cmd = ''

func killersheep#Start(sounddir)
  let s:dir = a:sounddir

  if !has('sound')
    if executable('afplay')
      " Probably on Mac
      let s:sound_cmd = 'afplay'
      let g:killersheep_sound_ext = '.mp3'
    elseif executable('paplay')
      " Probably on Unix
      let s:sound_cmd = 'paplay'
      let g:killersheep_sound_ext = '.ogg'
    elseif executable('cvlc')
      " Probably on Unix
      let s:sound_cmd = 'cvlc --play-and-exit'
      let g:killersheep_sound_ext = '.ogg'
    else
      echomsg 'This build of Vim is lacking sound support, you are missing out!'
      sleep 2
    endif
  endif

  if !s:did_init
    let s:did_init = 1
    call s:Init()
  endif

  call s:Clear()
  call s:Intro()
endfunc

func s:NoProp(text)
  return #{text: a:text, props: []}
endfunc

func s:Intro()
  hi SheepTitle cterm=bold gui=bold
  hi introHL ctermbg=cyan guibg=cyan
  call prop_type_delete('sheepTitle')
  call prop_type_add('sheepTitle', #{highlight: 'SheepTitle'})
  call prop_type_delete('introHL')
  call prop_type_add('introHL', #{highlight: 'introHL'})
  let s:intro = popup_create([
	\   #{text: '   The sheep are out to get you!',
	\     props: [#{col: 4, length: 29, type: 'sheepTitle'}]},
	\   s:NoProp(''),
	\   s:NoProp('In the game:'),
	\   #{text: '     h       move cannon left',
	\     props: [#{col: 6, length: 1, type: 'sheepTitle'}]},
	\   #{text: '     l       move cannon right',
	\     props: [#{col: 6, length: 1, type: 'sheepTitle'}]},
	\   #{text: '  <Space>    fire',
	\     props: [#{col: 3, length: 7, type: 'sheepTitle'}]},
	\   #{text: '   <Esc>     quit (colon also works)',
	\     props: [#{col: 4, length: 5, type: 'sheepTitle'}]},
	\   s:NoProp(''),
	\   #{text: 'Now press  s  to start or  x  to exit',
	\     props: [#{col: 12, length: 1, type: 'sheepTitle'},
	\             #{col: 28, length: 1, type: 'sheepTitle'}]},
	\ ], #{
	\   filter: function('s:IntroFilter'),
	\   callback: function('s:IntroClose'),
	\   border: [],
	\   padding: [],
	\   mapping: 0,
	\   drag: 1,
	\   close: 'button',
	\ })
  if has('sound') || len(s:sound_cmd)
    let s:keep_playing = 1
    call s:PlayMusic()
  endif
  call s:IntroHighlight(0)
endfunc

const s:introHL = [[4, 3], [8, 5], [14, 3], [18, 3], [22, 2], [25, 3], [29, 4]]
let s:intro_timer = 0
func s:IntroHighlight(idx)
  let idx = a:idx
  if idx >= len(s:introHL)
    let idx = 0
  endif
  let buf = winbufnr(s:intro)
  call prop_remove(#{type: 'introHL', bufnr: buf}, 1)
  call prop_add(1, s:introHL[idx][0],
	\ #{length: s:introHL[idx][1], bufnr: buf, type: 'introHL'})
  let s:intro_timer = timer_start(300, { -> s:IntroHighlight(idx + 1)})
endfunc

func s:IntroFilter(id, key)
  if a:key == 's' || a:key == 'S'
    call s:Clear()
    let s:round = 0
    let s:ready = popup_create('Get Ready!', #{border: [], padding: [2, 4, 2, 4]})
    call s:BlinkLevel(s:ready, 1)
    call timer_start(s:blink_time * 8, { -> s:NextRound()})
    let s:ready_timer = timer_start(300, {... -> s:ReadySound()})
  elseif a:key == 'x' || a:key == 'X' || a:key == "\<Esc>"
    call s:Clear()
  endif
  return 1
endfunc

func s:ReadySound()
  call s:PlaySound('quack')
  let s:ready_timer = timer_start(s:blink_time * 2, {... -> s:ReadySound()})
endfunc

func s:IntroClose(id, res)
  call s:Clear()
endfunc

" Play the music in a loop
func s:PlayMusic()
  if s:keep_playing
    let fname = s:dir .. '/music' .. g:killersheep_sound_ext
    if has('sound')
      let s:music_id = sound_playfile(fname, {x -> s:PlayMusic()})
    elseif len(s:sound_cmd)
      let s:music_job = job_start(s:sound_cmd .. ' ' .. fname)
      " Detecting job exit is a bit slow, use a timer to loop.
      let s:music_timer = timer_start(14100, {x -> s:PlayMusic()})
    endif
  endif
endfunc

func s:StopMusic()
  let s:keep_playing = 0
  if has('sound')
    call sound_clear()
  elseif len(s:sound_cmd) && exists('s:music_job')
    call job_stop(s:music_job)
    call timer_stop(s:music_timer)
    unlet s:music_job s:music_timer
  endif
endfunc

func s:Init()
  hi def KillerCannon ctermbg=blue guibg=blue
  hi def KillerBullet ctermbg=red guibg=red
  hi def KillerSheep ctermfg=black ctermbg=green guifg=black guibg=green
  hi def KillerSheep2 ctermfg=black ctermbg=cyan guifg=black guibg=cyan
  if &bg == 'light'
    hi def KillerPoop ctermbg=black guibg=black
  else
    hi def KillerPoop ctermbg=white guibg=white
  endif
  hi def KillerPoop ctermbg=black guibg=black
  hi def KillerLevel ctermbg=magenta guibg=magenta
  hi def KillerLevelX ctermbg=yellow guibg=yellow

  if !exists('g:killersheep_sound_ext')
    if has('win32') || len(s:sound_cmd)
      " most systems can play MP3 files
      let g:killersheep_sound_ext = ".mp3"
    else
      " libcanberra defaults to supporting ogg only
      let g:killersheep_sound_ext = ".ogg"
    endif
  endif
endfunc

func s:NextRound()
  call s:Clear()

  let s:round += 1
  let s:sheepcount = 0
  let s:frozen = 0
  call s:ShowBulletSoon()

  " Every once in a while let the next sheep that moves poop.
  let s:wantpoop = 0
  let s:poop_timer = timer_start(s:poop_interval[s:round - 1], {x -> s:WantPoop()}, #{repeat: -1})

  " Create a few sheep to kill.
  let topline = &lines > 50 ? &lines - 50 : 0
  call s:PlaceSheep(topline +  0,  5, 'KillerSheep')
  call s:PlaceSheep(topline +  5, 75, 'KillerSheep2')
  call s:PlaceSheep(topline +  7, 35, 'KillerSheep')
  call s:PlaceSheep(topline + 10, 15, 'KillerSheep')
  call s:PlaceSheep(topline + 12, 70, 'KillerSheep')
  call s:PlaceSheep(topline + 15, 55, 'KillerSheep2')
  call s:PlaceSheep(topline + 20, 15, 'KillerSheep2')
  call s:PlaceSheep(topline + 21, 30, 'KillerSheep')
  call s:PlaceSheep(topline + 22, 60, 'KillerSheep2')
  call s:PlaceSheep(topline + 28, 0, 'KillerSheep')
  call s:ShowLevel(topline)

  let s:canon_id = popup_create(['  /#\  ', ' /###\ ', '/#####\'], #{
	\ line: &lines - 2,
	\ highlight: 'KillerCannon',
	\ filter: function('s:MoveCanon'),
	\ zindex: s:cannon_zindex,
	\ mask: [[1,2,1,1], [6,7,1,1], [1,1,2,2], [7,7,2,2]],
	\ mapping: 0,
	\ })
endfunc

func s:ShowLevel(line)
  let s:levelid = popup_create('Level ' .. s:round, #{
	\ line: a:line ? a:line : 1,
	\ border: [],
	\ padding: [0,1,0,1],
	\ highlight: 'KillerLevel'})
endfunc

func s:MoveCanon(id, key)
  if s:frozen
    return
  endif
  let pos = popup_getpos(a:id)

  let move = 0
  if a:key == 'h' && pos.col > 1
    let move = pos.col - 2
  endif
  if a:key == 'l' && pos.col < &columns - 6
    let move = pos.col + 2
  endif
  if move != 0
    call popup_move(a:id, #{col: move})
    if s:bullet_available
      call popup_move(s:bullet_available, #{col: move + 3})
    endif
  endif

  if a:key == ' '
    call s:Fire(pos.col + 3)
  endif
  if a:key == "\e" || a:key == 'x' || a:key == ':'
    call s:Clear()
  endif
  return a:key != ':'
endfunc

const s:bullet_holdoff = 800
const s:bullet_delay = 30
const s:poop_delay = 60
const s:sheep_anim = 40
const s:sheep_explode = 150
const s:cannon_zindex = 100
const s:bullet_zindex = 80
const s:sheep_zindex = 90
const s:poop_interval = [700, 500, 300, 200, 100]
const s:poop_countdown = 300 / s:sheep_anim 
const s:blink_time = 300

const s:sheepSprite = [[
      \ ' o^^) /^^^^^^\ ',
      \ '==___         |',
      \ '     \  ___  _/',
      \ '      ||   ||  '],[
      \ ' o^^) /^^^^^^\ ',
      \ '==___         |',
      \ '     \_ ____ _/',
      \ '       |    |  '],[
      \ ' o^^) /^^^^^^\ ',
      \ '==___         |',
      \ '     \  ___  _/',
      \ '      ||   ||  '],[
      \ ' o^^) /^^^^^^\ ',
      \ '==___         |',
      \ '     \ _ __ _ /',
      \ '      / |  / | '],[
      \ '        /^^^^^^\ ',
      \ '       |        |',
      \ ' O^^)            ',
      \ 'xx___ _         |',
      \ '      \ _____  _/',
      \ '       ||    ||  '],[
      \ '         /^^^^^^\ ',
      \ '        |        |',
      \ '                  ',
      \ ' O^^)             ',
      \ 'XX___             ',
      \ '       \ __  _  _/',
      \ '        ||    ||  ']]
const s:sheepSpriteMask = [[
      \ ' xxxx xxxxxxxx ',
      \ 'xxxxxxxxxxxxxxx',
      \ '     xxxxxxxxxx',
      \ '      xx   xx  '],[
      \ ' xxxx xxxxxxxx ',
      \ 'xxxxxxxxxxxxxxx',
      \ '     xxxxxxxxxx',
      \ '       x    x  '],[
      \ ' xxxx xxxxxxxx ',
      \ 'xxxxxxxxxxxxxxx',
      \ '     xxxxxxxxxx',
      \ '      xx   xx  '],[
      \ ' xxxx xxxxxxxx ',
      \ 'xxxxxxxxxxxxxxx',
      \ '     xxxxxxxxxx',
      \ '      x x  x x '],[
      \ '        xxxxxxxx ',
      \ '       xxxxxxxxxx',
      \ ' xxxx            ',
      \ 'xxxxx xxxxxxxxxxx',
      \ '      xxxxxxxxxxx',
      \ '       xx    xx  '],[
      \ '         xxxxxxxx ',
      \ '        xxxxxxxxxx',
      \ '                  ',
      \ ' xxxx             ',
      \ 'xxxxx             ',
      \ '       xxxxxxxxxxx',
      \ '        xx    xx  ']]

func GetMask(l)
  let mask = []
  for r in range(len(a:l))
    let s = 0
    let e = -1
    let l = a:l[r]
    for c in range(len(l))
      if l[c] == ' '
	let e = c
      elseif e >= s
	call add(mask, [s+1,e+1,r+1,r+1])
	let s = c + 1
	let e = c
      else
	let s = c + 1
      endif
    endfor
    if e >= s
      call add(mask, [s+1,e+1,r+1,r+1])
    endif
  endfor
  return mask
endfunc

let s:sheepMasks = []
for l in s:sheepSpriteMask
  call add(s:sheepMasks, GetMask(l))
endfor

func s:PlaceSheep(line, col, hl)
  let id = popup_create(s:sheepSprite[0], #{
	\ line: a:line,
	\ col: a:col,
	\ highlight: a:hl,
	\ mask: s:sheepMasks[0],
	\ fixed: 1,
	\ zindex: s:sheep_zindex,
        \ wrap: 0,
	\})
  call setwinvar(id, 'left', 0)
  call setwinvar(id, 'dead', 0)
  call timer_start(s:sheep_anim, {x -> s:AnimSheep(id, 1)})
  let s:sheepcount += 1
  sleep 10m
  return id
endfunc

func s:AnimSheep(id, state)
  if s:frozen
    return
  endif
  let pos = popup_getpos(a:id)
  if pos == {}
    return
  endif
  if getwinvar(a:id, 'dead')
    return
  endif
  let left = getwinvar(a:id, 'left')
  if left == 1
    if pos.line > &lines - 11
      call s:PlaySoundForEnd()
    endif
    call popup_setoptions(a:id, #{pos: 'topleft', col: &columns + 1, line: pos.line + 5})
    let left = 0
  elseif pos.col > 1
    call popup_move(a:id, #{col: pos.col - 1})
  else
    if left == 0
      let left = 15
    endif
    call popup_setoptions(a:id, #{pos: 'topright', col: left - 1})
    let left -= 1
  endif
  let poopid = getwinvar(a:id, 'poopid')
  if poopid
    let poopcount = getwinvar(a:id, 'poopcount')
    if poopcount == 1
      " drop the poop
      call popup_close(poopid)
      call setwinvar(a:id, 'poopid', 0)
      call s:Poop(pos.line + 1, left ? left : pos.col + 12)
    else
      call popup_move(poopid, #{col: left ? left + 1 : pos.col + 14,
	    \ line: pos.line + 1})
    endif
    call setwinvar(a:id, 'poopcount', poopcount - 1)
  endif

  call setwinvar(a:id, 'left', left)
  call popup_settext(a:id, s:sheepSprite[a:state])
  call popup_setoptions(a:id, #{mask: s:sheepMasks[a:state]})
  call timer_start(s:sheep_anim, {x -> s:AnimSheep(a:id, a:state == 3 ? 0 : a:state + 1)})

  if left || pos.col < &columns - 14
    if s:wantpoop && !getwinvar(a:id, 'poopid')
      let s:wantpoop = 0
      call setwinvar(a:id, 'poopcount', s:poop_countdown)
      let poopid = popup_create('x', #{
	\ col: left ? left + 1 : pos.col + 14,
	\ line: pos.line + 1,
	\ highlight: 'KillerPoop',
	\ zindex: s:bullet_zindex,
	\ })
      call setwinvar(a:id, 'poopid', poopid)
    endif
  endif
endfunc

func s:KillSheep(id, state)
  let pos = popup_getpos(a:id)
  if pos == {}
    return
  endif
  let poopid = getwinvar(a:id, 'poopid')
  if poopid
    call popup_close(poopid)
  endif
  let left = getwinvar(a:id, 'left')
  if a:state == 6
    let s:sheepcount -= 1
    if s:sheepcount == 0
      call s:PlaySoundForEnd()
    endif
    call popup_close(a:id)
    return
  endif
  call popup_settext(a:id, s:sheepSprite[a:state])
  call popup_setoptions(a:id, #{mask: s:sheepMasks[a:state], line: pos.line - 1, col: pos.col - 1})
  call timer_start(s:sheep_explode, {x -> s:KillSheep(a:id, a:state + 1)})
  call setwinvar(a:id, 'dead', 1)
endfunc

func s:WantPoop()
  let s:wantpoop = 1
endfunc

func s:Poop(line, col)
  if s:frozen
    return
  endif
  let id = popup_create(['|', '|'], #{
	\ col: a:col,
	\ line: a:line,
	\ highlight: 'KillerPoop',
	\ zindex: s:bullet_zindex,
	\ })
  call s:PlaySound('poop')
  call timer_start(s:poop_delay, {x -> s:MovePoop(x, id)}, #{repeat: -1})
endfunc

func s:MovePoop(x, id)
  if s:frozen
    return
  endif
  let pos = popup_getpos(a:id)
  if pos == {}
    call timer_stop(a:x)
    return
  endif
  if pos.line >= &lines - 1
    call popup_close(a:id)
    call timer_stop(a:x)
  else
    call popup_move(a:id, #{line: pos.line + 2})
    let winid = popup_locate(pos.line + 2, pos.col)
    " TODO: no hit if no overlap
    if winid != 0 && winid == s:canon_id
      call s:PlaySoundForEnd()
    endif
  endif
endfunc

func s:ShowBulletSoon()
  let s:bullet_available = 0
  let s:bullet_timer = timer_start(s:bullet_holdoff, {x -> ShowBullet()})
endfunc

func ShowBullet()
  if s:frozen
    return
  endif
  let s:bullet_timer = 0
  let pos = popup_getpos(s:canon_id)
  let s:bullet_available = popup_create(['|', '|'], #{
	\ col: pos.col + 3,
	\ line: &lines - 3,
	\ highlight: 'KillerBullet',
	\ zindex: s:bullet_zindex,
	\ })
endfunc

func s:Fire(col)
  if s:frozen
    return
  endif
  if !s:bullet_available
    return
  endif
  let id = s:bullet_available
  call s:ShowBulletSoon()

  call s:PlaySound('fire')
  call timer_start(s:bullet_delay, {x -> s:MoveBullet(x, id)}, #{repeat: -1})
endfunc

func s:MoveBullet(x, id)
  if s:frozen
    return
  endif
  let pos = popup_getpos(a:id)
  if pos == {}
    call timer_stop(a:x)
    return
  endif
  if pos.line <= 2
    call popup_close(a:id)
    call timer_stop(a:x)
  else
    call popup_move(a:id, #{line: pos.line - 2})
    let winid = popup_locate(pos.line - 2, pos.col)
    if winid != 0 && winid != a:id
      call s:KillSheep(winid, 4)
      if s:sheepcount == 1
	let s:frozen = 1
      endif
      call s:PlaySound('beh')
      call popup_close(a:id)
    endif
  endif
endfunc

func s:PlaySound(name)
  let fname = s:dir .. '/' .. a:name .. g:killersheep_sound_ext
  if has('sound')
    call sound_playfile(fname)
  elseif len(s:sound_cmd)
    call system(s:sound_cmd .. ' ' .. fname .. '&')
  endif
endfunc

func s:BlinkLevel(winid, on)
  call popup_setoptions(a:winid, #{highlight: a:on ? 'KillerLevelX': 'KillerLevel'})
  let s:blink_timer = timer_start(s:blink_time, {x -> s:BlinkLevel(a:winid, !a:on)})
endfunc

func s:PlaySoundForEnd()
  let s:frozen = 1
  if s:sheepcount == 0
    call s:PlaySound('win')
    if s:round == 5
      echomsg 'Amazing, you made it through ALL levels! (did you cheat???)'
      let s:end_timer = timer_start(2000, {x -> s:Clear()})
    else
      call popup_settext(s:levelid, 'Level ' .. (s:round + 1))
      call s:BlinkLevel(s:levelid, 1)
      call timer_start(2000, {x -> s:NextRound()})
    endif
  else
    call s:StopMusic()
    call s:PlaySound('fail')
    let s:end_timer = timer_start(4000, {x -> s:Clear()})
  endif
endfunc

func s:Clear()
  call s:StopMusic()
  if s:intro_timer
    call timer_stop(s:intro_timer)
    let s:intro_timer = 0
  endif
  call popup_clear()
  if get(s:, 'end_timer', 0)
    call timer_stop(s:end_timer)
    let s:end_timer = 0
  endif
  if get(s:, 'ready_timer', 0)
    call timer_stop(s:ready_timer)
    let s:ready_timer = 0
  endif
  if get(s:, 'poop_timer', 0)
    call timer_stop(s:poop_timer)
    let s:poop_timer = 0
  endif
  if get(s:, 'bullet_timer', 0)
    call timer_stop(s:bullet_timer)
    let s:bullet_timer = 0
  endif
  if get(s:, 'blink_timer', 0)
    call timer_stop(s:blink_timer)
    let s:blink_timer = 0
  endif
endfunc
