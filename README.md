# MDT Telegram Notification 🤖

![Platform](https://img.shields.io/badge/Platform-MDT%20%2F%20Windows-blue)
![Language](https://img.shields.io/badge/PowerShell-5.1-blue)
![Integration](https://img.shields.io/badge/API-Telegram-informational)

Script em PowerShell desenvolvido para integrar o **Microsoft Deployment Toolkit (MDT)** ao **Telegram**. Ele envia notificações ricas e formatadas ao final do processo de implantação de sistemas operacionais (OSD), permitindo monitoramento remoto da equipe de TI.

> **Versão 2.1 (Jan/2026):** Refatorado para maior segurança (método POST), suporte a Markdown V2 e melhor tratamento de erros.

## 🎯 Funcionalidades

* **Notificações em Tempo Real:** Avisa imediatamente quando um deployment termina.
* **Metadados Ricos:** Envia Nome da Máquina, Modelo, Serial Tag, Técnico Responsável e IP.
* **Métricas de Performance:** Calcula e exibe a duração total da formatação.
* **Monitoramento de Erros:** Exibe contagem de *Warnings* e *Errors* capturados pelo MDT Monitor.
* **Segurança:** Suporte a inserção de Token via `CustomSettings.ini` (sem credenciais hardcoded).

## 📸 Exemplo da Notificação

O bot envia uma mensagem formatada assim para o seu grupo:

> 📢 **MDT Deployment Finalizado**
>
> 🖥️ **Host:** DESKTOP-LAB01
> 📦 **Modelo:** Dell Latitude 5420
> 🏷️ **Tag:** 8X99A12
> 👤 **Tech:** Wesley Wilson
>
> ⏱️ **Duração:** 00h 45m
> 📅 **Fim:** 22/01/2026 14:30
>
> ⚠️ **Alertas:** 0
> ❌ **Erros:** 0
>
> _Enviado via MDT Automation_

## 🚀 Como Implementar

### 1. Pré-requisitos
* Um Bot no Telegram (criado via [@BotFather](https://t.me/botfather)).
* O `Chat ID` do usuário ou grupo que receberá os alertas.
* Servidor MDT com Monitor Service habilitado.

### 2. Instalação do Script
Salve o arquivo `Z-NotifyTelegram.ps1` na pasta de scripts do seu Deployment Share:
`\\SeuServidor\DeploymentShare$\Scripts\`

### 3. Configuração da Task Sequence
No console do MDT:
1.  Abra sua Task Sequence.
2.  Vá até a fase **State Restore** -> **Custom Tasks** (ou no final da lista).
3.  Adicione um passo do tipo **Run PowerShell Script**.
4.  **Command line:** `%ScriptRoot%\Z-NotifyTelegram.ps1`

### 4. Configuração Segura (Recomendado)
Para não deixar o Token do seu bot exposto no código, adicione as variáveis no seu `CustomSettings.ini` (na aba Rules):

```ini
[Settings]
Priority=Default
Properties=TelegramToken,TelegramChatID

[Default]
; Configure aqui suas credenciais
TelegramToken=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TelegramChatID=-100123456789
