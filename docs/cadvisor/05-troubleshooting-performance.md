# Módulo 05: Troubleshooting e Performance

> **Diagnóstico avançado e otimização** - Resolução de problemas, performance tuning e monitoramento proativo

## 📋 Objetivos do Módulo

Ao final deste módulo, você será capaz de:
- ✅ Diagnosticar problemas comuns do cAdvisor
- ✅ Otimizar performance e consumo de recursos
- ✅ Implementar monitoramento proativo
- ✅ Resolver gargalos de coleta de métricas
- ✅ Configurar alertas de saúde do sistema

## 🔍 Diagnóstico de Problemas Comuns

### Problemas de Conectividade

#### Script de Diagnóstico Completo

```bash
#!/bin/bash
# cadvisor-diagnostics.sh - Diagnóstico completo do cAdvisor

set -e

# Configurações
CADVISOR_URL="http://localhost:8080"
PROMETHEUS_URL="http://localhost:9090"
TIMEOUT=10
LOG_FILE="/tmp/cadvisor-diagnostics-$(date +%Y%m%d-%H%M%S).log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funções de logging
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}" | tee -a "$LOG_FILE"
}

# Verificar conectividade básica
check_connectivity() {
    log_section "Connectivity Tests"
    
    # Testar cAdvisor
    if curl -s --max-time $TIMEOUT "$CADVISOR_URL/healthz" > /dev/null; then
        log_info "✅ cAdvisor health endpoint is accessible"
    else
        log_error "❌ cAdvisor health endpoint is not accessible"
        return 1
    fi
    
    # Testar métricas
    if curl -s --max-time $TIMEOUT "$CADVISOR_URL/metrics" | head -n 1 | grep -q "#"; then
        log_info "✅ cAdvisor metrics endpoint is working"
    else
        log_error "❌ cAdvisor metrics endpoint is not working"
        return 1
    fi
    
    # Testar API
    if curl -s --max-time $TIMEOUT "$CADVISOR_URL/api/v1.3/containers" | jq . > /dev/null 2>&1; then
        log_info "✅ cAdvisor API is responding with valid JSON"
    else
        log_warn "⚠️ cAdvisor API may have issues or jq is not installed"
    fi
}

# Verificar recursos do sistema
check_system_resources() {
    log_section "System Resources Check"
    
    # CPU
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        log_warn "⚠️ High CPU usage detected: ${cpu_usage}%"
    else
        log_info "✅ CPU usage is normal: ${cpu_usage}%"
    fi
    
    # Memória
    mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    if (( $(echo "$mem_usage > 85" | bc -l) )); then
        log_warn "⚠️ High memory usage detected: ${mem_usage}%"
    else
        log_info "✅ Memory usage is normal: ${mem_usage}%"
    fi
    
    # Disco
    disk_usage=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    if [ "$disk_usage" -gt 85 ]; then
        log_warn "⚠️ High disk usage detected: ${disk_usage}%"
    else
        log_info "✅ Disk usage is normal: ${disk_usage}%"
    fi
    
    # Load average
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | cut -d',' -f1)
    cpu_cores=$(nproc)
    if (( $(echo "$load_avg > $cpu_cores" | bc -l) )); then
        log_warn "⚠️ High load average: $load_avg (cores: $cpu_cores)"
    else
        log_info "✅ Load average is normal: $load_avg (cores: $cpu_cores)"
    fi
}

# Verificar Docker
check_docker_status() {
    log_section "Docker Status Check"
    
    # Docker daemon
    if systemctl is-active --quiet docker; then
        log_info "✅ Docker daemon is running"
    else
        log_error "❌ Docker daemon is not running"
        return 1
    fi
    
    # Docker socket
    if [ -S "/var/run/docker.sock" ]; then
        log_info "✅ Docker socket is available"
    else
        log_error "❌ Docker socket is not available"
        return 1
    fi
    
    # Containers em execução
    running_containers=$(docker ps --format "table {{.Names}}\t{{.Status}}" | tail -n +2 | wc -l)
    log_info "📊 Running containers: $running_containers"
    
    # cAdvisor container
    if docker ps --format "{{.Names}}" | grep -q "cadvisor"; then
        log_info "✅ cAdvisor container is running"
        
        # Logs do cAdvisor
        log_info "📋 Recent cAdvisor logs:"
        docker logs --tail 10 cadvisor 2>&1 | sed 's/^/    /' | tee -a "$LOG_FILE"
    else
        log_error "❌ cAdvisor container is not running"
        return 1
    fi
}

# Verificar métricas específicas
check_metrics_quality() {
    log_section "Metrics Quality Check"
    
    # Número total de métricas
    total_metrics=$(curl -s "$CADVISOR_URL/metrics" | grep -c "^[a-zA-Z]" || echo "0")
    log_info "📊 Total metrics exposed: $total_metrics"
    
    if [ "$total_metrics" -lt 100 ]; then
        log_warn "⚠️ Low number of metrics, possible collection issues"
    fi
    
    # Métricas essenciais
    essential_metrics=(
        "container_cpu_usage_seconds_total"
        "container_memory_working_set_bytes"
        "container_network_receive_bytes_total"
        "container_fs_usage_bytes"
    )
    
    for metric in "${essential_metrics[@]}"; do
        if curl -s "$CADVISOR_URL/metrics" | grep -q "^$metric"; then
            log_info "✅ Essential metric present: $metric"
        else
            log_error "❌ Missing essential metric: $metric"
        fi
    done
    
    # Verificar se há containers sendo monitorados
    containers_monitored=$(curl -s "$CADVISOR_URL/metrics" | grep 'container_last_seen{' | wc -l)
    log_info "📊 Containers being monitored: $containers_monitored"
    
    if [ "$containers_monitored" -eq 0 ]; then
        log_warn "⚠️ No containers are being monitored"
    fi
}

# Verificar integração com Prometheus
check_prometheus_integration() {
    log_section "Prometheus Integration Check"
    
    # Verificar se Prometheus está acessível
    if curl -s --max-time $TIMEOUT "$PROMETHEUS_URL/api/v1/targets" > /dev/null; then
        log_info "✅ Prometheus is accessible"
        
        # Verificar target do cAdvisor
        cadvisor_target_status=$(curl -s "$PROMETHEUS_URL/api/v1/targets" | \
            jq -r '.data.activeTargets[] | select(.labels.job=="cadvisor") | .health' 2>/dev/null || echo "unknown")
        
        if [ "$cadvisor_target_status" = "up" ]; then
            log_info "✅ cAdvisor target is UP in Prometheus"
        else
            log_error "❌ cAdvisor target status: $cadvisor_target_status"
        fi
        
        # Verificar última coleta
        last_scrape=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=up{job='cadvisor'}" | \
            jq -r '.data.result[0].value[0]' 2>/dev/null || echo "0")
        
        if [ "$last_scrape" != "0" ]; then
            scrape_age=$(($(date +%s) - ${last_scrape%.*}))
            log_info "📊 Last scrape: ${scrape_age}s ago"
            
            if [ "$scrape_age" -gt 120 ]; then
                log_warn "⚠️ Last scrape is too old (>2min)"
            fi
        fi
    else
        log_warn "⚠️ Prometheus is not accessible, skipping integration checks"
    fi
}

# Verificar performance
check_performance() {
    log_section "Performance Analysis"
    
    # Tempo de resposta das métricas
    start_time=$(date +%s.%N)
    curl -s "$CADVISOR_URL/metrics" > /dev/null
    end_time=$(date +%s.%N)
    response_time=$(echo "$end_time - $start_time" | bc)
    
    log_info "📊 Metrics endpoint response time: ${response_time}s"
    
    if (( $(echo "$response_time > 5" | bc -l) )); then
        log_warn "⚠️ Slow metrics response time (>5s)"
    fi
    
    # Uso de recursos do cAdvisor
    if docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep -q "cadvisor"; then
        cadvisor_stats=$(docker stats --no-stream --format "{{.Container}},{{.CPUPerc}},{{.MemUsage}}" | grep "cadvisor")
        IFS=',' read -r container cpu_perc mem_usage <<< "$cadvisor_stats"
        
        log_info "📊 cAdvisor resource usage:"
        log_info "   CPU: $cpu_perc"
        log_info "   Memory: $mem_usage"
        
        # Alertar se uso for muito alto
        cpu_num=$(echo "$cpu_perc" | sed 's/%//')
        if (( $(echo "$cpu_num > 50" | bc -l) )); then
            log_warn "⚠️ cAdvisor CPU usage is high: $cpu_perc"
        fi
    fi
}

# Gerar relatório de saúde
generate_health_report() {
    log_section "Health Report Summary"
    
    # Contar problemas
    errors=$(grep -c "\[ERROR\]" "$LOG_FILE" || echo "0")
    warnings=$(grep -c "\[WARN\]" "$LOG_FILE" || echo "0")
    
    log_info "📊 Diagnostic Summary:"
    log_info "   Errors: $errors"
    log_info "   Warnings: $warnings"
    
    if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
        log_info "✅ System is healthy!"
        return 0
    elif [ "$errors" -eq 0 ]; then
        log_warn "⚠️ System has minor issues"
        return 1
    else
        log_error "❌ System has critical issues"
        return 2
    fi
}

# Função principal
main() {
    echo "🔍 Starting cAdvisor diagnostics..." | tee "$LOG_FILE"
    echo "📝 Log file: $LOG_FILE" | tee -a "$LOG_FILE"
    echo
    
    # Executar todas as verificações
    check_connectivity || true
    check_system_resources || true
    check_docker_status || true
    check_metrics_quality || true
    check_prometheus_integration || true
    check_performance || true
    
    # Gerar relatório final
    generate_health_report
    exit_code=$?
    
    echo
    echo "📝 Full diagnostic log saved to: $LOG_FILE"
    
    exit $exit_code
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### Problemas Específicos e Soluções

#### 1. Alto Consumo de CPU

```yaml
# docker-compose.cadvisor-optimized.yml
version: '3.8'

services:
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.47.0
    container_name: cadvisor-optimized
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
    # Configurações otimizadas para reduzir CPU
    command:
      # Intervalo de housekeeping mais longo
      - '--housekeeping_interval=60s'
      - '--max_housekeeping_interval=120s'
      
      # Desabilitar métricas desnecessárias
      - '--disable_metrics=percpu,sched,tcp,udp,disk,diskIO,accelerator,hugetlb,memory_numa,cpuset,advtcp,cpu_topology,resctrl'
      
      # Limitar armazenamento de eventos
      - '--event_storage_event_limit=default=0'
      - '--event_storage_age_limit=default=0'
      
      # Apenas containers Docker
      - '--docker_only=true'
      
      # Reduzir labels armazenados
      - '--store_container_labels=false'
      - '--whitelisted_container_labels=prometheus.scrape,service.name'
      
      # Configurações de performance
      - '--max_procs=2'
      - '--logtostderr=true'
      - '--v=1'
    
    # Limites de recursos
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
        reservations:
          cpus: '0.1'
          memory: 128M
```

#### 2. Problemas de Memória

```bash
#!/bin/bash
# memory-optimization.sh - Otimização de memória

# Configurar cAdvisor com limites de memória
setup_memory_limits() {
    echo "🔧 Configuring memory optimization..."
    
    # Parar cAdvisor existente
    docker stop cadvisor 2>/dev/null || true
    docker rm cadvisor 2>/dev/null || true
    
    # Iniciar com configurações otimizadas
    docker run -d \
        --name=cadvisor \
        --restart=unless-stopped \
        --memory=256m \
        --memory-swap=256m \
        --oom-kill-disable=false \
        --publish=8080:8080 \
        --volume=/:/rootfs:ro \
        --volume=/var/run:/var/run:ro \
        --volume=/sys:/sys:ro \
        --volume=/var/lib/docker/:/var/lib/docker:ro \
        --volume=/dev/disk/:/dev/disk:ro \
        --privileged \
        --device=/dev/kmsg \
        gcr.io/cadvisor/cadvisor:v0.47.0 \
        --housekeeping_interval=60s \
        --max_housekeeping_interval=120s \
        --disable_metrics=percpu,sched,tcp,udp,disk,diskIO \
        --event_storage_event_limit=default=0 \
        --event_storage_age_limit=default=0 \
        --docker_only=true \
        --store_container_labels=false
    
    echo "✅ cAdvisor started with memory optimization"
}

# Monitorar uso de memória
monitor_memory_usage() {
    echo "📊 Monitoring cAdvisor memory usage..."
    
    for i in {1..10}; do
        mem_usage=$(docker stats --no-stream --format "{{.MemUsage}}" cadvisor)
        echo "Memory usage ($i/10): $mem_usage"
        sleep 30
    done
}

# Verificar vazamentos de memória
check_memory_leaks() {
    echo "🔍 Checking for memory leaks..."
    
    # Coletar estatísticas por 5 minutos
    for i in {1..10}; do
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        mem_bytes=$(docker stats --no-stream --format "{{.MemUsage}}" cadvisor | cut -d'/' -f1 | sed 's/[^0-9.]//g')
        echo "$timestamp,$mem_bytes" >> /tmp/cadvisor-memory-usage.csv
        sleep 30
    done
    
    echo "📈 Memory usage data saved to /tmp/cadvisor-memory-usage.csv"
    
    # Análise simples de tendência
    first_value=$(head -n1 /tmp/cadvisor-memory-usage.csv | cut -d',' -f2)
    last_value=$(tail -n1 /tmp/cadvisor-memory-usage.csv | cut -d',' -f2)
    
    if (( $(echo "$last_value > $first_value * 1.2" | bc -l) )); then
        echo "⚠️ Possible memory leak detected (20% increase)"
    else
        echo "✅ No significant memory increase detected"
    fi
}

setup_memory_limits
monitor_memory_usage
check_memory_leaks
```

#### 3. Problemas de Conectividade

```bash
#!/bin/bash
# network-troubleshooting.sh - Diagnóstico de rede

# Testar conectividade de rede
test_network_connectivity() {
    echo "🌐 Testing network connectivity..."
    
    # Testar portas
    ports=("8080" "9090" "3000")
    
    for port in "${ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            echo "✅ Port $port is listening"
        else
            echo "❌ Port $port is not listening"
        fi
        
        # Testar conectividade externa
        if curl -s --max-time 5 "http://localhost:$port" > /dev/null; then
            echo "✅ Port $port is accessible via HTTP"
        else
            echo "❌ Port $port is not accessible via HTTP"
        fi
    done
}

# Verificar configuração de rede Docker
check_docker_network() {
    echo "🐳 Checking Docker network configuration..."
    
    # Listar redes
    echo "📋 Docker networks:"
    docker network ls
    
    # Verificar rede do cAdvisor
    cadvisor_network=$(docker inspect cadvisor --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' 2>/dev/null || echo "none")
    echo "📊 cAdvisor network: $cadvisor_network"
    
    # Verificar IP do cAdvisor
    cadvisor_ip=$(docker inspect cadvisor --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null || echo "none")
    echo "📊 cAdvisor IP: $cadvisor_ip"
    
    # Testar conectividade interna
    if [ "$cadvisor_ip" != "none" ]; then
        if docker run --rm --network "$cadvisor_network" alpine:latest wget -qO- "http://$cadvisor_ip:8080/healthz" > /dev/null 2>&1; then
            echo "✅ Internal network connectivity is working"
        else
            echo "❌ Internal network connectivity failed"
        fi
    fi
}

# Verificar firewall e iptables
check_firewall() {
    echo "🔥 Checking firewall configuration..."
    
    # Verificar iptables
    if command -v iptables > /dev/null; then
        echo "📋 Relevant iptables rules:"
        iptables -L -n | grep -E "(8080|9090|3000)" || echo "No specific rules found"
    fi
    
    # Verificar UFW (Ubuntu)
    if command -v ufw > /dev/null; then
        echo "📋 UFW status:"
        ufw status
    fi
    
    # Verificar firewalld (CentOS/RHEL)
    if command -v firewall-cmd > /dev/null; then
        echo "📋 Firewalld status:"
        firewall-cmd --list-all
    fi
}

test_network_connectivity
check_docker_network
check_firewall
```

## ⚡ Otimização de Performance

### Configurações Otimizadas por Cenário

#### Desenvolvimento Local

```yaml
# cadvisor-dev.yml - Configuração para desenvolvimento
version: '3.8'

services:
  cadvisor-dev:
    image: gcr.io/cadvisor/cadvisor:v0.47.0
    container_name: cadvisor-dev
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    privileged: true
    command:
      # Configuração relaxada para desenvolvimento
      - '--housekeeping_interval=30s'
      - '--max_housekeeping_interval=60s'
      - '--disable_metrics=tcp,udp'
      - '--docker_only=true'
      - '--store_container_labels=true'  # Manter labels para debug
      - '--logtostderr=true'
      - '--v=2'  # Mais verbose para debug
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
```

#### Produção de Alto Volume

```yaml
# cadvisor-production.yml - Configuração para produção
version: '3.8'

services:
  cadvisor-prod:
    image: gcr.io/cadvisor/cadvisor:v0.47.0
    container_name: cadvisor-prod
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    privileged: true
    command:
      # Configuração otimizada para produção
      - '--housekeeping_interval=120s'  # Menos frequente
      - '--max_housekeeping_interval=300s'
      
      # Desabilitar métricas não essenciais
      - '--disable_metrics=percpu,sched,tcp,udp,disk,diskIO,accelerator,hugetlb,memory_numa,cpuset,advtcp,cpu_topology,resctrl,perf_event'
      
      # Limitar eventos
      - '--event_storage_event_limit=default=0'
      - '--event_storage_age_limit=default=0'
      
      # Apenas Docker
      - '--docker_only=true'
      
      # Não armazenar labels
      - '--store_container_labels=false'
      
      # Logging mínimo
      - '--logtostderr=true'
      - '--v=0'
      
      # Limitar processos
      - '--max_procs=1'
    
    deploy:
      resources:
        limits:
          cpus: '0.3'
          memory: 128M
        reservations:
          cpus: '0.1'
          memory: 64M
    
    # Configurações de saúde
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### Script de Benchmark

```bash
#!/bin/bash
# cadvisor-benchmark.sh - Benchmark de performance

set -e

# Configurações
TEST_DURATION=300  # 5 minutos
CONFIGS=("dev" "prod" "minimal")
RESULTS_DIR="./benchmark-results-$(date +%Y%m%d-%H%M%S)"

# Criar diretório de resultados
mkdir -p "$RESULTS_DIR"

# Função para executar benchmark
run_benchmark() {
    local config=$1
    local config_file="cadvisor-${config}.yml"
    
    echo "🚀 Running benchmark for configuration: $config"
    
    # Parar cAdvisor existente
    docker-compose -f "$config_file" down 2>/dev/null || true
    
    # Iniciar nova configuração
    docker-compose -f "$config_file" up -d
    
    # Aguardar inicialização
    echo "⏳ Waiting for cAdvisor to start..."
    sleep 30
    
    # Verificar se está funcionando
    if ! curl -s http://localhost:8080/healthz > /dev/null; then
        echo "❌ cAdvisor failed to start for config: $config"
        return 1
    fi
    
    echo "📊 Starting benchmark for $TEST_DURATION seconds..."
    
    # Arquivo de resultados
    result_file="$RESULTS_DIR/benchmark-${config}.csv"
    echo "timestamp,cpu_percent,memory_mb,response_time_ms,metrics_count" > "$result_file"
    
    # Executar benchmark
    start_time=$(date +%s)
    end_time=$((start_time + TEST_DURATION))
    
    while [ $(date +%s) -lt $end_time ]; do
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # CPU e memória do cAdvisor
        stats=$(docker stats --no-stream --format "{{.CPUPerc}},{{.MemUsage}}" cadvisor-${config} 2>/dev/null || echo "0%,0MiB / 0MiB")
        cpu_percent=$(echo "$stats" | cut -d',' -f1 | sed 's/%//')
        memory_usage=$(echo "$stats" | cut -d',' -f2 | cut -d'/' -f1 | sed 's/[^0-9.]//g')
        
        # Tempo de resposta das métricas
        start_request=$(date +%s.%N)
        metrics_response=$(curl -s http://localhost:8080/metrics)
        end_request=$(date +%s.%N)
        response_time=$(echo "($end_request - $start_request) * 1000" | bc)
        
        # Número de métricas
        metrics_count=$(echo "$metrics_response" | grep -c "^[a-zA-Z]" || echo "0")
        
        # Salvar dados
        echo "$timestamp,$cpu_percent,$memory_usage,$response_time,$metrics_count" >> "$result_file"
        
        sleep 10
    done
    
    echo "✅ Benchmark completed for config: $config"
    
    # Parar configuração
    docker-compose -f "$config_file" down
    
    sleep 10
}

# Criar configurações de teste
create_test_configs() {
    echo "📝 Creating test configurations..."
    
    # Configuração de desenvolvimento
    cat > cadvisor-dev.yml << 'EOF'
version: '3.8'
services:
  cadvisor-dev:
    image: gcr.io/cadvisor/cadvisor:v0.47.0
    container_name: cadvisor-dev
    ports: ["8080:8080"]
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    privileged: true
    command:
      - '--housekeeping_interval=30s'
      - '--docker_only=true'
      - '--store_container_labels=true'
EOF

    # Configuração de produção
    cat > cadvisor-prod.yml << 'EOF'
version: '3.8'
services:
  cadvisor-prod:
    image: gcr.io/cadvisor/cadvisor:v0.47.0
    container_name: cadvisor-prod
    ports: ["8080:8080"]
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    privileged: true
    command:
      - '--housekeeping_interval=120s'
      - '--disable_metrics=percpu,sched,tcp,udp,disk'
      - '--docker_only=true'
      - '--store_container_labels=false'
      - '--max_procs=1'
    deploy:
      resources:
        limits:
          cpus: '0.3'
          memory: 128M
EOF

    # Configuração mínima
    cat > cadvisor-minimal.yml << 'EOF'
version: '3.8'
services:
  cadvisor-minimal:
    image: gcr.io/cadvisor/cadvisor:v0.47.0
    container_name: cadvisor-minimal
    ports: ["8080:8080"]
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    privileged: true
    command:
      - '--housekeeping_interval=300s'
      - '--disable_metrics=percpu,sched,tcp,udp,disk,diskIO,accelerator,hugetlb,memory_numa,cpuset,advtcp,cpu_topology,resctrl,perf_event'
      - '--event_storage_event_limit=default=0'
      - '--docker_only=true'
      - '--store_container_labels=false'
      - '--max_procs=1'
    deploy:
      resources:
        limits:
          cpus: '0.1'
          memory: 64M
EOF
}

# Gerar relatório de análise
generate_analysis_report() {
    echo "📊 Generating analysis report..."
    
    report_file="$RESULTS_DIR/benchmark-analysis.html"
    
    cat > "$report_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>cAdvisor Benchmark Analysis</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .chart-container { width: 800px; height: 400px; margin: 20px 0; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .metric { background-color: #e8f5e8; }
    </style>
</head>
<body>
    <h1>cAdvisor Performance Benchmark Analysis</h1>
    
    <h2>Summary</h2>
    <table>
        <tr><th>Configuration</th><th>Avg CPU %</th><th>Avg Memory MB</th><th>Avg Response Time ms</th><th>Metrics Count</th></tr>
EOF

    # Processar cada configuração
    for config in "${CONFIGS[@]}"; do
        if [ -f "$RESULTS_DIR/benchmark-${config}.csv" ]; then
            # Calcular médias
            avg_cpu=$(tail -n +2 "$RESULTS_DIR/benchmark-${config}.csv" | cut -d',' -f2 | awk '{sum+=$1} END {printf "%.2f", sum/NR}')
            avg_memory=$(tail -n +2 "$RESULTS_DIR/benchmark-${config}.csv" | cut -d',' -f3 | awk '{sum+=$1} END {printf "%.2f", sum/NR}')
            avg_response=$(tail -n +2 "$RESULTS_DIR/benchmark-${config}.csv" | cut -d',' -f4 | awk '{sum+=$1} END {printf "%.2f", sum/NR}')
            avg_metrics=$(tail -n +2 "$RESULTS_DIR/benchmark-${config}.csv" | cut -d',' -f5 | awk '{sum+=$1} END {printf "%.0f", sum/NR}')
            
            echo "        <tr><td>$config</td><td>$avg_cpu</td><td>$avg_memory</td><td>$avg_response</td><td>$avg_metrics</td></tr>" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << 'EOF'
    </table>
    
    <h2>Recommendations</h2>
    <div class="metric">
        <h3>Configuration Guidelines:</h3>
        <ul>
            <li><strong>Development:</strong> Use 'dev' config for full metrics and debugging</li>
            <li><strong>Production (Low Volume):</strong> Use 'prod' config for balanced performance</li>
            <li><strong>Production (High Volume):</strong> Use 'minimal' config for maximum efficiency</li>
        </ul>
        
        <h3>Performance Thresholds:</h3>
        <ul>
            <li><strong>CPU Usage:</strong> Should be < 5% for production workloads</li>
            <li><strong>Memory Usage:</strong> Should be < 200MB for most scenarios</li>
            <li><strong>Response Time:</strong> Should be < 2000ms for metrics endpoint</li>
        </ul>
    </div>
    
    <p><em>Report generated on: $(date)</em></p>
</body>
</html>
EOF

    echo "📊 Analysis report saved to: $report_file"
}

# Função principal
main() {
    echo "🚀 Starting cAdvisor performance benchmark..."
    echo "📊 Test duration: ${TEST_DURATION}s per configuration"
    echo "📁 Results will be saved to: $RESULTS_DIR"
    echo
    
    create_test_configs
    
    # Executar benchmark para cada configuração
    for config in "${CONFIGS[@]}"; do
        run_benchmark "$config" || echo "⚠️ Benchmark failed for $config"
    done
    
    generate_analysis_report
    
    echo
    echo "✅ Benchmark completed!"
    echo "📊 Results available in: $RESULTS_DIR"
    echo "📈 Open $RESULTS_DIR/benchmark-analysis.html for detailed analysis"
    
    # Limpeza
    rm -f cadvisor-*.yml
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## 📊 Monitoramento Proativo

### Alertas de Saúde do cAdvisor

```yaml
# cadvisor-health-alerts.yml - Alertas para saúde do cAdvisor
groups:
- name: cadvisor-health.rules
  rules:
  # cAdvisor está down
  - alert: CAdvisorDown
    expr: up{job="cadvisor"} == 0
    for: 1m
    labels:
      severity: critical
      component: monitoring
    annotations:
      summary: "cAdvisor is down"
      description: |
        cAdvisor has been down for more than 1 minute.
        
        Instance: {{ $labels.instance }}
        Job: {{ $labels.job }}
        
        Immediate action required:
        1. Check cAdvisor container status
        2. Verify Docker daemon is running
        3. Check system resources

  # Alto uso de CPU pelo cAdvisor
  - alert: CAdvisorHighCpuUsage
    expr: |
      (
        rate(container_cpu_usage_seconds_total{name="cadvisor"}[5m]) * 100
      ) > 10
    for: 5m
    labels:
      severity: warning
      component: monitoring
    annotations:
      summary: "cAdvisor high CPU usage"
      description: |
        cAdvisor is using {{ $value | humanizePercentage }} CPU.
        
        Current usage: {{ $value | humanizePercentage }}
        Instance: {{ $labels.instance }}
        
        Consider:
        1. Increasing housekeeping interval
        2. Disabling unnecessary metrics
        3. Checking for system load

  # Alto uso de memória pelo cAdvisor
  - alert: CAdvisorHighMemoryUsage
    expr: |
      (
        container_memory_working_set_bytes{name="cadvisor"} / 1024 / 1024
      ) > 500
    for: 3m
    labels:
      severity: warning
      component: monitoring
    annotations:
      summary: "cAdvisor high memory usage"
      description: |
        cAdvisor is using {{ $value | humanize }}MB of memory.
        
        Current usage: {{ $value | humanize }}MB
        Instance: {{ $labels.instance }}
        
        Actions:
        1. Check for memory leaks
        2. Restart cAdvisor if necessary
        3. Review configuration

  # Tempo de resposta lento
  - alert: CAdvisorSlowResponse
    expr: |
      histogram_quantile(0.95, 
        rate(prometheus_http_request_duration_seconds_bucket{
          job="cadvisor",
          handler="/metrics"
        }[5m])
      ) > 5
    for: 2m
    labels:
      severity: warning
      component: monitoring
    annotations:
      summary: "cAdvisor slow response time"
      description: |
        cAdvisor metrics endpoint is responding slowly.
        
        95th percentile response time: {{ $value | humanizeDuration }}
        Instance: {{ $labels.instance }}
        
        Investigation needed:
        1. Check system load
        2. Review cAdvisor configuration
        3. Monitor container count

  # Muitos containers sendo monitorados
  - alert: CAdvisorTooManyContainers
    expr: |
      count by (instance) (
        container_last_seen{name!=""}
      ) > 100
    for: 5m
    labels:
      severity: info
      component: monitoring
    annotations:
      summary: "cAdvisor monitoring many containers"
      description: |
        cAdvisor is monitoring {{ $value }} containers.
        
        Container count: {{ $value }}
        Instance: {{ $labels.instance }}
        
        Consider:
        1. Filtering unnecessary containers
        2. Increasing resource limits
        3. Optimizing configuration

  # Falha na coleta de métricas
  - alert: CAdvisorMetricsCollectionFailed
    expr: |
      increase(prometheus_tsdb_symbol_table_size_bytes[5m]) == 0
      and
      up{job="cadvisor"} == 1
    for: 2m
    labels:
      severity: warning
      component: monitoring
    annotations:
      summary: "cAdvisor metrics collection may be failing"
      description: |
        cAdvisor appears to be up but metrics collection may be failing.
        
        Instance: {{ $labels.instance }}
        
        Check:
        1. cAdvisor logs for errors
        2. Docker daemon connectivity
        3. System permissions
```

### Dashboard de Saúde do cAdvisor

```json
{
  "dashboard": {
    "id": null,
    "title": "cAdvisor Health Monitoring",
    "tags": ["cadvisor", "health", "monitoring"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "cAdvisor Status",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job='cadvisor'}",
            "legendFormat": "Status"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "mappings": [
              {"options": {"0": {"text": "DOWN", "color": "red"}}, "type": "value"},
              {"options": {"1": {"text": "UP", "color": "green"}}, "type": "value"}
            ],
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "green", "value": 1}
              ]
            }
          }
        },
        "gridPos": {"h": 4, "w": 6, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "cAdvisor CPU Usage",
        "type": "timeseries",
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name='cadvisor'}[5m]) * 100",
            "legendFormat": "CPU %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 5},
                {"color": "red", "value": 10}
              ]
            }
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 6, "y": 0}
      },
      {
        "id": 3,
        "title": "cAdvisor Memory Usage",
        "type": "timeseries",
        "targets": [
          {
            "expr": "container_memory_working_set_bytes{name='cadvisor'}",
            "legendFormat": "Memory Usage"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "bytes",
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 268435456},
                {"color": "red", "value": 536870912}
              ]
            }
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 18, "y": 0}
      },
      {
        "id": 4,
        "title": "Metrics Response Time",
        "type": "timeseries",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(prometheus_http_request_duration_seconds_bucket{job='cadvisor', handler='/metrics'}[5m]))",
            "legendFormat": "95th percentile"
          },
          {
            "expr": "histogram_quantile(0.50, rate(prometheus_http_request_duration_seconds_bucket{job='cadvisor', handler='/metrics'}[5m]))",
            "legendFormat": "50th percentile"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "s"
          }
        },
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
      },
      {
        "id": 5,
        "title": "Containers Monitored",
        "type": "stat",
        "targets": [
          {
            "expr": "count(container_last_seen{name!=''})",
            "legendFormat": "Containers"
          }
        ],
        "gridPos": {"h": 4, "w": 6, "x": 0, "y": 4}
      },
      {
        "id": 6,
        "title": "Scrape Duration",
        "type": "timeseries",
        "targets": [
          {
            "expr": "prometheus_target_scrape_duration_seconds{job='cadvisor'}",
            "legendFormat": "Scrape Duration"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "s"
          }
        },
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 16}
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
```

## 🚀 Exercício Prático

### Objetivo
Implementar sistema completo de troubleshooting e monitoramento de performance do cAdvisor.

### Parte 1: Diagnóstico Automático

1. **Executar diagnóstico completo:**
```bash
# Fazer download e executar script de diagnóstico
chmod +x cadvisor-diagnostics.sh
./cadvisor-diagnostics.sh
```

2. **Analisar resultados:**
```bash
# Verificar log de diagnóstico
cat /tmp/cadvisor-diagnostics-*.log

# Identificar problemas encontrados
grep "ERROR\|WARN" /tmp/cadvisor-diagnostics-*.log
```

### Parte 2: Otimização de Performance

1. **Executar benchmark:**
```bash
# Executar benchmark de configurações
chmod +x cadvisor-benchmark.sh
./cadvisor-benchmark.sh
```

2. **Analisar resultados:**
```bash
# Abrir relatório de análise
open benchmark-results-*/benchmark-analysis.html
```

### Parte 3: Monitoramento Proativo

1. **Configurar alertas de saúde:**
```bash
# Adicionar regras ao Prometheus
cp cadvisor-health-alerts.yml prometheus/rules/

# Recarregar configuração
curl -X POST http://localhost:9090/-/reload
```

2. **Importar dashboard de saúde:**
   - Acessar Grafana (http://localhost:3000)
   - Importar dashboard de saúde do cAdvisor
   - Configurar alertas no Grafana

### Validação
- [ ] Diagnóstico executado sem erros críticos
- [ ] Benchmark comparativo realizado
- [ ] Configuração otimizada implementada
- [ ] Alertas de saúde configurados
- [ ] Dashboard de monitoramento funcionando
- [ ] Performance melhorada (CPU < 5%, Memória < 200MB)

## 📚 Resumo do Módulo

### Conceitos Aprendidos
- ✅ **Diagnóstico:** Scripts automatizados de troubleshooting
- ✅ **Otimização:** Configurações por cenário de uso
- ✅ **Benchmark:** Comparação de performance
- ✅ **Monitoramento:** Alertas proativos de saúde
- ✅ **Resolução:** Soluções para problemas comuns

### Próximos Passos
- **[Módulo 06: Projeto Final](06-projeto-final.md)** - Implementação completa

---

## Navegação

- [← Módulo 04: Integração Prometheus](04-integracao-prometheus.md)
- [🏠 Página Principal](README.md)
- [➡️ Próximo: Projeto Final](06-projeto-final.md)

---

**Excelente!** 🎉 Você dominou o troubleshooting e otimização do cAdvisor. Agora você pode diagnosticar problemas, otimizar performance e manter um sistema de monitoramento saudável!