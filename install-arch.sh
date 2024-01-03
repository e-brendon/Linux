#!/bin/bash

#VARIAVEIS DE USUARIO
USUARIO='seuUsuario'
SENHA_USUARIO='suaSenha'
SENHA_ROOT='senhaRoot'

#CRIANDO TABELA DE PARTIÇÃO PARA DISCO 1
parted /dev/nvme0n1 mklabel gpt
#CRIANDO PARTIÇÃO /EFI
parted /dev/nvme0n1 mkpart primary fat32 0% 512MB
#CRIANDO PARTIÇÃO /
parted /dev/nvme0n1 mkpart primary ext4 512MB 100%
#CRIANDO TABELA DE PARTIÇÃO PARA DISCO 2
parted /dev/nvme1n1 mklabel gpt
#CRIANDO PARTIÇÃO QUE VAI SER A HOME
parted /dev/nvme1n1 mkpart primary ext4 0% 100%
#CONFERINDO PARTIÇÕES
clear
parted /dev/nvme0n1 print
parted /dev/nvme1n1 print
sleep 5
#FORMATANDO ROOT
mkfs.ext4 /dev/nvme0n1p2
#FORMATANDO EFI
mkfs.fat -F 32 /dev/nvme0n1p1
#FORMATANDO A HOME
mkfs.ext4 /dev/nvme1n1p1
#MONTANDO /
mount /dev/nvme0n1p2 /mnt
#MONTANDO /EFI
mount --mkdir /dev/nvme0n1p1 /mnt/efi
#MONTANDO /HOME
mount --mkdir /dev/nvme1n1p1 /mnt/home
#CONFIGURANDO O PACMAN.CONF
sed -i '/^#.*Color/s/^#//' /etc/pacman.conf
sed -i '/^#.*ParallelDownloads/s/^#//' /etc/pacman.conf
pacman -Sy
#INSTALANDO SISTEMA BASE
pacstrap /mnt base base-devel vim grub intel-ucode linux linux-firmware linux-headers efibootmgr sof-firmware zsh plasma
genfstab -U /mnt >> /mnt/etc/fstab

#POS INSTALL
arch-chroot /mnt <<EOF
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
sed -i '/^#.*pt_BR.UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo 'LANG=pt_BR.UTF-8' >> /etc/locale.conf
echo 'KEYMAP=br-abnt2' >> /etc/vconsole.conf
echo 'FONT=Lat2-Terminus16' >> /etc/vconsole.conf
echo 'tie' >> /etc/hostname
echo '127.0.0.1 localhost' >> /etc/hosts
echo '::1       localhost' >> /etc/hosts
echo '127.0.1.1 tie.local   tie' >> /etc/hosts
echo 'root:$SENHA_ROOT' | chpasswd
useradd -m -g users -G wheel -s /bin/zsh $USUARIO
echo '$USUARIO:$SENHA_USUARIO' | chpasswd
sed -i '/^#.*%wheel ALL=(ALL) ALL/s/^#//' /etc/sudoers
sed -i '/^#.*Color/s/^#//' /etc/pacman.conf
sed -i '/^#.*ParallelDownloads/s/^#//' /etc/pacman.conf
pacman -Syu
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=arch --recheck
grub-mkconfig -o /boot/grub/grub.cfg
yes | pacman -S plasma-wayland-session dolphin dolphin-plugins gvfs gvfs-smb kfind konsole spectacle okular gwenview kate print-manager cups system-config-printer \
virtualbox virtualbox-host-modules-arch power-profiles-daemon kcalc krita filelight ksystemlog kgpg partitionmanager skanlite kmousetool kcharselect krdc kompare sweeper acpid hplip usbutils \
kamoso kdf kcachegrind krfb kbackup kwallet5 kwalletmanager kdeconnect firefox firefox-i18n-pt-br gst-plugin-va gst-plugins-bad docker docker-compose vlc qbittorrent  \
unrar unzip p7zip mesa ark intel-media-driver lm_sensors i2c-tools libvdpau-va-gl libva-vdpau-driver libva-utils vdpauinfo vulkan-intel mesa-utils ntfs-3g dosfstools exfat-utils btrfs-progs tailscale zerotier-one git wget curl \
gst-libav gst-plugins-bad gst-plugins-base figlet gst-plugins-good gst-plugins-ugly gst-plugin-va
echo "export LIBVA_DRIVER_NAME=iHD" >> /etc/environment
echo "export VDPAU_DRIVER=va_gl" >> /etc/environment
wget https://telegram.org/dl/desktop/linux -O /tmp/tsetup.tar.xg && tar xJf /tmp/tsetup.tar.xg -C /opt/
wget https://vscode.download.prss.microsoft.com/dbazure/download/stable/0ee08df0cf4527e40edc9aa28f4b5bd38bbff2b2/code-stable-x64-1702460840.tar.gz -O /tmp/vscode.tar.gz && tar xzf /tmp/vscode.tar.gz -C /opt/
git clone https://aur.archlinux.org/microsoft-edge-stable-bin.git /home/$USUARIO/AppAUR/edge
ln -sf /opt/VSCode-linux-x64/bin/code /usr/bin/code
echo "auth            optional        pam_kwallet5.so" >> /etc/pam.d/sddm
echo "session         optional        pam_kwallet5.so auto_start" >> /etc/pam.d/sddm
gpasswd -a $USUARIO docker
systemctl enable sddm NetworkManager docker bluetooth acpid cups
mkinitcpio -P
clear
figlet "Sistema Instalado"
sleep 5
EOF
umount -R /mnt
reboot
