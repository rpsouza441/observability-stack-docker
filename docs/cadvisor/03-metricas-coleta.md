# Módulo 03: Métricas e Coleta

> **Dominando as métricas do cAdvisor** - Tipos, configuração, otimização e análise avançada

## 📋 Objetivos do Módulo

Ao final deste módulo, você será capaz de:
- ✅ Compreender todos os tipos de métricas do cAdvisor
- ✅ Configurar coleta seletiva de métricas
- ✅ Otimizar performance da coleta
- ✅ Analisar métricas de containers em profundidade
- ✅ Implementar filtros e customizações avançadas

## 📊 Tipos de Métricas

### Métricas de CPU

```yaml
# Principais métricas de CPU
cpu_metrics:
  # Uso total de CPU (segundos)
  container_cpu_usage_seconds_total:
    description: "Tempo total de CPU usado pelo container"
    type: "counter"
    labels: ["id", "name", "image", "cpu"]
    
  # Taxa de uso de CPU
  container_cpu_user_seconds_total:
    description: "Tempo de CPU em modo usuário"
    type: "counter"
    
  container_cpu_system_seconds_total:
    description: "Tempo de CPU em modo sistema"
    type: "counter"
    
  # Throttling de CPU
  container_cpu_cfs_throttled_seconds_total:
    description: "Tempo que o container foi throttled"
    type: "counter"
    
  container_cpu_cfs_periods_total:
    description: "Número de períodos CFS"
    type: "counter"
    
  container_cpu_cfs_throttled_periods_total:
    description: "Períodos CFS throttled"
    type: "counter"
```

### Métricas de Memória

```yaml
# Métricas de memória detalhadas
memory_metrics:
  # Uso atual de memória
  container_memory_usage_bytes:
    description: "Uso atual de memória em bytes"
    type: "gauge"
    
  container_memory_working_set_bytes:
    description: "Working set de memória"
    type: "gauge"
    
  # Limites e reservas
  container_spec_memory_limit_bytes:
    description: "Limite de memória configurado"
    type: "gauge"
    
  container_spec_memory_reservation_limit_bytes:
    description: "Reserva de memória"
    type: "gauge"
    
  # Cache e buffers
  container_memory_cache:
    description: "Memória em cache"
    type: "gauge"
    
  container_memory_rss:
    description: "Resident Set Size"
    type: "gauge"
    
  # Swap
  container_memory_swap:
    description: "Uso de swap"
    type: "gauge"
    
  # Falhas de página
  container_memory_failures_total:
    description: "Falhas de alocação de memória"
    type: "counter"
    labels: ["failure_type", "scope"]
```

### Métricas de Rede

```yaml
# Métricas de rede por interface
network_metrics:
  # Bytes transferidos
  container_network_receive_bytes_total:
    description: "Bytes recebidos pela interface"
    type: "counter"
    labels: ["interface"]
    
  container_network_transmit_bytes_total:
    description: "Bytes transmitidos pela interface"
    type: "counter"
    labels: ["interface"]
    
  # Pacotes
  container_network_receive_packets_total:
    description: "Pacotes recebidos"
    type: "counter"
    
  container_network_transmit_packets_total:
    description: "Pacotes transmitidos"
    type: "counter"
    
  # Erros e drops
  container_network_receive_errors_total:
    description: "Erros de recepção"
    type: "counter"
    
  container_network_transmit_errors_total:
    description: "Erros de transmissão"
    type: "counter"
    
  container_network_receive_packets_dropped_total:
    description: "Pacotes recebidos descartados"
    type: "counter"
    
  container_network_transmit_packets_dropped_total:
    description: "Pacotes transmitidos descartados"
    type: "counter"
```

### Métricas de Filesystem

```yaml
# Métricas de sistema de arquivos
filesystem_metrics:
  # Uso de espaço
  container_fs_usage_bytes:
    description: "Bytes usados no filesystem"
    type: "gauge"
    labels: ["device"]
    
  container_fs_limit_bytes:
    description: "Limite do filesystem em bytes"
    type: "gauge"
    
  # Inodes
  container_fs_inodes_free:
    description: "Inodes livres"
    type: "gauge"
    
  container_fs_inodes_total:
    description: "Total de inodes"
    type: "gauge"
    
  # I/O Operations
  container_fs_reads_total:
    description: "Operações de leitura"
    type: "counter"
    
  container_fs_writes_total:
    description: "Operações de escrita"
    type: "counter"
    
  container_fs_read_seconds_total:
    description: "Tempo gasto em leituras"
    type: "counter"
    
  container_fs_write_seconds_total:
    description: "Tempo gasto em escritas"
    type: "counter"
```

## 🔧 Configuração de Coleta

### Configuração Básica

```bash
#!/bin/bash
# configure-cadvisor-metrics.sh - Configuração de métricas

set -e

# Configurações de métricas
CONFIG_DIR="./cadvisor-config"
mkdir -p $CONFIG_DIR

# Configuração para desenvolvimento (todas as métricas)
cat > $CONFIG_DIR/dev-config.yaml << 'EOF'
# Configuração para desenvolvimento
args:
  - --housekeeping_interval=10s
  - --max_housekeeping_interval=15s
  - --event_storage_event_limit=default=100
  - --event_storage_age_limit=default=1h
  - --store_container_labels=true
  - --whitelisted_container_labels=*
  - --docker_only=false
  - --enable_metrics=cpu,memory,network,filesystem,disk
  
resources:
  limits:
    memory: 300Mi
    cpu: 500m
  requests:
    memory: 150Mi
    cpu: 100m
EOF

# Configuração para produção (métricas otimizadas)
cat > $CONFIG_DIR/prod-config.yaml << 'EOF'
# Configuração para produção
args:
  - --housekeeping_interval=30s
  - --max_housekeeping_interval=35s
  - --event_storage_event_limit=default=0
  - --event_storage_age_limit=default=0
  - --disable_metrics=percpu,sched,tcp,udp,disk
  - --docker_only=true
  - --store_container_labels=false
  - --whitelisted_container_labels=io.kubernetes.container.name,io.kubernetes.pod.name
  
resources:
  limits:
    memory: 200Mi
    cpu: 300m
  requests:
    memory: 100Mi
    cpu: 100m
EOF

# Configuração para alto volume (mínimas métricas)
cat > $CONFIG_DIR/high-volume-config.yaml << 'EOF'
# Configuração para alto volume
args:
  - --housekeeping_interval=60s
  - --max_housekeeping_interval=65s
  - --event_storage_event_limit=default=0
  - --event_storage_age_limit=default=0
  - --disable_metrics=percpu,sched,tcp,udp,disk,network,filesystem
  - --enable_metrics=cpu,memory
  - --docker_only=true
  - --store_container_labels=false
  - --max_procs=1
  
resources:
  limits:
    memory: 150Mi
    cpu: 200m
  requests:
    memory: 75Mi
    cpu: 50m
EOF

echo "✅ Configurações de métricas criadas em $CONFIG_DIR"
```

### Filtros de Containers

```yaml
# docker-compose.yml com filtros
version: '3.8'

services:
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.47.0
    container_name: cadvisor-filtered
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    privileged: true
    devices:
      - /dev/kmsg
    command:
      - '/usr/bin/cadvisor'
      - '--logtostderr'
      - '--v=0'
      # Filtros de containers
      - '--docker_only=true'
      - '--whitelisted_container_labels=monitor=true,env=production'
      - '--store_container_labels=false'
      # Métricas seletivas
      - '--disable_metrics=percpu,sched,tcp,udp'
      - '--enable_metrics=cpu,memory,network'
      # Performance
      - '--housekeeping_interval=30s'
      - '--max_housekeeping_interval=35s'
      - '--event_storage_event_limit=default=0'
    labels:
      - "monitor=true"
      - "env=production"

  # Aplicação de exemplo para monitorar
  nginx:
    image: nginx:alpine
    container_name: nginx-monitored
    ports:
      - "80:80"
    labels:
      - "monitor=true"  # Será monitorado
      - "env=production"

  # Aplicação que NÃO será monitorada
  redis:
    image: redis:alpine
    container_name: redis-unmonitored
    # Sem label 'monitor=true'
```

### Configuração Avançada de Labels

```bash
#!/bin/bash
# setup-container-labels.sh - Configurar labels para monitoramento

set -e

# Função para criar containers com labels específicos
create_monitored_containers() {
    echo "🏗️ Creating containers with monitoring labels..."
    
    # Container web com labels completos
    docker run -d \
        --name web-app \
        --label "monitor=true" \
        --label "service=web" \
        --label "team=frontend" \
        --label "env=production" \
        --label "version=1.2.3" \
        -p 8081:80 \
        nginx:alpine
    
    # Container API com labels específicos
    docker run -d \
        --name api-service \
        --label "monitor=true" \
        --label "service=api" \
        --label "team=backend" \
        --label "env=production" \
        --label "critical=true" \
        -p 8082:3000 \
        node:alpine sh -c "while true; do sleep 30; done"
    
    # Container de desenvolvimento (não monitorado)
    docker run -d \
        --name dev-container \
        --label "env=development" \
        alpine sh -c "while true; do sleep 30; done"
    
    echo "✅ Containers created with labels"
}

# Função para configurar cAdvisor com filtros
setup_cadvisor_with_filters() {
    echo "🔧 Setting up cAdvisor with label filters..."
    
    # Parar cAdvisor existente
    docker stop cadvisor 2>/dev/null || true
    docker rm cadvisor 2>/dev/null || true
    
    # Iniciar cAdvisor com filtros
    docker run -d \
        --volume=/:/rootfs:ro \
        --volume=/var/run:/var/run:ro \
        --volume=/sys:/sys:ro \
        --volume=/var/lib/docker/:/var/lib/docker:ro \
        --volume=/dev/disk/:/dev/disk:ro \
        --publish=8080:8080 \
        --name=cadvisor \
        --restart=unless-stopped \
        --privileged \
        --device=/dev/kmsg \
        gcr.io/cadvisor/cadvisor:latest \
        --logtostderr \
        --v=0 \
        --docker_only=true \
        --whitelisted_container_labels=monitor,service,team,env,critical \
        --store_container_labels=true \
        --housekeeping_interval=30s
    
    echo "✅ cAdvisor configured with label filters"
}

# Função para testar filtros
test_label_filters() {
    echo "🧪 Testing label filters..."
    
    # Aguardar cAdvisor inicializar
    sleep 10
    
    # Testar endpoint de containers
    echo "📊 Containers being monitored:"
    curl -s "http://localhost:8080/api/v1.3/containers/" | \
        jq -r '.[] | select(.labels != null) | "\(.name): \(.labels)"' | \
        head -10
    
    echo
    echo "📈 Sample metrics with labels:"
    curl -s "http://localhost:8080/metrics" | \
        grep 'container_cpu_usage_seconds_total.*monitor="true"' | \
        head -5
}

# Função principal
main() {
    echo "🚀 Setting up cAdvisor with advanced label filtering..."
    
    create_monitored_containers
    setup_cadvisor_with_filters
    test_label_filters
    
    echo
    echo "✅ Setup completed!"
    echo "🌐 cAdvisor UI: http://localhost:8080"
    echo "📊 Metrics: http://localhost:8080/metrics"
}

# Executar
main "$@"
```

## 📈 Análise de Métricas

### Queries PromQL Essenciais

```yaml
# queries-cadvisor.yaml - Queries essenciais para análise
queries:
  # CPU
  cpu_usage_rate:
    query: |
      rate(container_cpu_usage_seconds_total[5m]) * 100
    description: "Taxa de uso de CPU em porcentagem"
    
  cpu_throttling_rate:
    query: |
      rate(container_cpu_cfs_throttled_seconds_total[5m]) / 
      rate(container_cpu_cfs_periods_total[5m]) * 100
    description: "Taxa de throttling de CPU"
    
  # Memória
  memory_usage_percent:
    query: |
      (container_memory_working_set_bytes / 
       container_spec_memory_limit_bytes) * 100
    description: "Uso de memória em porcentagem do limite"
    
  memory_cache_ratio:
    query: |
      container_memory_cache / container_memory_usage_bytes * 100
    description: "Proporção de cache na memória total"
    
  # Rede
  network_receive_rate:
    query: |
      rate(container_network_receive_bytes_total[5m]) * 8
    description: "Taxa de recepção de rede em bits/s"
    
  network_transmit_rate:
    query: |
      rate(container_network_transmit_bytes_total[5m]) * 8
    description: "Taxa de transmissão de rede em bits/s"
    
  network_error_rate:
    query: |
      rate(container_network_receive_errors_total[5m]) + 
      rate(container_network_transmit_errors_total[5m])
    description: "Taxa de erros de rede"
    
  # Filesystem
  filesystem_usage_percent:
    query: |
      (container_fs_usage_bytes / container_fs_limit_bytes) * 100
    description: "Uso do filesystem em porcentagem"
    
  filesystem_io_rate:
    query: |
      rate(container_fs_reads_total[5m]) + 
      rate(container_fs_writes_total[5m])
    description: "Taxa de operações I/O"
```

### Script de Análise de Métricas

```bash
#!/bin/bash
# analyze-cadvisor-metrics.sh - Análise automatizada de métricas

set -e

# Configurações
CADVISOR_URL="http://localhost:8080"
OUTPUT_DIR="./metrics-analysis"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "${BLUE}[SECTION]${NC} $1"
}

# Criar diretório de output
mkdir -p $OUTPUT_DIR

# Função para coletar métricas básicas
collect_basic_metrics() {
    log_section "Collecting basic metrics..."
    
    local output_file="$OUTPUT_DIR/basic_metrics_$TIMESTAMP.txt"
    
    {
        echo "=== cAdvisor Basic Metrics Analysis ==="
        echo "Timestamp: $(date)"
        echo "cAdvisor URL: $CADVISOR_URL"
        echo
        
        # Verificar se cAdvisor está respondendo
        if curl -s -f "$CADVISOR_URL/healthz" > /dev/null; then
            echo "✅ cAdvisor is healthy"
        else
            echo "❌ cAdvisor is not responding"
            return 1
        fi
        
        echo
        echo "=== Container Count ==="
        curl -s "$CADVISOR_URL/api/v1.3/containers/" | \
            jq -r 'length' | \
            xargs -I {} echo "Total containers monitored: {}"
        
        echo
        echo "=== Top CPU Consumers ==="
        curl -s "$CADVISOR_URL/metrics" | \
            grep 'container_cpu_usage_seconds_total' | \
            grep -v 'cpu="total"' | \
            sort -k2 -nr | \
            head -10
        
        echo
        echo "=== Memory Usage Summary ==="
        curl -s "$CADVISOR_URL/metrics" | \
            grep 'container_memory_working_set_bytes' | \
            awk '{print $2}' | \
            sort -nr | \
            head -10 | \
            awk '{printf "%.2f MB\n", $1/1024/1024}'
        
    } > $output_file
    
    log_info "Basic metrics saved to: $output_file"
}

# Função para análise de performance
analyze_performance() {
    log_section "Analyzing container performance..."
    
    local output_file="$OUTPUT_DIR/performance_analysis_$TIMESTAMP.json"
    
    # Coletar dados de performance via API
    curl -s "$CADVISOR_URL/api/v1.3/containers/" | \
        jq '[
            .[] | 
            select(.name != "/" and .name != "/docker") |
            {
                name: .name,
                image: .spec.image,
                cpu_limit: .spec.cpu.limit,
                memory_limit: .spec.memory.limit,
                last_seen: .stats[-1].timestamp,
                cpu_usage: .stats[-1].cpu.usage.total,
                memory_usage: .stats[-1].memory.usage,
                network_rx: .stats[-1].network.rx_bytes,
                network_tx: .stats[-1].network.tx_bytes
            }
        ]' > $output_file
    
    log_info "Performance analysis saved to: $output_file"
}

# Função para detectar anomalias
detect_anomalies() {
    log_section "Detecting performance anomalies..."
    
    local output_file="$OUTPUT_DIR/anomalies_$TIMESTAMP.txt"
    
    {
        echo "=== Performance Anomalies Detection ==="
        echo "Timestamp: $(date)"
        echo
        
        # Containers com alto uso de CPU (simulado)
        echo "🔥 High CPU Usage Containers:"
        curl -s "$CADVISOR_URL/metrics" | \
            grep 'container_cpu_usage_seconds_total' | \
            awk '{print $1, $2}' | \
            sort -k2 -nr | \
            head -5
        
        echo
        echo "💾 High Memory Usage Containers:"
        curl -s "$CADVISOR_URL/metrics" | \
            grep 'container_memory_working_set_bytes' | \
            awk '{print $1, $2}' | \
            sort -k2 -nr | \
            head -5
        
        echo
        echo "🌐 High Network Traffic Containers:"
        curl -s "$CADVISOR_URL/metrics" | \
            grep 'container_network_transmit_bytes_total' | \
            awk '{print $1, $2}' | \
            sort -k2 -nr | \
            head -5
        
        echo
        echo "⚠️ Containers with Resource Limits Issues:"
        curl -s "$CADVISOR_URL/api/v1.3/containers/" | \
            jq -r '.[] | 
                select(.spec.memory.limit > 0 and .stats[-1].memory.usage > 0) |
                select((.stats[-1].memory.usage / .spec.memory.limit) > 0.8) |
                "\(.name): \((.stats[-1].memory.usage / .spec.memory.limit * 100 | floor))% memory usage"'
        
    } > $output_file
    
    log_info "Anomalies report saved to: $output_file"
}

# Função para gerar relatório consolidado
generate_report() {
    log_section "Generating consolidated report..."
    
    local report_file="$OUTPUT_DIR/cadvisor_report_$TIMESTAMP.html"
    
    cat > $report_file << EOF
<!DOCTYPE html>
<html>
<head>
    <title>cAdvisor Metrics Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f4f4f4; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border-left: 4px solid #007cba; }
        .metric { background: #f9f9f9; padding: 10px; margin: 5px 0; border-radius: 3px; }
        .warning { border-left-color: #ff9800; }
        .error { border-left-color: #f44336; }
        pre { background: #f5f5f5; padding: 10px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="header">
        <h1>📊 cAdvisor Metrics Analysis Report</h1>
        <p><strong>Generated:</strong> $(date)</p>
        <p><strong>cAdvisor URL:</strong> $CADVISOR_URL</p>
    </div>
    
    <div class="section">
        <h2>🏥 Health Status</h2>
        <div class="metric">
EOF

    # Verificar saúde e adicionar ao relatório
    if curl -s -f "$CADVISOR_URL/healthz" > /dev/null; then
        echo "            <span style='color: green;'>✅ cAdvisor is healthy and responding</span>" >> $report_file
    else
        echo "            <span style='color: red;'>❌ cAdvisor is not responding</span>" >> $report_file
    fi

    cat >> $report_file << EOF
        </div>
    </div>
    
    <div class="section">
        <h2>📈 Metrics Summary</h2>
        <div class="metric">
            <strong>Total Containers Monitored:</strong> 
EOF

    # Adicionar contagem de containers
    curl -s "$CADVISOR_URL/api/v1.3/containers/" | \
        jq -r 'length' >> $report_file

    cat >> $report_file << EOF
        </div>
        <div class="metric">
            <strong>Report Files Generated:</strong>
            <ul>
EOF

    # Listar arquivos gerados
    for file in $OUTPUT_DIR/*_$TIMESTAMP.*; do
        if [ -f "$file" ]; then
            echo "                <li>$(basename "$file")</li>" >> $report_file
        fi
    done

    cat >> $report_file << EOF
            </ul>
        </div>
    </div>
    
    <div class="section">
        <h2>🔗 Quick Links</h2>
        <div class="metric">
            <a href="$CADVISOR_URL" target="_blank">📊 cAdvisor Web UI</a><br>
            <a href="$CADVISOR_URL/metrics" target="_blank">📈 Raw Metrics</a><br>
            <a href="$CADVISOR_URL/api/v1.3/containers/" target="_blank">🔌 API Endpoint</a>
        </div>
    </div>
</body>
</html>
EOF

    log_info "HTML report generated: $report_file"
}

# Função principal
main() {
    log_info "Starting cAdvisor metrics analysis..."
    
    # Verificar se cAdvisor está acessível
    if ! curl -s -f "$CADVISOR_URL/healthz" > /dev/null; then
        log_error "cAdvisor is not accessible at $CADVISOR_URL"
        exit 1
    fi
    
    collect_basic_metrics
    analyze_performance
    detect_anomalies
    generate_report
    
    log_info "✅ Analysis completed!"
    log_info "📁 Results saved in: $OUTPUT_DIR"
    
    # Mostrar resumo
    echo
    echo "📊 Analysis Summary:"
    echo "   - Basic metrics: $OUTPUT_DIR/basic_metrics_$TIMESTAMP.txt"
    echo "   - Performance data: $OUTPUT_DIR/performance_analysis_$TIMESTAMP.json"
    echo "   - Anomalies report: $OUTPUT_DIR/anomalies_$TIMESTAMP.txt"
    echo "   - HTML report: $OUTPUT_DIR/cadvisor_report_$TIMESTAMP.html"
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## 🎯 Otimização de Performance

### Configurações por Cenário

```yaml
# performance-configs.yaml - Configurações otimizadas
configurations:
  # Desenvolvimento - Máxima visibilidade
  development:
    housekeeping_interval: "10s"
    max_housekeeping_interval: "15s"
    event_storage_event_limit: "100"
    event_storage_age_limit: "1h"
    store_container_labels: true
    disabled_metrics: []
    enabled_metrics: ["cpu", "memory", "network", "filesystem", "disk"]
    
  # Produção - Balanceado
  production:
    housekeeping_interval: "30s"
    max_housekeeping_interval: "35s"
    event_storage_event_limit: "0"
    event_storage_age_limit: "0"
    store_container_labels: false
    disabled_metrics: ["percpu", "sched", "tcp", "udp"]
    enabled_metrics: ["cpu", "memory", "network", "filesystem"]
    
  # Alto Volume - Mínimo overhead
  high_volume:
    housekeeping_interval: "60s"
    max_housekeeping_interval: "65s"
    event_storage_event_limit: "0"
    event_storage_age_limit: "0"
    store_container_labels: false
    disabled_metrics: ["percpu", "sched", "tcp", "udp", "disk", "network"]
    enabled_metrics: ["cpu", "memory"]
    max_procs: 1
    
  # Monitoramento Crítico - Apenas essencial
  critical_only:
    housekeeping_interval: "120s"
    max_housekeeping_interval: "125s"
    event_storage_event_limit: "0"
    event_storage_age_limit: "0"
    store_container_labels: false
    disabled_metrics: ["percpu", "sched", "tcp", "udp", "disk", "network", "filesystem"]
    enabled_metrics: ["cpu", "memory"]
    max_procs: 1
    docker_only: true
```

### Benchmark de Performance

```bash
#!/bin/bash
# benchmark-cadvisor.sh - Benchmark de diferentes configurações

set -e

# Configurações de teste
TEST_DURATION=300  # 5 minutos
CONTAINERS_COUNT=10
BENCHMARK_DIR="./benchmark-results"

mkdir -p $BENCHMARK_DIR

# Função para criar containers de teste
create_test_containers() {
    local count=$1
    echo "🏗️ Creating $count test containers..."
    
    for i in $(seq 1 $count); do
        docker run -d \
            --name "test-container-$i" \
            --label "benchmark=true" \
            --memory="100m" \
            --cpus="0.1" \
            alpine sh -c "while true; do dd if=/dev/zero of=/tmp/test bs=1M count=10 2>/dev/null; sleep 5; done"
    done
    
    echo "✅ Test containers created"
}

# Função para executar benchmark
run_benchmark() {
    local config_name=$1
    local config_args=$2
    
    echo "🚀 Running benchmark for configuration: $config_name"
    
    # Parar cAdvisor existente
    docker stop cadvisor 2>/dev/null || true
    docker rm cadvisor 2>/dev/null || true
    
    # Iniciar cAdvisor com configuração específica
    docker run -d \
        --volume=/:/rootfs:ro \
        --volume=/var/run:/var/run:ro \
        --volume=/sys:/sys:ro \
        --volume=/var/lib/docker/:/var/lib/docker:ro \
        --volume=/dev/disk/:/dev/disk:ro \
        --publish=8080:8080 \
        --name=cadvisor \
        --privileged \
        --device=/dev/kmsg \
        gcr.io/cadvisor/cadvisor:latest \
        $config_args
    
    # Aguardar inicialização
    sleep 30
    
    # Coletar métricas de performance
    local start_time=$(date +%s)
    local result_file="$BENCHMARK_DIR/benchmark_${config_name}_$(date +%Y%m%d_%H%M%S).json"
    
    {
        echo "{"
        echo "  \"configuration\": \"$config_name\","
        echo "  \"start_time\": \"$(date -Iseconds)\","
        echo "  \"test_duration\": $TEST_DURATION,"
        echo "  \"containers_count\": $CONTAINERS_COUNT,"
        
        # Métricas do cAdvisor container
        echo "  \"cadvisor_metrics\": {"
        
        # CPU usage
        local cpu_usage=$(docker stats cadvisor --no-stream --format "{{.CPUPerc}}" | sed 's/%//')
        echo "    \"cpu_usage_percent\": $cpu_usage,"
        
        # Memory usage
        local mem_usage=$(docker stats cadvisor --no-stream --format "{{.MemUsage}}" | cut -d'/' -f1 | sed 's/MiB//')
        echo "    \"memory_usage_mb\": $mem_usage,"
        
        # Response time
        local response_time=$(curl -w "%{time_total}" -s -o /dev/null "http://localhost:8080/metrics")
        echo "    \"metrics_response_time_seconds\": $response_time,"
        
        # Metrics count
        local metrics_count=$(curl -s "http://localhost:8080/metrics" | wc -l)
        echo "    \"total_metrics_lines\": $metrics_count"
        
        echo "  },"
        
        # Teste de carga
        echo "  \"load_test\": {"
        
        local load_start=$(date +%s)
        for i in {1..10}; do
            curl -s "http://localhost:8080/metrics" > /dev/null
        done
        local load_end=$(date +%s)
        local load_duration=$((load_end - load_start))
        
        echo "    \"requests_count\": 10,"
        echo "    \"total_time_seconds\": $load_duration,"
        echo "    \"avg_response_time\": $(echo "scale=3; $load_duration / 10" | bc)"
        
        echo "  },"
        echo "  \"end_time\": \"$(date -Iseconds)\""
        echo "}"
        
    } > $result_file
    
    echo "📊 Benchmark results saved to: $result_file"
}

# Função para executar todos os benchmarks
run_all_benchmarks() {
    echo "🎯 Starting comprehensive cAdvisor benchmark..."
    
    # Configurações para testar
    declare -A configs
    configs["development"]="--housekeeping_interval=10s --store_container_labels=true"
    configs["production"]="--housekeeping_interval=30s --disable_metrics=percpu,sched,tcp,udp --docker_only=true"
    configs["high_volume"]="--housekeeping_interval=60s --disable_metrics=percpu,sched,tcp,udp,disk,network --docker_only=true --max_procs=1"
    configs["minimal"]="--housekeeping_interval=120s --disable_metrics=percpu,sched,tcp,udp,disk,network,filesystem --docker_only=true --max_procs=1"
    
    # Executar benchmark para cada configuração
    for config_name in "${!configs[@]}"; do
        run_benchmark "$config_name" "${configs[$config_name]}"
        sleep 10  # Pausa entre testes
    done
}

# Função para gerar relatório comparativo
generate_comparison_report() {
    echo "📈 Generating comparison report..."
    
    local report_file="$BENCHMARK_DIR/comparison_report_$(date +%Y%m%d_%H%M%S).html"
    
    cat > $report_file << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>cAdvisor Performance Benchmark</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #f2f2f2; }
        .best { background-color: #d4edda; }
        .worst { background-color: #f8d7da; }
    </style>
</head>
<body>
    <h1>📊 cAdvisor Performance Benchmark Report</h1>
    <p><strong>Generated:</strong> $(date)</p>
    
    <h2>🎯 Test Configuration</h2>
    <ul>
        <li><strong>Test Duration:</strong> $TEST_DURATION seconds</li>
        <li><strong>Test Containers:</strong> $CONTAINERS_COUNT</li>
        <li><strong>Benchmark Files:</strong> $(ls $BENCHMARK_DIR/benchmark_*.json | wc -l)</li>
    </ul>
    
    <h2>📈 Performance Comparison</h2>
    <table>
        <tr>
            <th>Configuration</th>
            <th>CPU Usage (%)</th>
            <th>Memory Usage (MB)</th>
            <th>Response Time (s)</th>
            <th>Metrics Count</th>
            <th>Avg Load Time (s)</th>
        </tr>
EOF

    # Processar resultados de benchmark
    for file in $BENCHMARK_DIR/benchmark_*.json; do
        if [ -f "$file" ]; then
            local config=$(jq -r '.configuration' "$file")
            local cpu=$(jq -r '.cadvisor_metrics.cpu_usage_percent' "$file")
            local memory=$(jq -r '.cadvisor_metrics.memory_usage_mb' "$file")
            local response=$(jq -r '.cadvisor_metrics.metrics_response_time_seconds' "$file")
            local metrics=$(jq -r '.cadvisor_metrics.total_metrics_lines' "$file")
            local load_time=$(jq -r '.load_test.avg_response_time' "$file")
            
            echo "        <tr>" >> $report_file
            echo "            <td>$config</td>" >> $report_file
            echo "            <td>$cpu</td>" >> $report_file
            echo "            <td>$memory</td>" >> $report_file
            echo "            <td>$response</td>" >> $report_file
            echo "            <td>$metrics</td>" >> $report_file
            echo "            <td>$load_time</td>" >> $report_file
            echo "        </tr>" >> $report_file
        fi
    done

    cat >> $report_file << 'EOF'
    </table>
    
    <h2>💡 Recommendations</h2>
    <ul>
        <li><strong>Development:</strong> Use development config for maximum visibility</li>
        <li><strong>Production:</strong> Use production config for balanced performance</li>
        <li><strong>High Volume:</strong> Use high_volume config for minimal overhead</li>
        <li><strong>Critical Systems:</strong> Use minimal config for essential metrics only</li>
    </ul>
</body>
</html>
EOF

    echo "📋 Comparison report generated: $report_file"
}

# Função de limpeza
cleanup() {
    echo "🧹 Cleaning up test environment..."
    
    # Parar e remover containers de teste
    for i in $(seq 1 $CONTAINERS_COUNT); do
        docker stop "test-container-$i" 2>/dev/null || true
        docker rm "test-container-$i" 2>/dev/null || true
    done
    
    # Parar cAdvisor
    docker stop cadvisor 2>/dev/null || true
    docker rm cadvisor 2>/dev/null || true
    
    echo "✅ Cleanup completed"
}

# Função principal
main() {
    echo "🚀 Starting cAdvisor performance benchmark suite..."
    
    # Trap para limpeza em caso de interrupção
    trap cleanup EXIT
    
    create_test_containers $CONTAINERS_COUNT
    run_all_benchmarks
    generate_comparison_report
    
    echo "✅ Benchmark suite completed!"
    echo "📁 Results available in: $BENCHMARK_DIR"
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## 🚀 Exercício Prático

### Objetivo
Configurar coleta otimizada de métricas e realizar análise de performance.

### Parte 1: Configuração de Métricas

1. **Configurar diferentes perfis:**
```bash
# Executar script de configuração
chmod +x configure-cadvisor-metrics.sh
./configure-cadvisor-metrics.sh
```

2. **Deploy com filtros:**
```bash
# Usar configuração com labels
chmod +x setup-container-labels.sh
./setup-container-labels.sh
```

### Parte 2: Análise de Métricas

1. **Executar análise:**
```bash
# Análise automatizada
chmod +x analyze-cadvisor-metrics.sh
./analyze-cadvisor-metrics.sh
```

2. **Verificar resultados:**
```bash
# Visualizar relatórios
ls -la metrics-analysis/
cat metrics-analysis/basic_metrics_*.txt
```

### Parte 3: Benchmark de Performance

1. **Executar benchmark:**
```bash
# Benchmark completo
chmod +x benchmark-cadvisor.sh
./benchmark-cadvisor.sh
```

2. **Analisar resultados:**
```bash
# Visualizar comparação
ls -la benchmark-results/
# Abrir relatório HTML no navegador
```

### Validação
- [ ] Diferentes configurações testadas
- [ ] Métricas coletadas seletivamente
- [ ] Análise de performance executada
- [ ] Benchmark comparativo realizado
- [ ] Relatórios gerados e analisados

## 📚 Resumo do Módulo

### Conceitos Aprendidos
- ✅ **Tipos de Métricas:** CPU, memória, rede, filesystem
- ✅ **Configuração:** Filtros, labels, otimizações
- ✅ **Análise:** Queries PromQL, detecção de anomalias
- ✅ **Performance:** Benchmarks, otimizações
- ✅ **Automação:** Scripts de análise e relatórios

### Próximos Passos
- **[Módulo 04: Integração com Prometheus](04-integracao-prometheus.md)** - Integração completa
- **[Módulo 05: Troubleshooting](05-troubleshooting-performance.md)** - Diagnóstico avançado

---

## Navegação

- [← Módulo 02: Configuração e Deploy](02-configuracao-deploy.md)
- [🏠 Página Principal](README.md)
- [➡️ Próximo: Integração com Prometheus](04-integracao-prometheus.md)

---

**Excelente!** 🎉 Você dominou a coleta e análise de métricas do cAdvisor. Agora você pode otimizar o monitoramento para qualquer cenário!