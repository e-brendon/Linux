#!/bin/bash

myhostname="archlinux"
myusername="unckros"

# Função para inserir comandos no sistema montando em /mnt
arch_chroot(){
    arch-chroot /mnt /bin/bash -c "${1}"
}
#repositório do kernel CK
echo [repo-ck] \nServer = https://mirror.lesviallon.fr/$repo/os/$arch \nServer = http://repo-ck.com/$arch >> /etc/pacman.conf
pacman-key -r 5EE46C4C --keyserver hkp://pool.sks-keyservers.net && pacman-key --lsign-key 5EE46C4C

mkfs.fat -F32 -b BOOT /dev/nvme0n1p1
mkfs.f2fs -l ROOT -O extra_attr,inode_checksum,sb_checksum,compression /dev/nvme0n1p2

mount /dev/nvme0n1p2 /mnt
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot

#btrfs sub cr /mnt/root
#btrfs sub cr /mnt/root/@
#btrfs sub cr /mnt/root/@home
#btrfs sub cr /mnt/root/@snapshots
#btrfs sub list /mnt/; sleep 8;
#umount /mnt
#mount -o defaults,noatime,space_cache,ssd,compress=zstd,subvol=/arch/@ /dev/nvme0n1p2 /mnt
#mkdir /mnt/home;
#mkdir /mnt/.snapshots;
#mount -o defaults,noatime,space_cache,ssd,compress=zstd,subvol=/arch/@home /dev/nvme0n1p2 /mnt/home
#mount -o defaults,noatime,space_cache,ssd,compress=zstd,subvol=/arch/@snapshots /dev/sda2 /mnt/.snapshots

pacstrap /mnt base base-devel linux-firmware nano vim efibootmgr linux-ck-skylake linux-ck-skylake-headers dhcpcd tlp --noconfirm
arch_chroot "pacman-key -r 5EE46C4C --keyserver hkp://pool.sks-keyservers.net && pacman-key --lsign-key 5EE46C4C";

genfstab -U -p /mnt >> /mnt/etc/fstab
cp /etc/pacman.conf /mnt/etc/pacman.conf

# Locale, timedate. Keyboard Layout
arch_chroot "ln -sf /usr/share/zoneinfo/America/Cuiaba /etc/localtime";
arch_chroot "hwclock --systohc";

# Otimizar os locales do locale.gen com expressões regulares.
arch_chroot "nano /etc/locale.gen";
arch_chroot "locale-gen";
arch_chroot "echo KEYMAP=br-abnt2 >> /etc/vconsole.conf"; #localectl set-keymap --no-convert br-abnt2
arch_chroot "localectl set-x11-keymap br abnt2";

# Hosts
arch_chroot "echo $myhostname >> /etc/hostname";
arch_chroot "printf '\n127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$myhostname.localdomain	$myhostname' >> /etc/hosts"; # nano /etc/hosts
#deve ficar assim:
# 127.0.0.1	localhost
# ::1		localhost
# 127.0.1.1	$myhostname.localdomain	$myhostname

# User passwords
printf "\n\n\n\nCONFIGURING USER\n\n\n\n"; sleep 3;
arch_chroot "useradd -m -c "Brendon Esteves" -G wheel $myusername; sleep 2"; #useradd -m -g users -G wheel $myusername;
printf "\nRoot passwword:\n";
arch_chroot "passwd; sleep 2";
printf "\nUser passwword:\n";
arch_chroot "passwd $myusername; sleep 2";
arch_chroot "echo '$myusername ALL=(ALL) ALL' | tee -a /etc/sudoers"; # sudo grep $myusername /etc/sudoers;

arch_chroot "UUID=$(blkid -s UUID -o value /dev/nvme0n1p2)"
#arch_chroot "efibootmgr -q --disk /dev/nvme0n1 --part 1 --create --label "ArchLinux" --loader "\vmlinuz-linux-ck-skylake" --unicode 'root=PARTUUID=$UUID rw initrd=\initramfs-linux-ck-skylake.img quiet rd.udev.log-priority=0 pci=noaer nowatchdog' --verbose";

# pacotes rede e gerenciar arquivos
arch_chroot "sudo pacman -S networkmanager unzip unrar               \
p7zip mlocate a52dec faac faad2 flac jasper lame libdca              \ 
libdv libmad libmpeg2 libtheora libvorbis libxv wavpack              \ 
x264 xvidcore gstreamer gst-plugins-base gst-plugins-base-libs       \ 
gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav gvfs     \ 
gvfs-afc gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-smb --noconfirm";

# Enabling services
arch_chroot "systemctl enable NetworkManager";

arch-chroot /mnt
# reboot

# Mais informações:

# https://www.vivaolinux.com.br/dica/Arch-Linux-Configurando-Wi-Fi-com-wifi-menu
# https://wiki.archlinux.org/index.php/Linux_console/Keyboard_configuration
# https://wiki.archlinux.org/index.php/locale
# https://unix.stackexchange.com/questions/453585/shell-script-to-comment-and-uncomment-a-line-in-file
