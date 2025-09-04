# Módulo 08: Troubleshooting

## Objetivos do Módulo

Ao final deste módulo, você será capaz de:
- Diagnosticar problemas comuns do Grafana
- Otimizar performance de dashboards e queries
- Resolver problemas de conectividade com data sources
- Debuggar alertas e notificações
- Monitorar a saúde do próprio Grafana
- Implementar logging e métricas para troubleshooting
- Resolver problemas de autenticação e permissões

## 1. Diagnóstico Geral

### 1.1 Health Check do Grafana

**Verificação Básica de Saúde:**
```bash
# Health endpoint
curl -f http://localhost:3000/api/health

# Resposta esperada
{
  "commit": "abc123",
  "database": "ok",
  "version": "9.5.0"
}

# Verificar status detalhado
curl -H "Authorization: Bearer $API_KEY" \
     http://localhost:3000/api/admin/stats
```

**Script de Diagnóstico Completo:**
```bash
#!/bin/bash
# grafana-health-check.sh

GRAFANA_URL="http://localhost:3000"
API_KEY="your-api-key"
LOG_FILE="/var/log/grafana/grafana.log"

echo "=== Grafana Health Check ==="
echo "Data: $(date)"
echo

# 1. Verificar se o serviço está rodando
echo "1. Status do Serviço:"
if systemctl is-active --quiet grafana-server; then
    echo "✅ Grafana está rodando"
else
    echo "❌ Grafana não está rodando"
    systemctl status grafana-server
fi
echo

# 2. Verificar conectividade HTTP
echo "2. Conectividade HTTP:"
if curl -s -f "$GRAFANA_URL/api/health" > /dev/null; then
    echo "✅ HTTP endpoint acessível"
    curl -s "$GRAFANA_URL/api/health" | jq .
else
    echo "❌ HTTP endpoint não acessível"
fi
echo

# 3. Verificar uso de recursos
echo "3. Uso de Recursos:"
echo "CPU: $(ps -o %cpu -p $(pgrep grafana-server) --no-headers)%"
echo "Memória: $(ps -o %mem -p $(pgrep grafana-server) --no-headers)%"
echo "Processos Grafana: $(pgrep -c grafana-server)"
echo

# 4. Verificar logs recentes
echo "4. Logs Recentes (últimas 10 linhas):"
if [ -f "$LOG_FILE" ]; then
    tail -10 "$LOG_FILE"
else
    echo "Log file não encontrado: $LOG_FILE"
fi
echo

# 5. Verificar data sources
echo "5. Status dos Data Sources:"
if [ -n "$API_KEY" ]; then
    curl -s -H "Authorization: Bearer $API_KEY" \
         "$GRAFANA_URL/api/datasources" | \
    jq -r '.[] | "\(.name): \(.type) - \(.url)"'
else
    echo "API_KEY não configurada"
fi
echo

# 6. Verificar espaço em disco
echo "6. Espaço em Disco:"
df -h /var/lib/grafana
echo

echo "=== Fim do Health Check ==="
```

### 1.2 Logs e Debugging

**Configuração de Logs Detalhados:**
```ini
# grafana.ini
[log]
# Níveis: trace, debug, info, warn, error, critical
level = debug
mode = console file

[log.console]
level = info
format = console

[log.file]
level = debug
format = text
log_rotate = true
max_lines = 1000000
max_size_shift = 28
daily_rotate = true
max_days = 7

# Logs específicos
[log.frontend]
level = debug

[log.filters]
# Filtrar logs específicos
rendering = debug
tsdb.graphite = warn
tsdb.influxdb = debug
tsdb.prometheus = debug
```

**Análise de Logs:**
```bash
# Filtrar erros nos logs
grep -i error /var/log/grafana/grafana.log | tail -20

# Filtrar problemas de data source
grep -i "datasource" /var/log/grafana/grafana.log | grep -i error

# Filtrar problemas de query
grep -i "query" /var/log/grafana/grafana.log | grep -E "(error|timeout|failed)"

# Monitorar logs em tempo real
tail -f /var/log/grafana/grafana.log | grep --color=always -E "(ERROR|WARN|CRITICAL)"

# Análise de performance
grep -i "slow" /var/log/grafana/grafana.log
grep -E "took [0-9]+ms" /var/log/grafana/grafana.log | sort -k3 -nr
```

## 2. Problemas de Performance

### 2.1 Otimização de Queries

**Identificação de Queries Lentas:**
```bash
# Script para identificar queries problemáticas
#!/bin/bash
# slow-queries.sh

LOG_FILE="/var/log/grafana/grafana.log"
THRESHOLD=5000  # 5 segundos em ms

echo "Queries que demoram mais que ${THRESHOLD}ms:"
grep -E "took [0-9]+ms" "$LOG_FILE" | \
awk -v threshold=$THRESHOLD '
{
    match($0, /took ([0-9]+)ms/, arr)
    if (arr[1] > threshold) {
        print $0
    }
}' | sort -k3 -nr | head -20
```

**Otimizações Comuns:**

1. **PromQL Otimizado:**
```promql
# ❌ Query ineficiente
rate(http_requests_total[5m])

# ✅ Query otimizada com filtros
rate(http_requests_total{job="api", status=~"2.."}[5m])

# ❌ Agregação desnecessária
avg(rate(cpu_usage[5m])) by (instance)

# ✅ Agregação eficiente
avg by (instance) (rate(cpu_usage[5m]))

# ❌ Range muito longo
rate(http_requests_total[1h])

# ✅ Range apropriado
rate(http_requests_total[5m])
```

2. **Configuração de Cache:**
```ini
# grafana.ini
[caching]
# Cache de data source
data_source_cache_ttl = 300s

# Cache de query
[query_cache]
enabled = true
ttl = 300s
max_cache_size_mb = 100
```

### 2.2 Otimização de Dashboards

**Dashboard Performance Checklist:**
```json
{
  "dashboard_optimization": {
    "panels": {
      "max_recommended": 20,
      "current": "{{ panel_count }}",
      "status": "{{ panel_count <= 20 ? 'OK' : 'WARNING' }}"
    },
    "queries_per_panel": {
      "max_recommended": 5,
      "optimization_tips": [
        "Combine similar queries",
        "Use query variables",
        "Implement query caching"
      ]
    },
    "refresh_interval": {
      "recommended_minimum": "30s",
      "high_frequency_panels": "Use separate dashboard"
    },
    "time_range": {
      "recommendation": "Avoid very long ranges (>7d)",
      "use_relative_time": true
    }
  }
}
```

**Script de Análise de Performance:**
```bash
#!/bin/bash
# dashboard-performance.sh

GRAFANA_URL="http://localhost:3000"
API_KEY="your-api-key"

echo "=== Dashboard Performance Analysis ==="

# Listar todos os dashboards
curl -s -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/search?type=dash-db" | \
jq -r '.[] | "\(.uid) \(.title)"' | \
while read uid title; do
    echo "Analisando: $title ($uid)"
    
    # Obter dashboard
    dashboard=$(curl -s -H "Authorization: Bearer $API_KEY" \
                     "$GRAFANA_URL/api/dashboards/uid/$uid")
    
    # Contar painéis
    panel_count=$(echo "$dashboard" | jq '.dashboard.panels | length')
    
    # Contar queries
    query_count=$(echo "$dashboard" | jq '[.dashboard.panels[].targets[]?] | length')
    
    # Verificar refresh interval
    refresh=$(echo "$dashboard" | jq -r '.dashboard.refresh // "null"')
    
    echo "  Painéis: $panel_count"
    echo "  Queries: $query_count"
    echo "  Refresh: $refresh"
    
    # Alertas de performance
    if [ "$panel_count" -gt 20 ]; then
        echo "  ⚠️  Muitos painéis ($panel_count > 20)"
    fi
    
    if [ "$query_count" -gt 50 ]; then
        echo "  ⚠️  Muitas queries ($query_count > 50)"
    fi
    
    case "$refresh" in
        "5s"|"10s")
            echo "  ⚠️  Refresh muito frequente ($refresh)"
            ;;
    esac
    
    echo
done
```

### 2.3 Monitoramento do Grafana

**Métricas Internas do Grafana:**
```yaml
# prometheus.yml - scrape do Grafana
scrape_configs:
  - job_name: 'grafana'
    static_configs:
      - targets: ['localhost:3000']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

**Dashboard de Monitoramento do Grafana:**
```json
{
  "dashboard": {
    "title": "Grafana Monitoring",
    "panels": [
      {
        "title": "HTTP Requests",
        "type": "timeseries",
        "targets": [
          {
            "expr": "rate(grafana_http_request_duration_seconds_count[5m])",
            "legendFormat": "{{ method }} {{ code }}"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "timeseries",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(grafana_http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ]
      },
      {
        "title": "Active Sessions",
        "type": "stat",
        "targets": [
          {
            "expr": "grafana_stat_active_sessions",
            "legendFormat": "Sessions"
          }
        ]
      },
      {
        "title": "Database Connections",
        "type": "timeseries",
        "targets": [
          {
            "expr": "grafana_database_conn_open",
            "legendFormat": "Open connections"
          }
        ]
      }
    ]
  }
}
```

## 3. Problemas de Data Sources

### 3.1 Conectividade

**Teste de Conectividade:**
```bash
#!/bin/bash
# test-datasources.sh

GRAFANA_URL="http://localhost:3000"
API_KEY="your-api-key"

echo "=== Teste de Data Sources ==="

# Listar data sources
curl -s -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/datasources" | \
jq -r '.[] | "\(.id) \(.name) \(.type) \(.url)"' | \
while read id name type url; do
    echo "Testando: $name ($type)"
    echo "URL: $url"
    
    # Testar conectividade básica
    if curl -s --connect-timeout 5 "$url" > /dev/null 2>&1; then
        echo "✅ Conectividade básica OK"
    else
        echo "❌ Falha na conectividade básica"
    fi
    
    # Testar via API do Grafana
    test_result=$(curl -s -X POST \
                       -H "Authorization: Bearer $API_KEY" \
                       "$GRAFANA_URL/api/datasources/$id/health")
    
    status=$(echo "$test_result" | jq -r '.status // "unknown"')
    message=$(echo "$test_result" | jq -r '.message // "no message"')
    
    case "$status" in
        "success")
            echo "✅ Teste do Grafana: OK"
            ;;
        "error")
            echo "❌ Teste do Grafana: ERRO - $message"
            ;;
        *)
            echo "⚠️  Teste do Grafana: Status desconhecido - $status"
            ;;
    esac
    
    echo
done
```

### 3.2 Problemas Específicos por Tipo

**Prometheus:**
```bash
# Verificar se Prometheus está acessível
curl -f http://prometheus:9090/api/v1/status/config

# Testar query simples
curl "http://prometheus:9090/api/v1/query?query=up"

# Verificar targets
curl "http://prometheus:9090/api/v1/targets" | jq '.data.activeTargets[] | select(.health != "up")'

# Problemas comuns:
# 1. Timeout de query
# 2. Métricas não encontradas
# 3. Rate limiting
```

**InfluxDB:**
```bash
# InfluxDB 1.x
curl "http://influxdb:8086/ping"
curl "http://influxdb:8086/query?q=SHOW+DATABASES"

# InfluxDB 2.x
curl -H "Authorization: Token $INFLUX_TOKEN" \
     "http://influxdb:8086/health"

# Problemas comuns:
# 1. Token expirado
# 2. Bucket não existe
# 3. Sintaxe Flux incorreta
```

**MySQL/PostgreSQL:**
```bash
# Testar conexão MySQL
mysql -h mysql -u grafana -p -e "SELECT 1"

# Testar conexão PostgreSQL
psql -h postgres -U grafana -d grafana -c "SELECT 1"

# Problemas comuns:
# 1. Credenciais incorretas
# 2. Firewall/rede
# 3. Limite de conexões
# 4. SSL/TLS
```

### 3.3 Debug de Queries

**Query Inspector:**
```javascript
// Habilitar query inspector no dashboard
// 1. Abrir painel
// 2. Clicar em "Inspect" > "Query"
// 3. Verificar:
//    - Query executada
//    - Tempo de resposta
//    - Dados retornados
//    - Erros

// Exemplo de análise
{
  "query": "rate(http_requests_total[5m])",
  "executionTime": "2.3s",
  "dataPoints": 1440,
  "error": null,
  "warnings": [
    "Query returned large dataset"
  ]
}
```

## 4. Problemas de Alertas

### 4.1 Debug de Alert Rules

**Verificação de Alert Rules:**
```bash
#!/bin/bash
# debug-alerts.sh

GRAFANA_URL="http://localhost:3000"
API_KEY="your-api-key"

echo "=== Debug de Alertas ==="

# Listar todas as regras
echo "1. Regras de Alerta:"
curl -s -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/ruler/grafana/api/v1/rules" | \
jq -r '.[] | keys[] as $namespace | "\($namespace): \(.[$namespace] | length) rules"'

echo

# Verificar estado das regras
echo "2. Estado das Regras:"
curl -s -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/prometheus/grafana/api/v1/rules" | \
jq -r '.data.groups[].rules[] | "\(.alert // .record): \(.state // "recording")"'

echo

# Verificar alertas ativos
echo "3. Alertas Ativos:"
curl -s -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/prometheus/grafana/api/v1/alerts" | \
jq -r '.data[] | "\(.labels.alertname): \(.state) since \(.activeAt)"'

echo

# Verificar contact points
echo "4. Contact Points:"
curl -s -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/alertmanager/grafana/config" | \
jq -r '.alertmanager_config.receivers[] | "\(.name): \([.email_configs[]?, .slack_configs[]?, .webhook_configs[]?] | length) configs"'
```

**Problemas Comuns de Alertas:**

1. **Query não retorna dados:**
```json
{
  "problem": "NoData state",
  "solutions": [
    "Verificar se a query está correta",
    "Confirmar se os dados existem no data source",
    "Ajustar o time range da query",
    "Verificar filtros e labels"
  ]
}
```

2. **Alerta não dispara:**
```json
{
  "problem": "Alert not firing",
  "checklist": [
    "Condition expression está correta?",
    "Threshold value está apropriado?",
    "For duration está configurado?",
    "Data source está funcionando?",
    "Query retorna valores esperados?"
  ]
}
```

3. **Notificações não chegam:**
```json
{
  "problem": "Notifications not received",
  "checklist": [
    "Contact point está configurado corretamente?",
    "Notification policy está roteando para o contact point?",
    "Não há silences ativos?",
    "Webhook/email/slack está funcionando?",
    "Rate limiting não está bloqueando?"
  ]
}
```

### 4.2 Teste de Notificações

**Script de Teste:**
```bash
#!/bin/bash
# test-notifications.sh

GRAFANA_URL="http://localhost:3000"
API_KEY="your-api-key"

# Testar contact points
echo "Testando contact points..."

curl -s -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/alertmanager/grafana/config" | \
jq -r '.alertmanager_config.receivers[].name' | \
while read receiver; do
    echo "Testando: $receiver"
    
    # Enviar notificação de teste
    curl -X POST \
         -H "Authorization: Bearer $API_KEY" \
         -H "Content-Type: application/json" \
         -d '{
           "receiver": "'$receiver'",
           "alerts": [{
             "labels": {
               "alertname": "Test Alert",
               "severity": "info"
             },
             "annotations": {
               "summary": "This is a test alert",
               "description": "Testing notification delivery"
             },
             "startsAt": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
           }]
         }' \
         "$GRAFANA_URL/api/alertmanager/grafana/api/v1/alerts"
    
    echo "Teste enviado para $receiver"
done
```

## 5. Problemas de Autenticação

### 5.1 Debug de Login

**Logs de Autenticação:**
```bash
# Filtrar logs de autenticação
grep -i "auth\|login\|ldap\|oauth" /var/log/grafana/grafana.log | tail -20

# Verificar tentativas de login falhadas
grep -i "failed login" /var/log/grafana/grafana.log

# Verificar problemas de LDAP
grep -i "ldap" /var/log/grafana/grafana.log | grep -i error
```

**Teste de Autenticação:**
```bash
#!/bin/bash
# test-auth.sh

GRAFANA_URL="http://localhost:3000"
USERNAME="admin"
PASSWORD="admin"

echo "Testando autenticação..."

# Testar login básico
response=$(curl -s -X POST \
                -H "Content-Type: application/json" \
                -d '{
                  "user": "'$USERNAME'",
                  "password": "'$PASSWORD'"
                }' \
                "$GRAFANA_URL/login")

if echo "$response" | grep -q "message.*Logged in"; then
    echo "✅ Login básico funcionando"
else
    echo "❌ Falha no login básico"
    echo "Response: $response"
fi

# Testar API key
if [ -n "$API_KEY" ]; then
    api_response=$(curl -s -H "Authorization: Bearer $API_KEY" \
                        "$GRAFANA_URL/api/user")
    
    if echo "$api_response" | jq -e '.login' > /dev/null 2>&1; then
        echo "✅ API key funcionando"
    else
        echo "❌ Falha na API key"
        echo "Response: $api_response"
    fi
fi
```

### 5.2 Problemas de LDAP

**Debug LDAP:**
```ini
# grafana.ini
[auth.ldap]
enabled = true
config_file = /etc/grafana/ldap.toml
allow_sign_up = true

# Logs detalhados para LDAP
[log.filters]
ldap = debug
```

**Teste LDAP:**
```bash
# Testar conectividade LDAP
ldapsearch -x -H ldap://ldap.company.com:389 -D "cn=admin,dc=company,dc=com" -W

# Testar busca de usuário
ldapsearch -x -H ldap://ldap.company.com:389 \
           -D "cn=admin,dc=company,dc=com" -W \
           -b "ou=users,dc=company,dc=com" \
           "(uid=username)"
```

## 6. Problemas de Rede e Conectividade

### 6.1 Diagnóstico de Rede

**Script de Teste de Conectividade:**
```bash
#!/bin/bash
# network-test.sh

echo "=== Teste de Conectividade ==="

# Serviços para testar
SERVICES=(
    "prometheus:9090"
    "influxdb:8086"
    "mysql:3306"
    "postgres:5432"
    "elasticsearch:9200"
    "loki:3100"
)

for service in "${SERVICES[@]}"; do
    host=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)
    
    echo "Testando $service..."
    
    # Teste de resolução DNS
    if nslookup "$host" > /dev/null 2>&1; then
        echo "  ✅ DNS resolve"
    else
        echo "  ❌ DNS não resolve"
        continue
    fi
    
    # Teste de conectividade TCP
    if timeout 5 bash -c "</dev/tcp/$host/$port"; then
        echo "  ✅ Porta $port acessível"
    else
        echo "  ❌ Porta $port não acessível"
    fi
    
    # Teste HTTP (se aplicável)
    if [[ "$port" =~ ^(80|443|8080|8086|9090|9200|3100)$ ]]; then
        if curl -s --connect-timeout 5 "http://$host:$port" > /dev/null; then
            echo "  ✅ HTTP responde"
        else
            echo "  ❌ HTTP não responde"
        fi
    fi
    
    echo
done
```

### 6.2 Problemas de Proxy

**Configuração Nginx:**
```nginx
# /etc/nginx/sites-available/grafana
server {
    listen 80;
    server_name grafana.company.com;
    
    # Logs para debug
    access_log /var/log/nginx/grafana-access.log;
    error_log /var/log/nginx/grafana-error.log debug;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

**Debug Proxy:**
```bash
# Verificar logs do Nginx
tail -f /var/log/nginx/grafana-error.log

# Testar conectividade direta
curl -v http://localhost:3000/api/health

# Testar através do proxy
curl -v -H "Host: grafana.company.com" http://proxy-server/api/health
```

## 7. Ferramentas de Monitoramento

### 7.1 Métricas do Sistema

**Script de Coleta de Métricas:**
```bash
#!/bin/bash
# collect-metrics.sh

OUTPUT_FILE="grafana-metrics-$(date +%Y%m%d-%H%M%S).json"

echo "Coletando métricas do sistema..."

# Função para coletar métricas
collect_metrics() {
    cat << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "system": {
    "cpu_usage": $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1),
    "memory_usage": $(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}'),
    "disk_usage": $(df /var/lib/grafana | tail -1 | awk '{print $5}' | cut -d'%' -f1),
    "load_average": "$(uptime | awk -F'load average:' '{print $2}')"
  },
  "grafana": {
    "process_count": $(pgrep -c grafana-server),
    "cpu_percent": $(ps -o %cpu -p $(pgrep grafana-server) --no-headers | head -1),
    "memory_percent": $(ps -o %mem -p $(pgrep grafana-server) --no-headers | head -1),
    "open_files": $(lsof -p $(pgrep grafana-server) | wc -l),
    "tcp_connections": $(netstat -an | grep :3000 | wc -l)
  },
  "database": {
    "size_mb": $(du -m /var/lib/grafana/grafana.db 2>/dev/null | cut -f1 || echo 0),
    "connections": $(sqlite3 /var/lib/grafana/grafana.db "PRAGMA database_list;" 2>/dev/null | wc -l || echo 0)
  }
}
EOF
}

# Coletar e salvar métricas
collect_metrics > "$OUTPUT_FILE"
echo "Métricas salvas em: $OUTPUT_FILE"

# Exibir resumo
echo
echo "=== Resumo ==="
jq -r '
"CPU: " + (.system.cpu_usage | tostring) + "%" +
"\nMemória: " + (.system.memory_usage | tostring) + "%" +
"\nDisco: " + (.system.disk_usage | tostring) + "%" +
"\nProcessos Grafana: " + (.grafana.process_count | tostring)
' "$OUTPUT_FILE"
```

### 7.2 Alertas de Sistema

**Configuração de Alertas para o Grafana:**
```yaml
# prometheus-rules.yml
groups:
  - name: grafana.rules
    rules:
      - alert: GrafanaDown
        expr: up{job="grafana"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Grafana is down"
          description: "Grafana has been down for more than 1 minute"
      
      - alert: GrafanaHighMemoryUsage
        expr: process_resident_memory_bytes{job="grafana"} / 1024 / 1024 > 500
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Grafana high memory usage"
          description: "Grafana is using {{ $value }}MB of memory"
      
      - alert: GrafanaSlowQueries
        expr: histogram_quantile(0.95, rate(grafana_http_request_duration_seconds_bucket{handler=~"/api/datasources/proxy.*"}[5m])) > 10
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Grafana slow queries detected"
          description: "95th percentile of query duration is {{ $value }}s"
      
      - alert: GrafanaTooManyErrors
        expr: rate(grafana_http_request_total{code=~"5.."}[5m]) > 0.1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Grafana error rate too high"
          description: "Error rate is {{ $value }} errors per second"
```

## 8. Exercícios Práticos

### Exercício 1: Diagnóstico Completo

**Cenário:** Grafana está lento e alguns dashboards não carregam

**Tarefas:**
1. Executar health check completo
2. Analisar logs para identificar problemas
3. Verificar performance de queries
4. Testar conectividade com data sources
5. Implementar monitoramento preventivo

**Script de Solução:**
```bash
#!/bin/bash
# diagnostic-complete.sh

echo "=== Diagnóstico Completo do Grafana ==="

# 1. Health check
echo "1. Executando health check..."
./grafana-health-check.sh

# 2. Análise de performance
echo "2. Analisando performance..."
./dashboard-performance.sh

# 3. Teste de data sources
echo "3. Testando data sources..."
./test-datasources.sh

# 4. Verificação de rede
echo "4. Testando conectividade..."
./network-test.sh

# 5. Coleta de métricas
echo "5. Coletando métricas..."
./collect-metrics.sh

echo "Diagnóstico completo finalizado!"
```

### Exercício 2: Otimização de Performance

**Objetivo:** Otimizar um dashboard lento

**Passos:**
1. Identificar queries problemáticas
2. Otimizar expressões PromQL
3. Implementar cache
4. Reduzir número de painéis
5. Ajustar intervalos de refresh

### Exercício 3: Resolução de Problemas de Alertas

**Cenário:** Alertas não estão sendo enviados

**Checklist de Troubleshooting:**
- [ ] Alert rule está ativa?
- [ ] Query retorna dados?
- [ ] Condition está correta?
- [ ] Contact point configurado?
- [ ] Notification policy roteando?
- [ ] Não há silences ativos?
- [ ] Webhook/email funcionando?

## 9. Resumo do Módulo

### Conceitos Aprendidos

- ✅ **Diagnóstico**: Health checks e análise de logs
- ✅ **Performance**: Otimização de queries e dashboards
- ✅ **Data Sources**: Resolução de problemas de conectividade
- ✅ **Alertas**: Debug de regras e notificações
- ✅ **Autenticação**: Troubleshooting de login e LDAP
- ✅ **Rede**: Diagnóstico de conectividade e proxy
- ✅ **Monitoramento**: Métricas e alertas preventivos

### Ferramentas Essenciais

- **Scripts de diagnóstico automatizado**
- **Monitoramento de métricas internas**
- **Análise de logs estruturada**
- **Testes de conectividade**
- **Alertas preventivos**

### Próximos Passos

- **Módulo 09**: Projeto final integrado

### Recursos Adicionais

- [Grafana Troubleshooting Guide](https://grafana.com/docs/grafana/latest/troubleshooting/)
- [Performance Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
- [Monitoring Grafana](https://grafana.com/docs/grafana/latest/setup-grafana/set-up-grafana-monitoring/)

---

**Navegação:**
- [← Módulo 07: Provisioning](07-provisioning.md)
- [→ Módulo 09: Projeto Final](09-projeto-final.md)
- [🏠 Início](../README.md)