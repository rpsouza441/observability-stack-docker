# 🔧 Módulo 8: Troubleshooting do Alertmanager

> **Objetivo:** Aprender a diagnosticar e resolver problemas comuns do Alertmanager

---

## 📋 ÍNDICE

1. [Diagnóstico Inicial](#1-diagnóstico-inicial)
2. [Logs e Debugging](#2-logs-e-debugging)
3. [Métricas de Monitoramento](#3-métricas-de-monitoramento)
4. [Problemas de Configuração](#4-problemas-de-configuração)
5. [Problemas de Conectividade](#5-problemas-de-conectividade)
6. [Problemas de Notificação](#6-problemas-de-notificação)
7. [Problemas de Performance](#7-problemas-de-performance)
8. [Ferramentas de Diagnóstico](#8-ferramentas-de-diagnóstico)
9. [Cenários Comuns](#9-cenários-comuns)
10. [Prevenção de Problemas](#10-prevenção-de-problemas)

---

## 1. DIAGNÓSTICO INICIAL

### 🩺 Checklist de Saúde

#### ✅ Verificações Básicas
```bash
# 1. Status do serviço
docker-compose ps alertmanager

# 2. Logs recentes
docker-compose logs --tail=50 alertmanager

# 3. Conectividade
curl -s http://localhost:9093/-/healthy

# 4. Configuração válida
docker exec alertmanager amtool config show

# 5. Alertas ativos
curl -s http://localhost:9093/api/v1/alerts | jq '.data | length'
```

#### 🔍 Status da Interface Web
```bash
# Verificar se a interface está acessível
curl -I http://localhost:9093/

# Verificar API
curl -s http://localhost:9093/api/v1/status | jq '.status'

# Verificar receivers
curl -s http://localhost:9093/api/v1/receivers | jq '.data[].name'
```

### 📊 Dashboard de Saúde

#### 🎯 Métricas Essenciais
```promql
# Alertmanager está rodando?
up{job="alertmanager"}

# Alertas sendo processados?
rate(alertmanager_alerts_received_total[5m])

# Notificações sendo enviadas?
rate(alertmanager_notifications_total[5m])

# Erros de notificação?
rate(alertmanager_notifications_failed_total[5m])
```

---

## 2. LOGS E DEBUGGING

### 📝 Configuração de Logs

#### 🔧 Níveis de Log
```yaml
# alertmanager.yml
global:
  # Configurações globais...

# Via linha de comando
command:
  - '--log.level=debug'    # debug, info, warn, error
  - '--log.format=json'    # json ou logfmt
```

#### 🐳 Docker Compose com Debug
```yaml
# compose.yml
services:
  alertmanager:
    image: prom/alertmanager:latest
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://localhost:9093'
      - '--log.level=debug'
      - '--log.format=json'
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
    ports:
      - "9093:9093"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 🔍 Análise de Logs

#### 📋 Logs Importantes
```bash
# Logs de inicialização
docker-compose logs alertmanager | grep -E "(Starting|Listening|Config)"

# Logs de erro
docker-compose logs alertmanager | grep -E "(ERROR|WARN|error|failed)"

# Logs de notificação
docker-compose logs alertmanager | grep -E "(notification|notify|sent)"

# Logs de configuração
docker-compose logs alertmanager | grep -E "(config|reload|template)"
```

#### 🎯 Padrões de Log
```json
// Log de sucesso na notificação
{
  "level": "info",
  "ts": "2024-01-15T10:30:00.000Z",
  "caller": "notify/notify.go:732",
  "msg": "Completed successfully",
  "receiver": "web.hook",
  "integration": "webhook",
  "attempts": 1
}

// Log de erro na notificação
{
  "level": "error",
  "ts": "2024-01-15T10:30:00.000Z",
  "caller": "notify/webhook.go:108",
  "msg": "Notify attempt failed",
  "receiver": "web.hook",
  "integration": "webhook",
  "attempts": 1,
  "err": "Post \"http://webhook.example.com\": dial tcp: connection refused"
}
```

### 🔧 Debug Avançado

#### 🎯 Rastreamento de Alertas
```bash
# Seguir logs em tempo real
docker-compose logs -f alertmanager

# Filtrar por alerta específico
docker-compose logs alertmanager | grep "DatabaseDown"

# Filtrar por receiver
docker-compose logs alertmanager | grep "slack-alerts"

# Logs estruturados com jq
docker-compose logs alertmanager --since=1h | \
  grep '^{' | jq 'select(.receiver == "slack-alerts")'
```

---

## 3. MÉTRICAS DE MONITORAMENTO

### 📊 Métricas Essenciais

#### 🎯 Alertas Recebidos
```promql
# Taxa de alertas recebidos
rate(alertmanager_alerts_received_total[5m])

# Alertas ativos por estado
alertmanager_alerts{state="active"}
alertmanager_alerts{state="suppressed"}

# Alertas inválidos
rate(alertmanager_alerts_invalid_total[5m])
```

#### 📤 Notificações
```promql
# Taxa de notificações enviadas
rate(alertmanager_notifications_total[5m])

# Taxa de falhas por receiver
rate(alertmanager_notifications_failed_total[5m]) by (receiver)

# Latência de notificações
histogram_quantile(0.95, 
  rate(alertmanager_notification_latency_seconds_bucket[5m])
) by (receiver)
```

#### 🔄 Configuração
```promql
# Última recarga de configuração
alertmanager_config_last_reload_success_timestamp_seconds

# Falhas na recarga
rate(alertmanager_config_last_reload_successful[5m]) == 0

# Hash da configuração atual
alertmanager_config_hash
```

### 📈 Dashboard de Monitoramento

#### 🎯 Grafana Dashboard
```json
{
  "dashboard": {
    "title": "Alertmanager Health",
    "panels": [
      {
        "title": "Alerts Received Rate",
        "type": "graph",
        "targets": [{
          "expr": "rate(alertmanager_alerts_received_total[5m])"
        }]
      },
      {
        "title": "Notification Success Rate",
        "type": "stat",
        "targets": [{
          "expr": "(
            rate(alertmanager_notifications_total[5m]) - 
            rate(alertmanager_notifications_failed_total[5m])
          ) / rate(alertmanager_notifications_total[5m]) * 100"
        }]
      },
      {
        "title": "Active Alerts",
        "type": "stat",
        "targets": [{
          "expr": "alertmanager_alerts{state=\"active\"}"
        }]
      }
    ]
  }
}
```

---

## 4. PROBLEMAS DE CONFIGURAÇÃO

### ❌ Erros Comuns

#### 🔧 Sintaxe YAML
```yaml
# ❌ ERRO - Indentação incorreta
route:
default_receiver: 'web.hook'
group_wait: 10s

# ✅ CORRETO - Indentação correta
route:
  default_receiver: 'web.hook'
  group_wait: 10s
```

#### 📧 Configuração de Email
```yaml
# ❌ ERRO - Configuração incompleta
receivers:
- name: 'email-alerts'
  email_configs:
  - to: 'admin@example.com'

# ✅ CORRETO - Configuração completa
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@example.com'
  smtp_auth_username: 'alerts@example.com'
  smtp_auth_password: 'app-password'

receivers:
- name: 'email-alerts'
  email_configs:
  - to: 'admin@example.com'
    subject: 'Alert: {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      {{ end }}
```

### 🔍 Validação de Configuração

#### ✅ Usando amtool
```bash
# Validar configuração
amtool config check alertmanager.yml

# Mostrar configuração processada
amtool config show --alertmanager.url=http://localhost:9093

# Testar roteamento
amtool config routes test \
  --config.file=alertmanager.yml \
  --tree \
  severity=critical alertname=DatabaseDown
```

#### 🧪 Teste de Templates
```bash
# Testar template específico
amtool template test \
  --template.file=templates/email.tmpl \
  --template.name=email.subject \
  --template.data-file=test-alert.json

# Arquivo de teste (test-alert.json)
{
  "Status": "firing",
  "GroupLabels": {"alertname": "TestAlert"},
  "CommonLabels": {"severity": "warning"},
  "Alerts": [{
    "Status": "firing",
    "Labels": {"instance": "localhost:9090"},
    "Annotations": {"summary": "Test alert"}
  }]
}
```

---

## 5. PROBLEMAS DE CONECTIVIDADE

### 🌐 Diagnóstico de Rede

#### 🔍 Testes de Conectividade
```bash
# Testar conectividade com Prometheus
curl -s http://prometheus:9090/api/v1/query?query=up

# Testar webhook
curl -X POST http://webhook.example.com/alerts \
  -H "Content-Type: application/json" \
  -d '[{"status":"firing","labels":{"alertname":"test"}}]'

# Testar SMTP
telnet smtp.gmail.com 587

# Testar Slack webhook
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -H "Content-Type: application/json" \
  -d '{"text":"Test message"}'
```

#### 🐳 Problemas Docker
```bash
# Verificar rede Docker
docker network ls
docker network inspect observability-stack-docker_default

# Testar conectividade entre containers
docker exec alertmanager ping prometheus
docker exec alertmanager nslookup prometheus

# Verificar portas expostas
docker port alertmanager
netstat -tlnp | grep 9093
```

### 🔧 Resolução de Problemas

#### 🌐 Proxy e Firewall
```bash
# Verificar variáveis de proxy
echo $HTTP_PROXY
echo $HTTPS_PROXY
echo $NO_PROXY

# Testar sem proxy
unset HTTP_PROXY HTTPS_PROXY
curl -s http://webhook.example.com/test

# Verificar firewall (Linux)
sudo iptables -L
sudo ufw status

# Verificar firewall (Windows)
netsh advfirewall show allprofiles
```

---

## 6. PROBLEMAS DE NOTIFICAÇÃO

### 📧 Email

#### ❌ Problemas Comuns
```yaml
# Problema: Autenticação SMTP
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@example.com'
  # ❌ Faltando autenticação

# Solução: Adicionar credenciais
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@example.com'
  smtp_auth_username: 'alerts@example.com'
  smtp_auth_password: 'app-password'  # Use App Password, não senha normal
  smtp_require_tls: true
```

#### 🔍 Debug de Email
```bash
# Testar SMTP manualmente
openssl s_client -connect smtp.gmail.com:587 -starttls smtp

# Logs específicos de email
docker-compose logs alertmanager | grep -i "email\|smtp"

# Verificar configuração TLS
curl -v --ssl smtp://smtp.gmail.com:587
```

### 💬 Slack

#### ❌ Problemas Comuns
```yaml
# Problema: URL de webhook inválida
receivers:
- name: 'slack-alerts'
  slack_configs:
  - api_url: 'https://hooks.slack.com/invalid-url'  # ❌ URL incorreta

# Solução: URL correta e configuração completa
receivers:
- name: 'slack-alerts'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX'
    channel: '#alerts'
    username: 'Alertmanager'
    title: 'Alert: {{ .GroupLabels.alertname }}'
    text: |
      {{ range .Alerts }}
      *Alert:* {{ .Annotations.summary }}
      *Severity:* {{ .Labels.severity }}
      {{ end }}
```

#### 🔍 Debug de Slack
```bash
# Testar webhook manualmente
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -H "Content-Type: application/json" \
  -d '{
    "channel": "#alerts",
    "username": "Test",
    "text": "Test message from curl"
  }'

# Verificar resposta do Slack
curl -v -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -H "Content-Type: application/json" \
  -d '{"text":"test"}' 2>&1 | grep -E "(HTTP|ok|invalid)"
```

### 🔗 Webhook

#### ❌ Problemas Comuns
```bash
# Problema: Endpoint não responde
curl -X POST http://webhook.example.com/alerts
# curl: (7) Failed to connect to webhook.example.com port 80: Connection refused

# Diagnóstico
# 1. Verificar se o serviço está rodando
ping webhook.example.com
nslookup webhook.example.com

# 2. Verificar porta
telnet webhook.example.com 80

# 3. Testar com timeout
curl --connect-timeout 10 -X POST http://webhook.example.com/alerts
```

---

## 7. PROBLEMAS DE PERFORMANCE

### 📊 Identificação de Gargalos

#### 🎯 Métricas de Performance
```promql
# Latência de notificações
histogram_quantile(0.95, 
  rate(alertmanager_notification_latency_seconds_bucket[5m])
)

# Uso de memória
process_resident_memory_bytes{job="alertmanager"}

# Uso de CPU
rate(process_cpu_seconds_total{job="alertmanager"}[5m])

# Alertas em fila
alertmanager_alerts_received_total - alertmanager_alerts_processed_total
```

#### 🔍 Análise de Logs
```bash
# Notificações lentas
docker-compose logs alertmanager | \
  grep "notification_latency" | \
  grep -E "[5-9][0-9]{3}ms|[0-9]+s"

# Timeouts
docker-compose logs alertmanager | grep -i timeout

# Erros de memória
docker-compose logs alertmanager | grep -i "out of memory\|oom"
```

### ⚡ Otimizações

#### 🔧 Configuração de Performance
```yaml
# alertmanager.yml - Otimizações
global:
  # Reduzir timeouts para falhas rápidas
  smtp_timeout: 30s
  slack_api_url_timeout: 10s
  
route:
  # Agrupar mais alertas para reduzir notificações
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
  
  # Agrupar por mais labels
  group_by: ['alertname', 'cluster', 'service']

receivers:
- name: 'optimized-webhook'
  webhook_configs:
  - url: 'http://webhook.example.com/alerts'
    # Reduzir timeout
    timeout: 10s
    # Não enviar alertas resolvidos se não necessário
    send_resolved: false
```

#### 🐳 Docker Otimizado
```yaml
# compose.yml - Recursos otimizados
services:
  alertmanager:
    image: prom/alertmanager:latest
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'
    # Usar volume para persistência
    volumes:
      - alertmanager-data:/alertmanager
    # Configurar healthcheck
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9093/-/healthy"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  alertmanager-data:
```

---

## 8. FERRAMENTAS DE DIAGNÓSTICO

### 🛠️ amtool

#### 📋 Comandos Essenciais
```bash
# Status geral
amtool --alertmanager.url=http://localhost:9093 status

# Listar alertas
amtool --alertmanager.url=http://localhost:9093 alert query

# Alertas por severity
amtool alert query severity=critical

# Silences ativos
amtool silence query

# Configuração atual
amtool config show

# Testar roteamento
amtool config routes test severity=critical alertname=DatabaseDown
```

#### 🧪 Simulação de Alertas
```bash
# Criar alerta de teste
amtool alert add \
  alertname="TestAlert" \
  severity="warning" \
  instance="localhost:9090" \
  summary="Alert de teste"

# Verificar se foi processado
amtool alert query alertname="TestAlert"

# Criar silence para teste
amtool silence add \
  alertname="TestAlert" \
  --duration="1h" \
  --comment="Teste de silence"
```

### 🔍 Scripts de Diagnóstico

#### 🩺 Health Check Completo
```bash
#!/bin/bash
# alertmanager-health-check.sh

AM_URL="http://localhost:9093"
ERRORS=0

echo "🔍 Alertmanager Health Check"
echo "================================"

# 1. Verificar se está rodando
echo -n "📡 Conectividade: "
if curl -s "$AM_URL/-/healthy" >/dev/null; then
    echo "✅ OK"
else
    echo "❌ FALHA - Alertmanager não está acessível"
    ((ERRORS++))
fi

# 2. Verificar configuração
echo -n "⚙️  Configuração: "
if amtool --alertmanager.url="$AM_URL" config show >/dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ FALHA - Configuração inválida"
    ((ERRORS++))
fi

# 3. Verificar alertas
echo -n "🚨 Alertas ativos: "
ALERT_COUNT=$(amtool --alertmanager.url="$AM_URL" alert query --output=json 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")
echo "$ALERT_COUNT alertas"

# 4. Verificar silences
echo -n "🔇 Silences ativos: "
SILENCE_COUNT=$(amtool --alertmanager.url="$AM_URL" silence query --output=json 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")
echo "$SILENCE_COUNT silences"

# 5. Verificar métricas
echo -n "📊 Métricas: "
if curl -s "$AM_URL/metrics" | grep -q "alertmanager_build_info"; then
    echo "✅ OK"
else
    echo "❌ FALHA - Métricas não disponíveis"
    ((ERRORS++))
fi

echo "================================"
if [ $ERRORS -eq 0 ]; then
    echo "✅ Alertmanager está saudável!"
    exit 0
else
    echo "❌ Encontrados $ERRORS problemas"
    exit 1
fi
```

#### 📊 Monitor de Performance
```bash
#!/bin/bash
# alertmanager-performance.sh

AM_URL="http://localhost:9093"

echo "📊 Alertmanager Performance Monitor"
echo "==================================="

while true; do
    # Coletar métricas
    METRICS=$(curl -s "$AM_URL/metrics")
    
    # Alertas recebidos por minuto
    ALERTS_RATE=$(echo "$METRICS" | grep "alertmanager_alerts_received_total" | tail -1 | awk '{print $2}')
    
    # Notificações enviadas por minuto
    NOTIFICATIONS_RATE=$(echo "$METRICS" | grep "alertmanager_notifications_total" | tail -1 | awk '{print $2}')
    
    # Notificações falhadas
    NOTIFICATIONS_FAILED=$(echo "$METRICS" | grep "alertmanager_notifications_failed_total" | tail -1 | awk '{print $2}')
    
    # Uso de memória
    MEMORY_USAGE=$(echo "$METRICS" | grep "process_resident_memory_bytes" | awk '{print $2}')
    MEMORY_MB=$((MEMORY_USAGE / 1024 / 1024))
    
    # Exibir resultados
    clear
    echo "📊 Alertmanager Performance - $(date)"
    echo "====================================="
    echo "🚨 Alertas recebidos: $ALERTS_RATE"
    echo "📤 Notificações enviadas: $NOTIFICATIONS_RATE"
    echo "❌ Notificações falhadas: $NOTIFICATIONS_FAILED"
    echo "💾 Uso de memória: ${MEMORY_MB}MB"
    
    # Calcular taxa de sucesso
    if [ "$NOTIFICATIONS_RATE" -gt 0 ]; then
        SUCCESS_RATE=$(echo "scale=2; (($NOTIFICATIONS_RATE - $NOTIFICATIONS_FAILED) / $NOTIFICATIONS_RATE) * 100" | bc)
        echo "✅ Taxa de sucesso: ${SUCCESS_RATE}%"
    fi
    
    sleep 5
done
```

---

## 9. CENÁRIOS COMUNS

### 🚨 "Alertas não estão sendo enviados"

#### 🔍 Diagnóstico
```bash
# 1. Verificar se alertas estão chegando
amtool alert query

# 2. Verificar roteamento
amtool config routes test severity=critical alertname=DatabaseDown

# 3. Verificar logs de notificação
docker-compose logs alertmanager | grep -E "(notification|notify)"

# 4. Testar receiver manualmente
curl -X POST http://webhook.example.com/test
```

#### ✅ Soluções
```yaml
# Problema comum: Roteamento incorreto
route:
  default_receiver: 'null'  # ❌ Receiver que não existe
  
# Solução: Receiver válido
route:
  default_receiver: 'web.hook'
  
receivers:
- name: 'web.hook'
  webhook_configs:
  - url: 'http://webhook.example.com/alerts'
```

### 🔄 "Muitas notificações duplicadas"

#### 🔍 Diagnóstico
```bash
# Verificar configuração de agrupamento
amtool config show | grep -A 10 "group_"

# Verificar alertas ativos
amtool alert query --output=json | jq '.[] | {alertname: .labels.alertname, instance: .labels.instance}'
```

#### ✅ Soluções
```yaml
# Problema: Agrupamento insuficiente
route:
  group_by: ['alertname']  # ❌ Muito genérico
  group_wait: 5s          # ❌ Muito rápido
  
# Solução: Agrupamento melhor
route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
```

### 🐌 "Notificações muito lentas"

#### 🔍 Diagnóstico
```promql
# Verificar latência
histogram_quantile(0.95, 
  rate(alertmanager_notification_latency_seconds_bucket[5m])
)

# Verificar timeouts
rate(alertmanager_notifications_failed_total{reason="timeout"}[5m])
```

#### ✅ Soluções
```yaml
# Otimizar timeouts
global:
  smtp_timeout: 10s
  
receivers:
- name: 'fast-webhook'
  webhook_configs:
  - url: 'http://fast-webhook.example.com/alerts'
    timeout: 5s
    max_alerts: 10  # Limitar número de alertas por request
```

---

## 10. PREVENÇÃO DE PROBLEMAS

### 🛡️ Monitoramento Proativo

#### 📊 Alertas para o Alertmanager
```yaml
# prometheus-rules.yml
groups:
- name: alertmanager.rules
  rules:
  # Alertmanager down
  - alert: AlertmanagerDown
    expr: up{job="alertmanager"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Alertmanager está down"
      
  # Falhas de notificação
  - alert: AlertmanagerNotificationsFailing
    expr: rate(alertmanager_notifications_failed_total[5m]) > 0.1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Alertmanager com falhas de notificação"
      
  # Configuração não recarregada
  - alert: AlertmanagerConfigNotReloaded
    expr: time() - alertmanager_config_last_reload_success_timestamp_seconds > 3600
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: "Configuração do Alertmanager não foi recarregada há mais de 1h"
```

### 🧪 Testes Automatizados

#### 🔄 CI/CD Pipeline
```yaml
# .github/workflows/alertmanager-test.yml
name: Test Alertmanager Config

on:
  push:
    paths:
      - 'alertmanager.yml'
      - 'templates/**'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Download amtool
      run: |
        wget https://github.com/prometheus/alertmanager/releases/download/v0.25.0/alertmanager-0.25.0.linux-amd64.tar.gz
        tar xzf alertmanager-0.25.0.linux-amd64.tar.gz
        sudo mv alertmanager-0.25.0.linux-amd64/amtool /usr/local/bin/
    
    - name: Validate Config
      run: amtool config check alertmanager.yml
    
    - name: Test Templates
      run: |
        for template in templates/*.tmpl; do
          echo "Testing $template"
          amtool template test \
            --template.file="$template" \
            --template.data-file=tests/test-alert.json
        done
    
    - name: Test Routing
      run: |
        amtool config routes test \
          --config.file=alertmanager.yml \
          severity=critical alertname=TestAlert
```

### 📋 Checklist de Manutenção

#### 🗓️ Semanal
- [ ] Verificar logs de erro
- [ ] Revisar métricas de performance
- [ ] Testar notificações críticas
- [ ] Verificar espaço em disco

#### 🗓️ Mensal
- [ ] Atualizar versão do Alertmanager
- [ ] Revisar configuração de receivers
- [ ] Limpar silences expirados
- [ ] Backup da configuração

#### 🗓️ Trimestral
- [ ] Revisar templates de notificação
- [ ] Otimizar regras de roteamento
- [ ] Treinar equipe em novos recursos
- [ ] Documentar mudanças

---

## 🎯 RESUMO DO MÓDULO

### ✅ O que você aprendeu:

1. **Diagnóstico inicial** - Checklist e verificações básicas
2. **Logs e debugging** - Configuração e análise de logs
3. **Métricas de monitoramento** - Métricas essenciais e dashboards
4. **Problemas de configuração** - Erros comuns e validação
5. **Problemas de conectividade** - Diagnóstico de rede
6. **Problemas de notificação** - Debug de email, Slack, webhook
7. **Problemas de performance** - Identificação e otimização
8. **Ferramentas de diagnóstico** - amtool e scripts personalizados
9. **Cenários comuns** - Problemas frequentes e soluções
10. **Prevenção de problemas** - Monitoramento proativo e testes

### 🔧 Principais conceitos:
- **Diagnóstico sistemático** - Abordagem estruturada para resolver problemas
- **Logs estruturados** - Análise eficiente de logs JSON
- **Métricas de saúde** - Monitoramento proativo do Alertmanager
- **Validação automatizada** - Testes de configuração e templates
- **Performance tuning** - Otimização de recursos e latência

### 🚀 Próximos Passos

Agora que você sabe resolver problemas, vamos aprender sobre **integração avançada**:

**Próximo módulo:** [09-integracao-avancada.md](09-integracao-avancada.md) - Integração com outras ferramentas

---

## 🔗 Links Relacionados

- **[Anterior: Templates](07-templates.md)**
- **[Próximo: Integração Avançada](09-integracao-avancada.md)**
- **[Voltar ao Índice](README.md)**