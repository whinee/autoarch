#!/bin/bash

# making directories
mkdir -p ~/pix ~/dl ~/mc ~/stuff ~/.cache/zsh

# setting fonts
curl -L "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures/Regular/complete/JetBrains%20Mono%20Regular%20Nerd%20Font%20Complete%20Mono.ttf" -o ~/.local/share/fonts/JetBrains\ Mono\ Regular\ Nerd\ Font\ Complete\ Mono.ttf

# setting prompt
cd ~/
git clone https://github.com/spaceship-prompt/spaceship-prompt.git --depth=1 ~/.config/zsh/functions/spaceship/
ln -sf /home/${user}/.config/zsh/functions/spaceship/spaceship.zsh /home/${user}/.config/zsh/functions/prompt_spaceship_setup

# compiling clipmenu
cd /tmp
git clone https://github.com/cdown/clipmenu
cd clipmenu
doas make install

# compiling mpv-mpris
cd /tmp
git clone https://github.com/hoyon/mpv-mpris
cd mpv-mpris
doas make install

# compiling dmenu
cd ~/stuff/dmenu
git remote set-url origin git@github.com:71zenith/dmenu
make
doas make install

# compiling slock
cd ~/stuff/slock
git remote set-url origin git@github.com:71zenith/slock
make
doas make install

# compiling st
cd ~/stuff/st
git remote set-url origin git@github.com:71zenith/st
make
doas make install