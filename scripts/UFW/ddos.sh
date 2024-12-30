#!/bin/bash

# Configurações iniciais
mkdir -r /var/log/ufw-ddos/
LOG_FILE="/var/log/ufw-ddos/ufw.log"

# Função para verificar erros e sair em caso de falha
check_error() {
  if [ $? -ne 0 ]; then
    echo "Erro ao executar o comando anterior. Abortando."
    exit 1
  fi
}

# Etapa 1: Preparar o ambiente
echo "Atualizando pacotes e verificando UFW..."
sudo apt update && sudo apt install -y ufw
check_error

# Etapa 2: Limpar regras antigas no UFW
echo "Limpando regras antigas no UFW..."
sudo ufw disable
sudo ufw reset
check_error

# Etapa 3: Configurar políticas padrão
echo "Configurando políticas padrão do UFW..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
check_error

# Etapa 4: Regras para proteger contra DDoS e DoS
echo "Configurando regras para mitigar ataques DDoS e DoS..."

# Limitar conexões SSH
echo "Limitando conexões SSH para evitar força bruta..."
sudo ufw limit 22/tcp
check_error

# Limitar conexões HTTP/HTTPS
echo "Limitando conexões HTTP/HTTPS..."
sudo ufw limit 80/tcp
sudo ufw limit 443/tcp
check_error

# Limitar conexões em outras portas sensíveis
echo "Limitando conexões em portas críticas..."
sudo ufw limit 48222/tcp      # Porta SSH customizada (ajuste se necessário)
sudo ufw limit 51820/udp      # Porta WireGuard (ajuste se necessário)
check_error

# Etapa 5: Habilitar UFW e logs
echo "Habilitando UFW e logs..."
sudo ufw logging on
sudo ufw enable
check_error

# Configurar logs detalhados para tráfego bloqueado
echo "Configurando redirecionamento de logs para $LOG_FILE..."
echo ':msg, contains, "UFW BLOCK" '"$LOG_FILE"'
& stop' | sudo tee /etc/rsyslog.d/ufw.conf > /dev/null

echo "Reiniciando o rsyslog..."
sudo systemctl restart rsyslog
check_error

# Teste e validação
echo "Testando configurações..."
sudo ufw status verbose
echo "Configuração concluída! O servidor está protegido contra ataques DDoS e DoS."
