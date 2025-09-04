# Módulo 06: Troubleshooting e Otimização

Este módulo aborda técnicas avançadas de diagnóstico, resolução de problemas e otimização de performance do Node Exporter em ambientes de produção.

## 🔍 Diagnóstico de Problemas

### Verificação de Status e Saúde

```bash
#!/bin/bash
# node-exporter-health-check.sh

NODE_EXPORTER_URL="http://localhost:9100"
PROMETHEUS_URL="http://localhost:9090"

echo "🔍 Diagnóstico do Node Exporter"
echo "=============================="

# Função para verificar conectividade
check_connectivity() {
    local url=$1
    local service=$2
    
    if curl -s --max-time 5 "$url" > /dev/null; then
        echo "✅ $service está acessível"
        return 0
    else
        echo "❌ $service não está acessível em $url"
        return 1
    fi
}

# Função para verificar métricas
check_metrics() {
    local response=$(curl -s "${NODE_EXPORTER_URL}/metrics")
    local metric_count=$(echo "$response" | grep -c "^node_")
    
    if [ $metric_count -gt 100 ]; then
        echo "✅ Métricas sendo coletadas: $metric_count métricas encontradas"
    else
        echo "⚠️ Poucas métricas encontradas: $metric_count (esperado > 100)"
    fi
}

# Função para verificar collectors ativos
check_collectors() {
    echo "\n📊 Verificando collectors ativos..."
    
    local collectors=$(curl -s "${NODE_EXPORTER_URL}/metrics" | grep "node_scrape_collector_success" | grep '1$')
    
    if [ -n "$collectors" ]; then
        echo "✅ Collectors ativos:"
        echo "$collectors" | sed 's/.*collector="\([^"]*\)".*/  - \1/'
    else
        echo "❌ Nenhum collector ativo encontrado"
    fi
}

# Função para verificar erros
check_errors() {
    echo "\n🚨 Verificando erros..."
    
    local errors=$(curl -s "${NODE_EXPORTER_URL}/metrics" | grep "node_scrape_collector_success.*0$")
    
    if [ -n "$errors" ]; then
        echo "⚠️ Collectors com erro:"
        echo "$errors" | sed 's/.*collector="\([^"]*\)".*/  - \1/'
    else
        echo "✅ Nenhum erro de collector encontrado"
    fi
}

# Função para verificar performance
check_performance() {
    echo "\n⚡ Verificando performance..."
    
    local scrape_duration=$(curl -s "${NODE_EXPORTER_URL}/metrics" | grep "node_scrape_collector_duration_seconds" | head -5)
    
    if [ -n "$scrape_duration" ]; then
        echo "📈 Duração de coleta por collector:"
        echo "$scrape_duration" | while read line; do
            collector=$(echo "$line" | sed 's/.*collector="\([^"]*\)".*/\1/')
            duration=$(echo "$line" | awk '{print $2}')
            echo "  - $collector: ${duration}s"
        done
    fi
}

# Executar verificações
check_connectivity "$NODE_EXPORTER_URL" "Node Exporter"
check_connectivity "$PROMETHEUS_URL" "Prometheus"
check_metrics
check_collectors
check_errors
check_performance

echo "\n📋 Diagnóstico concluído!"
```

### Análise de Logs

```bash
#!/bin/bash
# analyze-node-exporter-logs.sh

LOG_FILE="/var/log/node_exporter.log"
SYSTEMD_SERVICE="node_exporter"

echo "📋 Análise de Logs do Node Exporter"
echo "=================================="

# Função para analisar logs do systemd
analyze_systemd_logs() {
    echo "\n🔍 Analisando logs do systemd..."
    
    if systemctl is-active --quiet "$SYSTEMD_SERVICE"; then
        echo "✅ Serviço está ativo"
    else
        echo "❌ Serviço não está ativo"
        systemctl status "$SYSTEMD_SERVICE" --no-pager -l
    fi
    
    echo "\n📊 Últimas 20 linhas do log:"
    journalctl -u "$SYSTEMD_SERVICE" -n 20 --no-pager
    
    echo "\n🚨 Erros recentes:"
    journalctl -u "$SYSTEMD_SERVICE" -p err --since "1 hour ago" --no-pager
}

# Função para analisar arquivo de log
analyze_log_file() {
    if [ -f "$LOG_FILE" ]; then
        echo "\n📄 Analisando arquivo de log: $LOG_FILE"
        
        echo "\n📊 Estatísticas do log:"
        echo "  - Total de linhas: $(wc -l < "$LOG_FILE")"
        echo "  - Tamanho: $(du -h "$LOG_FILE" | cut -f1)"
        echo "  - Última modificação: $(stat -c %y "$LOG_FILE")"
        
        echo "\n🚨 Erros encontrados:"
        grep -i "error\|fail\|panic" "$LOG_FILE" | tail -10
        
        echo "\n⚠️ Warnings encontrados:"
        grep -i "warn" "$LOG_FILE" | tail -5
    else
        echo "\n📄 Arquivo de log não encontrado: $LOG_FILE"
    fi
}

# Função para verificar recursos do sistema
check_system_resources() {
    echo "\n💻 Verificando recursos do sistema..."
    
    echo "📊 CPU:"
    top -bn1 | grep "node_exporter" | head -5
    
    echo "\n💾 Memória:"
    ps aux | grep node_exporter | grep -v grep | awk '{print "  PID: " $2 ", CPU: " $3 "%, MEM: " $4 "%, CMD: " $11}'
    
    echo "\n💽 Disco (diretório de trabalho):"
    df -h /opt/node_exporter 2>/dev/null || df -h /usr/local/bin/
}

# Executar análises
analyze_systemd_logs
analyze_log_file
check_system_resources

echo "\n✅ Análise de logs concluída!"
```

## ⚡ Otimização de Performance

### Configuração Otimizada por Ambiente

```bash
#!/bin/bash
# optimize-node-exporter.sh

ENVIRONMENT=${1:-"production"}
CONFIG_DIR="/etc/node_exporter"

echo "⚡ Otimizando Node Exporter para ambiente: $ENVIRONMENT"
echo "====================================================="

# Função para configuração de desenvolvimento
setup_development() {
    echo "🔧 Configurando para desenvolvimento..."
    
    cat > "$CONFIG_DIR/node_exporter_dev.yml" << 'EOF'
# Configuração para desenvolvimento
collectors:
  enabled:
    - cpu
    - meminfo
    - diskstats
    - filesystem
    - netdev
    - loadavg
    - time
  disabled:
    - arp
    - bcache
    - bonding
    - conntrack
    - edac
    - entropy
    - hwmon
    - infiniband
    - ipvs
    - mdadm
    - netclass
    - netstat
    - nfs
    - nfsd
    - pressure
    - rapl
    - schedstat
    - sockstat
    - softnet
    - stat
    - textfile
    - thermal
    - vmstat
    - xfs
    - zfs

web:
  listen-address: ":9100"
  telemetry-path: "/metrics"
  max-requests: 10
EOF

    echo "✅ Configuração de desenvolvimento criada"
}

# Função para configuração de produção
setup_production() {
    echo "🔧 Configurando para produção..."
    
    cat > "$CONFIG_DIR/node_exporter_prod.yml" << 'EOF'
# Configuração para produção
collectors:
  enabled:
    - cpu
    - meminfo
    - diskstats
    - filesystem
    - netdev
    - loadavg
    - time
    - hwmon
    - thermal
    - pressure
    - vmstat
    - stat
    - netstat
    - sockstat
    - textfile
  disabled:
    - arp
    - bcache
    - bonding
    - conntrack
    - edac
    - entropy
    - infiniband
    - ipvs
    - mdadm
    - netclass
    - nfs
    - nfsd
    - rapl
    - schedstat
    - softnet
    - xfs
    - zfs

web:
  listen-address: ":9100"
  telemetry-path: "/metrics"
  max-requests: 40
  
# Filtros para reduzir overhead
filters:
  filesystem:
    ignored-mount-points: "^/(dev|proc|sys|var/lib/docker/.+)($|/)"
    ignored-fs-types: "^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$"
  
  netdev:
    ignored-devices: "^(veth.*|docker.*|br-.*|lo)$"
EOF

    echo "✅ Configuração de produção criada"
}

# Função para configuração de alta performance
setup_high_performance() {
    echo "🔧 Configurando para alta performance..."
    
    cat > "$CONFIG_DIR/node_exporter_hp.yml" << 'EOF'
# Configuração para alta performance
collectors:
  enabled:
    - cpu
    - meminfo
    - diskstats
    - filesystem
    - netdev
    - loadavg
  disabled:
    - arp
    - bcache
    - bonding
    - conntrack
    - edac
    - entropy
    - hwmon
    - infiniband
    - ipvs
    - mdadm
    - netclass
    - netstat
    - nfs
    - nfsd
    - pressure
    - rapl
    - schedstat
    - sockstat
    - softnet
    - stat
    - textfile
    - thermal
    - time
    - vmstat
    - xfs
    - zfs

web:
  listen-address: ":9100"
  telemetry-path: "/metrics"
  max-requests: 20
  
# Filtros agressivos
filters:
  filesystem:
    ignored-mount-points: "^/(dev|proc|sys|var/lib/docker/.+|run|tmp)($|/)"
    ignored-fs-types: "^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs|tmpfs)$"
  
  netdev:
    ignored-devices: "^(veth.*|docker.*|br-.*|lo|flannel.*|cni.*|cali.*)$"
EOF

    echo "✅ Configuração de alta performance criada"
}

# Função para otimizar systemd service
optimize_systemd_service() {
    echo "🔧 Otimizando serviço systemd..."
    
    local config_file="$CONFIG_DIR/node_exporter_${ENVIRONMENT}.yml"
    
    cat > "/etc/systemd/system/node_exporter_optimized.service" << EOF
[Unit]
Description=Node Exporter (Optimized)
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
    --web.listen-address=:9100 \
    --web.telemetry-path=/metrics \
    --web.max-requests=40 \
    --collector.filesystem.ignored-mount-points="^/(dev|proc|sys|var/lib/docker/.+)(\$|/)" \
    --collector.filesystem.ignored-fs-types="^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)(\$|/)" \
    --collector.netdev.ignored-devices="^(veth.*|docker.*|br-.*|lo)(\$)" \
    --log.level=warn

SyslogIdentifier=node_exporter
Restart=always
RestartSec=5

# Otimizações de performance
Nice=-10
IOSchedulingClass=1
IOSchedulingPriority=4
CPUSchedulingPolicy=1
CPUSchedulingPriority=50

# Limites de recursos
LimitNOFILE=65536
LimitNPROC=32768

# Segurança
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/node_exporter

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    echo "✅ Serviço systemd otimizado criado"
}

# Executar configuração baseada no ambiente
case $ENVIRONMENT in
    "development")
        setup_development
        ;;
    "production")
        setup_production
        ;;
    "high-performance")
        setup_high_performance
        ;;
    *)
        echo "❌ Ambiente inválido. Use: development, production, ou high-performance"
        exit 1
        ;;
esac

optimize_systemd_service

echo "\n✅ Otimização concluída para ambiente: $ENVIRONMENT"
echo "🔄 Execute 'systemctl restart node_exporter_optimized' para aplicar"
```

### Monitoramento de Performance

```bash
#!/bin/bash
# monitor-node-exporter-performance.sh

NODE_EXPORTER_URL="http://localhost:9100"
MONITOR_DURATION=${1:-300}  # 5 minutos por padrão

echo "📊 Monitorando performance do Node Exporter por ${MONITOR_DURATION}s"
echo "================================================================"

# Função para coletar métricas de performance
collect_performance_metrics() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local response_time=$(curl -w "%{time_total}" -s -o /dev/null "$NODE_EXPORTER_URL/metrics")
    local metric_count=$(curl -s "$NODE_EXPORTER_URL/metrics" | wc -l)
    local process_info=$(ps aux | grep node_exporter | grep -v grep | awk '{print $3 "," $4 "," $5 "," $6}')
    
    echo "$timestamp,$response_time,$metric_count,$process_info" >> performance_log.csv
}

# Criar cabeçalho do CSV
echo "timestamp,response_time,metric_count,cpu_percent,mem_percent,vsz,rss" > performance_log.csv

# Coletar métricas em intervalos
echo "🔄 Coletando métricas a cada 10 segundos..."
for i in $(seq 1 $((MONITOR_DURATION / 10))); do
    collect_performance_metrics
    echo -n "."
    sleep 10
done

echo "\n\n📈 Análise de Performance:"
echo "========================"

# Analisar resultados
python3 << 'EOF'
import pandas as pd
import numpy as np

# Ler dados
df = pd.read_csv('performance_log.csv')

# Estatísticas de tempo de resposta
print(f"⏱️  Tempo de Resposta:")
print(f"   Média: {df['response_time'].mean():.3f}s")
print(f"   Mediana: {df['response_time'].median():.3f}s")
print(f"   Mínimo: {df['response_time'].min():.3f}s")
print(f"   Máximo: {df['response_time'].max():.3f}s")
print(f"   Desvio Padrão: {df['response_time'].std():.3f}s")

# Estatísticas de métricas
print(f"\n📊 Contagem de Métricas:")
print(f"   Média: {df['metric_count'].mean():.0f}")
print(f"   Mínimo: {df['metric_count'].min()}")
print(f"   Máximo: {df['metric_count'].max()}")

# Uso de CPU e Memória
if 'cpu_percent' in df.columns:
    print(f"\n💻 Uso de Recursos:")
    print(f"   CPU Média: {df['cpu_percent'].mean():.2f}%")
    print(f"   Memória Média: {df['mem_percent'].mean():.2f}%")
    print(f"   RSS Médio: {df['rss'].mean():.0f} KB")

# Identificar problemas
if df['response_time'].max() > 1.0:
    print(f"\n⚠️  ALERTA: Tempo de resposta alto detectado ({df['response_time'].max():.3f}s)")

if df['cpu_percent'].mean() > 10:
    print(f"\n⚠️  ALERTA: Alto uso de CPU detectado ({df['cpu_percent'].mean():.2f}%)")
EOF

echo "\n📄 Log detalhado salvo em: performance_log.csv"
```

## 🛠️ Resolução de Problemas Comuns

### Script de Troubleshooting Automatizado

```bash
#!/bin/bash
# troubleshoot-node-exporter.sh

echo "🔧 Troubleshooting Automatizado do Node Exporter"
echo "==============================================="

# Função para verificar e corrigir problemas comuns
fix_common_issues() {
    echo "\n🔍 Verificando problemas comuns..."
    
    # Problema 1: Serviço não está rodando
    if ! systemctl is-active --quiet node_exporter; then
        echo "❌ Problema: Serviço não está ativo"
        echo "🔧 Tentando iniciar o serviço..."
        systemctl start node_exporter
        
        if systemctl is-active --quiet node_exporter; then
            echo "✅ Serviço iniciado com sucesso"
        else
            echo "❌ Falha ao iniciar serviço. Verificando logs..."
            journalctl -u node_exporter -n 10 --no-pager
        fi
    else
        echo "✅ Serviço está ativo"
    fi
    
    # Problema 2: Porta ocupada
    if netstat -tlnp | grep -q ":9100 "; then
        local pid=$(netstat -tlnp | grep ":9100 " | awk '{print $7}' | cut -d'/' -f1)
        local process=$(ps -p $pid -o comm= 2>/dev/null)
        
        if [ "$process" != "node_exporter" ]; then
            echo "⚠️ Problema: Porta 9100 ocupada por processo: $process (PID: $pid)"
            echo "🔧 Considere parar o processo conflitante ou alterar a porta"
        else
            echo "✅ Porta 9100 está sendo usada pelo Node Exporter"
        fi
    else
        echo "❌ Problema: Porta 9100 não está em uso"
    fi
    
    # Problema 3: Permissões de arquivo
    if [ ! -r "/proc/stat" ]; then
        echo "❌ Problema: Sem permissão para ler /proc/stat"
        echo "🔧 Verifique as permissões do usuário node_exporter"
    else
        echo "✅ Permissões de /proc estão OK"
    fi
    
    # Problema 4: Collectors falhando
    local failed_collectors=$(curl -s "http://localhost:9100/metrics" | grep "node_scrape_collector_success.*0$" | wc -l)
    
    if [ $failed_collectors -gt 0 ]; then
        echo "⚠️ Problema: $failed_collectors collectors falhando"
        echo "🔧 Collectors com falha:"
        curl -s "http://localhost:9100/metrics" | grep "node_scrape_collector_success.*0$" | sed 's/.*collector="\([^"]*\)".*/  - \1/'
    else
        echo "✅ Todos os collectors estão funcionando"
    fi
}

# Função para verificar configuração
check_configuration() {
    echo "\n⚙️ Verificando configuração..."
    
    local config_file="/etc/systemd/system/node_exporter.service"
    
    if [ -f "$config_file" ]; then
        echo "✅ Arquivo de configuração encontrado: $config_file"
        
        # Verificar argumentos comuns
        if grep -q "web.listen-address" "$config_file"; then
            echo "✅ Endereço de escuta configurado"
        else
            echo "⚠️ Endereço de escuta não especificado (usando padrão)"
        fi
        
        if grep -q "collector.filesystem.ignored-mount-points" "$config_file"; then
            echo "✅ Filtros de filesystem configurados"
        else
            echo "⚠️ Filtros de filesystem não configurados"
        fi
    else
        echo "❌ Arquivo de configuração não encontrado"
    fi
}

# Função para testar conectividade
test_connectivity() {
    echo "\n🌐 Testando conectividade..."
    
    # Teste local
    if curl -s --max-time 5 "http://localhost:9100/metrics" > /dev/null; then
        echo "✅ Conectividade local OK"
    else
        echo "❌ Falha na conectividade local"
    fi
    
    # Teste de métricas específicas
    local cpu_metrics=$(curl -s "http://localhost:9100/metrics" | grep -c "node_cpu_seconds_total")
    
    if [ $cpu_metrics -gt 0 ]; then
        echo "✅ Métricas de CPU disponíveis ($cpu_metrics métricas)"
    else
        echo "❌ Métricas de CPU não encontradas"
    fi
}

# Função para gerar relatório de diagnóstico
generate_diagnostic_report() {
    echo "\n📋 Gerando relatório de diagnóstico..."
    
    local report_file="node_exporter_diagnostic_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "Node Exporter Diagnostic Report"
        echo "Generated: $(date)"
        echo "==============================="
        echo ""
        
        echo "System Information:"
        echo "- OS: $(uname -a)"
        echo "- Uptime: $(uptime)"
        echo "- Load: $(cat /proc/loadavg)"
        echo ""
        
        echo "Node Exporter Status:"
        systemctl status node_exporter --no-pager -l
        echo ""
        
        echo "Process Information:"
        ps aux | grep node_exporter | grep -v grep
        echo ""
        
        echo "Network Status:"
        netstat -tlnp | grep :9100
        echo ""
        
        echo "Recent Logs:"
        journalctl -u node_exporter -n 20 --no-pager
        echo ""
        
        echo "Metrics Sample:"
        curl -s "http://localhost:9100/metrics" | head -20
        
    } > "$report_file"
    
    echo "📄 Relatório salvo em: $report_file"
}

# Executar troubleshooting
fix_common_issues
check_configuration
test_connectivity
generate_diagnostic_report

echo "\n✅ Troubleshooting concluído!"
echo "💡 Se os problemas persistirem, verifique o relatório de diagnóstico gerado."
```

## 📊 Métricas de Monitoramento Interno

### Monitoramento do Próprio Node Exporter

```bash
#!/bin/bash
# monitor-node-exporter-health.sh

echo "🏥 Monitoramento de Saúde do Node Exporter"
echo "=========================================="

# Função para criar métricas customizadas
create_health_metrics() {
    local textfile_dir="/var/lib/node_exporter/textfile_collector"
    mkdir -p "$textfile_dir"
    
    # Métrica de saúde geral
    local health_status=1
    
    # Verificar se o serviço está rodando
    if ! systemctl is-active --quiet node_exporter; then
        health_status=0
    fi
    
    # Verificar se as métricas estão sendo geradas
    local metric_count=$(curl -s "http://localhost:9100/metrics" 2>/dev/null | wc -l)
    if [ $metric_count -lt 100 ]; then
        health_status=0
    fi
    
    # Verificar tempo de resposta
    local response_time=$(curl -w "%{time_total}" -s -o /dev/null "http://localhost:9100/metrics" 2>/dev/null)
    if (( $(echo "$response_time > 2.0" | bc -l) )); then
        health_status=0
    fi
    
    # Gerar arquivo de métricas
    cat > "${textfile_dir}/node_exporter_health.prom" << EOF
# HELP node_exporter_health Node Exporter health status
# TYPE node_exporter_health gauge
node_exporter_health $health_status

# HELP node_exporter_metric_count Number of metrics being exported
# TYPE node_exporter_metric_count gauge
node_exporter_metric_count $metric_count

# HELP node_exporter_response_time Response time in seconds
# TYPE node_exporter_response_time gauge
node_exporter_response_time $response_time

# HELP node_exporter_uptime_seconds Node Exporter uptime in seconds
# TYPE node_exporter_uptime_seconds counter
node_exporter_uptime_seconds $(systemctl show node_exporter --property=ActiveEnterTimestamp --value | xargs -I {} date -d "{}" +%s 2>/dev/null || echo 0)
EOF

    echo "✅ Métricas de saúde atualizadas"
}

# Função para verificar alertas
check_alerts() {
    echo "\n🚨 Verificando alertas ativos..."
    
    local prometheus_url="http://localhost:9090"
    local alerts=$(curl -s "${prometheus_url}/api/v1/alerts" 2>/dev/null | jq -r '.data.alerts[] | select(.labels.job=="node-exporter" and .state=="firing") | .labels.alertname' 2>/dev/null)
    
    if [ -n "$alerts" ]; then
        echo "⚠️ Alertas ativos relacionados ao Node Exporter:"
        echo "$alerts" | while read alert; do
            echo "  - $alert"
        done
    else
        echo "✅ Nenhum alerta ativo relacionado ao Node Exporter"
    fi
}

# Função para verificar tendências
check_trends() {
    echo "\n📈 Verificando tendências de performance..."
    
    # Coletar dados históricos do Prometheus
    local prometheus_url="http://localhost:9090"
    
    # CPU usage trend
    local cpu_trend=$(curl -s "${prometheus_url}/api/v1/query?query=rate(process_cpu_seconds_total{job='node-exporter'}[1h])" | jq -r '.data.result[0].value[1]' 2>/dev/null)
    
    if [ "$cpu_trend" != "null" ] && [ -n "$cpu_trend" ]; then
        echo "📊 Uso de CPU (última hora): ${cpu_trend}%"
    fi
    
    # Memory usage trend
    local mem_trend=$(curl -s "${prometheus_url}/api/v1/query?query=process_resident_memory_bytes{job='node-exporter'}" | jq -r '.data.result[0].value[1]' 2>/dev/null)
    
    if [ "$mem_trend" != "null" ] && [ -n "$mem_trend" ]; then
        local mem_mb=$((mem_trend / 1024 / 1024))
        echo "💾 Uso de Memória: ${mem_mb}MB"
    fi
}

# Executar monitoramento
create_health_metrics
check_alerts
check_trends

echo "\n✅ Monitoramento de saúde concluído!"
```

## 🧪 Exercício Prático

### Script Principal do Exercício

```bash
#!/bin/bash
# exercicio-troubleshooting-otimizacao.sh

echo "🎯 Exercício: Troubleshooting e Otimização"
echo "==========================================="

# Função para simular problemas
simulate_problems() {
    echo "\n🎭 Simulando problemas para diagnóstico..."
    
    # Problema 1: Alto uso de CPU
    echo "🔥 Simulando alto uso de CPU..."
    stress --cpu 2 --timeout 60s &
    STRESS_PID=$!
    
    # Problema 2: Collector com falha (simulado)
    echo "❌ Simulando falha de collector..."
    # Temporariamente desabilitar um collector
    systemctl stop node_exporter
    
    # Iniciar com collector desabilitado
    /usr/local/bin/node_exporter \
        --collector.disable-defaults \
        --collector.cpu \
        --collector.meminfo \
        --web.listen-address=:9101 &
    TEMP_EXPORTER_PID=$!
    
    sleep 5
    echo "⚠️ Problemas simulados. Iniciando diagnóstico..."
}

# Função para executar diagnóstico
run_diagnostics() {
    echo "\n🔍 Executando diagnóstico completo..."
    
    # Executar script de health check
    ./node-exporter-health-check.sh
    
    # Executar troubleshooting
    ./troubleshoot-node-exporter.sh
    
    # Monitorar performance
    echo "\n📊 Monitorando performance por 60 segundos..."
    timeout 60s ./monitor-node-exporter-performance.sh 60
}

# Função para aplicar otimizações
apply_optimizations() {
    echo "\n⚡ Aplicando otimizações..."
    
    # Parar simulação
    kill $STRESS_PID 2>/dev/null
    kill $TEMP_EXPORTER_PID 2>/dev/null
    
    # Aplicar configuração otimizada
    ./optimize-node-exporter.sh production
    
    # Reiniciar serviço
    systemctl restart node_exporter_optimized
    
    sleep 10
    
    echo "✅ Otimizações aplicadas"
}

# Função para validar melhorias
validate_improvements() {
    echo "\n✅ Validando melhorias..."
    
    # Verificar tempo de resposta
    local response_time=$(curl -w "%{time_total}" -s -o /dev/null "http://localhost:9100/metrics")
    echo "⏱️ Tempo de resposta: ${response_time}s"
    
    # Verificar contagem de métricas
    local metric_count=$(curl -s "http://localhost:9100/metrics" | wc -l)
    echo "📊 Métricas disponíveis: $metric_count"
    
    # Verificar uso de recursos
    local cpu_usage=$(ps aux | grep node_exporter | grep -v grep | awk '{print $3}')
    local mem_usage=$(ps aux | grep node_exporter | grep -v grep | awk '{print $4}')
    echo "💻 Uso de CPU: ${cpu_usage}%"
    echo "💾 Uso de Memória: ${mem_usage}%"
    
    # Verificar collectors ativos
    local active_collectors=$(curl -s "http://localhost:9100/metrics" | grep "node_scrape_collector_success.*1$" | wc -l)
    echo "🔧 Collectors ativos: $active_collectors"
}

# Executar exercício
echo "📋 Iniciando exercício de troubleshooting e otimização..."

# Verificar estado inicial
echo "\n📊 Estado inicial:"
validate_improvements

# Simular problemas
simulate_problems

# Executar diagnóstico
run_diagnostics

# Aplicar otimizações
apply_optimizations

# Validar melhorias
echo "\n📊 Estado após otimização:"
validate_improvements

echo "\n🎉 Exercício concluído!"
echo "📄 Verifique os relatórios gerados para análise detalhada."
```

### Critérios de Validação

```bash
#!/bin/bash
# validacao-troubleshooting.sh

echo "🔍 Validando habilidades de troubleshooting..."

SCORE=0
TOTAL=12

# Teste 1: Diagnóstico de serviço
if systemctl is-active --quiet node_exporter; then
    echo "✅ Serviço Node Exporter está ativo"
    ((SCORE++))
else
    echo "❌ Serviço Node Exporter não está ativo"
fi

# Teste 2: Conectividade
if curl -s --max-time 5 "http://localhost:9100/metrics" > /dev/null; then
    echo "✅ Node Exporter está respondendo"
    ((SCORE++))
else
    echo "❌ Node Exporter não está respondendo"
fi

# Teste 3: Tempo de resposta
response_time=$(curl -w "%{time_total}" -s -o /dev/null "http://localhost:9100/metrics")
if (( $(echo "$response_time < 1.0" | bc -l) )); then
    echo "✅ Tempo de resposta adequado: ${response_time}s"
    ((SCORE++))
else
    echo "⚠️ Tempo de resposta alto: ${response_time}s"
fi

# Teste 4: Contagem de métricas
metric_count=$(curl -s "http://localhost:9100/metrics" | wc -l)
if [ $metric_count -gt 100 ]; then
    echo "✅ Número adequado de métricas: $metric_count"
    ((SCORE++))
else
    echo "⚠️ Poucas métricas disponíveis: $metric_count"
fi

# Teste 5: Collectors funcionando
failed_collectors=$(curl -s "http://localhost:9100/metrics" | grep "node_scrape_collector_success.*0$" | wc -l)
if [ $failed_collectors -eq 0 ]; then
    echo "✅ Todos os collectors estão funcionando"
    ((SCORE++))
else
    echo "⚠️ $failed_collectors collectors com falha"
fi

# Teste 6: Configuração otimizada
if [ -f "/etc/systemd/system/node_exporter_optimized.service" ]; then
    echo "✅ Configuração otimizada encontrada"
    ((SCORE++))
else
    echo "❌ Configuração otimizada não encontrada"
fi

# Teste 7: Filtros configurados
if systemctl cat node_exporter | grep -q "ignored-mount-points"; then
    echo "✅ Filtros de filesystem configurados"
    ((SCORE++))
else
    echo "⚠️ Filtros de filesystem não configurados"
fi

# Teste 8: Logs sem erros críticos
error_count=$(journalctl -u node_exporter --since "1 hour ago" -p err --no-pager | wc -l)
if [ $error_count -eq 0 ]; then
    echo "✅ Nenhum erro crítico nos logs"
    ((SCORE++))
else
    echo "⚠️ $error_count erros encontrados nos logs"
fi

# Teste 9: Uso de recursos
cpu_usage=$(ps aux | grep node_exporter | grep -v grep | awk '{print $3}' | head -1)
if (( $(echo "$cpu_usage < 5.0" | bc -l) )); then
    echo "✅ Uso de CPU otimizado: ${cpu_usage}%"
    ((SCORE++))
else
    echo "⚠️ Alto uso de CPU: ${cpu_usage}%"
fi

# Teste 10: Métricas de saúde
if [ -f "/var/lib/node_exporter/textfile_collector/node_exporter_health.prom" ]; then
    echo "✅ Métricas de saúde configuradas"
    ((SCORE++))
else
    echo "❌ Métricas de saúde não configuradas"
fi

# Teste 11: Relatório de diagnóstico
if ls node_exporter_diagnostic_*.txt 1> /dev/null 2>&1; then
    echo "✅ Relatório de diagnóstico gerado"
    ((SCORE++))
else
    echo "❌ Relatório de diagnóstico não encontrado"
fi

# Teste 12: Log de performance
if [ -f "performance_log.csv" ]; then
    echo "✅ Log de performance gerado"
    ((SCORE++))
else
    echo "❌ Log de performance não encontrado"
fi

echo "\n📊 Pontuação Final: $SCORE/$TOTAL"

if [ $SCORE -eq $TOTAL ]; then
    echo "🏆 Excelente! Domínio completo de troubleshooting e otimização!"
elif [ $SCORE -ge 9 ]; then
    echo "🎉 Muito bom! Habilidades sólidas de troubleshooting!"
elif [ $SCORE -ge 6 ]; then
    echo "👍 Bom progresso! Continue praticando!"
else
    echo "📚 Precisa de mais prática. Revise os conceitos!"
fi
```

## 📚 Resumo do Módulo

Neste módulo você aprendeu:

### 🎯 **Conceitos Principais**
- **Diagnóstico Sistemático**: Metodologias para identificar problemas
- **Otimização de Performance**: Configurações para diferentes ambientes
- **Monitoramento Proativo**: Métricas de saúde e alertas
- **Resolução de Problemas**: Scripts automatizados de troubleshooting

### 🛠️ **Habilidades Desenvolvidas**
- Análise de logs e métricas de performance
- Configuração otimizada para produção
- Criação de scripts de diagnóstico
- Monitoramento da saúde do próprio Node Exporter

### 📈 **Próximos Passos**
- **Módulo 07**: Projeto Final - Implementação completa

---

## 🔗 Navegação

- [← Módulo Anterior: Dashboards e Alertas](05-dashboards-alertas.md)
- [→ Próximo Módulo: Projeto Final](07-projeto-final.md)
- [🏠 Voltar ao Índice](README.md)

---

*Documentação do Node Exporter - Módulo 06*
*Observability Stack - Especialização em Monitoramento*