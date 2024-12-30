#!/bin/bash

# Diretório raiz do compartilhamento
BASE_DIR="/seu_diretorio"

# Loop por todos os diretórios no compartilhamento
for dir in "$BASE_DIR"/*; do
    if [ -d "$dir" ]; then
        group=$(stat -c '%G' "$dir") # Obtém o grupo do diretório
        echo "Configurando permissões para $dir com grupo $group"

        # Ajustar permissões para o grupo proprietário
        sudo chmod 2770 "$dir"        # 2 ativa o SetGID
        sudo chown root:"$group" "$dir"
        sudo setfacl -m g:"$group":rwx "$dir"
        sudo setfacl -d -m g:"$group":rwx "$dir"

        # Garantir que 'outros' não tenham permissão
        sudo setfacl -m o::--- "$dir"
        sudo setfacl -d -m o::--- "$dir"
    fi
done

echo "Configurações de permissões concluídas!"
