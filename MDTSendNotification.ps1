<#
# Criado:   22-05-2018
# Update:   22-01-2026
# Version:  2.1
# Autor:    Wesley Wilson
# Linkedin: https://www.linkedin.com/in/wesley-wilson-fernandes-de-almeida-7b832223/   
# Blog:     https://liwertech.wordpress.com/
#==================================================================================#
.SYNOPSIS
    Envia notificação de status de OSD para o Telegram.
.DESCRIPTION
    Script otimizado para integrar com Task Sequence do MDT.
    Utiliza método POST para evitar erros de URL Encoding.
    Suporta leitura de variáveis do CustomSettings.ini.
.PARAMETER Token
    Token do Bot (pode ser passado via script ou TS Variable 'TelegramToken')
.PARAMETER ChatID
    ID de destino (pode ser passado via script ou TS Variable 'TelegramChatID')
#>
[CmdletBinding()]
Param(
    [string]$Token = $TSEnv:TelegramToken,
    [string]$ChatID = $TSEnv:TelegramChatID
)

# Configurações Padrão
if ([string]::IsNullOrEmpty($Token)) { $Token = "SEU_TOKEN_AQUI_APENAS_TESTE" }
if ([string]::IsNullOrEmpty($ChatID)) { $ChatID = "-0000000" }

$MDTMonitorServer = $TSEnv:DeployRoot.Split('\')[2]
if ([string]::IsNullOrEmpty($MDTMonitorServer)) { $MDTMonitorServer = "LIWER-MDT01" }

# --- Funções Auxiliares ---
Function Get-MDTCurrentComputerStatus {
    Param($Server)
    
    Try {
        # Otimização: Tenta filtrar direto na query se a API suportar, senão processa local
        # MDT Monitor service é antigo, atualizado para Error Handling
        $URL = "http://$Server`:9801/MDTMonitorData/Computers"
        $RawData = Invoke-RestMethod $URL -ErrorAction Stop
        
        # Filtra apenas o computador atual para processar menos dados
        $MyComputer = $RawData.content.properties | Where-Object { $_.Name -eq $env:COMPUTERNAME }
        
        if ($MyComputer) {
            return [PSCustomObject]@{
                Warnings  = $MyComputer.Warnings.'#text'
                Errors    = $MyComputer.Errors.'#text'
                StartTime = ($MyComputer.StartTime.'#text' -replace "T"," ")
                EndTime   = ($MyComputer.EndTime.'#text' -replace "T"," ")
                LastTime  = ($MyComputer.LastTime.'#text' -replace "T"," ")
            }
        }
    }
    Catch {
        Write-Warning "Não foi possível contatar o MDT Monitor Service. Erro: $_"
        return $null
    }
    return $null
}

# --- Execução Principal ---

Write-Progress -Activity "Telegram Notification" -Status "Coletando Metadados..." -PercentComplete 10

# Tenta pegar dados do servidor, se falhar, usa dados locais
$MDTData = Get-MDTCurrentComputerStatus -Server $MDTMonitorServer

# Calculo de tempo
if ($MDTData) {
    $TimeSpan = New-TimeSpan -Start ([datetime]$MDTData.StartTime) -End ([datetime]$MDTData.LastTime)
    $Duration = "{0:hh}h {0:mm}m" -f $TimeSpan
} else {
    $Duration = "N/A (Monitor Offline)"
}

# Decodificação do UserID
$DecodedUser = "Desconhecido"
try {
    if ($TSEnv:UserID) {
        $DecodedUser = [System.Text.Encoding]::Default.GetString([System.Convert]::FromBase64String($TSEnv:UserID))
    }
} catch {
    $DecodedUser = $TSEnv:UserID 
}

# Formatação da Mensagem com Emojis - para melhor visualização no app do telegram
$Message = @"
📢 *MDT Deployment Finalizado*

🖥️ *Host:* `$env:COMPUTERNAME`
📦 *Modelo:* $($TSEnv:Model)
🏷️ *Tag:* $($TSEnv:SerialNumber)
👤 *Tech:* $DecodedUser

⏱️ *Duração:* $Duration
📅 *Fim:* $(Get-Date -Format "dd/MM/yyyy HH:mm")

⚠️ *Alertas:* $($MDTData.Warnings ?? 0)
❌ *Erros:* $($MDTData.Errors ?? 0)

_Enviado via MDT Automation_
"@

# Envio Seguro via POST
Write-Progress -Activity "Telegram Notification" -Status "Enviando mensagem..." -PercentComplete 80

$Payload = @{
    chat_id = $ChatID
    text    = $Message
    parse_mode = "Markdown"
}

Try {
    $Response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$Token/sendMessage" -Method Post -Body $Payload -ErrorAction Stop
    Write-Output "Telegram enviado com sucesso: MessageID $($Response.result.message_id)"
}
Catch {
    Write-Error "Falha ao enviar Telegram: $_"
}

Write-Progress -Activity "Telegram Notification" -Status "Concluído" -PercentComplete 100
