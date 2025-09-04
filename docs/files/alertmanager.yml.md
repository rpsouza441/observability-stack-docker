# Documentação: alertmanager.yml

## Visão Geral

O arquivo `alertmanager.yml` configura o Alertmanager, responsável por gerenciar alertas enviados pelo Prometheus. Esta configuração define como os alertas são agrupados, roteados, silenciados e enviados para diferentes canais de notificação como email, Slack, webhooks e outros sistemas.

## Estrutura da Configuração

### 1. Configurações Globais

```yaml
global:
  smtp_smarthost: '${SMTP_SMARTHOST:-localhost:587}'
  smtp_from: '${SMTP_FROM:-alertmanager@company.com}'
  smtp_auth_username: '${SMTP_USERNAME:-}'
  smtp_auth_password: '${SMTP_PASSWORD:-}'
  smtp_require_tls: true
  
  slack_api_url: '${SLACK_API_URL:-}'
  
  resolve_timeout: 5m
```

**Parâmetros SMTP:**
- **smtp_smarthost**: Servidor SMTP (host:porta)
- **smtp_from**: Endereço de origem dos emails
- **smtp_auth_username/password**: Credenciais de autenticação
- **smtp_require_tls**: Força uso de TLS/SSL

**Parâmetros Gerais:**
- **slack_api_url**: URL global da API do Slack
- **resolve_timeout**: Tempo para considerar alerta resolvido automaticamente

**Variáveis de Ambiente:**
```bash
# SMTP Configuration
SMTP_SMARTHOST=smtp.gmail.com:587
SMTP_FROM=alerts@mycompany.com
SMTP_USERNAME=alerts@mycompany.com
SMTP_PASSWORD=app_password_here

# Slack Configuration
SLACK_API_URL=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
```

### 2. Templates

```yaml
templates:
  - '/etc/alertmanager/templates/*.tmpl'
```

**Organização de Templates:**
```
templates/
├── email.tmpl          # Templates para email
├── slack.tmpl          # Templates para Slack
├── webhook.tmpl        # Templates para webhooks
└── common.tmpl         # Templates compartilhados
```

**Exemplo de Template (email.tmpl):**
```go
{{ define "email.subject" }}
[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] {{ .GroupLabels.SortedPairs.Values | join " " }}
{{ end }}

{{ define "email.html" }}
<h2>Alertas {{ .Status }}</h2>
<table border="1">
  <tr>
    <th>Alerta</th>
    <th>Severidade</th>
    <th>Instância</th>
    <th>Descrição</th>
    <th>Início</th>
  </tr>
  {{ range .Alerts }}
  <tr>
    <td>{{ .Labels.alertname }}</td>
    <td>{{ .Labels.severity }}</td>
    <td>{{ .Labels.instance }}</td>
    <td>{{ .Annotations.description }}</td>
    <td>{{ .StartsAt.Format "2006-01-02 15:04:05" }}</td>
  </tr>
  {{ end }}
</table>
{{ end }}
```

## Configuração de Roteamento

### 1. Rota Principal

```yaml
route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: '${GROUP_WAIT:-10s}'
  group_interval: '${GROUP_INTERVAL:-10s}'
  repeat_interval: '${REPEAT_INTERVAL:-12h}'
  receiver: 'default'
```

**Parâmetros de Agrupamento:**
- **group_by**: Labels usados para agrupar alertas
- **group_wait**: Tempo de espera antes de enviar grupo inicial
- **group_interval**: Tempo entre envios de novos alertas no grupo
- **repeat_interval**: Intervalo para reenvio de alertas não resolvidos
- **receiver**: Receptor padrão para alertas não roteados

### 2. Rotas Específicas

```yaml
route:
  routes:
    # Alertas Críticos - Notificação Imediata
    - match:
        severity: critical
      receiver: 'critical-alerts'
      group_wait: 0s
      group_interval: 5m
      repeat_interval: 30m
      continue: true  # Continua processando outras rotas
    
    # Alertas de Infraestrutura
    - match_re:
        alertname: '^(InstanceDown|NodeFilesystemSpaceFillingUp|NodeMemoryHighUtilization)$'
      receiver: 'infrastructure-team'
      group_by: ['alertname', 'instance']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 2h
    
    # Alertas de Aplicação
    - match:
        team: application
      receiver: 'application-team'
      group_by: ['alertname', 'service']
      group_wait: 1m
      group_interval: 10m
      repeat_interval: 4h
    
    # Alertas de Rede/SNMP
    - match:
        job: snmp-exporter
      receiver: 'network-team'
      group_by: ['alertname', 'instance']
      group_wait: 2m
      group_interval: 15m
      repeat_interval: 6h
    
    # Alertas de Monitoramento (Meta)
    - match_re:
        alertname: '^(PrometheusTargetDown|AlertmanagerDown|GrafanaDown)$'
      receiver: 'monitoring-team'
      group_wait: 0s
      group_interval: 1m
      repeat_interval: 15m
```

## Configuração de Receptores

### 1. Receptor Padrão

```yaml
receivers:
  - name: 'default'
    email_configs:
      - to: '${DEFAULT_EMAIL:-admin@company.com}'
        subject: '[ALERT] {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alerta: {{ .Labels.alertname }}
          Severidade: {{ .Labels.severity }}
          Instância: {{ .Labels.instance }}
          Descrição: {{ .Annotations.description }}
          {{ end }}
        html: '{{ template "email.html" . }}'
        headers:
          Subject: '{{ template "email.subject" . }}'
```

### 2. Alertas Críticos

```yaml
  - name: 'critical-alerts'
    # Webhook para n8n/automação
    webhook_configs:
      - url: 'http://n8n:5678/webhook/critical-alerts'
        send_resolved: true
        http_config:
          basic_auth:
            username: '${WEBHOOK_USERNAME:-monitoring}'
            password: '${WEBHOOK_PASSWORD:-}'
        title: 'Alerta Crítico: {{ .GroupLabels.alertname }}'
        text: |
          {{ range .Alerts }}
          🚨 **CRÍTICO**: {{ .Labels.alertname }}
          📍 **Instância**: {{ .Labels.instance }}
          📝 **Descrição**: {{ .Annotations.description }}
          ⏰ **Início**: {{ .StartsAt.Format "2006-01-02 15:04:05" }}
          {{ end }}
    
    # Slack para alertas críticos
    slack_configs:
      - api_url: '${SLACK_CRITICAL_URL:-}'
        channel: '${SLACK_CRITICAL_CHANNEL:-#alerts-critical}'
        username: 'Alertmanager'
        icon_emoji: ':rotating_light:'
        title: '🚨 Alerta Crítico'
        text: |
          {{ range .Alerts }}
          *Alerta:* {{ .Labels.alertname }}
          *Severidade:* {{ .Labels.severity }}
          *Instância:* {{ .Labels.instance }}
          *Descrição:* {{ .Annotations.description }}
          {{ if .Labels.runbook_url }}*Runbook:* {{ .Labels.runbook_url }}{{ end }}
          {{ end }}
        send_resolved: true
    
    # Email para alertas críticos
    email_configs:
      - to: '${CRITICAL_EMAIL:-oncall@company.com}'
        subject: '🚨 [CRÍTICO] {{ .GroupLabels.alertname }}'
        html: '{{ template "email.html" . }}'
        headers:
          Priority: 'high'
          X-Priority: '1'
```

### 3. Equipe de Infraestrutura

```yaml
  - name: 'infrastructure-team'
    email_configs:
      - to: '${INFRA_EMAIL:-infra@company.com}'
        subject: '[INFRA] {{ .GroupLabels.alertname }}'
        html: '{{ template "email.html" . }}'
    
    slack_configs:
      - channel: '#infra-alerts'
        username: 'Infrastructure Monitor'
        icon_emoji: ':construction:'
        title: '🏗️ Alerta de Infraestrutura'
        text: |
          {{ range .Alerts }}
          *Alerta:* {{ .Labels.alertname }}
          *Instância:* {{ .Labels.instance }}
          *Descrição:* {{ .Annotations.description }}
          {{ end }}
        send_resolved: true
```

### 4. Equipe de Aplicação

```yaml
  - name: 'application-team'
    email_configs:
      - to: '${APP_EMAIL:-dev@company.com}'
        subject: '[APP] {{ .GroupLabels.alertname }}'
        html: '{{ template "email.html" . }}'
    
    slack_configs:
      - channel: '#app-alerts'
        username: 'Application Monitor'
        icon_emoji: ':computer:'
        title: '💻 Alerta de Aplicação'
        text: |
          {{ range .Alerts }}
          *Alerta:* {{ .Labels.alertname }}
          *Serviço:* {{ .Labels.service }}
          *Descrição:* {{ .Annotations.description }}
          {{ end }}
        send_resolved: true
```

### 5. Equipe de Rede

```yaml
  - name: 'network-team'
    email_configs:
      - to: '${NETWORK_EMAIL:-network@company.com}'
        subject: '[REDE] {{ .GroupLabels.alertname }}'
        html: '{{ template "email.html" . }}'
    
    slack_configs:
      - channel: '#network-alerts'
        username: 'Network Monitor'
        icon_emoji: ':globe_with_meridians:'
        title: '🌐 Alerta de Rede'
        text: |
          {{ range .Alerts }}
          *Alerta:* {{ .Labels.alertname }}
          *Dispositivo:* {{ .Labels.instance }}
          *Descrição:* {{ .Annotations.description }}
          {{ end }}
        send_resolved: true
```

### 6. Equipe de Monitoramento

```yaml
  - name: 'monitoring-team'
    email_configs:
      - to: '${MONITORING_EMAIL:-monitoring@company.com}'
        subject: '[MONITORING] {{ .GroupLabels.alertname }}'
        html: '{{ template "email.html" . }}'
    
    slack_configs:
      - channel: '#monitoring-alerts'
        username: 'Meta Monitor'
        icon_emoji: ':chart_with_upwards_trend:'
        title: '📊 Alerta de Monitoramento'
        text: |
          {{ range .Alerts }}
          *Alerta:* {{ .Labels.alertname }}
          *Componente:* {{ .Labels.instance }}
          *Descrição:* {{ .Annotations.description }}
          {{ end }}
        send_resolved: true
```

## Regras de Inibição

```yaml
inhibit_rules:
  # Inibe alertas de instância quando o nó está down
  - source_match:
      alertname: 'InstanceDown'
    target_match_re:
      alertname: '^(NodeFilesystemSpaceFillingUp|NodeMemoryHighUtilization|NodeCPUHighUtilization)$'
    equal: ['instance']
  
  # Inibe alertas de aplicação quando o container está down
  - source_match:
      alertname: 'ContainerDown'
    target_match_re:
      alertname: '^(ApplicationResponseTime|ApplicationErrorRate)$'
    equal: ['container', 'instance']
  
  # Inibe alertas de warning quando há critical
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']
  
  # Inibe alertas de interface quando switch está down
  - source_match:
      alertname: 'SNMPDeviceDown'
    target_match_re:
      alertname: '^(SNMPInterfaceDown|SNMPHighTraffic)$'
    equal: ['instance']
```

## Configurações Avançadas

### 1. Múltiplos Webhooks

```yaml
  - name: 'webhook-integrations'
    webhook_configs:
      # n8n para automação
      - url: 'http://n8n:5678/webhook/alerts'
        send_resolved: true
        http_config:
          basic_auth:
            username: '${N8N_USERNAME:-}'
            password: '${N8N_PASSWORD:-}'
      
      # PagerDuty
      - url: 'https://events.pagerduty.com/v2/enqueue'
        send_resolved: true
        http_config:
          headers:
            Authorization: 'Token token=${PAGERDUTY_TOKEN}'
        title: '{{ .GroupLabels.alertname }}'
        text: |
          {{ range .Alerts }}
          {{ .Annotations.description }}
          {{ end }}
      
      # Microsoft Teams
      - url: '${TEAMS_WEBHOOK_URL:-}'
        send_resolved: true
        title: 'Alerta: {{ .GroupLabels.alertname }}'
        text: |
          {{ range .Alerts }}
          **Alerta:** {{ .Labels.alertname }}
          **Severidade:** {{ .Labels.severity }}
          **Instância:** {{ .Labels.instance }}
          **Descrição:** {{ .Annotations.description }}
          {{ end }}
```

### 2. Configuração de SMS (via webhook)

```yaml
  - name: 'sms-critical'
    webhook_configs:
      - url: 'https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json'
        send_resolved: false  # Não enviar SMS para resolução
        http_config:
          basic_auth:
            username: '${TWILIO_ACCOUNT_SID}'
            password: '${TWILIO_AUTH_TOKEN}'
        title: 'ALERTA CRÍTICO'
        text: |
          {{ range .Alerts }}
          CRÍTICO: {{ .Labels.alertname }}
          Host: {{ .Labels.instance }}
          {{ .Annotations.summary }}
          {{ end }}
```

### 3. Configuração Condicional

```yaml
route:
  routes:
    # Horário comercial - email + Slack
    - match:
        severity: warning
      receiver: 'business-hours'
      active_time_intervals:
        - business_hours
    
    # Fora do horário - apenas críticos
    - match:
        severity: critical
      receiver: 'after-hours'
      active_time_intervals:
        - after_hours

# Definição de intervalos de tempo
time_intervals:
  - name: business_hours
    time_intervals:
      - times:
          - start_time: '09:00'
            end_time: '18:00'
        weekdays: ['monday:friday']
        location: 'America/Sao_Paulo'
  
  - name: after_hours
    time_intervals:
      - times:
          - start_time: '18:01'
            end_time: '08:59'
        weekdays: ['monday:friday']
        location: 'America/Sao_Paulo'
      - weekdays: ['saturday', 'sunday']
        location: 'America/Sao_Paulo'
```

## Variáveis de Ambiente

### Arquivo .env Completo

```bash
# === CONFIGURAÇÕES GLOBAIS ===
GROUP_WAIT=10s
GROUP_INTERVAL=10s
REPEAT_INTERVAL=12h

# === SMTP ===
SMTP_SMARTHOST=smtp.gmail.com:587
SMTP_FROM=alerts@mycompany.com
SMTP_USERNAME=alerts@mycompany.com
SMTP_PASSWORD=app_password_here

# === EMAILS POR EQUIPE ===
DEFAULT_EMAIL=admin@mycompany.com
CRITICAL_EMAIL=oncall@mycompany.com
INFRA_EMAIL=infra@mycompany.com
APP_EMAIL=dev@mycompany.com
NETWORK_EMAIL=network@mycompany.com
MONITORING_EMAIL=monitoring@mycompany.com

# === SLACK ===
SLACK_API_URL=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
SLACK_CRITICAL_URL=https://hooks.slack.com/services/T00000000/B00000001/YYYYYYYYYYYYYYYYYYYYYYYY
SLACK_CRITICAL_CHANNEL=#alerts-critical

# === WEBHOOKS ===
WEBHOOK_USERNAME=monitoring
WEBHOOK_PASSWORD=secure_password_here
N8N_USERNAME=alertmanager
N8N_PASSWORD=n8n_password_here

# === INTEGRAÇÕES EXTERNAS ===
PAGERDUTY_TOKEN=your_pagerduty_integration_key
TEAMS_WEBHOOK_URL=https://outlook.office.com/webhook/...
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
```

## Troubleshooting

### 1. Validação da Configuração

```bash
# Verificar sintaxe
amtool check-config alertmanager.yml

# Testar roteamento
amtool config routes --config.file=alertmanager.yml

# Testar templates
amtool template --config.file=alertmanager.yml --template.file=templates/email.tmpl
```

### 2. Teste de Alertas

```bash
# Enviar alerta de teste
curl -XPOST http://localhost:9093/api/v1/alerts -H 'Content-Type: application/json' -d '[
  {
    "labels": {
      "alertname": "TestAlert",
      "severity": "warning",
      "instance": "test-instance"
    },
    "annotations": {
      "summary": "Teste de alerta",
      "description": "Este é um alerta de teste"
    },
    "startsAt": "'$(date -Iseconds)'",
    "endsAt": "'$(date -d '+5 minutes' -Iseconds)'"
  }
]'
```

### 3. Debugging

```bash
# Ver alertas ativos
curl http://localhost:9093/api/v1/alerts

# Ver status dos receivers
curl http://localhost:9093/api/v1/status

# Ver silenciamentos
curl http://localhost:9093/api/v1/silences
```

### 4. Logs Úteis

```bash
# Ver logs do Alertmanager
docker-compose logs alertmanager

# Logs com filtro
docker-compose logs alertmanager | grep -E '(error|failed|timeout)'

# Logs em tempo real
docker-compose logs -f alertmanager
```

## Melhores Práticas

### 1. Organização

- **Agrupe alertas por equipe/responsabilidade**
- **Use templates para padronizar mensagens**
- **Documente rotas e receivers**
- **Mantenha configurações em controle de versão**

### 2. Performance

- **Configure group_wait adequadamente**
- **Use inibição para reduzir ruído**
- **Monitore latência de notificações**
- **Limite número de alertas por grupo**

### 3. Segurança

- **Use variáveis de ambiente para credenciais**
- **Configure TLS para SMTP**
- **Limite acesso à API do Alertmanager**
- **Monitore tentativas de acesso não autorizado**

### 4. Manutenção

- **Teste mudanças em ambiente de desenvolvimento**
- **Monitore taxa de entrega de notificações**
- **Revise e ajuste regras de inibição regularmente**
- **Mantenha templates atualizados**

### 5. Escalabilidade

- **Configure clustering para alta disponibilidade**
- **Use service discovery quando possível**
- **Monitore uso de recursos do Alertmanager**
- **Implemente backup de configurações**

Este arquivo é essencial para o funcionamento efetivo do sistema de alertas e deve ser configurado cuidadosamente para atender às necessidades específicas da organização.