# 📡 ALERTMANAGER - RECEIVERS E NOTIFICAÇÕES

> **Módulo 5:** Dominando canais de notificação

---

## 📋 CONTEÚDO DESTE MÓDULO

1. [Conceitos de Receivers](#1-conceitos-de-receivers)
2. [Email](#2-email)
3. [Slack](#3-slack)
4. [PagerDuty](#4-pagerduty)
5. [Webhooks](#5-webhooks)
6. [SMS e Telegram](#6-sms-e-telegram)
7. [Múltiplos Canais](#7-múltiplos-canais)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. CONCEITOS DE RECEIVERS

### 📡 O que são Receivers?

> **Analogia:** Se o roteamento é o **sistema postal** que decide onde entregar, os receivers são os **métodos de entrega**: carta registrada (email), telegrama (SMS), mensageiro (Slack), ou sirene de emergência (PagerDuty).

```mermaid
flowchart LR
    A[Alerta] --> B[Roteamento]
    B --> C[Receiver]
    
    C --> D[📧 Email]
    C --> E[💬 Slack]
    C --> F[📱 PagerDuty]
    C --> G[🔗 Webhook]
    C --> H[📲 SMS]
    
    D --> I[📬 Caixa de Email]
    E --> J[💻 Canal Slack]
    F --> K[📱 App PagerDuty]
    G --> L[🖥️ Sistema Externo]
    H --> M[📱 Celular]
```

### 🏗️ Estrutura Básica

```yaml
receivers:
  - name: 'nome-do-receiver'        # 🏷️ Nome único
    email_configs:                  # 📧 Configurações de email
      - to: 'admin@empresa.com'
    slack_configs:                  # 💬 Configurações do Slack
      - channel: '#alerts'
    pagerduty_configs:              # 📱 Configurações do PagerDuty
      - routing_key: 'abc123'
    webhook_configs:                # 🔗 Configurações de webhook
      - url: 'http://api.empresa.com/alerts'
```

### 🎯 Receiver vs Route

```yaml
# ❌ CONFUSÃO COMUM
route:
  receiver: 'team-email'          # ← Aponta para receiver
  
receivers:
  - name: 'team-email'            # ← Nome deve ser igual
    email_configs:
      - to: 'team@empresa.com'

# ✅ CORRETO
route:
  receiver: 'database-team'       # ← Nome da rota
  
receivers:
  - name: 'database-team'         # ← Mesmo nome
    email_configs:
      - to: 'dba@empresa.com'
```

---

## 2. EMAIL

### 📧 Configuração Básica

```yaml
# Global (compartilhado)
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@empresa.com'
  smtp_auth_username: 'alerts@empresa.com'
  smtp_auth_password: '${SMTP_PASSWORD}'
  smtp_require_tls: true

receivers:
  - name: 'email-team'
    email_configs:
      - to: 'team@empresa.com'
        subject: '[ALERTA] {{ .GroupLabels.alertname }}'
        body: |
          🚨 ALERTA DETECTADO
          
          Alerta: {{ .GroupLabels.alertname }}
          Severidade: {{ .GroupLabels.severity }}
          Instância: {{ .GroupLabels.instance }}
          
          Descrição: {{ range .Alerts }}{{ .Annotations.description }}{{ end }}
```

### 📨 Configurações Avançadas

```yaml
receivers:
  - name: 'advanced-email'
    email_configs:
      # ========================================
      # 👥 DESTINATÁRIOS
      # ========================================
      - to: 'admin@empresa.com,team@empresa.com'  # Múltiplos emails
        cc: 'manager@empresa.com'                 # Cópia
        bcc: 'audit@empresa.com'                  # Cópia oculta
        
        # ========================================
        # 📝 CONTEÚDO
        # ========================================
        subject: |
          [{{ .Status | toUpper }}] {{ .GroupLabels.alertname }} 
          ({{ .Alerts | len }} alertas)
        
        body: |
          <!DOCTYPE html>
          <html>
          <head>
              <style>
                  .critical { color: #ff0000; font-weight: bold; }
                  .warning { color: #ff8800; }
                  .info { color: #0088ff; }
              </style>
          </head>
          <body>
              <h2>🚨 Relatório de Alertas</h2>
              
              {{ if gt (len .Alerts.Firing) 0 }}
              <h3 class="critical">🔥 ALERTAS ATIVOS ({{ len .Alerts.Firing }})</h3>
              <ul>
              {{ range .Alerts.Firing }}
                  <li>
                      <strong>{{ .Labels.alertname }}</strong><br>
                      Instância: {{ .Labels.instance }}<br>
                      Severidade: <span class="{{ .Labels.severity }}">{{ .Labels.severity }}</span><br>
                      Descrição: {{ .Annotations.description }}<br>
                      Iniciado: {{ .StartsAt.Format "2006-01-02 15:04:05" }}<br>
                  </li>
              {{ end }}
              </ul>
              {{ end }}
              
              {{ if gt (len .Alerts.Resolved) 0 }}
              <h3 style="color: green;">✅ ALERTAS RESOLVIDOS ({{ len .Alerts.Resolved }})</h3>
              <ul>
              {{ range .Alerts.Resolved }}
                  <li>
                      <strong>{{ .Labels.alertname }}</strong><br>
                      Resolvido: {{ .EndsAt.Format "2006-01-02 15:04:05" }}<br>
                  </li>
              {{ end }}
              </ul>
              {{ end }}
              
              <hr>
              <p><small>Enviado pelo Alertmanager em {{ now.Format "2006-01-02 15:04:05" }}</small></p>
          </body>
          </html>
        
        # ========================================
        # 🔧 CONFIGURAÇÕES TÉCNICAS
        # ========================================
        headers:
          X-Priority: '1'                         # Alta prioridade
          X-Mailer: 'Alertmanager'
          Reply-To: 'noreply@empresa.com'
        
        # ========================================
        # 🔒 SMTP ESPECÍFICO (sobrescreve global)
        # ========================================
        smarthost: 'smtp.empresa.com:25'         # SMTP específico
        from: 'alertas@empresa.com'              # From específico
        auth_username: 'alertas@empresa.com'
        auth_password: '${EMPRESA_SMTP_PASSWORD}'
        require_tls: false                       # Servidor interno
```

### 📧 Templates de Email

```yaml
# templates/email.tmpl
{{ define "email.subject" }}
[{{ .Status | toUpper }}] {{ .GroupLabels.alertname }} - {{ .GroupLabels.instance }}
{{ end }}

{{ define "email.body" }}
🚨 RELATÓRIO DE ALERTAS
========================

Resumo:
- Total de alertas: {{ .Alerts | len }}
- Alertas ativos: {{ .Alerts.Firing | len }}
- Alertas resolvidos: {{ .Alerts.Resolved | len }}
- Horário: {{ now.Format "2006-01-02 15:04:05" }}

{{ if gt (len .Alerts.Firing) 0 }}
🔥 ALERTAS ATIVOS:
{{ range .Alerts.Firing }}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Alerta: {{ .Labels.alertname }}
Severidade: {{ .Labels.severity | toUpper }}
Instância: {{ .Labels.instance }}
Descrição: {{ .Annotations.description }}
Iniciado: {{ .StartsAt.Format "2006-01-02 15:04:05" }}
Duração: {{ .StartsAt | since }}
Labels: {{ range .Labels.SortedPairs }}{{ .Name }}={{ .Value }} {{ end }}
{{ end }}
{{ end }}

{{ if gt (len .Alerts.Resolved) 0 }}
✅ ALERTAS RESOLVIDOS:
{{ range .Alerts.Resolved }}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Alerta: {{ .Labels.alertname }}
Resolvido: {{ .EndsAt.Format "2006-01-02 15:04:05" }}
Duração total: {{ .StartsAt | since }}
{{ end }}
{{ end }}

🔗 Links úteis:
- Alertmanager: http://alertmanager.empresa.com:9093
- Prometheus: http://prometheus.empresa.com:9090
- Grafana: http://grafana.empresa.com:3000

--
Enviado automaticamente pelo Alertmanager
{{ end }}

# Usar no receiver
receivers:
  - name: 'templated-email'
    email_configs:
      - to: 'team@empresa.com'
        subject: '{{ template "email.subject" . }}'
        body: '{{ template "email.body" . }}'
```

---

## 3. SLACK

### 💬 Configuração Básica

```yaml
# Global
global:
  slack_api_url: 'https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX'

receivers:
  - name: 'slack-team'
    slack_configs:
      - channel: '#alerts'                    # Canal público
        username: 'AlertBot'                  # Nome do bot
        icon_emoji: ':warning:'               # Emoji do bot
        title: '🚨 {{ .GroupLabels.alertname }}'
        text: |
          {{ range .Alerts }}
          *Alerta:* {{ .Labels.alertname }}
          *Severidade:* {{ .Labels.severity }}
          *Instância:* {{ .Labels.instance }}
          *Descrição:* {{ .Annotations.description }}
          {{ end }}
```

### 🎨 Slack Avançado com Cores

```yaml
receivers:
  - name: 'slack-advanced'
    slack_configs:
      - channel: '#alerts-critical'
        username: 'AlertManager'
        icon_url: 'https://empresa.com/alertmanager-icon.png'
        
        # ========================================
        # 🎨 CORES POR SEVERIDADE
        # ========================================
        color: |
          {{ if eq .Status "firing" }}
            {{ if eq .GroupLabels.severity "critical" }}danger{{ end }}
            {{ if eq .GroupLabels.severity "warning" }}warning{{ end }}
            {{ if eq .GroupLabels.severity "info" }}good{{ end }}
          {{ else }}good{{ end }}
        
        # ========================================
        # 📝 TÍTULO DINÂMICO
        # ========================================
        title: |
          {{ if eq .Status "firing" }}
            🚨 [{{ .GroupLabels.severity | toUpper }}] {{ .GroupLabels.alertname }}
          {{ else }}
            ✅ [RESOLVIDO] {{ .GroupLabels.alertname }}
          {{ end }}
        
        title_link: 'http://alertmanager.empresa.com:9093'
        
        # ========================================
        # 📊 TEXTO DETALHADO
        # ========================================
        text: |
          {{ if gt (len .Alerts.Firing) 0 }}
          *🔥 Alertas Ativos: {{ len .Alerts.Firing }}*
          {{ range .Alerts.Firing }}
          
          • *{{ .Labels.alertname }}*
            📍 Instância: `{{ .Labels.instance }}`
            ⚠️ Severidade: `{{ .Labels.severity }}`
            📝 Descrição: {{ .Annotations.description }}
            ⏰ Iniciado: {{ .StartsAt.Format "15:04:05" }}
            🔗 <http://prometheus.empresa.com:9090/graph?g0.expr={{ .GeneratorURL | reReplaceAll ".*expr=([^&]*).*" "$1" | urlquery }}|Ver no Prometheus>
          {{ end }}
          {{ end }}
          
          {{ if gt (len .Alerts.Resolved) 0 }}
          *✅ Alertas Resolvidos: {{ len .Alerts.Resolved }}*
          {{ range .Alerts.Resolved }}
          • {{ .Labels.alertname }} (resolvido às {{ .EndsAt.Format "15:04:05" }})
          {{ end }}
          {{ end }}
        
        # ========================================
        # 📎 CAMPOS ESTRUTURADOS
        # ========================================
        fields:
          - title: 'Ambiente'
            value: '{{ .GroupLabels.environment | default "N/A" }}'
            short: true
          - title: 'Equipe'
            value: '{{ .GroupLabels.team | default "N/A" }}'
            short: true
          - title: 'Serviço'
            value: '{{ .GroupLabels.service | default "N/A" }}'
            short: true
          - title: 'Total de Alertas'
            value: '{{ .Alerts | len }}'
            short: true
        
        # ========================================
        # 🔧 CONFIGURAÇÕES TÉCNICAS
        # ========================================
        send_resolved: true                   # Enviar quando resolver
        http_config:
          proxy_url: 'http://proxy.empresa.com:8080'
```

### 🎯 Slack por Severidade

```yaml
receivers:
  # 🔴 Crítico - Canal específico com @here
  - name: 'slack-critical'
    slack_configs:
      - channel: '#alerts-critical'
        color: 'danger'
        title: '🚨 CRÍTICO: {{ .GroupLabels.alertname }}'
        text: |
          <!here> Alerta crítico detectado!
          
          {{ range .Alerts.Firing }}
          *Instância:* {{ .Labels.instance }}
          *Descrição:* {{ .Annotations.description }}
          *Ação necessária:* {{ .Annotations.runbook_url | default "Verificar imediatamente" }}
          {{ end }}
  
  # 🟡 Warning - Canal geral
  - name: 'slack-warning'
    slack_configs:
      - channel: '#alerts'
        color: 'warning'
        title: '⚠️ Warning: {{ .GroupLabels.alertname }}'
        text: |
          {{ range .Alerts.Firing }}
          Instância: {{ .Labels.instance }}
          Descrição: {{ .Annotations.description }}
          {{ end }}
  
  # 🔵 Info - Canal de logs
  - name: 'slack-info'
    slack_configs:
      - channel: '#logs'
        color: 'good'
        title: 'ℹ️ Info: {{ .GroupLabels.alertname }}'
        text: 'Alerta informativo - {{ .GroupLabels.alertname }}'
```

---

## 4. PAGERDUTY

### 📱 Configuração Básica

```yaml
# Global
global:
  pagerduty_url: 'https://events.pagerduty.com/v2/enqueue'

receivers:
  - name: 'pagerduty-oncall'
    pagerduty_configs:
      - routing_key: '${PAGERDUTY_ROUTING_KEY}'   # Integration Key
        description: '{{ .GroupLabels.alertname }} - {{ .GroupLabels.instance }}'
        severity: |
          {{ if eq .GroupLabels.severity "critical" }}critical{{ end }}
          {{ if eq .GroupLabels.severity "warning" }}warning{{ end }}
          {{ if eq .GroupLabels.severity "info" }}info{{ end }}
```

### 🚨 PagerDuty Avançado

```yaml
receivers:
  - name: 'pagerduty-advanced'
    pagerduty_configs:
      - routing_key: '${PAGERDUTY_ROUTING_KEY}'
        
        # ========================================
        # 📝 DESCRIÇÃO DETALHADA
        # ========================================
        description: |
          [{{ .GroupLabels.severity | toUpper }}] {{ .GroupLabels.alertname }}
          Instância: {{ .GroupLabels.instance }}
          Ambiente: {{ .GroupLabels.environment }}
        
        # ========================================
        # 🏷️ SEVERIDADE MAPEADA
        # ========================================
        severity: |
          {{ if eq .GroupLabels.severity "critical" }}critical
          {{ else if eq .GroupLabels.severity "warning" }}warning
          {{ else if eq .GroupLabels.severity "info" }}info
          {{ else }}error{{ end }}
        
        # ========================================
        # 🔗 LINKS ÚTEIS
        # ========================================
        client: 'Alertmanager'
        client_url: 'http://alertmanager.empresa.com:9093'
        
        # ========================================
        # 📊 DETALHES CUSTOMIZADOS
        # ========================================
        details:
          alertname: '{{ .GroupLabels.alertname }}'
          instance: '{{ .GroupLabels.instance }}'
          severity: '{{ .GroupLabels.severity }}'
          environment: '{{ .GroupLabels.environment }}'
          team: '{{ .GroupLabels.team }}'
          firing_alerts: '{{ len .Alerts.Firing }}'
          resolved_alerts: '{{ len .Alerts.Resolved }}'
          started_at: '{{ range .Alerts.Firing }}{{ .StartsAt.Format "2006-01-02 15:04:05" }}{{ end }}'
          description: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
          runbook: '{{ range .Alerts }}{{ .Annotations.runbook_url }}{{ end }}'
        
        # ========================================
        # 🎯 IMAGENS E CONTEXTO
        # ========================================
        images:
          - src: 'http://grafana.empresa.com/render/d/alerts/alert-dashboard?panelId=1&width=400&height=200'
            alt: 'Gráfico do alerta'
            href: 'http://grafana.empresa.com/d/alerts/alert-dashboard'
        
        links:
          - href: 'http://prometheus.empresa.com:9090/graph'
            text: 'Ver no Prometheus'
          - href: 'http://grafana.empresa.com/d/alerts/alert-dashboard'
            text: 'Dashboard de Alertas'
          - href: '{{ range .Alerts }}{{ .Annotations.runbook_url }}{{ end }}'
            text: 'Runbook'
```

### 🔄 PagerDuty com Escalation

```yaml
receivers:
  # Nível 1 - Equipe primária
  - name: 'pagerduty-level1'
    pagerduty_configs:
      - routing_key: '${PAGERDUTY_L1_KEY}'
        description: '[L1] {{ .GroupLabels.alertname }}'
        severity: 'warning'
  
  # Nível 2 - Supervisores (após 15min)
  - name: 'pagerduty-level2'
    pagerduty_configs:
      - routing_key: '${PAGERDUTY_L2_KEY}'
        description: '[L2 ESCALATION] {{ .GroupLabels.alertname }}'
        severity: 'error'
  
  # Nível 3 - Gerência (após 30min)
  - name: 'pagerduty-level3'
    pagerduty_configs:
      - routing_key: '${PAGERDUTY_L3_KEY}'
        description: '[L3 CRITICAL ESCALATION] {{ .GroupLabels.alertname }}'
        severity: 'critical'
```

---

## 5. WEBHOOKS

### 🔗 Webhook Básico

```yaml
receivers:
  - name: 'webhook-basic'
    webhook_configs:
      - url: 'http://api.empresa.com/alerts'
        send_resolved: true
        http_config:
          basic_auth:
            username: 'alertmanager'
            password: '${WEBHOOK_PASSWORD}'
```

### 🎯 Webhook Avançado

```yaml
receivers:
  - name: 'webhook-advanced'
    webhook_configs:
      - url: 'http://api.empresa.com/v2/alerts'
        
        # ========================================
        # 🔒 AUTENTICAÇÃO
        # ========================================
        http_config:
          authorization:
            type: 'Bearer'
            credentials: '${API_TOKEN}'
          
          # Headers customizados
          headers:
            Content-Type: 'application/json'
            X-Source: 'Alertmanager'
            X-Environment: 'production'
        
        # ========================================
        # ⏰ CONFIGURAÇÕES DE TIMEOUT
        # ========================================
        max_alerts: 10                        # Máximo de alertas por request
        send_resolved: true                   # Enviar resoluções
        
        # ========================================
        # 🔄 RETRY E TIMEOUT
        # ========================================
        http_config:
          timeout: 30s
          proxy_url: 'http://proxy.empresa.com:8080'
          tls_config:
            insecure_skip_verify: false
            ca_file: '/etc/ssl/certs/ca.pem'
            cert_file: '/etc/ssl/certs/client.pem'
            key_file: '/etc/ssl/private/client.key'
```

### 📊 Webhook para Sistemas Específicos

```yaml
receivers:
  # 📈 Grafana Annotations
  - name: 'grafana-annotations'
    webhook_configs:
      - url: 'http://grafana:3000/api/annotations'
        http_config:
          authorization:
            type: 'Bearer'
            credentials: '${GRAFANA_API_KEY}'
        # Payload será o JSON padrão do Alertmanager
  
  # 📊 InfluxDB
  - name: 'influxdb-metrics'
    webhook_configs:
      - url: 'http://influxdb:8086/write?db=alerts'
        http_config:
          basic_auth:
            username: 'alertmanager'
            password: '${INFLUXDB_PASSWORD}'
  
  # 🎫 Jira (criar tickets)
  - name: 'jira-tickets'
    webhook_configs:
      - url: 'http://jira-webhook-service:8080/create-ticket'
        http_config:
          basic_auth:
            username: 'jira-bot'
            password: '${JIRA_PASSWORD}'
  
  # 💬 Microsoft Teams
  - name: 'teams-webhook'
    webhook_configs:
      - url: '${TEAMS_WEBHOOK_URL}'
        send_resolved: true
```

### 🔧 Webhook Personalizado com Template

```yaml
# Criar um serviço intermediário que recebe o JSON do Alertmanager
# e transforma para o formato desejado

# docker-compose.yml
services:
  webhook-transformer:
    image: nginx:alpine
    volumes:
      - ./webhook-transformer.lua:/etc/nginx/webhook.lua
    ports:
      - "8080:80"

# webhook-transformer.lua (usando OpenResty)
local json = require "cjson"

-- Receber JSON do Alertmanager
local body = ngx.req.get_body_data()
local alert_data = json.decode(body)

-- Transformar para formato customizado
local custom_payload = {
    timestamp = os.time(),
    source = "alertmanager",
    alerts = {}
}

for _, alert in ipairs(alert_data.alerts) do
    table.insert(custom_payload.alerts, {
        name = alert.labels.alertname,
        severity = alert.labels.severity,
        instance = alert.labels.instance,
        status = alert_data.status,
        description = alert.annotations.description
    })
end

-- Enviar para sistema final
local http = require "resty.http"
local httpc = http.new()
local res, err = httpc:request_uri("http://final-system/api/alerts", {
    method = "POST",
    body = json.encode(custom_payload),
    headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. os.getenv("API_TOKEN")
    }
})

ngx.status = 200
ngx.say("OK")
```

---

## 6. SMS E TELEGRAM

### 📲 SMS via Webhook

```yaml
# Usando serviço SMS (Twilio, AWS SNS, etc.)
receivers:
  - name: 'sms-critical'
    webhook_configs:
      - url: 'http://sms-service:8080/send'
        http_config:
          basic_auth:
            username: 'alertmanager'
            password: '${SMS_SERVICE_PASSWORD}'
        # O serviço SMS receberá o JSON e enviará SMS
```

### 🤖 Telegram Bot

```yaml
# Usando webhook para Telegram Bot
receivers:
  - name: 'telegram-alerts'
    webhook_configs:
      - url: 'http://telegram-bot:8080/alert'
        send_resolved: true

# telegram-bot service (Python exemplo)
# app.py
from flask import Flask, request
import requests
import json

app = Flask(__name__)

TELEGRAM_BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')
TELEGRAM_CHAT_ID = os.getenv('TELEGRAM_CHAT_ID')

@app.route('/alert', methods=['POST'])
def handle_alert():
    data = request.json
    
    # Formatar mensagem
    if data['status'] == 'firing':
        emoji = '🚨'
        status = 'ATIVO'
    else:
        emoji = '✅'
        status = 'RESOLVIDO'
    
    message = f"""{emoji} ALERTA {status}
    
Alerta: {data['groupLabels']['alertname']}
Severidade: {data['groupLabels']['severity']}
Instância: {data['groupLabels']['instance']}

Total de alertas: {len(data['alerts'])}
"""
    
    # Enviar para Telegram
    telegram_url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    payload = {
        'chat_id': TELEGRAM_CHAT_ID,
        'text': message,
        'parse_mode': 'HTML'
    }
    
    requests.post(telegram_url, json=payload)
    return 'OK'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```

---

## 7. MÚLTIPLOS CANAIS

### 🎯 Receiver com Múltiplos Canais

```yaml
receivers:
  - name: 'multi-channel-critical'
    # 📧 Email para documentação
    email_configs:
      - to: 'alerts-log@empresa.com'
        subject: '[CRÍTICO] {{ .GroupLabels.alertname }}'
        body: 'Alerta crítico registrado para auditoria.'
    
    # 💬 Slack para equipe
    slack_configs:
      - channel: '#alerts-critical'
        color: 'danger'
        title: '🚨 CRÍTICO: {{ .GroupLabels.alertname }}'
        text: '<!here> Alerta crítico detectado!'
    
    # 📱 PagerDuty para on-call
    pagerduty_configs:
      - routing_key: '${PAGERDUTY_CRITICAL_KEY}'
        description: 'CRÍTICO: {{ .GroupLabels.alertname }}'
        severity: 'critical'
    
    # 🔗 Webhook para sistema de tickets
    webhook_configs:
      - url: 'http://ticket-system:8080/create'
        http_config:
          basic_auth:
            username: 'alertmanager'
            password: '${TICKET_SYSTEM_PASSWORD}'
```

### 🎭 Canais por Contexto

```yaml
receivers:
  # 🌅 Horário comercial - Todos os canais
  - name: 'business-hours'
    email_configs:
      - to: 'team@empresa.com'
    slack_configs:
      - channel: '#alerts'
    webhook_configs:
      - url: 'http://dashboard:8080/alerts'
  
  # 🌙 Fora do horário - Só críticos
  - name: 'after-hours'
    pagerduty_configs:
      - routing_key: '${PAGERDUTY_ONCALL_KEY}'
        description: 'Alerta fora do horário: {{ .GroupLabels.alertname }}'
    email_configs:
      - to: 'oncall@empresa.com'
        subject: '[FORA DO HORÁRIO] {{ .GroupLabels.alertname }}'
  
  # 🎯 Produção - Máxima redundância
  - name: 'production-critical'
    pagerduty_configs:
      - routing_key: '${PAGERDUTY_PROD_KEY}'
    slack_configs:
      - channel: '#prod-alerts'
    email_configs:
      - to: 'prod-team@empresa.com'
    webhook_configs:
      - url: 'http://incident-manager:8080/create'
    # SMS via webhook
    webhook_configs:
      - url: 'http://sms-service:8080/emergency'
```

### 🔄 Fallback e Redundância

```yaml
receivers:
  - name: 'redundant-alerts'
    # Canal primário
    slack_configs:
      - channel: '#alerts'
        title: '{{ .GroupLabels.alertname }}'
        # Se Slack falhar, não afeta outros canais
    
    # Canal secundário (sempre funciona)
    email_configs:
      - to: 'backup-alerts@empresa.com'
        subject: '[BACKUP] {{ .GroupLabels.alertname }}'
    
    # Canal terciário (webhook confiável)
    webhook_configs:
      - url: 'http://reliable-service:8080/alerts'
        http_config:
          timeout: 10s
        max_alerts: 1  # Um por vez para garantir entrega
```

---

## 8. TROUBLESHOOTING

### 🔍 Problemas Comuns

#### 📧 Email não chega

```bash
# Verificar logs do Alertmanager
docker-compose logs alertmanager | grep -i smtp

# Testar SMTP manualmente
telnet smtp.gmail.com 587

# Verificar configuração
amtool config check alertmanager.yml

# Testar receiver específico
amtool alert add alertname="TestEmail" severity="warning"
```

#### 💬 Slack não funciona

```bash
# Verificar webhook URL
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Teste do Alertmanager"}' \
  https://hooks.slack.com/services/T00/B00/XXX

# Verificar logs
docker-compose logs alertmanager | grep -i slack

# Verificar permissões do bot
# - Bot deve estar no canal
# - Webhook deve ter permissões corretas
```

#### 📱 PagerDuty não dispara

```bash
# Testar integration key
curl -X POST https://events.pagerduty.com/v2/enqueue \
  -H 'Content-Type: application/json' \
  -d '{
    "routing_key": "YOUR_ROUTING_KEY",
    "event_action": "trigger",
    "payload": {
      "summary": "Teste do Alertmanager",
      "severity": "critical",
      "source": "alertmanager"
    }
  }'

# Verificar se integration está ativa no PagerDuty
# Verificar se routing_key está correto
```

### 🧪 Testando Receivers

```bash
# Enviar alerta de teste
amtool alert add \
  alertname="TestReceiver" \
  severity="warning" \
  instance="test-instance" \
  --alertmanager.url=http://localhost:9093

# Verificar se alerta foi recebido
amtool alert query --alertmanager.url=http://localhost:9093

# Verificar roteamento
amtool config routes test \
  --config.file=alertmanager.yml \
  alertname="TestReceiver" severity="warning"

# Silenciar alerta de teste
amtool silence add \
  alertname="TestReceiver" \
  --duration=1h \
  --comment="Teste finalizado"
```

### 📊 Monitoramento dos Receivers

```yaml
# Adicionar métricas no Prometheus
# prometheus.yml
scrape_configs:
  - job_name: 'alertmanager'
    static_configs:
      - targets: ['alertmanager:9093']

# Queries úteis
# Notificações enviadas por receiver
rate(alertmanager_notifications_total[5m])

# Falhas de notificação
rate(alertmanager_notifications_failed_total[5m])

# Latência de notificações
histogram_quantile(0.95, rate(alertmanager_notification_latency_seconds_bucket[5m]))
```

---

## 🎯 RESUMO DO MÓDULO

### ✅ O que você aprendeu:

1. **Conceitos de receivers** - Como funcionam os canais de notificação
2. **Email** - Configuração SMTP e templates HTML
3. **Slack** - Integração com cores, campos e formatação
4. **PagerDuty** - Alertas críticos com escalation
5. **Webhooks** - Integração com sistemas externos
6. **SMS/Telegram** - Canais alternativos via webhook
7. **Múltiplos canais** - Redundância e fallback
8. **Troubleshooting** - Diagnóstico e resolução de problemas

### 🔧 Principais tipos de receiver:
- **email_configs** - Notificações por email
- **slack_configs** - Integração com Slack
- **pagerduty_configs** - Alertas críticos
- **webhook_configs** - Sistemas personalizados

### 🚀 Próximos Passos

Agora que você domina os receivers, vamos aprender sobre **silenciamento e inibição**:

**Próximo módulo:** [06-silenciamento.md](06-silenciamento.md) - Silenciamento e inibição de alertas

---

## 🔗 Links Relacionados

- **[Anterior: Roteamento](04-roteamento.md)**
- **[Próximo: Silenciamento](06-silenciamento.md)**
- **[Voltar ao Índice](README.md)**