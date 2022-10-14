#!/bin/bash
################################################################################
# Escallo: verificaSipTrunk.sh
#
# @author Josimar Rocha <josimar@futurotec.com.br>
# @version 20220930
################################################################################

# Configuracoes basicas do script
myVersion="20220930"
logFile="/var/log/asterisk/externip.log"

# Obtém o valor setado no parâmetro externip e armazena na variável
externIp=$(grep externip /etc/asterisk/sip.conf | awk -F '=' '{ print $2 }')

# Obtém o IP pelo qual o Escallo está navegando e armazena na variável
browsingIp=$(curl -s ifconfig.me)

# Array com todas as redes locais do ambiente [Formato: 'IP_de_rede/Máscara', ou só o IP caso queira especificar somente o host, separados por vírgula)
localNet=(192.168.1.0/255.255.252.0 10.10.10.0/255.255.255.0 10.253.224.0/255.255.255.0 187.62.209.82)

# Linha do arquivo "/etc/asterisk/sip.conf" em que o parâmetro "externip" será inserido
externIpLinePosition="2"

# Linha do arquivo "/etc/asterisk/sip.conf" em que o parâmetro "localnet" será inserido
localNetLinePosition="3"

# Separador para organizar as informações do arquivo de log
#
function separator {
        
	for i in $(seq 1 70)0; do echo "*"; done | tr '\n' '*' >> ${logFile}
        echo -e "\n" >> ${logFile}
}

# Restarta o módulo SIP no Asterisk
#
function sipReload (){
    sleep 3    
	asterisk -rx 'sip reload'
}

# "Restarta" arquivo de log caso seja maior que 50MB
#
function logSizeCheck () {
	
	logSize=$(du -hsm ${logFile} | awk '{ print $1 }')
	if [ $logSize -gt 50 ]
	then
		echo "${logSize}"
		echo "$(date) - Log resetado pois ultrapassou o limite estipulado" > $logFile
	fi
}
	

# Realiza operações necessárias para verificar se o parâmetro "externip" está setado. Caso positivo, verifica se o valor definido está de acordo com o IP de navegação do Escallo
# Realiza inserções e alterações, se necessário
#
function checkExternIp (){

        # Valida se o valor da variável "externIp" é nulo
	# Obs: será nulo caso o parâmetro não esteja definido
	if [ -z $externIp ]
        then
                separator

		# Escreve no arquivo de log
		echo -e "$(date) - O parâmetro externip não está configurado" >> ${logFile}
                
		# Insere o parâmetro externip com seu respectivo valor na linha 2 do arquivo "/etc/asterisk/sip.conf"
		sed -i "${externIpLinePosition} iexternip=${browsingIp}" /etc/asterisk/sip.conf

		# Simplesmente para inserir dois "espaços" antes do parâmetro (mantendo a padronização)
                sed -i "s/externip=${browsingIp}/  externip=${browsingIp}/" /etc/asterisk/sip.conf

		# Laço de repetição para inserir os valores atribuidos ao array "localNet" na linha 3 do arquivo "/etc/asterisk/sip.conf"
                for i in "${localNet[@]}"
                do
                        sed -i "${localNetLinePosition} ilocalnet=${i}" /etc/asterisk/sip.conf
                        sed -i "s|localnet=${i}|  localnet=${i}|" /etc/asterisk/sip.conf
                done

                sipReload

		# Escreve no arquivo de log
                echo -e "$(date) - Parâmetro devidamente inserido. Módulo SIP reiniciado." >> ${logFile}

                # Encerra a execução do script
		exit

        else

                # Valida se o valor atribuido ao parâmetro "externip" está de acordo com o IP de navegação do Escallo
		if [ $externIp != $browsingIp ]
                then
                        separator

			# Escreve no arquivo de log
			echo -e "$(date) - O valor setado para o parâmetro está em desacordo com o IP de navegação" >> ${logFile}
			echo -e "$(date) - Navegação: ${browsingIp}  |  Parâmetro: ${externIp}"  >> ${logFile}

			# Substitui o valor atribuído ao parâmetro "externip"
                        sed -i "s/${externIp}/${browsingIp}/" /etc/asterisk/sip.conf

                        sipReload

			# Escreve no arquivo de log
                        echo -e "$(date) - Valor devidamente alterado. Módulo SIP reiniciado." >> ${logFile}

			# Encerra a execução do script
                        exit

                else

                        separator

			# Escreve no arquivo de log
			echo -e "$(date) - O valor setado para o parâmetro está condizente com o IP de navegação. Nenhuma alteração realizada" >> ${logFile}
			echo -e "$(date) - Navegação: ${browsingIp}  |  Parâmetro: ${externIp}"  >> ${logFile}
			
			# Encerra a execução do script
                        exit

                fi
        fi
}

logSizeCheck
checkExternIp
