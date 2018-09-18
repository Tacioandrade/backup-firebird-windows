# backup-firebird-windows
Script de backup do firebird para Windows, com o banco de dados compactado com 7zip e enviado para o Mega.nz usando o megatools.

# Configuração
Instale o 7zip https://www.7-zip.org/download.html, de preferência a versão do seu sistema operacional
Instale o MegaTools https://github.com/megous/megatools (baixe o .zip e descompacte em C:\Program Files\)

# Configuração do MegaTools
Vá a até a pasta do megatools e edite o arquivo C:\Program Files\megatools\mega.ini com as suas credenciais do Mega.nz

# Configuração do Script
1 - Vá até o menu iniciar e abra o Agendador de taredas;
2 - Crie uma tarefa (não uma tarefa básica);
3 - Na tarefa: Dê um nome, selecione a opção "Executar com o usuário conectado ou não" e "Executar com os mais altos privilégios";
4 - Em disparadores, configure os dias e horários que deseja que o backup seja executado;
5 - Em ações crie uma ação: "Executar um programa", nela configure o programa "Powershell.exe" e em "Adicionar argumentos (opcional), configure o script: -FILE "C:\Program Files\Firebird\Firebird_2_5\backupFirebird.ps1"
6 - Na aba Configurações, altere a opção: "Interromper a tarefa se ela for executada por mais de:" e altere pelo tempo que achar melhor, no geral coloco 8 horas ou 12 horas.
7 - Salve o Job e espere o backup ser executado.
