# MDT Telegram Notification 🤖

Script de automação para enviar notificações em tempo real sobre o status de implantação de Sistemas Operacionais (OSD) via Microsoft Deployment Toolkit (MDT).

## 🎯 Funcionalidades

* Notifica Início, Fim e Falha do deployment.
* Envia nome da máquina, Modelo, IP e Tempo decorrido.
* Integração direta na Task Sequence do MDT.

## ⚙️ Configuração

### Pré-requisitos
* Token do Bot Telegram (via @BotFather).
* Chat ID do grupo/usuário de destino.
* PowerShell 4.0+ habilitado no Boot Image (WinPE).

### Instalação no MDT

1.  baixe o script `MDTSendNotification.ps1` para a pasta `Scripts` do seu Deployment Share.
2.  Na Task Sequence, adicione um passo "Run PowerShell Script":
    * **Command:** `%ScriptRoot%\MDTSendNotification.ps1`

### Exemplo de Uso (Parâmetros)

```powershell
.\MDTSendNotification.ps1 -Token "12345:ABCDE..." -ChatID "-987654321" -Message "Deployment Finalizado com Sucesso!"
