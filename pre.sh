#!/bin/sh

###############################################################################
#                                                                             #
# autoarch: auto-install stuff                                                #
# Copyright (C) 2022 71zenith                                                 #
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

###############################################################################

# SET VARIABLES

###############################################################################

## COLORS
green=$(tput setaf 2)
reset=$(tput sgr0)

## OPTIONS
user="whine"
host="blackspace"
timezone="Asia/Manila"
boot="/dev/sda1"
swap="/dev/sda2"
root="/dev/sda3"

###############################################################################



###############################################################################

# SETUP THE DISKS

###############################################################################

## PARTITION DISK
fdisk /dev/sda << EOF
g
n


+512M
n


+16G
n



t
1
1
t
2
19
w
EOF

#══════════════════════════════════════════════════════════#
## SETUP PARTITIONS
#══════════════════════════════════════════════════════════#

### BOOT
mkfs.fat -F32 "$boot"
mkdir /mnt/boot
mount  /mnt/boot

### SWAP
mkswap "$swap"
swapon "$swap"
swaplabel -L Swap "$swap"

### ROOT
yes | mkfs.ext4 "$root" -L "Arch"
mount "$root" /mnt

#══════════════════════════════════════════════════════════#

###############################################################################



###############################################################################

# PACMAN!

###############################################################################

## PULL GOOD MIRRORS
reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt/etc/pacman.d/
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

## ADD chaotic-aur REPO
pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
pacman-key --lsign-key FBA220DFC880C036
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

## MODIFY pacman.conf
sed -e 's/CheckSpace/#CheckSpace/' -e 's/#ParallelDownloads\ =\ 5/ParallelDownloads = 25\nILoveCandy/' -e 's/#Color/Color/' -e 's/#VerbosePkgLists/VerbosePkgLists/' -e '$a [chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' -i /etc/pacman.conf

## SETUP GPG FOR sublime-text
curl -O https://download.sublimetext.com/sublimehq-pub.gpg && pacman-key --add sublimehq-pub.gpg && pacman-key --lsign-key 8A8F901A && rm sublimehq-pub.gpg
echo -e "\n[sublime-text]\nServer = https://download.sublimetext.com/arch/stable/x86_64" >> /etc/pacman.conf

## INSTALL BASE SYSTEM AND PACKAGES
pacstrap /mnt base linux linux-firmware xorg-server xorg-xinit xorg-xprop xorg-xset xorg-xsetroot
# pacstrap /mnt alacritty base base-devel bat bleachbit blueman bluez ccls chromium clipnotify cron dash dunst ffmpeg flameshot flatpak fuse gcc gcolor3 git gnome-keyring libreoffice-fresh linux-lts make man man-pages moc moreutils mpv nano networkmanager noto-fonts-emoji npm obs-studio opendoas openssh patch pkgconf playerctl pop-gtk-theme pop-icon-theme pulseaudio pulseaudio-alsa pulseaudio-bluetooth pulsemixer rust scrot shellcheck spectacle squashfuse sublime-text sxhkd sxiv terminus-font ttf-hanazono ttf-joypixels unzip vivaldi vivaldi-ffmpeg-codecs wget xorg-server xorg-xinit xorg-xprop xorg-xset xorg-xsetroot xsel xwallpaper yajl yt-dlp zathura-pdf-poppler zip zsh

###############################################################################



# GENERATE fstab
genfstab -U /mnt >> /mnt/etc/fstab



###############################################################################

# CHROOT

###############################################################################

arch-chroot /mnt << EOF

#══════════════════════════════════════════════════════════#
## SETUP STUFF
#══════════════════════════════════════════════════════════#

pacman -Syy --noconfirm dosfstools efibootmgr grub mtools os-prober
reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
mkdir /boot/EFI
mkdir /boot/EFI
mount $boot /boot/EFI
mount $boot /boot/EFI
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
grub-mkconfig -o /boot/grub/grub.cfg

### DOWNLOAD xorg.conf AND SET IT UP
curl -L https://github.com/whinee/autoarch/raw/master/xorg.conf > /etc/X11/xorg.conf

### SET TIMEZONE AND HARDWARE CLOCK
ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime
hwclock --systohc

### SET LANGUAGE
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

### SET USER
useradd -m "${user}" -G wheel,audio,video
echo "$user:$1" | chpasswd
echo "root:$1" | chpasswd

### SET HOSTNAME AND HOSTS FILE
echo "${host}" >> /etc/hostname
echo "127.0.0.1    localhost
::1          localhost
127.0.1.1    ${host}" >> /etc/hosts

### SET UP DOAS AS REPLACEMENT FOR SUDO
echo "permit :wheel
permit nopass :wheel" >> /etc/doas.conf
ln -s /bin/doas /bin/sudo

### SET ENV VARS
echo "ZDOTDIR=/home/${user}/.config/zsh" >> /etc/environment

### REPLACE sh WITH dash
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

### SET DEFAULT SHELL TO zsh
chsh "${user}" -s /bin/zsh

#══════════════════════════════════════════════════════════#

#══════════════════════════════════════════════════════════#
## ENABLE STUFF
#══════════════════════════════════════════════════════════#

### HIBERNATION
sed -e 's/^HOOKS.*/HOOKS=(base udev autodetect keyboard modconf block filesystems resume fsck)/' -i /etc/mkinitcpio.conf
mkinitcpio -p linux-lts

### SERVICES
systemctl enable NetworkManager
systemctl enable cronie.service
systemctl enable bluetooth.service

#══════════════════════════════════════════════════════════#

#══════════════════════════════════════════════════════════#
## INSTALL STUFF
#══════════════════════════════════════════════════════════#

#—————————————————————————————————————#
### FROM SOURCE
#—————————————————————————————————————#

#-----------------#
#### /tmp
#-----------------#

cd /tmp/

##### PACKAGE QUERY
git clone https://aur.archlinux.org/package-query.git
cd package-query/
makepkg -si --noconfirm
cd .. && rm -rf package-query

##### PYTHON
# NOTE: enable if necessary
# mkdir python/
# wget -O python.tgz https://www.python.org/ftp/python/3.10.2/Python-3.10.2.tgz
# tar xzf python.tgz --directory python --strip-components 1
# cd python/
# ./configure
# make
# make install
# cd .. && rm -rf python.tgz python/

##### YAOURT
git clone https://aur.archlinux.org/yaourt.git
cd yaourt/
makepkg -si --noconfirm
echo -e "NOCONFIRM=1\nBUILD_NOCONFIRM=1\nEDITFILES=0" >> ~/.config/.yaourtrc
cd .. && rm -rf yaourt/

##### NPM
curl -qL https://www.npmjs.com/install.sh | sh

##### BETTER DISCORD
git clone https://github.com/BetterDiscord/BetterDiscord.git
npm install
npm run build
npm run inject canary
cd .. && rm -rf BetterDiscord/

##### SNAP
git clone https://aur.archlinux.org/snapd.git
cd snapd
makepkg -si --noconfirm
systemctl enable --now snapd.socket
ln -s /var/lib/snapd/snap /snap
modprobe loop
cd .. && rm -rf snapd

cd ~

#-----------------#

#-----------------#
#### /opt
#-----------------#

cd /opt

##### YAY
git clone https://aur.archlinux.org/yay.git
chown -R "$USER:" yay/
cd yay
makepkg -si --noconfirm

cd ~

#-----------------#

#-----------------#
#### MISCELLANEOUS
#-----------------#

#### PROMPT
git clone https://github.com/spaceship-prompt/spaceship-prompt.git --depth=1 ~/.config/zsh/functions/spaceship/
ln -sf /home/${user}/.config/zsh/functions/spaceship/spaceship.zsh /home/${user}/.config/zsh/functions/prompt_spaceship_setup

#-----------------#

#—————————————————————————————————————#

### THROUGH YAOURT
yes | yaourt -S discord_arch_electron discord-canary-electron-bin discord-ptb insomnia pamac-aur scrcpy visual-studio-code-bin

### THROUGH SNAP
snap install drawio

#══════════════════════════════════════════════════════════#

## CLEANUP & EXIT
rm -rf /home/${user}/{.bash_history,.bash_profile,.bash_logout,.bashrc}
EOF

################################################################################

# UNMOUNT & REBOOT
umount -R /mnt
shutdown now
