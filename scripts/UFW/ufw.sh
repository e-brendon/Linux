#!/bin/bash

# Configurações iniciais
LOG_FILE="/tmp/ufw.log"
BR_IP_LIST="/tmp/br-ips.txt"
CRON_SCRIPT="/tmp/update_br_ips.sh"

# Função para verificar erros e sair em caso de falha
check_error() {
  if [ $? -ne 0 ]; then
    echo "Erro ao executar o comando anterior. Abortando."
    exit 1
  fi
}

# Etapa 1: Preparar o ambiente
echo "Atualizando pacotes e verificando UFW..."
sudo apt update && sudo apt install -y ufw wget
check_error

# Etapa 2: Baixar lista de IPs do Brasil
echo "Baixando lista de IPs do Brasil..."
wget -O $BR_IP_LIST https://www.ipdeny.com/ipblocks/data/countries/br.zone
check_error

# Etapa 3: Limpar regras antigas no UFW
echo "Limpando regras antigas no UFW..."
sudo ufw disable
sudo ufw reset
check_error

# Etapa 4: Configurar regras do UFW
echo "Configurando políticas padrão do UFW..."
sudo ufw default deny incoming
sudo ufw default allow outgoing

echo "Aplicando regras para IPs do Brasil..."
while read ip; do
  sudo ufw allow from $ip to any
done < $BR_IP_LIST

echo "Configurando regras específicas..."
while read ip; do
  sudo ufw allow from $ip to any port 48222 proto tcp # SSH
  sudo ufw allow from $ip to any port 80 proto tcp    # HTTP
  sudo ufw allow from $ip to any port 443 proto tcp  # HTTPS
  sudo ufw allow from $ip to any port 51820 proto udp # WireGuard
done < $BR_IP_LIST

echo "Habilitando UFW..."
sudo ufw enable
check_error

# Etapa 5: Configurar logs detalhados
echo "Habilitando logs detalhados do UFW..."
sudo ufw logging on

echo "Configurando redirecionamento de logs para $LOG_FILE..."
echo ':msg, contains, "UFW BLOCK" '"$LOG_FILE"'
& stop' | sudo tee /etc/rsyslog.d/ufw.conf > /dev/null

echo "Reiniciando o rsyslog..."
sudo systemctl restart rsyslog
check_error

echo "Configurando rotação de logs..."
echo "$LOG_FILE {
    daily
    missingok
    rotate 7
    compress
    notifempty
    create 640 syslog adm
}" | sudo tee /etc/logrotate.d/ufw > /dev/null

# Etapa 6: Configurar atualização automática dos IPs
echo "Configurando atualização automática da lista de IPs..."
echo "#!/bin/bash
wget -O $BR_IP_LIST https://www.ipdeny.com/ipblocks/data/countries/br.zone
while read ip; do
  sudo ufw allow from \$ip to any
done < $BR_IP_LIST
sudo ufw reload
" > $CRON_SCRIPT

chmod +x $CRON_SCRIPT
(crontab -l 2>/dev/null; echo "0 3 * * * $CRON_SCRIPT") | crontab -

# Testes e validação
echo "Testando configurações..."
sudo ufw status verbose
echo "A configuração foi concluída com sucesso. Verifique os logs em $LOG_FILE."