# killersheep

Silly game to show off the new features of Vim 8.2:
-   Popup windows with colors and mask
-   Text properties to highlight text
-   Sound

Installation
------------

Use your favorite plugin manager.

For example, using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'vim/killersheep'
```

Or download the files using the zip archive, and unpack them in your
pack directory `~/.vim/pack/mine/opt/killersheep/`.
Then load the pack manually with:

```vim
packadd killersheep
```

Or put this in your vimrc:

```vim
packadd! killersheep
```

How to play
-----------

First of all: make sure you can hear the sound (or put on your headphones if
you don't want your friends/colleagues to find out what you are doing).

```vim
:KillKillKill
```

Or, if you don't have conflicting commands, just:

```vim
:Kill
```

In the game:

| Key     | Description       |
| ------- | ----------------- |
| l       | move cannon right |
| h       | move cannon left  |
| Space   | fire cannon       |
| Esc     | exit game         |


Requirements
------------

-   Vim 8.2
-   feature +textprop
-   feature +sound or command "afplay", "paplay" or "cvlc".
-   terminal with at least 45 lines
