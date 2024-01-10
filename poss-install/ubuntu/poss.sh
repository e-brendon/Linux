#!/bin/bash

#definindo a logo do ubuntu no dash
#copiando o original para um arquivo .bak
sudo cp /usr/share/icons/Yaru/scalable/actions/view-app-grid-symbolic.svg /usr/share/icons/Yaru/scalable/actions/view-app-grid-symbolic.svg.bak
#Copiando o arquivo de ../../logo-svg_ubuntu/
sudo cp ../../logo-svg_ubuntu/view-app-grid-symbolic.svg /usr/share/icons/Yaru/scalable/actions/view-app-grid-symbolic.svg

#Atualizando o tema do gdm para o yaru-purple-dark
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
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
