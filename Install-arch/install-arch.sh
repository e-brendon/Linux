#!/bin/bash

#VARIAVEIS DE USUARIO
USUARIO='brendon'
SENHA_USUARIO='123'
SENHA_ROOT='123'
DE='gnome'
GLOGIN='gdm'

#CRIANDO TABELA DE PARTIÇÃO PARA DISCO 1
parted /dev/nvme0n1 mklabel gpt
#CRIANDO PARTIÇÃO /EFI
parted /dev/nvme0n1p1 mkpart primary fat32 0% 512MB
#CRIANDO PARTIÇÃO /
parted /dev/nvme0n1p2 mkpart primary btrfs 512MB 100%
#CRIANDO TABELA DE PARTIÇÃO PARA DISCO 2
#parted /dev/nvme1n1 mklabel gpt
#CRIANDO PARTIÇÃO QUE VAI SER A HOME
#parted /dev/nvme1n1 mkpart primary ext4 0% 100%
#CONFERINDO PARTIÇÕES
clear
parted /dev/nvme0n1 print
#parted /dev/nvme1n1 print
sleep 5
#FORMATANDO ROOT
mkfs.btrfs /dev/nvme0n1p2
#FORMATANDO EFI
mkfs.fat -F 32 /dev/nvme0n1p1
#Ajustando volumes btrfs
mount /dev/nvme0n1p2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
chattr +C /mnt/@var
btrfs subvolume create /mnt/@snapshots
umount /mnt
#montando partições
mount -o defaults,noatime,discard,compress=zstd,ssd,subvol=@ /dev/nvme0n1p2 /mnt
#mkdir -p /mnt/boot/efi
mkdir /mnt/home
mkdir /mnt/var
mkdir /mnt/.snapshots
mount -o defaults,noatime,discard,compress=zstd,ssd,subvol=@home /dev/nvme0n1p2 /mnt/home
mount -o defaults,noatime,discard,compress=zstd,ssd,subvol=@var /dev/nvme0n1p2 /mnt/var
mount -o defaults,noatime,discard,compress=zstd,ssd,subvol=@snapshots /dev/nvme0n1p2 /mnt/.snapshots

#MONTANDO /EFI
mount --mkdir /dev/nvme0n1p1 /mnt/efi

#CONFIGURANDO O PACMAN.CONF
sed -i '/^#.*Color/s/^#//' /etc/pacman.conf
sed -i '/^#.*ParallelDownloads/s/^#//' /etc/pacman.conf
pacman -Sy
#INSTALANDO SISTEMA BASE
pacstrap /mnt base base-devel vim grub intel-ucode linux linux-firmware linux-headers efibootmgr sof-firmware zsh \
gvfs gvfs-smb virtualbox virtualbox-host-modules-arch fprintd imagemagick acpid  usbutils  firefox firefox-i18n-pt-br \
gst-plugin-va gst-plugins-bad vlc tilix  unrar unzip p7zip mesa ark intel-media-driver lm_sensors i2c-tools libvdpau-va-gl \
libva-vdpau-driver libva-utils vdpauinfo vulkan-intel mesa-utils ntfs-3g dosfstools exfat-utils btrfs-progs tailscale zerotier-one git  \
gst-libav gst-plugins-bad gst-plugins-base figlet gst-plugins-good gst-plugins-ugly gst-plugin-va tilix wget curl \
power-profiles-daemon libva-intel-driver libva-mesa-driver luajit sndio v4l2loopback-dkms $DE


genfstab -U /mnt >> /mnt/etc/fstab

#POS INSTALL
arch-chroot /mnt <<EOF
ln -sf /usr/share/zoneinfo/America/Cuiabá /etc/localtime
hwclock --systohc
sed -i '/^#.*pt_BR.UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo 'LANG=pt_BR.UTF-8' >> /etc/locale.conf
echo 'KEYMAP=br-abnt2' >> /etc/vconsole.conf
echo 'FONT=Lat2-Terminus16' >> /etc/vconsole.conf
printf '\n127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$myhostname.localdomain	$myhostname' >> /etc/hosts
echo 'root:$SENHA_ROOT' | chpasswd
useradd -m -c "Brendon Esteves" -g users -G wheel -s /bin/zsh $USUARIO
echo '$USUARIO:$SENHA_USUARIO' | chpasswd
sed -i '/^#.*%wheel ALL=(ALL) ALL/s/^#//' /etc/sudoers
sed -i '/^#.*Color/s/^#//' /etc/pacman.conf
sed -i '/^#.*ParallelDownloads/s/^#//' /etc/pacman.conf
pacman -Syu
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=arch --recheck
grub-mkconfig -o /boot/grub/grub.cfg

#video
echo "export LIBVA_DRIVER_NAME=iHD" >> /etc/environment
echo "export VDPAU_DRIVER=va_gl" >> /etc/environment

systemctl enable $GLOGIN NetworkManager bluetooth acpid
mkinitcpio -P
clear
figlet "Sistema Instalado"
sleep 5
EOF

#umount -R /mnt
#reboot

## Criador: https://github.com/wopgan/install-arch
