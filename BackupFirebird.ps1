###########################################################
# Name: BackupFirebird.ps1                              
# Criador: Tácio Andrade
# Criado: 07.08.2017                              
# Modificado: 07.08.2017                               
# Versão: 1.0
# Descrição: Script de backup dos bancos do Firebird, 
# compactado com 7zip e com envio do banco para o Mega.nz 
# usando o megatools https://github.com/megous/megatools
# Script homologado para Windows 2012R2 ou superior, roda
# no 2008R2, porém remova o -raw do comando cat e descomente
# a linha $message.Attachments.Add($attachment);
###########################################################

# Variaveis do usuario e senha do firebird
$FIREBIRD="C:\Program Files\Firebird\Firebird_2_5\bin\"
$USER="SYSDBA"
$PASSWORD="masterkey"
$7Z="C:\Program Files\7-Zip"
# Variaveis de arquivos
$LOG="C:\backup\BackupFirebird.log"
$BANCOS="192.168.1.40/3050:"
$BACKUP="C:\backup\"+ (Get-Date -format dd) + "\"
# Variaveis cloud
$MEGA="C:\Program Files\megatools"
$MEGADIR="/Root/backup/"+ (Get-Date -format dd)
# Variaveis email, recomendo o Yahoo, pois é o que menos da problema
$MAILUSER= "email@yahoo.com"
$MAILPASS= "senha"
$EMAILDESTINO= "seuemail@gmail.com"

########################### Funções Necessárias ###########################

Function Convert-Size() {
    Param ([decimal]$Type)
    If     ($Type -ge 1GB) {[string]::Format("{0:N2} GB", $Type / 1GB)}
    ElseIf ($Type -ge 1MB) {[string]::Format("{0:N2} MB", $Type / 1MB)}
    ElseIf ($Type -ge 1KB) {[string]::Format("{0:N2} KB", $Type / 1KB)}
    ElseIf ($Type -gt 0)   {[string]::Format("{0:N2} B ", $Type)}
    Else {""}
}
 
Function Format-Log{
        # parameter 1  = string to format
        # parameter 2  = max size of string to format
        # parameter 3  = position to align string (L = Left | R = Right)
        # parameter 4  = character to complete the size of string
        Param([string]$strString, [int]$iSize, [string]$strAlign, [string]$strChar )
        If ($strString.length -gt $iSize){
           $str = $strString.Substring(0,$iSize)
        } Else{
          If ($strAlign -eq  "R"){
             $str = $strString.PadLeft($iSize, $strChar)
          }
          If ($strAlign -eq "L"){
             $str = $strString.PadRight($iSize, $strChar)
          }
        }
        return $str
}

function Send-ToEmail([string]$email, [string]$attachmentpath){

    $message = new-object Net.Mail.MailMessage;
    $message.From = $MAILUSER;
    $message.To.Add($email);
    $message.Subject = "Backup HCC - Sucesso";
    $message.Body = cat -raw $LOG;
    $attachment = New-Object Net.Mail.Attachment($attachmentpath);
#    $message.Attachments.Add($attachment);

    $smtp = new-object Net.Mail.SmtpClient("smtp.mail.yahoo.com", "587");
    $smtp.EnableSSL = $true;
    $smtp.Credentials = New-Object System.Net.NetworkCredential($MAILUSER, $MAILPASS);
    $smtp.send($message);
    $attachment.Dispose();
}

########################### Fim Funções Necessárias ###########################

rm $LOG

# Inicia o backup
$TEXTO="Backup iniciado as "+ (Get-Date -format dd.MM.yyyy-HH:mm:ss)
add-Content -Path $LOG -Value $TEXTO

# Remove backup antigo
rm $BACKUP*

# Executa o backup dos bancos
cd $FIREBIRD
foreach ($i in get-content c:\bancos.txt) {
	$TEXTO="Backup do banco $i iniciado as "+ (Get-Date -format dd.MM.yyyy-HH:mm:ss)
	add-Content -Path $LOG -Value $TEXTO
	# Otimiza a base de dados
	.\gfix -sweep -user $USER -password $PASSWORD $BANCOS$i
	# Corrige os erros da base de dados se existirem
	#.\gfix -mend -full -user $USER -password $PASSWORD $BANCOS$i
	# Faz o backup da base
	#.\gbak.exe -b -user $USER -pas $PASSWORD -se 192.168.1.40/3050:service_mgr $i "$BACKUP/$i.GBK"
	.\gbak.exe -b -user $USER -pas $PASSWORD $BANCOS$i "$BACKUP/$i.gbk"
	$TEXTO="Backup do banco $i finalizado as "+ (Get-Date -format dd.MM.yyyy-HH:mm:ss)
	add-Content -Path $LOG -Value $TEXTO
}

# Executa a compressão dos bancos
cd $7Z
$dir = Get-ChildItem -path $BACKUP
foreach ($i in $dir) {
	$TEXTO="Compressão do banco $i iniciado as "+ (Get-Date -format dd.MM.yyyy-HH:mm:ss)
	add-Content -Path $LOG -Value $TEXTO
	.\7z.exe a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on -pajuda $BACKUP$i.7z $BACKUP$i
	$TEXTO="Compressão do banco $i finalizado as "+ (Get-Date -format dd.MM.yyyy-HH:mm:ss)
	add-Content -Path $LOG -Value $TEXTO
}

# Remove os arquivos de backup
rm $BACKUP*GBK

# Listar os backups
$TEXTO="Bancos cujo backup foram executados:"
add-Content -Path $LOG -Value $TEXTO
$files = Get-ChildItem -path $BACKUP
foreach($f in $files){
$name = $f.name
$size = Convert-Size $f.length
add-Content -Path $LOG -Value ("{0}{1}" -f (Format-Log $name 50 "L" " "), (Format-Log $size 20 "R" " "))
}

# Envia o backup pra nuvem
cd $MEGA
# Remove arquivos antigos do mega
.\megarm.exe $MEGADIR
$TEXTO="Inicia envio dos bancos para o Mega as "+ (Get-Date -format dd.MM.yyyy-HH:mm:ss)
add-Content -Path $LOG -Value $TEXTO
.\megamkdir.exe $MEGADIR
.\megacopy.exe  --no-progress --local $BACKUP --remote $MEGADIR

$TEXTO="Finaliza envio dos bancos para o Mega as "+ (Get-Date -format dd.MM.yyyy-HH:mm:ss)
add-Content -Path $LOG -Value $TEXTO

# Finaliza o backup
$TEXTO="Backup finalizado as "+ (Get-Date -format dd.MM.yyyy-HH:mm:ss)
add-Content -Path $LOG -Value $TEXTO

Send-ToEmail  -email $EMAILDESTINO -attachmentpath $LOG;
