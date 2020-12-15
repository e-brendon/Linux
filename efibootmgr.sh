#!/bin/bash
printf '\n[repo-ck] \nServer = https://mirror.lesviallon.fr/$repo/os/$arch \nServer = http://repo-ck.com/$arch' >> /etc/pacman.conf
efibootmgr -q --disk /dev/nvme0n1 --part 1 --create --label "Arch Linux" --loader "\vmlinuz-linux-ck-skylake" --unicode 'root=PARTUUID="7f6cc65e-397b-ea4f-ac51-a8fe5b5e9ed0" rw initrd=\initramfs-linux-ck-skylake.img quiet rd.udev.log-priority=0 pci=noaer nowatchdog' --verbose
