#!/bin/sh

###############################################################################
#                                                                             #
# autoarch: auto-install stuff                                                #
# Copyright (C) 2022 zenith71                                                 #
# Copyright (C) 2022 whinee                                                   #
#                                                                             #
# This program is free software: you can redistribute it and/or modify        #
# it under the terms of the GNU General Public License as published by        #
# the Free Software Foundation, either version 3 of the License, or           #
# (at your option) any later version.                                         #
#                                                                             #
# This program is distributed in the hope that it will be useful,             #
# but WITHOUT ANY WARRANTY; without even the implied warranty of              #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               #
# GNU General Public License for more details.                                #
#                                                                             #
# You should have received a copy of the GNU General Public License           #
# along with this program.  If not, see <https://www.gnu.org/licenses/>.      #
#                                                                             #
###############################################################################

# Setting the tty font
setfont ter-122n

# colors
green=$(tput setaf 2)
reset=$(tput sgr0)

# options
user="whine"
host="blackspace"
timezone="Asia/Manila"
root="/dev/sdb3"
boot="/dev/sdb1"
home="/dev/sdb4"
swap="/dev/sdb2"
echo "Enter password"
read pass
clear

# Changing some settings in /etc/pacman.conf
sed -e 's/CheckSpace/#CheckSpace/' -e 's/#ParallelDownloads\ =\ 5/ParallelDownloads = 10\nILoveCandy/' -e 's/#Color/Color/' -e 's/#VerbosePkgLists/VerbosePkgLists/' -i /etc/pacman.conf

# pulling down good mirrors
reflector --country China,India --latest 20 --sort rate --save /etc/pacman.d/mirrorlist 2> /dev/null

# preparing the disks
mkfs.fat -F32 "$boot"
mkswap "$swap" -L "Swap"
yes | mkfs.ext4 "$root" -L "Arch"
yes | mkfs.ext4 "$home"
mount "$root" /mnt
mkdir /mnt/{boot,home}
mount "$boot" /mnt/boot
mount "$home" /mnt/home
swapon "$swap"

# installing the base system
pacstrap /mnt amd-ucode base bspwm git linux-lts man moc neovim networkmanager nvidia-lts opendoas playerctl pulseaudio pulseaudio-alsa pulsemixer scrot \
  openssh sxhkd sxiv terminus-font ttf-hanazono xorg-server man-pages xorg-xinit xorg-xprop xorg-xset xorg-xsetroot xwallpaper zathura-pdf-poppler cron \
  pop-gtk-theme pop-icon-theme xsel make pkgconf clipnotify ttf-joypixels discord dunst ffmpeg yt-dlp zip unzip mpv dash shellcheck gcc bluez blueman \
  pulseaudio-bluetooth alacritty zsh bat ueberzug ccls patch newsboat

# generating the fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# putting the mirrorlist to system so that i don't need to run it again
cp -f /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

# setting /mnt
arch-chroot /mnt /bin/bash -e <<-EOF
# setting the locale and timezone
ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# setting the hostname and hosts file
echo "${host}" >> /etc/hostname
echo -e "127.0.0.1    localhost\n::1          localhost\n127.0.1.1    ${host}" >> /etc/hosts

# setting up doas
echo "permit :wheel
permit nopass :wheel" >> /etc/doas.conf

# changing /bin/sh to dash
ln -sfT dash /usr/bin/sh
echo "[Trigger]
Type = Package
Operation = Install
Operation = Upgrade
Target = bash

[Action]
Description = Re-pointing /bin/sh symlink to dash...
When = PostTransaction
Exec = /usr/bin/ln -sfT dash /usr/bin/sh
Depends = dash" > /usr/share/libalpm/hooks/dashbinsh.hook

# setting up systemd-boot
bootctl install
echo -e "default arch.conf\ntimeout 0" > /boot/loader/loader.conf
echo -e "title   Arch Linux\nlinux   /vmlinuz-linux-lts\ninitrd  /amd-ucode.img\ninitrd  /initramfs-linux-lts.img\noptions root=\"LABEL=Arch\" resume=\"LABEL=Swap\" rw" > /boot/loader/entries/arch.conf

# setting ZDOTDIR
echo "ZDOTDIR=/home/${user}/.config/zsh" >> /etc/environment

# enabling services
systemctl enable NetworkManager
systemctl enable cronie.service
systemctl enable bluetooth.service

# setting the user
useradd -m "${user}" -G wheel,audio,video
echo "$user:$pass" | chpasswd
echo "root:$pass" | chpasswd

# adding chaotic-aur repo and downloading packages
pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
pacman-key --lsign-key FBA220DFC880C036
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
sed -e 's/CheckSpace/#CheckSpace/' -e 's/#ParallelDownloads\ =\ 5/ParallelDownloads = 10\nILoveCandy/' -e 's/#Color/Color/' -e 's/#VerbosePkgLists/VerbosePkgLists/' -e '$a [chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' -i /etc/pacman.conf
pacman -Sy --noconfirm zoom polybar lf brave-bin picom-ibhagwan-git
yes | pacman -S libxft-bgra

# setting mkinitcpio for hibernating
sed -e 's/^HOOKS.*/HOOKS=(base udev autodetect keyboard modconf block filesystems resume fsck)/' -e 's/vim.*/vim:ft=sh/' -i /etc/mkinitcpio.conf
mkinitcpio -p linux-lts

# downloading and putting xorg.conf to /etc/X11
curl -L https://github.com/whinee/autoarch/raw/master/xorg.conf > /etc/X11/xorg.conf

# running the script as the user
su "${user}" -c "/bin/bash -e <<-EOE
# setting up cron jobs
echo -e "*/30 * * * *  /home/${user}/.local/bin/notify_update\n*/30 * * * *  /usr/bin/newsboat -x reload" | crontab -

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

EOE

# changing the default shell of user to zsh
chsh "${user}" -s /bin/zsh

# cleanup
rm -rf /home/${user}/{.bash_history,.bash_profile,.bash_logout,.bashrc,postpost.sh}
EOF

# rebooting the system
reboot
