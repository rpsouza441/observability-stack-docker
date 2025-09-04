# 🛠️ MÓDULO 08: TROUBLESHOOTING

> **Objetivo:** Dominar técnicas de troubleshooting e resolução de problemas no Prometheus  
> **Duração:** 90 minutos  
> **Nível:** Intermediário/Avançado

---

## 🎯 O QUE VOCÊ VAI APRENDER

Neste módulo você irá:
- ✅ Diagnosticar problemas comuns do Prometheus
- ✅ Usar ferramentas de debugging e validação
- ✅ Resolver problemas de performance
- ✅ Troubleshoot targets e service discovery
- ✅ Analisar logs e métricas internas

---

## 🚨 PROBLEMAS COMUNS

### **🔴 Targets Down**

#### **Sintomas:**
```promql
# Verificar targets down
up == 0

# Contar targets down por job
count by (job) (up == 0)

# Targets que ficaram down recentemente
changes(up[1h]) > 0 and up == 0
```

#### **Diagnóstico:**
```bash
# 1. Verificar status dos targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'

# 2. Verificar conectividade
telnet target-host 9100
nc -zv target-host 9100

# 3. Verificar logs do Prometheus
docker logs prometheus 2>&1 | grep -i error

# 4. Testar endpoint manualmente
curl -v http://target-host:9100/metrics
```

#### **Soluções:**
```yaml
# prometheus.yml - Ajustar timeouts
scrape_configs:
  - job_name: 'node-exporter'
    scrape_interval: 15s
    scrape_timeout: 10s     # Aumentar timeout
    metrics_path: /metrics
    static_configs:
      - targets: ['node-exporter:9100']
    # Adicionar retry
    sample_limit: 0
    target_limit: 0
```

### **📊 Métricas Ausentes**

#### **Sintomas:**
```promql
# Verificar se métrica existe
absent(node_cpu_seconds_total)

# Verificar últimos dados
time() - timestamp(node_cpu_seconds_total) > 300  # Mais de 5 minutos

# Verificar se job está coletando
absent(up{job="node-exporter"})
```

#### **Diagnóstico:**
```bash
# 1. Verificar se exporter está funcionando
curl http://target:9100/metrics | grep node_cpu

# 2. Verificar configuração do job
prometheus --config.file=prometheus.yml --dry-run

# 3. Verificar logs de scraping
docker logs prometheus 2>&1 | grep "scrape"

# 4. Verificar se métrica foi renomeada
curl -s http://localhost:9090/api/v1/label/__name__/values | jq -r '.data[]' | grep cpu
```

#### **Soluções:**
```yaml
# Verificar configuração do job
scrape_configs:
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']  # Verificar host/porta
    metrics_path: '/metrics'              # Verificar path
    scheme: 'http'                        # Verificar protocolo
```

### **🐌 Performance Lenta**

#### **Sintomas:**
```promql
# Queries lentas
prometheus_engine_query_duration_seconds{quantile="0.9"} > 1

# Alto uso de CPU do Prometheus
rate(process_cpu_seconds_total{job="prometheus"}[5m]) * 100 > 80

# Alto uso de memória
process_resident_memory_bytes{job="prometheus"} / 1024 / 1024 / 1024 > 4  # > 4GB

# Muitas séries temporais
prometheus_tsdb_symbol_table_size_bytes > 100 * 1024 * 1024  # > 100MB
```

#### **Diagnóstico:**
```bash
# 1. Verificar métricas internas
curl -s http://localhost:9090/metrics | grep prometheus_

# 2. Verificar número de séries
curl -s "http://localhost:9090/api/v1/query?query=prometheus_tsdb_head_series"

# 3. Verificar queries mais lentas
curl -s "http://localhost:9090/api/v1/query?query=topk(10,prometheus_engine_query_duration_seconds)"

# 4. Verificar uso de recursos
docker stats prometheus
```

#### **Soluções:**
```yaml
# prometheus.yml - Otimizações
global:
  scrape_interval: 30s        # Aumentar intervalo
  evaluation_interval: 30s    # Aumentar avaliação
  
# Limitar métricas por job
scrape_configs:
  - job_name: 'node-exporter'
    sample_limit: 10000       # Limitar amostras
    metric_relabel_configs:
      # Remover métricas desnecessárias
      - source_labels: [__name__]
        regex: 'node_network_.*'
        action: drop
```

---

## 🔧 FERRAMENTAS DE DEBUGGING

### **🔍 Promtool**

```bash
# === VALIDAÇÃO DE CONFIGURAÇÃO ===
# Validar prometheus.yml
promtool check config prometheus.yml

# Validar regras de alerta
promtool check rules rules/*.yml

# Validar sintaxe PromQL
promtool query instant 'up'
promtool query range 'up' --start=2024-01-01T00:00:00Z --end=2024-01-01T01:00:00Z

# === ANÁLISE DE MÉTRICAS ===
# Analisar arquivo de métricas
promtool query instant 'node_cpu_seconds_total' --config.file=prometheus.yml

# Testar query específica
promtool query instant 'rate(http_requests_total[5m])' \
  --config.file=prometheus.yml

# === DEBUGGING DE REGRAS ===
# Testar regra de alerta
promtool test rules test_rules.yml

# Exemplo test_rules.yml:
# rule_files:
#   - rules.yml
# tests:
#   - interval: 1m
#     input_series:
#       - series: 'up{job="prometheus", instance="localhost:9090"}'
#         values: '0 0 0 0 0'
#     alert_rule_test:
#       - eval_time: 5m
#         alertname: InstanceDown
#         exp_alerts:
#           - exp_labels:
#               severity: critical
#               instance: localhost:9090
#               job: prometheus
```

### **📊 APIs de Debug**

```bash
# === STATUS E CONFIGURAÇÃO ===
# Status geral
curl -s http://localhost:9090/api/v1/status/config | jq .

# Informações de build
curl -s http://localhost:9090/api/v1/status/buildinfo | jq .

# Status dos targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health, lastError: .lastError}'

# === MÉTRICAS INTERNAS ===
# Estatísticas do TSDB
curl -s http://localhost:9090/api/v1/status/tsdb | jq .

# Informações de runtime
curl -s http://localhost:9090/api/v1/status/runtimeinfo | jq .

# === DEBUGGING DE QUERIES ===
# Explicar query (debug)
curl -s "http://localhost:9090/api/v1/query?query=up&debug=true" | jq .

# Analisar performance de query
curl -s "http://localhost:9090/api/v1/query?query=rate(http_requests_total[5m])&stats=all" | jq '.stats'

# === SERVICE DISCOVERY ===
# Status do service discovery
curl -s http://localhost:9090/api/v1/targets/metadata | jq .

# Labels descobertos
curl -s "http://localhost:9090/api/v1/targets?state=active" | jq '.data.activeTargets[0].discoveredLabels'
```

### **📋 Métricas de Monitoramento Interno**

```promql
# === PERFORMANCE DO PROMETHEUS ===
# Duração de queries
prometheus_engine_query_duration_seconds{quantile="0.9"}

# Queries concorrentes
prometheus_engine_queries

# Queries por segundo
rate(prometheus_engine_queries_total[5m])

# === TSDB ===
# Número de séries temporais
prometheus_tsdb_head_series

# Tamanho do WAL
prometheus_tsdb_wal_size_bytes

# Compactações
rate(prometheus_tsdb_compactions_total[5m])

# === SCRAPING ===
# Duração de scraping
prometheus_target_scrape_duration_seconds{quantile="0.9"}

# Scrapes por segundo
rate(prometheus_target_scrapes_total[5m])

# Scrapes com erro
rate(prometheus_target_scrapes_exceeded_sample_limit_total[5m])

# === REGRAS ===
# Duração de avaliação de regras
prometheus_rule_evaluation_duration_seconds{quantile="0.9"}

# Regras avaliadas por segundo
rate(prometheus_rule_evaluations_total[5m])

# === RECURSOS ===
# Uso de CPU
rate(process_cpu_seconds_total{job="prometheus"}[5m]) * 100

# Uso de memória
process_resident_memory_bytes{job="prometheus"} / 1024 / 1024 / 1024

# Goroutines
go_goroutines{job="prometheus"}
```

---

## 🎯 TROUBLESHOOTING POR CATEGORIA

### **🌐 Problemas de Rede**

```bash
# === DIAGNÓSTICO ===
# 1. Verificar conectividade
ping target-host
telnet target-host 9100
nc -zv target-host 9100

# 2. Verificar DNS
nslookup target-host
dig target-host

# 3. Verificar firewall
sudo iptables -L
sudo ufw status

# 4. Verificar portas abertas
netstat -tlnp | grep 9100
ss -tlnp | grep 9100

# === SOLUÇÕES ===
# Configurar timeout adequado
scrape_configs:
  - job_name: 'problematic-targets'
    scrape_interval: 30s
    scrape_timeout: 25s
    static_configs:
      - targets: ['slow-target:9100']
```

### **🔐 Problemas de Autenticação**

```yaml
# === TLS/SSL ===
scrape_configs:
  - job_name: 'secure-targets'
    scheme: https
    tls_config:
      ca_file: /etc/ssl/certs/ca.pem
      cert_file: /etc/ssl/certs/client.pem
      key_file: /etc/ssl/private/client.key
      insecure_skip_verify: false  # Para debug temporário: true
    static_configs:
      - targets: ['secure-target:9100']

# === BASIC AUTH ===
scrape_configs:
  - job_name: 'auth-targets'
    basic_auth:
      username: 'prometheus'
      password: 'secret'
    # Ou usando arquivo
    basic_auth:
      username: 'prometheus'
      password_file: '/etc/prometheus/password'
    static_configs:
      - targets: ['auth-target:9100']

# === BEARER TOKEN ===
scrape_configs:
  - job_name: 'token-targets'
    bearer_token: 'your-token-here'
    # Ou usando arquivo
    bearer_token_file: '/etc/prometheus/token'
    static_configs:
      - targets: ['token-target:9100']
```

### **📊 Problemas de Métricas**

```bash
# === DIAGNÓSTICO ===
# 1. Verificar se exporter está funcionando
curl http://target:9100/metrics

# 2. Verificar formato das métricas
curl http://target:9100/metrics | head -20

# 3. Verificar se métrica específica existe
curl http://target:9100/metrics | grep metric_name

# 4. Verificar labels
curl -s "http://localhost:9090/api/v1/series?match[]=metric_name" | jq .

# === SOLUÇÕES ===
# Relabeling para corrigir métricas
scrape_configs:
  - job_name: 'custom-metrics'
    static_configs:
      - targets: ['target:9100']
    metric_relabel_configs:
      # Renomear métrica
      - source_labels: [__name__]
        regex: 'old_metric_name'
        target_label: '__name__'
        replacement: 'new_metric_name'
      # Adicionar label
      - target_label: 'environment'
        replacement: 'production'
      # Remover métricas desnecessárias
      - source_labels: [__name__]
        regex: 'unwanted_metric.*'
        action: drop
```

---

## 🚀 OTIMIZAÇÃO DE PERFORMANCE

### **📈 Monitoramento de Performance**

```promql
# === DASHBOARD DE PERFORMANCE ===
# Queries mais lentas
topk(10, prometheus_engine_query_duration_seconds{quantile="0.9"})

# Uso de CPU por query
rate(prometheus_engine_query_duration_seconds_sum[5m]) / rate(prometheus_engine_query_duration_seconds_count[5m])

# Memória usada por queries
prometheus_engine_query_samples_total

# Número de séries ativas
prometheus_tsdb_head_series

# Taxa de ingestão
rate(prometheus_tsdb_head_samples_appended_total[5m])

# Tamanho do banco de dados
prometheus_tsdb_size_bytes

# === ALERTAS DE PERFORMANCE ===
# Query muito lenta
prometheus_engine_query_duration_seconds{quantile="0.9"} > 5

# Muitas séries temporais
prometheus_tsdb_head_series > 1000000

# Alto uso de memória
process_resident_memory_bytes{job="prometheus"} > 8 * 1024 * 1024 * 1024  # 8GB

# WAL muito grande
prometheus_tsdb_wal_size_bytes > 1024 * 1024 * 1024  # 1GB
```

### **⚡ Técnicas de Otimização**

```yaml
# === CONFIGURAÇÃO OTIMIZADA ===
global:
  scrape_interval: 30s        # Aumentar para reduzir carga
  evaluation_interval: 30s
  external_labels:
    cluster: 'production'
    
# === STORAGE ===
storage:
  tsdb:
    retention.time: 15d       # Reduzir retenção
    retention.size: 50GB      # Limitar tamanho
    
# === SCRAPING OTIMIZADO ===
scrape_configs:
  - job_name: 'optimized-job'
    scrape_interval: 60s      # Intervalo maior para métricas menos críticas
    sample_limit: 5000        # Limitar amostras por scrape
    metric_relabel_configs:
      # Remover métricas desnecessárias
      - source_labels: [__name__]
        regex: '(go_|process_).*'
        action: drop
      # Manter apenas métricas importantes
      - source_labels: [__name__]
        regex: '(up|node_cpu_seconds_total|node_memory_MemAvailable_bytes)'
        action: keep
```

### **📊 Recording Rules para Performance**

```yaml
# === RECORDING RULES OTIMIZADAS ===
groups:
  - name: performance_rules
    interval: 60s             # Intervalo maior para recording rules
    rules:
      # Pré-calcular métricas complexas
      - record: instance:cpu_usage:rate5m
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
        
      - record: instance:memory_usage:ratio
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
        
      # Agregações por cluster
      - record: cluster:cpu_usage:mean
        expr: avg(instance:cpu_usage:rate5m)
        
      - record: cluster:memory_usage:mean
        expr: avg(instance:memory_usage:ratio)
        
  # === ALERTAS USANDO RECORDING RULES ===
  - name: optimized_alerts
    rules:
      - alert: HighCPUUsage
        expr: instance:cpu_usage:rate5m > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
```

---

## 🔍 DEBUGGING AVANÇADO

### **📋 Análise de Logs**

```bash
# === LOGS DO PROMETHEUS ===
# Logs gerais
docker logs prometheus

# Filtrar por nível
docker logs prometheus 2>&1 | grep -i error
docker logs prometheus 2>&1 | grep -i warn

# Logs de scraping
docker logs prometheus 2>&1 | grep "scrape"

# Logs de regras
docker logs prometheus 2>&1 | grep "rule"

# === ANÁLISE ESPECÍFICA ===
# Targets com problema
docker logs prometheus 2>&1 | grep "failed to scrape"

# Problemas de configuração
docker logs prometheus 2>&1 | grep "config"

# Problemas de memória
docker logs prometheus 2>&1 | grep -i "memory\|oom"

# === LOGS ESTRUTURADOS ===
# Se usando log format JSON
docker logs prometheus 2>&1 | jq 'select(.level == "error")'
docker logs prometheus 2>&1 | jq 'select(.msg | contains("scrape"))'
```

### **🔬 Profiling e Debug**

```bash
# === PPROF ENDPOINTS ===
# CPU profile
curl -o cpu.prof http://localhost:9090/debug/pprof/profile?seconds=30
go tool pprof cpu.prof

# Memory profile
curl -o mem.prof http://localhost:9090/debug/pprof/heap
go tool pprof mem.prof

# Goroutines
curl http://localhost:9090/debug/pprof/goroutine?debug=1

# === MÉTRICAS DE DEBUG ===
# Verificar goroutines
curl -s "http://localhost:9090/api/v1/query?query=go_goroutines{job='prometheus'}"

# Verificar GC
curl -s "http://localhost:9090/api/v1/query?query=go_gc_duration_seconds{job='prometheus'}"

# Verificar heap
curl -s "http://localhost:9090/api/v1/query?query=go_memstats_heap_inuse_bytes{job='prometheus'}"
```

### **🎯 Debugging de Queries**

```bash
# === QUERY DEBUGGING ===
# Query com debug
curl -s "http://localhost:9090/api/v1/query?query=up&debug=true" | jq '.stats'

# Query com stats
curl -s "http://localhost:9090/api/v1/query?query=rate(http_requests_total[5m])&stats=all" | jq '.stats'

# === ANÁLISE DE PERFORMANCE ===
# Queries mais caras
curl -s "http://localhost:9090/api/v1/query?query=topk(10,prometheus_engine_query_duration_seconds{quantile='0.9'})" | jq '.data.result'

# Samples processados
curl -s "http://localhost:9090/api/v1/query?query=prometheus_engine_query_samples_total" | jq '.data.result'
```

---

## 🧪 CENÁRIOS DE TROUBLESHOOTING

### **🎯 Cenário 1: Target Intermitente**

```bash
# === PROBLEMA ===
# Target fica alternando entre UP e DOWN

# === DIAGNÓSTICO ===
# 1. Verificar padrão
changes(up{instance="problematic-target:9100"}[1h])

# 2. Verificar timeout
prometheus_target_scrape_duration_seconds{instance="problematic-target:9100"}

# 3. Verificar logs
docker logs prometheus 2>&1 | grep "problematic-target"

# === SOLUÇÃO ===
# Aumentar timeout e intervalo
scrape_configs:
  - job_name: 'unstable-targets'
    scrape_interval: 30s
    scrape_timeout: 25s
    static_configs:
      - targets: ['problematic-target:9100']
```

### **🎯 Cenário 2: Métricas com Valores Estranhos**

```promql
# === PROBLEMA ===
# Métricas com valores impossíveis ou inconsistentes

# === DIAGNÓSTICO ===
# 1. Verificar valores extremos
topk(10, node_cpu_seconds_total)
bottomk(10, node_cpu_seconds_total)

# 2. Verificar resets
resets(node_cpu_seconds_total[1h])

# 3. Verificar timestamps
time() - timestamp(node_cpu_seconds_total)

# === SOLUÇÃO ===
# Filtrar valores inválidos
(
  node_cpu_seconds_total > 0
  and
  node_cpu_seconds_total < 1e10
)
```

### **🎯 Cenário 3: Performance Degradada**

```bash
# === PROBLEMA ===
# Prometheus ficando lento

# === DIAGNÓSTICO ===
# 1. Verificar número de séries
curl -s "http://localhost:9090/api/v1/query?query=prometheus_tsdb_head_series"

# 2. Verificar queries lentas
curl -s "http://localhost:9090/api/v1/query?query=prometheus_engine_query_duration_seconds{quantile='0.9'}"

# 3. Verificar uso de recursos
docker stats prometheus

# === SOLUÇÃO ===
# 1. Implementar recording rules
# 2. Reduzir retenção
# 3. Filtrar métricas desnecessárias
# 4. Aumentar recursos
```

---

## 📚 CHECKLIST DE TROUBLESHOOTING

### **✅ Checklist Básico**

```bash
# === VERIFICAÇÕES INICIAIS ===
□ Prometheus está rodando?
  docker ps | grep prometheus
  
□ Configuração é válida?
  promtool check config prometheus.yml
  
□ Targets estão acessíveis?
  curl http://target:9100/metrics
  
□ Logs mostram erros?
  docker logs prometheus 2>&1 | grep -i error
  
□ Recursos suficientes?
  docker stats prometheus

# === VERIFICAÇÕES AVANÇADAS ===
□ Service discovery funcionando?
  curl -s http://localhost:9090/api/v1/targets
  
□ Métricas sendo coletadas?
  curl -s "http://localhost:9090/api/v1/query?query=up"
  
□ Regras sendo avaliadas?
  curl -s http://localhost:9090/api/v1/rules
  
□ Performance adequada?
  curl -s "http://localhost:9090/api/v1/query?query=prometheus_engine_query_duration_seconds"
```

### **🔧 Ferramentas Essenciais**

```bash
# === COMANDOS ÚTEIS ===
# Validação
promtool check config prometheus.yml
promtool check rules rules/*.yml

# Conectividade
telnet host port
nc -zv host port
curl -v http://host:port/metrics

# Análise
jq                    # Parse JSON
grep -i error        # Filtrar logs
tail -f              # Seguir logs
htop                 # Monitor recursos

# APIs
curl -s http://localhost:9090/api/v1/targets
curl -s http://localhost:9090/api/v1/query?query=up
curl -s http://localhost:9090/metrics
```

---

## 🎓 RESUMO DO MÓDULO

### **Técnicas Aprendidas:**
- ✅ **Diagnóstico:** Identificar problemas comuns
- ✅ **Ferramentas:** promtool, APIs, logs, profiling
- ✅ **Performance:** Otimização e monitoramento
- ✅ **Debugging:** Análise avançada e profiling
- ✅ **Cenários:** Casos práticos de troubleshooting
- ✅ **Checklist:** Metodologia sistemática

### **Próximos Passos:**
1. 📊 **[Módulo 09: Integração Grafana](09-integracao-grafana.md)** - Visualizações
2. 🚀 **[Módulo 10: Projeto Final](10-projeto-final.md)** - Implementação completa

---

**📚 Módulo Anterior:** [07 - Regras de Alerta](07-regras-alerta.md)  
**📚 Próximo Módulo:** [09 - Integração Grafana](09-integracao-grafana.md)  
**🏠 Voltar ao:** [README Principal](README.md)

---

*Módulo criado pela comunidade DevOps*  
*Última atualização: Janeiro 2025*