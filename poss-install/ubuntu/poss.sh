#!/bin/bash
#instalando pacotes
figlet "Instalando pacotes"
sleep 5
sudo apt install tilix vlc flatpak virtualbox virtualbox-dkms -y 

#definindo a logo do ubuntu no dash
#copiando o original para um arquivo .bak
figlet "Temas, copiando o icone original para um arquivo .bak"
sleep 5
sudo cp /usr/share/icons/Yaru/scalable/actions/view-app-grid-symbolic.svg /usr/share/icons/Yaru/scalable/actions/view-app-grid-symbolic.svg.bak
#Copiando o arquivo de ../../logo-svg_ubuntu/
figlet "Temas, definindo o logo do Ubuntu para a dash"
sleep 5
sudo cp ../../logo-svg_ubuntu/view-app-grid-symbolic.svg /usr/share/icons/Yaru/scalable/actions/view-app-grid-symbolic.svg

#Atualizando o tema do gdm para o yaru-purple-dark
figlet "Temas, Atualizando o tema da tela de login para yaru-purple-dark"
sleep 5
#dependencias
sudo apt install git libglib2.0-dev dconf-cli -y
#repositorio
git clone --depth=1 https://github.com/realmazharhussain/gdm-tools.git
cd gdm-tools/
./install.sh
#criando um backup do tema aplicado
set-gdm-theme backup update
#Aplicando Yaru-purpler-dark
set-gdm-theme set Yaru-purple-dark
# Instalando pacotes para o zsh
apt install zsh curl 
#instalando oh-myzsh
figlet "Temas, Definindo zsh "
sleep 5
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
