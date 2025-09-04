# 🚨 MÓDULO 07: REGRAS DE ALERTA

> **Objetivo:** Criar alertas eficazes e inteligentes para monitoramento proativo  
> **Duração:** 90 minutos  
> **Nível:** Intermediário/Avançado

---

## 🎯 O QUE VOCÊ VAI APRENDER

Neste módulo você irá:
- ✅ Entender a anatomia de uma regra de alerta
- ✅ Criar alertas para diferentes cenários
- ✅ Implementar alertas preditivos e inteligentes
- ✅ Configurar severidades e escalação
- ✅ Evitar alertas falso-positivos

---

## 📚 FUNDAMENTOS DE ALERTAS

### **🏗️ Anatomia de uma Regra de Alerta**

```yaml
groups:
  - name: example_alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
          team: infrastructure
          component: cpu
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ $value }}% on {{ $labels.instance }}"
          runbook_url: "https://wiki.company.com/runbooks/high-cpu"
```

### **🔍 Componentes Explicados**

```yaml
# IDENTIFICAÇÃO
alert: HighCPUUsage              # Nome único do alerta

# CONDIÇÃO
expr: cpu_usage > 80             # Query PromQL que define quando alertar

# DURAÇÃO
for: 5m                          # Tempo que a condição deve persistir

# METADADOS
labels:                          # Labels adicionados ao alerta
  severity: warning              # Nível de severidade
  team: infrastructure           # Equipe responsável
  component: cpu                 # Componente afetado
  
# INFORMAÇÕES
annotations:                     # Informações descritivas
  summary: "Resumo do problema"   # Título do alerta
  description: "Descrição detalhada"  # Detalhes do problema
  runbook_url: "URL do runbook"   # Link para procedimentos
```

---

## 🎯 ALERTAS DE INFRAESTRUTURA

### **🖥️ Alertas de Sistema**

```yaml
groups:
  - name: system_alerts
    rules:
      # === CPU ===
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ $value | humanizePercentage }} on {{ $labels.instance }}"
          
      - alert: CriticalCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 95
        for: 2m
        labels:
          severity: critical
          team: infrastructure
        annotations:
          summary: "Critical CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ $value | humanizePercentage }} on {{ $labels.instance }}"
          
      # === MEMÓRIA ===
      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is {{ $value | humanizePercentage }} on {{ $labels.instance }}"
          
      - alert: CriticalMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 95
        for: 2m
        labels:
          severity: critical
          team: infrastructure
        annotations:
          summary: "Critical memory usage on {{ $labels.instance }}"
          description: "Memory usage is {{ $value | humanizePercentage }} on {{ $labels.instance }}"
          
      # === DISCO ===
      - alert: HighDiskUsage
        expr: (1 - (node_filesystem_free_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100 > 85
        for: 5m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "High disk usage on {{ $labels.instance }}"
          description: "Disk usage is {{ $value | humanizePercentage }} on {{ $labels.instance }} ({{ $labels.mountpoint }})"
          
      - alert: CriticalDiskUsage
        expr: (1 - (node_filesystem_free_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100 > 95
        for: 2m
        labels:
          severity: critical
          team: infrastructure
        annotations:
          summary: "Critical disk usage on {{ $labels.instance }}"
          description: "Disk usage is {{ $value | humanizePercentage }} on {{ $labels.instance }} ({{ $labels.mountpoint }})"
          
      # === LOAD AVERAGE ===
      - alert: HighLoadAverage
        expr: node_load1 / on(instance) group_left count by(instance) (node_cpu_seconds_total{mode="idle"}) > 1.5
        for: 10m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "High load average on {{ $labels.instance }}"
          description: "Load average is {{ $value }} on {{ $labels.instance }}"
```

### **🌐 Alertas de Rede**

```yaml
groups:
  - name: network_alerts
    rules:
      # === CONECTIVIDADE ===
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
          team: infrastructure
        annotations:
          summary: "Instance {{ $labels.instance }} is down"
          description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute"
          
      # === TRÁFEGO ALTO ===
      - alert: HighNetworkTraffic
        expr: rate(node_network_receive_bytes_total{device!="lo"}[5m]) + rate(node_network_transmit_bytes_total{device!="lo"}[5m]) > 100 * 1024 * 1024  # 100MB/s
        for: 5m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "High network traffic on {{ $labels.instance }}"
          description: "Network traffic is {{ $value | humanizeBytes }}/s on {{ $labels.instance }} ({{ $labels.device }})"
          
      # === ERROS DE REDE ===
      - alert: NetworkErrors
        expr: rate(node_network_receive_errs_total[5m]) + rate(node_network_transmit_errs_total[5m]) > 0.1
        for: 2m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "Network errors on {{ $labels.instance }}"
          description: "Network error rate is {{ $value }} errors/sec on {{ $labels.instance }} ({{ $labels.device }})"
```

---

## 🌐 ALERTAS DE APLICAÇÃO

### **📊 Alertas HTTP/API**

```yaml
groups:
  - name: application_alerts
    rules:
      # === TAXA DE ERRO ===
      - alert: HighErrorRate
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[5m])) by (job, instance)
            /
            sum(rate(http_requests_total[5m])) by (job, instance)
          ) * 100 > 5
        for: 5m
        labels:
          severity: warning
          team: backend
        annotations:
          summary: "High error rate on {{ $labels.instance }}"
          description: "Error rate is {{ $value | humanizePercentage }} on {{ $labels.instance }}"
          
      - alert: CriticalErrorRate
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[5m])) by (job, instance)
            /
            sum(rate(http_requests_total[5m])) by (job, instance)
          ) * 100 > 20
        for: 2m
        labels:
          severity: critical
          team: backend
        annotations:
          summary: "Critical error rate on {{ $labels.instance }}"
          description: "Error rate is {{ $value | humanizePercentage }} on {{ $labels.instance }}"
          
      # === LATÊNCIA ===
      - alert: HighLatency
        expr: histogram_quantile(0.95, sum by(job, instance, le) (rate(http_request_duration_seconds_bucket[5m]))) > 1
        for: 5m
        labels:
          severity: warning
          team: backend
        annotations:
          summary: "High latency on {{ $labels.instance }}"
          description: "95th percentile latency is {{ $value }}s on {{ $labels.instance }}"
          
      - alert: CriticalLatency
        expr: histogram_quantile(0.95, sum by(job, instance, le) (rate(http_request_duration_seconds_bucket[5m]))) > 5
        for: 2m
        labels:
          severity: critical
          team: backend
        annotations:
          summary: "Critical latency on {{ $labels.instance }}"
          description: "95th percentile latency is {{ $value }}s on {{ $labels.instance }}"
          
      # === THROUGHPUT ===
      - alert: LowThroughput
        expr: sum(rate(http_requests_total[5m])) by (job, instance) < 10
        for: 10m
        labels:
          severity: warning
          team: backend
        annotations:
          summary: "Low throughput on {{ $labels.instance }}"
          description: "Request rate is {{ $value }} req/s on {{ $labels.instance }}"
          
      - alert: NoTraffic
        expr: sum(rate(http_requests_total[5m])) by (job, instance) == 0
        for: 5m
        labels:
          severity: critical
          team: backend
        annotations:
          summary: "No traffic on {{ $labels.instance }}"
          description: "No HTTP requests received on {{ $labels.instance }} for 5 minutes"
```

### **🗄️ Alertas de Banco de Dados**

```yaml
groups:
  - name: database_alerts
    rules:
      # === MYSQL ===
      - alert: MySQLDown
        expr: mysql_up == 0
        for: 1m
        labels:
          severity: critical
          team: database
        annotations:
          summary: "MySQL is down on {{ $labels.instance }}"
          description: "MySQL database is not responding on {{ $labels.instance }}"
          
      - alert: MySQLSlowQueries
        expr: rate(mysql_global_status_slow_queries[5m]) > 0.1
        for: 5m
        labels:
          severity: warning
          team: database
        annotations:
          summary: "MySQL slow queries on {{ $labels.instance }}"
          description: "Slow query rate is {{ $value }} queries/sec on {{ $labels.instance }}"
          
      - alert: MySQLConnections
        expr: mysql_global_status_threads_connected / mysql_global_variables_max_connections * 100 > 80
        for: 5m
        labels:
          severity: warning
          team: database
        annotations:
          summary: "High MySQL connections on {{ $labels.instance }}"
          description: "Connection usage is {{ $value | humanizePercentage }} on {{ $labels.instance }}"
          
      # === POSTGRESQL ===
      - alert: PostgreSQLDown
        expr: pg_up == 0
        for: 1m
        labels:
          severity: critical
          team: database
        annotations:
          summary: "PostgreSQL is down on {{ $labels.instance }}"
          description: "PostgreSQL database is not responding on {{ $labels.instance }}"
          
      - alert: PostgreSQLConnections
        expr: sum by(instance) (pg_stat_activity_count) / on(instance) pg_settings_max_connections * 100 > 80
        for: 5m
        labels:
          severity: warning
          team: database
        annotations:
          summary: "High PostgreSQL connections on {{ $labels.instance }}"
          description: "Connection usage is {{ $value | humanizePercentage }} on {{ $labels.instance }}"
```

---

## 🔮 ALERTAS PREDITIVOS

### **📈 Alertas Baseados em Tendências**

```yaml
groups:
  - name: predictive_alerts
    rules:
      # === DISCO CHEIO ===
      - alert: DiskWillFillIn4Hours
        expr: |
          (
            predict_linear(node_filesystem_free_bytes{fstype!="tmpfs"}[1h], 4*3600) < 0
          )
          and
          (
            deriv(node_filesystem_free_bytes{fstype!="tmpfs"}[1h]) < 0
          )
        for: 5m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "Disk will fill in 4 hours on {{ $labels.instance }}"
          description: "Filesystem {{ $labels.mountpoint }} on {{ $labels.instance }} will be full in approximately 4 hours"
          
      # === MEMÓRIA ESGOTANDO ===
      - alert: MemoryWillExhaustIn2Hours
        expr: |
          (
            predict_linear(node_memory_MemAvailable_bytes[30m], 2*3600) < 
            node_memory_MemTotal_bytes * 0.05
          )
          and
          (
            deriv(node_memory_MemAvailable_bytes[30m]) < 0
          )
        for: 10m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "Memory will exhaust in 2 hours on {{ $labels.instance }}"
          description: "Available memory on {{ $labels.instance }} will drop below 5% in approximately 2 hours"
          
      # === CRESCIMENTO ANÔMALO ===
      - alert: AbnormalTrafficGrowth
        expr: |
          (
            predict_linear(rate(http_requests_total[5m])[1h:], 2*3600) >
            max_over_time(rate(http_requests_total[5m])[1w:]) * 2
          )
          and
          (
            deriv(rate(http_requests_total[5m])[1h:]) > 0
          )
        for: 15m
        labels:
          severity: warning
          team: backend
        annotations:
          summary: "Abnormal traffic growth on {{ $labels.instance }}"
          description: "Traffic on {{ $labels.instance }} is growing abnormally and may cause issues in 2 hours"
```

### **🎯 Alertas de Anomalia**

```yaml
groups:
  - name: anomaly_alerts
    rules:
      # === OUTLIERS DE CPU ===
      - alert: CPUUsageOutlier
        expr: |
          abs(
            100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) -
            avg(100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100))
          ) > 
          2 * stddev(100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100))
        for: 10m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "CPU usage outlier detected on {{ $labels.instance }}"
          description: "CPU usage on {{ $labels.instance }} deviates significantly from cluster average"
          
      # === LATÊNCIA ANÔMALA ===
      - alert: LatencyAnomaly
        expr: |
          histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) >
          (
            avg_over_time(histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))[1h:]) +
            3 * stddev_over_time(histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))[1h:])
          )
        for: 5m
        labels:
          severity: warning
          team: backend
        annotations:
          summary: "Latency anomaly detected on {{ $labels.instance }}"
          description: "95th percentile latency on {{ $labels.instance }} is significantly higher than normal"
          
      # === MUDANÇA BRUSCA ===
      - alert: SuddenTrafficDrop
        expr: |
          (
            rate(http_requests_total[5m]) < 
            rate(http_requests_total[5m]) offset 15m * 0.5
          )
          and
          (
            rate(http_requests_total[5m]) offset 15m > 10
          )
        for: 5m
        labels:
          severity: warning
          team: backend
        annotations:
          summary: "Sudden traffic drop on {{ $labels.instance }}"
          description: "Traffic on {{ $labels.instance }} dropped by more than 50% in the last 15 minutes"
```

---

## 🎯 ALERTAS INTELIGENTES

### **⏰ Alertas Baseados em Tempo**

```yaml
groups:
  - name: time_based_alerts
    rules:
      # === HORÁRIO COMERCIAL ===
      - alert: HighCPUDuringBusinessHours
        expr: |
          (
            100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 70
          )
          and on()
          (
            hour() >= 9 and hour() <= 17
          )
          and on()
          (
            day_of_week() >= 1 and day_of_week() <= 5
          )
        for: 5m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "High CPU during business hours on {{ $labels.instance }}"
          description: "CPU usage is {{ $value | humanizePercentage }} during business hours on {{ $labels.instance }}"
          
      # === FORA DO HORÁRIO ===
      - alert: UnexpectedTrafficAfterHours
        expr: |
          (
            rate(http_requests_total[5m]) > 
            avg_over_time(rate(http_requests_total[5m])[1w:]) * 2
          )
          and on()
          (
            hour() < 6 or hour() > 22
          )
        for: 10m
        labels:
          severity: warning
          team: security
        annotations:
          summary: "Unexpected traffic after hours on {{ $labels.instance }}"
          description: "High traffic detected outside business hours on {{ $labels.instance }}"
          
      # === FINS DE SEMANA ===
      - alert: WeekendActivity
        expr: |
          (
            rate(http_requests_total[5m]) > 
            quantile_over_time(0.95, rate(http_requests_total[5m])[1w:])
          )
          and on()
          (
            day_of_week() == 0 or day_of_week() == 6
          )
        for: 15m
        labels:
          severity: info
          team: backend
        annotations:
          summary: "High weekend activity on {{ $labels.instance }}"
          description: "Unusual activity detected during weekend on {{ $labels.instance }}"
```

### **🔄 Alertas com Contexto**

```yaml
groups:
  - name: contextual_alerts
    rules:
      # === CORRELAÇÃO DE PROBLEMAS ===
      - alert: MultipleSystemIssues
        expr: |
          (
            # Alta CPU
            100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
          )
          and on(instance)
          (
            # Alta memória
            (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80
          )
          and on(instance)
          (
            # Alto load
            node_load1 > 2
          )
        for: 5m
        labels:
          severity: critical
          team: infrastructure
        annotations:
          summary: "Multiple system issues on {{ $labels.instance }}"
          description: "{{ $labels.instance }} has high CPU, memory, and load average simultaneously"
          
      # === IMPACTO NO USUÁRIO ===
      - alert: UserImpactingIssue
        expr: |
          (
            # Alta taxa de erro
            sum(rate(http_requests_total{status=~"5.."}[5m])) by (instance) /
            sum(rate(http_requests_total[5m])) by (instance) * 100 > 10
          )
          and on(instance)
          (
            # Alta latência
            histogram_quantile(0.95, sum by(instance, le) (rate(http_request_duration_seconds_bucket[5m]))) > 2
          )
        for: 3m
        labels:
          severity: critical
          team: backend
          impact: user_facing
        annotations:
          summary: "User-impacting issue on {{ $labels.instance }}"
          description: "High error rate ({{ $value | humanizePercentage }}) and latency affecting users on {{ $labels.instance }}"
```

---

## 🎨 BOAS PRÁTICAS

### **📝 Nomenclatura e Organização**

```yaml
# ✅ BOAS PRÁTICAS
groups:
  - name: infrastructure_cpu        # Nome descritivo do grupo
    rules:
      - alert: NodeHighCPUUsage     # Prefixo + Componente + Problema
        expr: node_cpu_usage > 80
        for: 5m                     # Tempo apropriado para evitar flapping
        labels:
          severity: warning         # Severidade consistente
          team: infrastructure      # Equipe responsável
          component: cpu           # Componente específico
          runbook: "cpu-high"      # Link para runbook
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"  # Resumo claro
          description: "CPU usage is {{ $value | humanizePercentage }} on {{ $labels.instance }}"  # Detalhes com valores
          
# ❌ EVITAR
groups:
  - name: alerts                   # Nome genérico
    rules:
      - alert: Alert1               # Nome não descritivo
        expr: cpu > 80
        for: 0s                     # Sem tempo de espera (flapping)
        labels:
          severity: high            # Severidade inconsistente
        annotations:
          summary: "Problem"        # Resumo vago
```

### **🎯 Severidades Padronizadas**

```yaml
# === CRITICAL ===
# - Serviço completamente indisponível
# - Perda de dados iminente
# - Impacto direto no usuário
# - Requer ação imediata (24/7)
labels:
  severity: critical
  
# === WARNING ===
# - Degradação de performance
# - Recursos próximos do limite
# - Problemas que podem escalar
# - Requer ação em horário comercial
labels:
  severity: warning
  
# === INFO ===
# - Eventos informativos
# - Mudanças de estado
# - Métricas para análise
# - Não requer ação imediata
labels:
  severity: info
```

### **⚡ Evitando Falso-Positivos**

```yaml
groups:
  - name: robust_alerts
    rules:
      # ✅ BOM - Múltiplas condições
      - alert: RealHighCPU
        expr: |
          (
            # CPU alto
            100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
          )
          and
          (
            # Load alto também
            node_load1 > 1.5
          )
          and
          (
            # Não é apenas um pico
            avg_over_time((100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100))[10m:]) > 70
          )
        for: 10m  # Tempo suficiente para confirmar
        
      # ✅ BOM - Excluir situações normais
      - alert: UnexpectedHighMemory
        expr: |
          (
            (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
          )
          unless
          (
            # Excluir durante backup (exemplo)
            increase(node_disk_writes_completed_total[5m]) > 1000
          )
        for: 5m
        
      # ✅ BOM - Considerar contexto temporal
      - alert: AbnormalErrorRate
        expr: |
          (
            # Taxa de erro atual
            sum(rate(http_requests_total{status=~"5.."}[5m])) by (instance) /
            sum(rate(http_requests_total[5m])) by (instance) * 100 > 5
          )
          and
          (
            # Maior que a média histórica
            sum(rate(http_requests_total{status=~"5.."}[5m])) by (instance) /
            sum(rate(http_requests_total[5m])) by (instance) * 100 >
            avg_over_time(
              (sum(rate(http_requests_total{status=~"5.."}[5m])) by (instance) /
               sum(rate(http_requests_total[5m])) by (instance) * 100)[1h:]
            ) * 2
          )
        for: 5m
```

---

## 📊 RECORDING RULES PARA ALERTAS

### **🚀 Otimizando Performance**

```yaml
groups:
  # === RECORDING RULES ===
  - name: recording_rules
    interval: 30s
    rules:
      # CPU usage por instância
      - record: instance:cpu_usage:rate5m
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
        
      # Uso de memória por instância
      - record: instance:memory_usage:ratio
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
        
      # Taxa de erro HTTP por instância
      - record: instance:http_error_rate:rate5m
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) by (instance) /
          sum(rate(http_requests_total[5m])) by (instance) * 100
          
      # Latência P95 por instância
      - record: instance:http_latency:p95
        expr: histogram_quantile(0.95, sum by(instance, le) (rate(http_request_duration_seconds_bucket[5m])))
        
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
          description: "CPU usage is {{ $value | humanizePercentage }} on {{ $labels.instance }}"
          
      - alert: HighMemoryUsage
        expr: instance:memory_usage:ratio > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is {{ $value | humanizePercentage }} on {{ $labels.instance }}"
          
      - alert: HighErrorRate
        expr: instance:http_error_rate:rate5m > 5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate on {{ $labels.instance }}"
          description: "Error rate is {{ $value | humanizePercentage }} on {{ $labels.instance }}"
          
      - alert: HighLatency
        expr: instance:http_latency:p95 > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High latency on {{ $labels.instance }}"
          description: "95th percentile latency is {{ $value }}s on {{ $labels.instance }}"
```

---

## 🧪 EXERCÍCIOS PRÁTICOS

### **🎯 Exercício 1: Alertas Básicos**

```yaml
# Crie alertas para:
# 1. Disco com mais de 90% de uso
# 2. Serviço indisponível por mais de 30 segundos
# 3. Taxa de erro HTTP > 10%
# 4. Latência P95 > 2 segundos
# 5. Mais de 100 conexões simultâneas

groups:
  - name: exercise_1
    rules:
      # Sua solução aqui
```

### **🎯 Exercício 2: Alertas Preditivos**

```yaml
# Crie alertas preditivos para:
# 1. Disco que ficará cheio em 6 horas
# 2. Memória que se esgotará em 1 hora
# 3. Tráfego que dobrará em 2 horas
# 4. Conexões de banco que atingirão o limite em 30 minutos

groups:
  - name: exercise_2
    rules:
      # Sua solução aqui
```

### **🎯 Exercício 3: Alertas Contextuais**

```yaml
# Crie alertas que considerem:
# 1. Alta CPU apenas durante horário comercial
# 2. Tráfego baixo apenas em dias úteis
# 3. Erros correlacionados com alta latência
# 4. Múltiplos problemas simultâneos

groups:
  - name: exercise_3
    rules:
      # Sua solução aqui
```

---

## 🎓 RESUMO DO MÓDULO

### **Conceitos Aprendidos:**
- ✅ **Anatomia de alertas:** expr, for, labels, annotations
- ✅ **Alertas de infraestrutura:** CPU, memória, disco, rede
- ✅ **Alertas de aplicação:** HTTP, latência, throughput
- ✅ **Alertas preditivos:** predict_linear, tendências
- ✅ **Alertas inteligentes:** contexto, tempo, correlação
- ✅ **Boas práticas:** nomenclatura, severidades, falso-positivos

### **Próximos Passos:**
1. 🛠️ **[Módulo 08: Troubleshooting](08-troubleshooting.md)** - Resolução de problemas
2. 📊 **[Módulo 09: Integração Grafana](09-integracao-grafana.md)** - Visualizações
3. 🚀 **[Módulo 10: Projeto Final](10-projeto-final.md)** - Implementação completa

---

**📚 Módulo Anterior:** [06 - PromQL Avançado](06-promql-avancado.md)  
**📚 Próximo Módulo:** [08 - Troubleshooting](08-troubleshooting.md)  
**🏠 Voltar ao:** [README Principal](README.md)

---

*Módulo criado pela comunidade DevOps*  
*Última atualização: Janeiro 2025*