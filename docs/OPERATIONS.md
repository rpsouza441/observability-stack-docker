# Guia de Operações - Stack de Observabilidade

## Índice

1. [Inicialização e Validação](#inicialização-e-validação)
2. [Operações Diárias](#operações-diárias)
3. [Hot Reload e Atualizações](#hot-reload-e-atualizações)
4. [Backup e Restore](#backup-e-restore)
5. [Monitoramento da Stack](#monitoramento-da-stack)
6. [Troubleshooting](#troubleshooting)
7. [Manutenção Preventiva](#manutenção-preventiva)
8. [Procedimentos de Emergência](#procedimentos-de-emergência)

## Inicialização e Validação

### 1. Pré-requisitos

```bash
# Verificar Docker e Docker Compose
docker --version
docker compose version

# Verificar recursos disponíveis
docker system df
docker system info | grep -E "CPUs|Total Memory"

# Verificar portas disponíveis
netstat -tuln | grep -E ":(3000|9090|9093|9100|8080|9116)"
```

### 2. Validação de Configuração

```bash
# Validar sintaxe do Prometheus
docker run --rm -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:latest \
  promtool check config /etc/prometheus/prometheus.yml

# Validar regras de alerta
docker run --rm -v $(pwd)/rules:/etc/prometheus/rules \
  prom/prometheus:latest \
  promtool check rules /etc/prometheus/rules/*.yml

# Validar configuração do Alertmanager
docker run --rm -v $(pwd)/alertmanager:/etc/alertmanager \
  prom/alertmanager:latest \
  amtool check-config /etc/alertmanager/alertmanager.yml
```

### 3. Inicialização da Stack

```bash
# Inicializar todos os serviços
docker compose up -d

# Verificar status dos containers
docker compose ps

# Verificar logs de inicialização
docker compose logs -f prometheus
docker compose logs -f grafana
docker compose logs -f alertmanager
```

### 4. Validação Pós-Inicialização

```bash
#!/bin/bash
# Script: validate_stack.sh

echo "🔍 Validando Stack de Observabilidade..."

# Função para verificar endpoint
check_endpoint() {
    local service=$1
    local url=$2
    local expected_code=${3:-200}
    
    echo -n "Verificando $service... "
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_code"; then
        echo "✅ OK"
        return 0
    else
        echo "❌ FALHOU"
        return 1
    fi
}

# Verificar serviços principais
check_endpoint "Prometheus" "http://localhost:9090/-/healthy"
check_endpoint "Grafana" "http://localhost:3000/api/health"
check_endpoint "Alertmanager" "http://localhost:9093/-/healthy"

# Verificar exporters
check_endpoint "Node Exporter" "http://localhost:9100/metrics"
check_endpoint "cAdvisor" "http://localhost:8080/metrics"
check_endpoint "SNMP Exporter" "http://localhost:9116/metrics"

# Verificar targets no Prometheus
echo -n "Verificando targets do Prometheus... "
targets_up=$(curl -s "http://localhost:9090/api/v1/targets" | \
    jq -r '.data.activeTargets[] | select(.health=="up") | .scrapeUrl' | wc -l)

if [ "$targets_up" -gt 0 ]; then
    echo "✅ $targets_up targets ativos"
else
    echo "❌ Nenhum target ativo"
fi

# Verificar conectividade Grafana -> Prometheus
echo -n "Verificando datasource Grafana... "
if curl -s -u admin:${GF_SECURITY_ADMIN_PASSWORD:-admin} \
    "http://localhost:3000/api/datasources/proxy/1/api/v1/label/__name__/values" | \
    grep -q "prometheus"; then
    echo "✅ Conectividade OK"
else
    echo "❌ Problema de conectividade"
fi

echo "\n🎯 Validação concluída!"
```

## Operações Diárias

### 1. Verificação de Saúde

```bash
#!/bin/bash
# Script: daily_health_check.sh

echo "📊 Verificação Diária de Saúde - $(date)"

# Status dos containers
echo "\n🐳 Status dos Containers:"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# Uso de recursos
echo "\n💾 Uso de Recursos:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

# Espaço em disco dos volumes
echo "\n📁 Uso de Volumes:"
docker system df -v | grep -E "(prometheus_data|grafana_data|alertmanager_data)"

# Alertas ativos
echo "\n🚨 Alertas Ativos:"
curl -s "http://localhost:9093/api/v1/alerts" | \
    jq -r '.data[] | select(.status.state=="active") | "\(.labels.alertname) - \(.labels.severity)"' | \
    head -10

# Targets com problemas
echo "\n🎯 Targets com Problemas:"
curl -s "http://localhost:9090/api/v1/targets" | \
    jq -r '.data.activeTargets[] | select(.health!="up") | "\(.scrapeUrl) - \(.health)"'

# Métricas de performance
echo "\n⚡ Performance do Prometheus:"
curl -s "http://localhost:9090/api/v1/query?query=prometheus_tsdb_head_samples_appended_total" | \
    jq -r '.data.result[0].value[1] + " samples/sec"'

echo "\n✅ Verificação concluída!"
```

### 2. Limpeza de Logs

```bash
#!/bin/bash
# Script: cleanup_logs.sh

echo "🧹 Limpeza de Logs Docker..."

# Limpar logs antigos (mais de 7 dias)
docker system prune -f --filter "until=168h"

# Truncar logs grandes (>100MB)
for container in $(docker compose ps -q); do
    log_file=$(docker inspect $container | jq -r '.[0].LogPath')
    if [ -f "$log_file" ] && [ $(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file") -gt 104857600 ]; then
        echo "Truncando log do container $container"
        truncate -s 50M "$log_file"
    fi
done

echo "✅ Limpeza concluída!"
```

## Hot Reload e Atualizações

### 1. Reload de Configurações

#### Prometheus

```bash
# Método 1: Sinal SIGHUP
docker compose kill -s SIGHUP prometheus

# Método 2: API HTTP
curl -X POST http://localhost:9090/-/reload

# Verificar se reload foi bem-sucedido
curl -s http://localhost:9090/api/v1/status/config | jq '.data.yaml' | head -20
```

#### Alertmanager

```bash
# Reload via API
curl -X POST http://localhost:9093/-/reload

# Verificar configuração atual
curl -s http://localhost:9093/api/v1/status | jq '.data.configYAML' | head -20
```

#### Grafana

```bash
# Grafana recarrega automaticamente datasources e dashboards provisionados
# Para forçar reload:
docker compose restart grafana

# Verificar datasources
curl -s -u admin:${GF_SECURITY_ADMIN_PASSWORD:-admin} \
    http://localhost:3000/api/datasources | jq '.[].name'
```

### 2. Atualizações de Imagens

```bash
#!/bin/bash
# Script: update_images.sh

echo "🔄 Atualizando Imagens Docker..."

# Backup antes da atualização
./backup_stack.sh

# Pull das novas imagens
docker compose pull

# Atualização rolling (um serviço por vez)
services=("prometheus" "grafana" "alertmanager" "node-exporter" "cadvisor" "snmp-exporter")

for service in "${services[@]}"; do
    echo "Atualizando $service..."
    
    # Parar o serviço
    docker compose stop $service
    
    # Remover container antigo
    docker compose rm -f $service
    
    # Iniciar com nova imagem
    docker compose up -d $service
    
    # Aguardar estabilização
    sleep 30
    
    # Verificar saúde
    if ! ./validate_stack.sh | grep -q "$service.*✅"; then
        echo "❌ Falha na atualização de $service. Fazendo rollback..."
        docker compose down
        docker compose up -d
        exit 1
    fi
    
    echo "✅ $service atualizado com sucesso"
done

echo "🎉 Todas as atualizações concluídas!"
```

### 3. Rollback de Emergência

```bash
#!/bin/bash
# Script: emergency_rollback.sh

echo "🚨 Iniciando Rollback de Emergência..."

# Parar todos os serviços
docker compose down

# Restaurar backup mais recente
latest_backup=$(ls -t backups/stack_backup_*.tar.gz | head -1)
if [ -n "$latest_backup" ]; then
    echo "Restaurando backup: $latest_backup"
    tar -xzf "$latest_backup" -C .
else
    echo "❌ Nenhum backup encontrado!"
    exit 1
fi

# Restaurar volumes
docker run --rm -v prometheus_data:/data -v $(pwd):/backup alpine \
    sh -c "rm -rf /data/* && tar -xzf /backup/prometheus_data.tar.gz -C /data"

docker run --rm -v grafana_data:/data -v $(pwd):/backup alpine \
    sh -c "rm -rf /data/* && tar -xzf /backup/grafana_data.tar.gz -C /data"

docker run --rm -v alertmanager_data:/data -v $(pwd):/backup alpine \
    sh -c "rm -rf /data/* && tar -xzf /backup/alertmanager_data.tar.gz -C /data"

# Reiniciar stack
docker compose up -d

# Validar
sleep 60
./validate_stack.sh

echo "✅ Rollback concluído!"
```

## Backup e Restore

### 1. Backup Completo

```bash
#!/bin/bash
# Script: backup_stack.sh

BACKUP_DIR="backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="stack_backup_$TIMESTAMP"

echo "💾 Iniciando Backup Completo..."

# Criar diretório de backup
mkdir -p $BACKUP_DIR

# Backup de configurações
echo "Fazendo backup das configurações..."
tar -czf "$BACKUP_DIR/${BACKUP_NAME}_configs.tar.gz" \
    prometheus.yml alertmanager/ grafana/ snmp_exporter/ rules/ compose.yml .env

# Backup de volumes Docker
echo "Fazendo backup dos volumes..."

# Prometheus data
docker run --rm -v prometheus_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine \
    tar -czf "/backup/${BACKUP_NAME}_prometheus_data.tar.gz" -C /data .

# Grafana data
docker run --rm -v grafana_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine \
    tar -czf "/backup/${BACKUP_NAME}_grafana_data.tar.gz" -C /data .

# Alertmanager data
docker run --rm -v alertmanager_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine \
    tar -czf "/backup/${BACKUP_NAME}_alertmanager_data.tar.gz" -C /data .

# Criar arquivo de metadados
cat > "$BACKUP_DIR/${BACKUP_NAME}_metadata.json" << EOF
{
    "timestamp": "$TIMESTAMP",
    "date": "$(date -Iseconds)",
    "docker_compose_version": "$(docker compose version --short)",
    "images": {
        "prometheus": "$(docker inspect prom/prometheus:latest --format='{{.Id}}')",
        "grafana": "$(docker inspect grafana/grafana:latest --format='{{.Id}}')",
        "alertmanager": "$(docker inspect prom/alertmanager:latest --format='{{.Id}}')"
    },
    "volumes": {
        "prometheus_data": "$(docker volume inspect prometheus_data --format='{{.Mountpoint}}')",
        "grafana_data": "$(docker volume inspect grafana_data --format='{{.Mountpoint}}')",
        "alertmanager_data": "$(docker volume inspect alertmanager_data --format='{{.Mountpoint}}')"
    }
}
EOF

# Compactar tudo em um arquivo final
tar -czf "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" -C $BACKUP_DIR \
    ${BACKUP_NAME}_configs.tar.gz \
    ${BACKUP_NAME}_prometheus_data.tar.gz \
    ${BACKUP_NAME}_grafana_data.tar.gz \
    ${BACKUP_NAME}_alertmanager_data.tar.gz \
    ${BACKUP_NAME}_metadata.json

# Limpar arquivos temporários
rm -f $BACKUP_DIR/${BACKUP_NAME}_*.tar.gz $BACKUP_DIR/${BACKUP_NAME}_metadata.json

# Limpar backups antigos (manter últimos 7)
ls -t $BACKUP_DIR/stack_backup_*.tar.gz | tail -n +8 | xargs -r rm

echo "✅ Backup concluído: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"
echo "📊 Tamanho: $(du -h $BACKUP_DIR/${BACKUP_NAME}.tar.gz | cut -f1)"
```

### 2. Restore de Backup

```bash
#!/bin/bash
# Script: restore_stack.sh

if [ $# -eq 0 ]; then
    echo "Uso: $0 <arquivo_backup.tar.gz>"
    echo "Backups disponíveis:"
    ls -la backups/stack_backup_*.tar.gz
    exit 1
fi

BACKUP_FILE=$1
RESTORE_DIR="restore_temp"

echo "🔄 Iniciando Restore do Backup: $BACKUP_FILE"

# Verificar se arquivo existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Arquivo de backup não encontrado: $BACKUP_FILE"
    exit 1
fi

# Parar stack atual
echo "Parando stack atual..."
docker compose down

# Criar diretório temporário
mkdir -p $RESTORE_DIR

# Extrair backup
echo "Extraindo backup..."
tar -xzf "$BACKUP_FILE" -C $RESTORE_DIR

# Extrair componentes individuais
cd $RESTORE_DIR
for file in *.tar.gz; do
    tar -xzf "$file"
done
cd ..

# Restaurar configurações
echo "Restaurando configurações..."
cp -r $RESTORE_DIR/prometheus.yml .
cp -r $RESTORE_DIR/alertmanager/ .
cp -r $RESTORE_DIR/grafana/ .
cp -r $RESTORE_DIR/snmp_exporter/ .
cp -r $RESTORE_DIR/rules/ .

# Restaurar volumes
echo "Restaurando volumes..."

# Remover volumes existentes
docker volume rm prometheus_data grafana_data alertmanager_data 2>/dev/null || true

# Criar novos volumes
docker volume create prometheus_data
docker volume create grafana_data
docker volume create alertmanager_data

# Restaurar dados
docker run --rm -v prometheus_data:/data -v $(pwd)/$RESTORE_DIR:/backup alpine \
    sh -c "tar -xzf /backup/*prometheus_data.tar.gz -C /data"

docker run --rm -v grafana_data:/data -v $(pwd)/$RESTORE_DIR:/backup alpine \
    sh -c "tar -xzf /backup/*grafana_data.tar.gz -C /data"

docker run --rm -v alertmanager_data:/data -v $(pwd)/$RESTORE_DIR:/backup alpine \
    sh -c "tar -xzf /backup/*alertmanager_data.tar.gz -C /data"

# Limpar diretório temporário
rm -rf $RESTORE_DIR

# Reiniciar stack
echo "Reiniciando stack..."
docker compose up -d

# Aguardar inicialização
echo "Aguardando inicialização..."
sleep 60

# Validar restore
echo "Validando restore..."
./validate_stack.sh

echo "✅ Restore concluído!"
```

### 3. Backup Automático

```bash
#!/bin/bash
# Script: setup_automated_backup.sh

echo "⏰ Configurando Backup Automático..."

# Criar script de backup diário
cat > /usr/local/bin/observability_backup.sh << 'EOF'
#!/bin/bash
cd /opt/observability-stack
./backup_stack.sh

# Sincronizar com storage remoto (opcional)
# rsync -av backups/ user@backup-server:/backups/observability/
# aws s3 sync backups/ s3://my-backup-bucket/observability/
EOF

chmod +x /usr/local/bin/observability_backup.sh

# Adicionar ao crontab
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/observability_backup.sh") | crontab -

echo "✅ Backup automático configurado para executar diariamente às 2:00"
```

## Monitoramento da Stack

### 1. Métricas de Auto-Monitoramento

```yaml
# Adicionar ao prometheus.yml
- job_name: 'prometheus-self'
  static_configs:
    - targets: ['localhost:9090']
  metrics_path: /metrics
  scrape_interval: 15s

- job_name: 'grafana-self'
  static_configs:
    - targets: ['grafana:3000']
  metrics_path: /metrics
  scrape_interval: 30s

- job_name: 'alertmanager-self'
  static_configs:
    - targets: ['alertmanager:9093']
  metrics_path: /metrics
  scrape_interval: 30s
```

### 2. Alertas para a Stack

```yaml
# rules/stack_monitoring.yml
groups:
- name: observability_stack
  rules:
  - alert: PrometheusDown
    expr: up{job="prometheus-self"} == 0
    for: 1m
    labels:
      severity: critical
      team: infrastructure
    annotations:
      summary: "Prometheus está down"
      description: "Prometheus não está respondendo há {{ $value }} minutos"

  - alert: GrafanaDown
    expr: up{job="grafana-self"} == 0
    for: 2m
    labels:
      severity: warning
      team: infrastructure
    annotations:
      summary: "Grafana está down"
      description: "Grafana não está respondendo há {{ $value }} minutos"

  - alert: AlertmanagerDown
    expr: up{job="alertmanager-self"} == 0
    for: 1m
    labels:
      severity: critical
      team: infrastructure
    annotations:
      summary: "Alertmanager está down"
      description: "Alertmanager não está respondendo há {{ $value }} minutos"

  - alert: PrometheusHighMemoryUsage
    expr: (process_resident_memory_bytes{job="prometheus-self"} / 1024 / 1024 / 1024) > 0.8
    for: 5m
    labels:
      severity: warning
      team: infrastructure
    annotations:
      summary: "Prometheus usando muita memória"
      description: "Prometheus está usando {{ $value }}GB de memória"

  - alert: PrometheusTSDBCompactionsFailing
    expr: increase(prometheus_tsdb_compactions_failed_total[1h]) > 0
    for: 0m
    labels:
      severity: warning
      team: infrastructure
    annotations:
      summary: "Falhas na compactação do TSDB"
      description: "{{ $value }} compactações falharam na última hora"
```

### 3. Dashboard de Monitoramento da Stack

```json
{
  "dashboard": {
    "title": "Observability Stack Monitoring",
    "panels": [
      {
        "title": "Stack Services Status",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=~\"prometheus-self|grafana-self|alertmanager-self\"}",
            "legendFormat": "{{job}}"
          }
        ]
      },
      {
        "title": "Prometheus Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "process_resident_memory_bytes{job=\"prometheus-self\"} / 1024 / 1024 / 1024",
            "legendFormat": "Memory Usage (GB)"
          }
        ]
      },
      {
        "title": "Prometheus TSDB Metrics",
        "type": "graph",
        "targets": [
          {
            "expr": "prometheus_tsdb_head_samples_appended_total",
            "legendFormat": "Samples Appended"
          },
          {
            "expr": "prometheus_tsdb_head_series",
            "legendFormat": "Active Series"
          }
        ]
      }
    ]
  }
}
```

## Troubleshooting

### 1. Problemas Comuns

#### Prometheus não consegue fazer scrape

```bash
# Verificar conectividade
docker exec prometheus wget -qO- http://node-exporter:9100/metrics | head

# Verificar configuração
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Verificar logs
docker compose logs prometheus | grep -i error

# Verificar targets
curl -s "http://localhost:9090/api/v1/targets" | jq '.data.activeTargets[] | {job: .labels.job, health: .health, error: .lastError}'
```

#### Grafana não consegue conectar ao Prometheus

```bash
# Testar conectividade do container Grafana
docker exec grafana wget -qO- http://prometheus:9090/api/v1/label/__name__/values

# Verificar configuração do datasource
curl -s -u admin:admin "http://localhost:3000/api/datasources" | jq '.[0]'

# Testar datasource
curl -s -u admin:admin -X POST "http://localhost:3000/api/datasources/proxy/1/api/v1/query?query=up"
```

#### Alertmanager não está enviando notificações

```bash
# Verificar configuração
docker exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml

# Verificar alertas ativos
curl -s "http://localhost:9093/api/v1/alerts" | jq '.data[] | {name: .labels.alertname, status: .status.state}'

# Verificar silêncios
curl -s "http://localhost:9093/api/v1/silences" | jq '.data[] | {id: .id, comment: .comment, status: .status.state}'

# Testar webhook
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{"labels":{"alertname":"TestAlert","severity":"warning"}}]'
```

### 2. Diagnóstico de Performance

```bash
#!/bin/bash
# Script: performance_diagnosis.sh

echo "🔍 Diagnóstico de Performance"

# Métricas do Prometheus
echo "\n📊 Prometheus Performance:"
curl -s "http://localhost:9090/api/v1/query?query=rate(prometheus_tsdb_head_samples_appended_total[5m])" | \
    jq -r '.data.result[0].value[1] + " samples/sec"'

curl -s "http://localhost:9090/api/v1/query?query=prometheus_tsdb_head_series" | \
    jq -r '.data.result[0].value[1] + " active series"'

curl -s "http://localhost:9090/api/v1/query?query=rate(prometheus_engine_query_duration_seconds_sum[5m])" | \
    jq -r '.data.result[0].value[1] + " avg query duration"'

# Uso de recursos dos containers
echo "\n💾 Resource Usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

# Tamanho dos volumes
echo "\n📁 Volume Sizes:"
docker system df -v | grep -E "(prometheus_data|grafana_data|alertmanager_data)"

# Top queries mais lentas (últimos 5 minutos)
echo "\n🐌 Slowest Queries:"
curl -s "http://localhost:9090/api/v1/query?query=topk(5, rate(prometheus_engine_query_duration_seconds_sum[5m]) / rate(prometheus_engine_query_duration_seconds_count[5m]))" | \
    jq -r '.data.result[] | .metric.query + ": " + .value[1] + "s"'
```

### 3. Logs Centralizados

```bash
#!/bin/bash
# Script: collect_logs.sh

LOG_DIR="logs_$(date +%Y%m%d_%H%M%S)"
mkdir -p $LOG_DIR

echo "📋 Coletando logs para diagnóstico..."

# Logs dos containers
for service in prometheus grafana alertmanager node-exporter cadvisor snmp-exporter; do
    echo "Coletando logs do $service..."
    docker compose logs --tail=1000 $service > "$LOG_DIR/${service}.log" 2>&1
done

# Informações do sistema
echo "Coletando informações do sistema..."
docker system info > "$LOG_DIR/docker_info.txt"
docker compose ps > "$LOG_DIR/compose_status.txt"
docker stats --no-stream > "$LOG_DIR/resource_usage.txt"

# Configurações atuais
echo "Coletando configurações..."
cp prometheus.yml "$LOG_DIR/"
cp -r alertmanager/ "$LOG_DIR/"
cp compose.yml "$LOG_DIR/"

# Compactar logs
tar -czf "${LOG_DIR}.tar.gz" $LOG_DIR/
rm -rf $LOG_DIR

echo "✅ Logs coletados em: ${LOG_DIR}.tar.gz"
```

## Manutenção Preventiva

### 1. Checklist Semanal

```bash
#!/bin/bash
# Script: weekly_maintenance.sh

echo "🔧 Manutenção Semanal - $(date)"

# 1. Verificar saúde geral
echo "\n1. Verificando saúde da stack..."
./validate_stack.sh

# 2. Verificar uso de disco
echo "\n2. Verificando uso de disco..."
df -h | grep -E "(prometheus_data|grafana_data|alertmanager_data)"

# 3. Verificar alertas persistentes
echo "\n3. Alertas ativos há mais de 24h:"
curl -s "http://localhost:9093/api/v1/alerts" | \
    jq -r '.data[] | select(.status.state=="active" and (now - (.activeAt | fromdateiso8601)) > 86400) | .labels.alertname'

# 4. Verificar targets inativos
echo "\n4. Targets inativos:"
curl -s "http://localhost:9090/api/v1/targets" | \
    jq -r '.data.activeTargets[] | select(.health!="up") | .scrapeUrl'

# 5. Verificar performance
echo "\n5. Métricas de performance:"
curl -s "http://localhost:9090/api/v1/query?query=prometheus_tsdb_head_series" | \
    jq -r '"Series ativas: " + .data.result[0].value[1]'

# 6. Limpeza de dados antigos
echo "\n6. Limpando dados antigos..."
./cleanup_logs.sh

# 7. Backup
echo "\n7. Executando backup..."
./backup_stack.sh

echo "\n✅ Manutenção semanal concluída!"
```

### 2. Checklist Mensal

```bash
#!/bin/bash
# Script: monthly_maintenance.sh

echo "🗓️ Manutenção Mensal - $(date)"

# 1. Verificar atualizações de imagens
echo "\n1. Verificando atualizações disponíveis..."
docker compose pull --dry-run

# 2. Analisar crescimento de dados
echo "\n2. Análise de crescimento de dados:"
echo "Prometheus TSDB:"
docker exec prometheus du -sh /prometheus

echo "Grafana data:"
docker exec grafana du -sh /var/lib/grafana

# 3. Revisar configurações de retenção
echo "\n3. Configuração atual de retenção:"
docker exec prometheus cat /etc/prometheus/prometheus.yml | grep -A5 -B5 retention

# 4. Verificar certificados (se usando HTTPS)
echo "\n4. Verificando certificados..."
# openssl x509 -in /path/to/cert.pem -text -noout | grep -A2 "Not After"

# 5. Análise de alertas
echo "\n5. Estatísticas de alertas do último mês:"
# Implementar query para estatísticas de alertas

# 6. Teste de restore
echo "\n6. Agendando teste de restore..."
echo "LEMBRETE: Executar teste de restore em ambiente de desenvolvimento"

echo "\n✅ Manutenção mensal concluída!"
```

## Procedimentos de Emergência

### 1. Recuperação de Desastre

```bash
#!/bin/bash
# Script: disaster_recovery.sh

echo "🚨 PROCEDIMENTO DE RECUPERAÇÃO DE DESASTRE"
echo "Este script deve ser executado apenas em emergências!"
read -p "Confirma a execução? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Operação cancelada."
    exit 1
fi

# 1. Parar todos os serviços
echo "\n1. Parando todos os serviços..."
docker compose down --remove-orphans

# 2. Backup de emergência dos dados atuais
echo "\n2. Fazendo backup de emergência..."
mkdir -p emergency_backup
docker run --rm -v prometheus_data:/data -v $(pwd)/emergency_backup:/backup alpine \
    tar -czf /backup/emergency_prometheus_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .

# 3. Limpar volumes corrompidos
echo "\n3. Limpando volumes corrompidos..."
docker volume rm prometheus_data grafana_data alertmanager_data 2>/dev/null || true

# 4. Recriar volumes
echo "\n4. Recriando volumes..."
docker volume create prometheus_data
docker volume create grafana_data
docker volume create alertmanager_data

# 5. Restaurar do backup mais recente
echo "\n5. Restaurando do backup mais recente..."
latest_backup=$(ls -t backups/stack_backup_*.tar.gz | head -1)
if [ -n "$latest_backup" ]; then
    ./restore_stack.sh "$latest_backup"
else
    echo "❌ Nenhum backup encontrado! Iniciando com configuração limpa..."
    docker compose up -d
fi

# 6. Verificar recuperação
echo "\n6. Verificando recuperação..."
sleep 60
./validate_stack.sh

echo "\n✅ Procedimento de recuperação concluído!"
echo "📋 Verifique os logs e dashboards para confirmar a integridade dos dados."
```

### 2. Escalação de Incidentes

```bash
#!/bin/bash
# Script: incident_escalation.sh

SEVERITY=$1
DESCRIPTION=$2

if [ $# -lt 2 ]; then
    echo "Uso: $0 <severity> <description>"
    echo "Severidades: P1 (crítico), P2 (alto), P3 (médio), P4 (baixo)"
    exit 1
fi

echo "🚨 ESCALAÇÃO DE INCIDENTE - $SEVERITY"
echo "Descrição: $DESCRIPTION"
echo "Timestamp: $(date -Iseconds)"

# Coletar informações do incidente
echo "\n📊 Coletando informações do sistema..."
./collect_logs.sh
./performance_diagnosis.sh > incident_diagnosis.txt

# Notificar equipes
case $SEVERITY in
    "P1")
        echo "\n📞 Notificando equipe de plantão..."
        # curl -X POST "$PAGERDUTY_URL" -d '{"incident_key":"obs-stack-p1","event_type":"trigger"}'
        # curl -X POST "$SLACK_WEBHOOK" -d '{"text":"🚨 P1 - Observability Stack: '$DESCRIPTION'"}'
        ;;
    "P2")
        echo "\n📧 Notificando equipe de infraestrutura..."
        # Enviar email para equipe
        ;;
    *)
        echo "\n📝 Criando ticket de acompanhamento..."
        # Criar ticket no sistema de tickets
        ;;
esac

# Criar relatório de incidente
cat > "incident_report_$(date +%Y%m%d_%H%M%S).md" << EOF
# Relatório de Incidente - Observability Stack

## Informações Básicas
- **Severidade**: $SEVERITY
- **Descrição**: $DESCRIPTION
- **Timestamp**: $(date -Iseconds)
- **Operador**: $(whoami)

## Status dos Serviços
\`\`\`
$(docker compose ps)
\`\`\`

## Logs Relevantes
\`\`\`
$(docker compose logs --tail=50 | grep -i error)
\`\`\`

## Ações Tomadas
- [ ] Logs coletados
- [ ] Diagnóstico executado
- [ ] Equipe notificada
- [ ] Investigação iniciada

## Próximos Passos
- [ ] Identificar causa raiz
- [ ] Implementar correção
- [ ] Validar solução
- [ ] Atualizar documentação
EOF

echo "\n✅ Escalação iniciada. Relatório criado: incident_report_*.md"
```

Este guia de operações fornece todos os procedimentos necessários para manter a stack de observabilidade funcionando de forma confiável e eficiente. Mantenha os scripts atualizados e teste-os regularmente em ambiente de desenvolvimento.