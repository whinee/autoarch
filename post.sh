#!/bin/bash

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

# downloading postpost.sh install script and putting it in home folder of user
curl -L https://github.com/whinee/autoarch/raw/master/postpost.sh > /home/${user}/postpost.sh

# running the script as the user
su -c "sh /home/${user}/postpost.sh" "${user}"

# changing the default shell of user to zsh
chsh "${user}" -s /bin/zsh

# cleanup
rm -rf /home/${user}/{.bash_history,.bash_profile,.bash_logout,.bashrc,postpost.sh}
