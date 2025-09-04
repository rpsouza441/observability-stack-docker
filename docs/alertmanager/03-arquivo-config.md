# 📝 ALERTMANAGER - ENTENDENDO O ARQUIVO DE CONFIGURAÇÃO

> **Módulo 3:** Dominando o alertmanager.yml

---

## 📋 CONTEÚDO DESTE MÓDULO

1. [Estrutura Básica](#1-estrutura-básica)
2. [Seção Global](#2-seção-global)
3. [Templates](#3-templates)
4. [Configurações de Timing](#4-configurações-de-timing)
5. [Variáveis de Ambiente](#5-variáveis-de-ambiente)

---

## 1. ESTRUTURA BÁSICA

### 📄 Anatomia do alertmanager.yml

```yaml
# alertmanager.yml - Estrutura completa

# ========================================
# 🌍 CONFIGURAÇÕES GLOBAIS
# ========================================
global:
  # Configurações SMTP, Slack, etc.
  smtp_smarthost: 'smtp.empresa.com:587'
  smtp_from: 'alerts@empresa.com'
  resolve_timeout: 5m

# ========================================
# 📝 TEMPLATES PERSONALIZADOS
# ========================================
templates:
  - 'templates/*.tmpl'

# ========================================
# 🛤️ ROTEAMENTO DE ALERTAS
# ========================================
route:
  group_by: ['alertname', 'cluster']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'default'
  
  routes:
    - match:
        severity: critical
      receiver: 'critical-team'

# ========================================
# 🚫 INIBIÇÃO DE ALERTAS
# ========================================
inhibit_rules:
  - source_match:
      alertname: 'DatacenterDown'
    target_match:
      alertname: 'InstanceDown'
    equal: ['datacenter']

# ========================================
# 📡 RECEIVERS (DESTINOS)
# ========================================
receivers:
  - name: 'default'
    email_configs:
      - to: 'admin@empresa.com'
        subject: '[ALERTA] {{ .GroupLabels.alertname }}'
  
  - name: 'critical-team'
    slack_configs:
      - channel: '#alerts-critical'
        title: '🚨 Alerta Crítico'
```

### 🔍 Seções Obrigatórias vs Opcionais

```yaml
# ✅ OBRIGATÓRIAS
route:          # Como rotear alertas
  receiver: 'default'
receivers:      # Onde enviar alertas
  - name: 'default'

# 🔧 OPCIONAIS
global:         # Configurações globais
templates:      # Templates personalizados
inhibit_rules:  # Regras de inibição
```

---

## 2. SEÇÃO GLOBAL

### 🌍 Configurações Globais Comuns

```yaml
global:
  # ⏰ TIMEOUTS E INTERVALOS
  resolve_timeout: 5m              # Tempo para considerar alerta resolvido
  
  # 📧 CONFIGURAÇÕES SMTP
  smtp_smarthost: 'smtp.gmail.com:587'     # Servidor SMTP
  smtp_from: 'noreply@empresa.com'         # Email remetente
  smtp_auth_username: 'usuario@gmail.com'  # Usuário SMTP
  smtp_auth_password: 'senha-app'          # Senha SMTP
  smtp_require_tls: true                   # Usar TLS
  smtp_hello: 'alertmanager.empresa.com'  # HELO/EHLO hostname
  
  # 💬 CONFIGURAÇÕES SLACK
  slack_api_url: 'https://hooks.slack.com/services/T00/B00/XXX'
  
  # 📱 CONFIGURAÇÕES PAGERDUTY
  pagerduty_url: 'https://events.pagerduty.com/v2/enqueue'
  
  # 🌐 CONFIGURAÇÕES HTTP
  http_config:
    proxy_url: 'http://proxy.empresa.com:8080'
    tls_config:
      insecure_skip_verify: false
  
  # 🔗 URLS EXTERNAS
  wechat_api_url: 'https://qyapi.weixin.qq.com/cgi-bin/'
  victorops_api_url: 'https://alert.victorops.com/integrations/generic/20131114/alert/'
```

### 📧 Configuração SMTP Detalhada

```yaml
global:
  # Gmail
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@empresa.com'
  smtp_auth_username: 'alerts@empresa.com'
  smtp_auth_password: 'senha-de-app'      # Use senha de app, não senha normal
  smtp_require_tls: true
  
  # Outlook/Office 365
  smtp_smarthost: 'smtp-mail.outlook.com:587'
  smtp_from: 'alerts@empresa.com'
  smtp_auth_username: 'alerts@empresa.com'
  smtp_auth_password: 'senha123'
  smtp_require_tls: true
  
  # Servidor corporativo
  smtp_smarthost: 'mail.empresa.com:25'
  smtp_from: 'alertmanager@empresa.com'
  smtp_hello: 'alertmanager.empresa.com'
  smtp_require_tls: false                  # Servidor interno sem TLS
```

### 🔐 Configuração com Autenticação

```yaml
global:
  # SMTP com autenticação PLAIN
  smtp_smarthost: 'smtp.empresa.com:587'
  smtp_auth_username: 'usuario'
  smtp_auth_password: 'senha'
  smtp_auth_secret: 'segredo'              # Para CRAM-MD5
  smtp_auth_identity: 'identidade'         # Para PLAIN
  
  # HTTP com autenticação básica
  http_config:
    basic_auth:
      username: 'usuario'
      password: 'senha'
    
    # Ou com bearer token
    authorization:
      type: 'Bearer'
      credentials: 'token-jwt'
```

---

## 3. TEMPLATES

### 📝 Carregando Templates

```yaml
templates:
  - 'templates/*.tmpl'              # Todos os arquivos .tmpl
  - 'templates/email.tmpl'          # Arquivo específico
  - '/etc/alertmanager/custom.tmpl' # Caminho absoluto
  - 'https://example.com/tmpl'      # URL remota (não recomendado)
```

### 📄 Exemplo de Template Simples

```go
{{/* templates/email.tmpl */}}
{{ define "email.subject" }}
[{{ .Status | toUpper }}] {{ .GroupLabels.alertname }}
{{ end }}

{{ define "email.body" }}
{{ if gt (len .Alerts.Firing) 0 }}
🔥 ALERTAS ATIVOS:
{{ range .Alerts.Firing }}
- {{ .Annotations.summary }}
  Instância: {{ .Labels.instance }}
  Severidade: {{ .Labels.severity }}
{{ end }}
{{ end }}

{{ if gt (len .Alerts.Resolved) 0 }}
✅ ALERTAS RESOLVIDOS:
{{ range .Alerts.Resolved }}
- {{ .Annotations.summary }}
{{ end }}
{{ end }}
{{ end }}
```

### 🎨 Usando Templates nos Receivers

```yaml
receivers:
  - name: 'email-team'
    email_configs:
      - to: 'team@empresa.com'
        subject: '{{ template "email.subject" . }}'
        body: '{{ template "email.body" . }}'
        html: '{{ template "email.html" . }}'
```

---

## 4. CONFIGURAÇÕES DE TIMING

### ⏰ Entendendo os Timings

```yaml
route:
  group_wait: 10s      # ⏰ Aguarda 10s coletando alertas do mesmo grupo
  group_interval: 5m   # ⏰ Após enviar, aguarda 5m antes de enviar novos do grupo
  repeat_interval: 4h  # ⏰ Se alerta não resolver, reenvia a cada 4h
```

### 📊 Exemplo Prático de Timing

```
Cenário: 3 servidores web ficam com CPU alta

00:00:00 - web-01 CPU > 80% → Alerta A dispara
00:00:05 - web-02 CPU > 80% → Alerta B dispara (mesmo grupo)
00:00:10 - Envia notificação com A+B (group_wait = 10s atingido)
00:00:15 - web-03 CPU > 80% → Alerta C dispara (mesmo grupo)
00:05:10 - Envia notificação com C (group_interval = 5m atingido)
04:00:10 - Reenvia A+B+C se ainda ativos (repeat_interval = 4h)
```

### 🎯 Configurações por Severidade

```yaml
route:
  receiver: 'default'
  routes:
    # Crítico: Sem espera, reenvia frequentemente
    - match:
        severity: critical
      receiver: 'oncall-team'
      group_wait: 0s        # Envia imediatamente
      repeat_interval: 5m   # Reenvia a cada 5min
    
    # Warning: Espera um pouco, reenvia menos
    - match:
        severity: warning
      receiver: 'team-slack'
      group_wait: 30s       # Aguarda 30s
      repeat_interval: 2h   # Reenvia a cada 2h
    
    # Info: Agrupa bastante, reenvia raramente
    - match:
        severity: info
      receiver: 'logs-webhook'
      group_wait: 5m        # Aguarda 5min
      repeat_interval: 24h  # Reenvia a cada 24h
```

---

## 5. VARIÁVEIS DE AMBIENTE

### 🔐 Usando Variáveis para Segurança

```yaml
# alertmanager.yml com variáveis
global:
  smtp_smarthost: '${SMTP_HOST}:${SMTP_PORT}'
  smtp_from: '${SMTP_FROM}'
  smtp_auth_username: '${SMTP_USERNAME}'
  smtp_auth_password: '${SMTP_PASSWORD}'
  slack_api_url: '${SLACK_WEBHOOK_URL}'

receivers:
  - name: 'pagerduty'
    pagerduty_configs:
      - routing_key: '${PAGERDUTY_ROUTING_KEY}'
```

### 🐳 Arquivo .env para Docker

```bash
# .env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_FROM=alerts@empresa.com
SMTP_USERNAME=alerts@empresa.com
SMTP_PASSWORD=senha-de-app-gmail
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T00/B00/XXX
PAGERDUTY_ROUTING_KEY=abc123def456
```

### 🔧 Docker Compose com Variáveis

```yaml
# docker-compose.yml
version: '3.8'

services:
  alertmanager:
    image: prom/alertmanager:v0.25.0
    env_file:
      - .env
    environment:
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_PORT=${SMTP_PORT}
      - SMTP_USERNAME=${SMTP_USERNAME}
      - SMTP_PASSWORD=${SMTP_PASSWORD}
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
```

### 🛡️ Boas Práticas de Segurança

```yaml
# ❌ NUNCA faça isso (credenciais no código)
global:
  smtp_auth_password: 'minha-senha-123'
  slack_api_url: 'https://hooks.slack.com/services/T123/B456/token-secreto'

# ✅ SEMPRE use variáveis de ambiente
global:
  smtp_auth_password: '${SMTP_PASSWORD}'
  slack_api_url: '${SLACK_WEBHOOK_URL}'

# ✅ Ou use arquivos de segredos
global:
  smtp_auth_password_file: '/run/secrets/smtp_password'
  slack_api_url_file: '/run/secrets/slack_webhook'
```

### 📁 Usando Arquivos de Segredos

```yaml
# alertmanager.yml
global:
  smtp_auth_password_file: '/etc/alertmanager/secrets/smtp_password'
  
receivers:
  - name: 'slack'
    slack_configs:
      - api_url_file: '/etc/alertmanager/secrets/slack_webhook'
```

```bash
# Criar arquivos de segredos
echo 'minha-senha-smtp' > secrets/smtp_password
echo 'https://hooks.slack.com/...' > secrets/slack_webhook

# Montar no container
docker run -v ./secrets:/etc/alertmanager/secrets prom/alertmanager
```

---

## 🧪 VALIDAÇÃO DA CONFIGURAÇÃO

### ✅ Verificar Sintaxe

```bash
# Usar amtool para validar
amtool config check alertmanager.yml

# Saída esperada se OK:
# Checking 'alertmanager.yml'  SUCCESS
# Found:
# - global config
# - route
# - 2 inhibit rules
# - 3 receivers
```

### 🔍 Testar Configuração

```bash
# Testar roteamento
amtool config routes test \
  --config.file=alertmanager.yml \
  --tree \
  severity=critical team=database

# Resultado:
# Matched: dba-critical
```

### 🚀 Recarregar Configuração

```bash
# Recarregar sem reiniciar (hot reload)
curl -X POST http://localhost:9093/-/reload

# Ou via Docker
docker-compose exec alertmanager kill -HUP 1

# Verificar se carregou
curl http://localhost:9093/api/v2/status | jq '.configYAML'
```

---

## 🎯 RESUMO DO MÓDULO

### ✅ O que você aprendeu:

1. **Estrutura do alertmanager.yml** com 5 seções principais
2. **Configurações globais** para SMTP, Slack, timeouts
3. **Templates** para personalizar mensagens
4. **Configurações de timing** para controlar quando enviar
5. **Variáveis de ambiente** para segurança
6. **Validação** da configuração com amtool

### 🔧 Principais seções:
- `global` - Configurações compartilhadas
- `templates` - Arquivos de template
- `route` - Como rotear alertas
- `inhibit_rules` - Regras de supressão
- `receivers` - Destinos das notificações

### 🚀 Próximos Passos

Agora que você domina o arquivo de configuração, vamos aprender sobre **roteamento avançado**:

**Próximo módulo:** [04-roteamento.md](04-roteamento.md) - Roteamento de alertas

---

## 🔗 Links Relacionados

- **[Anterior: Configuração](02-configuracao.md)**
- **[Próximo: Roteamento](04-roteamento.md)**
- **[Voltar ao Índice](README.md)**