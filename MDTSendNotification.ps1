<#
#=================================================================================#
###### Script de Envio de notificação para o Telegram no final do deployment ######
#=================================================================================#
# Criado:   22-05-2018
# Version:  1.2
# Autor:    Wesley Wilson
# Linkedin: https://www.linkedin.com/in/wesley-wilson-fernandes-de-almeida-7b832223/   
# Blog:     https://liwertech.wordpress.com/
#==================================================================================#
#>

Write-Progress -Activity "Enviado Notificação" -Status "Obtendo Informações" -PercentComplete 25 -Id 1 
$MDTServerName = 'LIWER-MDT01'
$MailSubject = "[MDT] Notificação do processo OS Deployment - PC $env:COMPUTERNAME"
$botid = "seu-codigo-bot"
$destination = "-0000000"

Function Get-MDTOData{
    <# 
    .Synopsis 
        Function for getting MDTOdata 
    .DESCRIPTION 
        Function for getting MDTOdata 
    .EXAMPLE 
        Get-MDTOData -MDTMonitorServer MDTSERVER01 
    .NOTES 
        Created: 2016-03-07 
        Version: 1.0 
 
        Author - Mikael Nystrom 
        Twitter: @mikael_nystrom 
        Blog : http://deploymentbunny.com 
 
    .LINK 
        http://www.deploymentbunny.com 
    #>
    Param(
    $MDTMonitorServer = $MDTServerName
    ) 
    $URL = "http://" + $MDTMonitorServer + ":9801/MDTMonitorData/Computers"
    $Data = Invoke-RestMethod $URL
    foreach($property in ($Data.content.properties) ){
        $Hash =  [ordered]@{ 
            Name = $($property.Name); 
            PercentComplete = $($property.PercentComplete.'#text'); 
            Warnings = $($property.Warnings.'#text'); 
            Errors = $($property.Errors.'#text'); 
            DeploymentStatus = $( 
            Switch($property.DeploymentStatus.'#text'){ 
                1 { "Active/Running"} 
                2 { "Failed"} 
                3 { "Successfully completed"} 
                Default {"Unknown"} 
                }
            );
            StepName = $($property.StepName);
            TotalSteps = $($property.TotalStepS.'#text')
            CurrentStep = $($property.CurrentStep.'#text')
            DartIP = $($property.DartIP);
            DartPort = $($property.DartPort);
            DartTicket = $($property.DartTicket);
            VMHost = $($property.VMHost.'#text');
            VMName = $($property.VMName.'#text');
            LastTime = $($property.LastTime.'#text') -replace "T"," ";
            StartTime = $($property.StartTime.'#text') -replace "T"," "; 
            EndTime = $($property.EndTime.'#text') -replace "T"," "; 
            }
        New-Object PSObject -Property $Hash
    }
} 
 
$Property = (Get-MDTOData -MDTMonitorServer $MDTServerName) | Where-Object {$_.Name -eq "$env:ComputerName"}

Write-Progress -Activity "Enviando Notificação" -Status "Criando Notificação" -PercentComplete 50 -Id 1 

$Inicio = [datetime]$($property.StartTime)
$Fim = [datetime]$($property.LastTime)
$ElapsedTime = New-TimeSpan -Start $Inicio -End $Fim

$UserID = $TSEnv:UserID
$UserID = [System.Text.Encoding]::Default.GetString([System.Convert]::FromBase64String($UserID))


$MailBody = @"
Informações MDT OS Deployment.

Deployment do computador $env:COMPUTERNAME foi concluído.
Servidor: $TSEnv:DeployRoot
Responsável: $UserID
Inicio: $($property.StartTime)
Tempo Decorrido: $ElapsedTime
TaskSequence Name: $TSEnv:TASKSEQUENCENAME
Fabricante: $TSEnv:Make
Modelo: $TSEnv:Model
Memoria: $TSEnv:Memory MB
ServiceTag: $TSEnv:SerialNumber
 
====== MDT Monitor Info. ======
Alertas: $($property.Warnings)
Erros: $($property.Errors)
Finalizado: $($property.LastTime)
"@
 
Write-Progress -Activity "Enviando Notificação" -Status "Enviando Notificação para $destination" -PercentComplete 75 -Id 1 

Write-Progress -Activity "Enviando Notificação" -Status "Notificação enviada com sucesso" -PercentComplete 100 -Id 1

$data = "https://api.telegram.org/bot" + $botid + "/sendMessage?chat_id=" + $destination + "&text=" + $MailBody
Invoke-WebRequest $data
