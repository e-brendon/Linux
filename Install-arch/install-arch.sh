#!/bin/bash

#Atualizando repositorios
pacman -Syy reflector --noconfirm
reflector --verbose -l 40 --sort rate --save /etc/pacman.d/mirrorlist

#VARIAVEIS DE USUARIO
USUARIO='brendon'
SENHA_USUARIO='123'
SENHA_ROOT='123'
HOSTNAME='ArchLinux'
DE='gnome'
GLOGIN='gdm'
DISCO='nvme0n1'

#CRIANDO TABELA DE PARTIÇÃO PARA DISCO
parted /dev/$DISCO mklabel gpt
#CRIANDO PARTIÇÃO /EFI
parted /dev/$DISCO mkpart primary fat32 0% 512MB
#CRIANDO PARTIÇÃO /
parted /dev/$DISCO mkpart primary btrfs 512MB 100%
#CONFERINDO PARTIÇÕES
clear
parted /dev/$DISCO print
sleep 5
#FORMATANDO ROOT
mkfs.btrfs /dev/${DISCO}2
#FORMATANDO EFI
mkfs.fat -F 32 /dev/${DISCO}1
#Ajustando volumes btrfs
mount /dev/${DISCO}2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
chattr +C /mnt/@var
btrfs subvolume create /mnt/@snapshots
umount /mnt
#montando partições
mount -o defaults,noatime,discard,compress=zstd,ssd,subvol=@ /dev/${DISCO}2 /mnt
#mkdir -p /mnt/boot/efi
mkdir /mnt/home
mkdir /mnt/var
mkdir /mnt/.snapshots
mount -o defaults,noatime,discard,compress=zstd,ssd,subvol=@home /dev/${DISCO}2 /mnt/home
mount -o defaults,noatime,discard,compress=zstd,ssd,subvol=@var /dev/${DISCO}2 /mnt/var
mount -o defaults,noatime,discard,compress=zstd,ssd,subvol=@snapshots /dev/${DISCO}2 /mnt/.snapshots

#MONTANDO /EFI 
mount --mkdir /dev/${DISCO}1 /mnt/boot/efi

#CONFIGURANDO O PACMAN.CONF
sed -i '/^#.*Color/s/^#//' /etc/pacman.conf
sed -i '/^#.*ParallelDownloads/s/^#//' /etc/pacman.conf
pacman -Sy
#INSTALANDO SISTEMA BASE
pacstrap /mnt base base-devel vim grub intel-ucode linux linux-firmware linux-headers efibootmgr sof-firmware zsh \
gvfs gvfs-smb fprintd imagemagick acpid  usbutils  ntfs-3g dosfstools exfat-utils btrfs-progs \
gst-plugin-va gst-plugins-bad unrar unzip p7zip mesa intel-media-driver lm_sensors i2c-tools libvdpau-va-gl \
libva-vdpau-driver libva-utils vdpauinfo vulkan-intel mesa-utils tailscale zerotier-one git flatpak\
gst-libav gst-plugins-bad gst-plugins-base figlet gst-plugins-good gst-plugins-ugly gst-plugin-va tilix wget curl \
power-profiles-daemon libva-intel-driver libva-mesa-driver luajit sndio v4l2loopback-dkms upower  networkmanager  \
hplip cups git go micro nano cmake libevdev libconfig systemd-libs glib2 $DE

genfstab -U /mnt >> /mnt/etc/fstab

#POS INSTALL
arch-chroot /mnt <<EOF
echo $HOSTNAME >> /etc/hostname
ln -sf /usr/share/zoneinfo/America/Cuiabá /etc/localtime
hwclock --systohc
sed -i '/^#.*pt_BR.UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo 'LANG=pt_BR.UTF-8' >> /etc/locale.conf
echo 'KEYMAP=br-abnt2' >> /etc/vconsole.conf
echo 'FONT=Lat2-Terminus16' >> /etc/vconsole.conf
#configurando hostname 
printf '\n127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$HOSTNAME.localdomain	$HOSTNAME' >> /etc/hosts
echo 'root:$SENHA_ROOT' | chpasswd
useradd -m -c "Brendon Esteves" -g users -G wheel -s /bin/zsh $USUARIO
echo '$USUARIO:$SENHA_USUARIO' | chpasswd
echo '$USUARIO ALL=(ALL) ALL' | tee -a /etc/sudoers
sed -i '/^#.*%wheel ALL=(ALL) ALL/s/^#//' /etc/sudoers
sed -i '/^#.*Color/s/^#//' /etc/pacman.conf
sed -i '/^#.*ParallelDownloads/s/^#//' /etc/pacman.conf
pacman -Syu
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=arch --recheck
grub-mkconfig -o /boot/grub/grub.cfg
#video
echo "export LIBVA_DRIVER_NAME=iHD" >> /etc/environment
echo "export VDPAU_DRIVER=va_gl" >> /etc/environment
# instalação telegram
wget https://telegram.org/dl/desktop/linux -O /tmp/tsetup.tar.xg && tar xJf /tmp/tsetup.tar.xg -C /opt/
# ativando serviços 
systemctl enable $GLOGIN NetworkManager bluetooth upower acpid
mkinitcpio -P
clear
figlet "Sistema Instalado"
sleep 5
EOF

#umount -R /mnt
#reboot

## Criador: https://github.com/wopgan/install-arch
