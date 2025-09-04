# 📊 MÓDULO 04: COLETA DE MÉTRICAS

> **Objetivo:** Dominar exporters, targets e estratégias de coleta de métricas  
> **Duração:** 75 minutos  
> **Nível:** Intermediário

---

## 🎯 O QUE VOCÊ VAI APRENDER

Neste módulo você irá:
- ✅ Entender tipos de métricas e exporters
- ✅ Configurar exporters principais (Node, cAdvisor, Blackbox)
- ✅ Implementar coleta de aplicações customizadas
- ✅ Usar service discovery para ambientes dinâmicos
- ✅ Otimizar performance de coleta

---

## 📈 TIPOS DE MÉTRICAS

### **🔢 Counter (Contador)**

**Características:**
- Valor que só aumenta (ou reseta para zero)
- Usado para eventos cumulativos
- Nunca diminui durante operação normal

**Exemplos:**
```promql
# Requisições HTTP totais
http_requests_total{method="GET", status="200"} 1547

# Bytes enviados pela rede
node_network_transmit_bytes_total{device="eth0"} 2847392847

# Erros de aplicação
app_errors_total{type="database_connection"} 23
```

**Uso típico:**
```promql
# Taxa por segundo (mais útil que valor absoluto)
rate(http_requests_total[5m])

# Incremento total em período
increase(http_requests_total[1h])
```

### **📊 Gauge (Medidor)**

**Características:**
- Valor que pode subir ou descer
- Representa estado atual
- Snapshot de um momento específico

**Exemplos:**
```promql
# Uso de CPU atual
node_cpu_usage_percent 45.2

# Memória disponível
node_memory_available_bytes 2147483648

# Número de conexões ativas
app_active_connections 127

# Temperatura do servidor
hardware_temperature_celsius{sensor="cpu"} 68.5
```

**Uso típico:**
```promql
# Valor atual
node_memory_available_bytes

# Agregações
avg(node_cpu_usage_percent)
max(app_active_connections)
```

### **📊 Histogram (Histograma)**

**Características:**
- Distribui observações em buckets
- Inclui contadores cumulativos
- Permite cálculo de percentis

**Estrutura:**
```promql
# Buckets cumulativos
http_request_duration_seconds_bucket{le="0.1"} 1000
http_request_duration_seconds_bucket{le="0.5"} 1500
http_request_duration_seconds_bucket{le="1.0"} 1800
http_request_duration_seconds_bucket{le="+Inf"} 2000

# Soma total
http_request_duration_seconds_sum 450.5

# Contagem total
http_request_duration_seconds_count 2000
```

**Uso típico:**
```promql
# Percentil 95
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Latência média
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])
```

### **📈 Summary (Resumo)**

**Características:**
- Percentis pré-calculados no cliente
- Menor overhead no Prometheus
- Menos flexível que histograms

**Estrutura:**
```promql
# Percentis específicos
http_request_duration_seconds{quantile="0.5"} 0.15
http_request_duration_seconds{quantile="0.9"} 0.45
http_request_duration_seconds{quantile="0.99"} 1.2

# Soma e contagem
http_request_duration_seconds_sum 450.5
http_request_duration_seconds_count 2000
```

---

## 🖥️ NODE EXPORTER

### **📦 Instalação e Configuração**

```yaml
# docker-compose.yml
version: '3.8'
services:
  node-exporter:
    image: prom/node-exporter:v1.6.1
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
      - /run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
      - '--collector.systemd'
      - '--collector.processes'
      - '--web.listen-address=0.0.0.0:9100'
    restart: unless-stopped
    privileged: true
    pid: host
```

### **🔧 Collectors Principais**

```bash
# Collectors habilitados por padrão
--collector.cpu          # Métricas de CPU
--collector.diskstats    # Estatísticas de disco
--collector.filesystem   # Uso de filesystem
--collector.loadavg      # Load average
--collector.meminfo      # Informações de memória
--collector.netdev       # Estatísticas de rede
--collector.stat         # Estatísticas do kernel
--collector.time         # Tempo do sistema
--collector.uname        # Informações do sistema

# Collectors opcionais úteis
--collector.systemd      # Serviços systemd
--collector.processes    # Informações de processos
--collector.tcpstat      # Estatísticas TCP
--collector.textfile     # Métricas de arquivos texto
```

### **📊 Métricas Principais**

```promql
# === CPU ===
# Uso por modo (user, system, idle, etc.)
node_cpu_seconds_total{mode="user"}

# CPU usage percentual
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# === MEMÓRIA ===
# Memória total
node_memory_MemTotal_bytes

# Memória disponível
node_memory_MemAvailable_bytes

# Uso de memória percentual
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# === DISCO ===
# Espaço total por filesystem
node_filesystem_size_bytes

# Espaço livre
node_filesystem_free_bytes

# Uso de disco percentual
(1 - (node_filesystem_free_bytes / node_filesystem_size_bytes)) * 100

# IOPS de leitura/escrita
rate(node_disk_reads_completed_total[5m])
rate(node_disk_writes_completed_total[5m])

# === REDE ===
# Bytes recebidos/enviados
rate(node_network_receive_bytes_total[5m])
rate(node_network_transmit_bytes_total[5m])

# Pacotes com erro
rate(node_network_receive_errs_total[5m])
rate(node_network_transmit_errs_total[5m])

# === LOAD AVERAGE ===
# Load average 1, 5, 15 minutos
node_load1
node_load5
node_load15
```

### **📝 Textfile Collector**

```bash
# Habilitar textfile collector
--collector.textfile.directory=/var/lib/node_exporter/textfile_collector

# Script de exemplo para métricas customizadas
#!/bin/bash
# /usr/local/bin/custom_metrics.sh

TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"

# Métrica de backup status
if [ -f "/var/log/backup.success" ]; then
    echo "backup_last_success_timestamp $(stat -c %Y /var/log/backup.success)" > "$TEXTFILE_DIR/backup.prom"
    echo "backup_status 1" >> "$TEXTFILE_DIR/backup.prom"
else
    echo "backup_status 0" > "$TEXTFILE_DIR/backup.prom"
fi

# Métrica de certificado SSL
SSL_EXPIRY=$(openssl x509 -in /etc/ssl/certs/server.crt -noout -enddate | cut -d= -f2)
SSL_EXPIRY_TIMESTAMP=$(date -d "$SSL_EXPIRY" +%s)
echo "ssl_certificate_expiry_timestamp $SSL_EXPIRY_TIMESTAMP" > "$TEXTFILE_DIR/ssl.prom"

# Métrica de aplicação customizada
APP_USERS=$(mysql -u monitor -p'password' -e "SELECT COUNT(*) FROM users" myapp | tail -1)
echo "app_total_users $APP_USERS" > "$TEXTFILE_DIR/app.prom"
```

---

## 🐳 CADVISOR (CONTAINER ADVISOR)

### **📦 Configuração**

```yaml
# docker-compose.yml
version: '3.8'
services:
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.47.0
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    devices:
      - /dev/kmsg
    privileged: true
    restart: unless-stopped
    command:
      - '--housekeeping_interval=30s'
      - '--docker_only=true'
      - '--disable_metrics=accelerator,cpu_topology,disk,memory_numa,tcp,udp,percpu,sched,process,hugetlb,referenced_memory,resctrl,cpuset,advtcp,memory_numa'
```

### **📊 Métricas de Containers**

```promql
# === CPU ===
# Uso de CPU por container
rate(container_cpu_usage_seconds_total[5m]) * 100

# CPU throttling
rate(container_cpu_cfs_throttled_seconds_total[5m])

# === MEMÓRIA ===
# Uso de memória
container_memory_usage_bytes

# Limite de memória
container_spec_memory_limit_bytes

# Uso percentual de memória
(container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100

# Cache de memória
container_memory_cache

# === REDE ===
# Bytes recebidos/enviados
rate(container_network_receive_bytes_total[5m])
rate(container_network_transmit_bytes_total[5m])

# Pacotes descartados
rate(container_network_receive_packets_dropped_total[5m])
rate(container_network_transmit_packets_dropped_total[5m])

# === FILESYSTEM ===
# Uso de disco por container
container_fs_usage_bytes

# Limite de disco
container_fs_limit_bytes

# IOPS
rate(container_fs_reads_total[5m])
rate(container_fs_writes_total[5m])
```

### **🎯 Queries Úteis para Containers**

```promql
# Top 10 containers por CPU
topk(10, rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100)

# Top 10 containers por memória
topk(10, container_memory_usage_bytes{name!=""})

# Containers com alto uso de CPU (>80%)
rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100 > 80

# Containers próximos do limite de memória (>90%)
(container_memory_usage_bytes{name!=""} / container_spec_memory_limit_bytes{name!=""}) * 100 > 90

# Containers com restart recente
increase(container_start_time_seconds{name!=""}[1h]) > 0
```

---

## 🌐 BLACKBOX EXPORTER

### **📦 Configuração**

```yaml
# docker-compose.yml
version: '3.8'
services:
  blackbox-exporter:
    image: prom/blackbox-exporter:v0.24.0
    container_name: blackbox-exporter
    ports:
      - "9115:9115"
    volumes:
      - ./blackbox.yml:/etc/blackbox_exporter/config.yml:ro
    restart: unless-stopped
    command:
      - '--config.file=/etc/blackbox_exporter/config.yml'
```

### **⚙️ Configuração de Módulos**

```yaml
# blackbox.yml
modules:
  # HTTP GET básico
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: [200]
      method: GET
      follow_redirects: true
      preferred_ip_protocol: "ip4"
  
  # HTTP POST com autenticação
  http_post_2xx:
    prober: http
    timeout: 5s
    http:
      method: POST
      headers:
        Content-Type: application/json
        Authorization: Bearer token123
      body: '{"test": true}'
      valid_status_codes: [200, 201]
  
  # HTTPS com validação de certificado
  http_2xx_ssl:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: [200]
      method: GET
      tls_config:
        insecure_skip_verify: false
      fail_if_ssl: false
      fail_if_not_ssl: true
  
  # TCP connect
  tcp_connect:
    prober: tcp
    timeout: 5s
    tcp:
      preferred_ip_protocol: "ip4"
  
  # ICMP ping
  icmp:
    prober: icmp
    timeout: 5s
    icmp:
      preferred_ip_protocol: "ip4"
  
  # DNS lookup
  dns_google:
    prober: dns
    timeout: 5s
    dns:
      query_name: "google.com"
      query_type: "A"
      valid_rcodes:
        - NOERROR
      validate_answer_rrs:
        fail_if_matches_regexp:
          - ".*127.0.0.1"
        fail_if_not_matches_regexp:
          - "google.com.\t300\tIN\tA\t.*"
```

### **🎯 Configuração no Prometheus**

```yaml
# prometheus.yml
scrape_configs:
  # HTTP endpoints
  - job_name: 'blackbox-http'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - https://google.com
        - https://github.com
        - http://prometheus.io
        - https://grafana.com
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115
  
  # TCP services
  - job_name: 'blackbox-tcp'
    metrics_path: /probe
    params:
      module: [tcp_connect]
    static_configs:
      - targets:
        - google.com:80
        - google.com:443
        - 8.8.8.8:53
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115
  
  # ICMP ping
  - job_name: 'blackbox-icmp'
    metrics_path: /probe
    params:
      module: [icmp]
    static_configs:
      - targets:
        - 8.8.8.8
        - 1.1.1.1
        - google.com
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115
```

### **📊 Métricas do Blackbox**

```promql
# === DISPONIBILIDADE ===
# Site está UP (1) ou DOWN (0)
probe_success

# === HTTP ===
# Duração total da requisição
probe_http_duration_seconds

# Status code HTTP
probe_http_status_code

# Tamanho da resposta
probe_http_content_length

# Versão do SSL/TLS
probe_http_ssl
probe_tls_version_info

# Expiração do certificado SSL
probe_ssl_earliest_cert_expiry

# === TCP ===
# Duração da conexão TCP
probe_tcp_duration_seconds

# === ICMP ===
# RTT (Round Trip Time)
probe_icmp_duration_seconds

# === DNS ===
# Tempo de resolução DNS
probe_dns_lookup_time_seconds
```

### **🚨 Alertas Comuns**

```yaml
# rules/blackbox.yml
groups:
  - name: blackbox-alerts
    rules:
      # Site down
      - alert: SiteDown
        expr: probe_success == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Site {{ $labels.instance }} está down"
          description: "O site {{ $labels.instance }} não está respondendo há mais de 1 minuto."
      
      # Certificado SSL expirando
      - alert: SSLCertExpiringSoon
        expr: (probe_ssl_earliest_cert_expiry - time()) / 86400 < 30
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "Certificado SSL expirando em breve"
          description: "O certificado SSL de {{ $labels.instance }} expira em {{ $value }} dias."
      
      # Alta latência HTTP
      - alert: HighHTTPLatency
        expr: probe_http_duration_seconds > 5
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Alta latência HTTP"
          description: "{{ $labels.instance }} está respondendo em {{ $value }}s (>5s)."
      
      # Status code HTTP não esperado
      - alert: HTTPStatusCodeError
        expr: probe_http_status_code >= 400
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Erro HTTP {{ $value }}"
          description: "{{ $labels.instance }} retornou status code {{ $value }}."
```

---

## 🔧 EXPORTERS ESPECIALIZADOS

### **🗄️ MySQL Exporter**

```yaml
# docker-compose.yml
services:
  mysql-exporter:
    image: prom/mysqld-exporter:v0.15.0
    container_name: mysql-exporter
    ports:
      - "9104:9104"
    environment:
      DATA_SOURCE_NAME: "exporter:password@(mysql:3306)/"
    restart: unless-stopped
    depends_on:
      - mysql
```

```sql
-- Criar usuário para monitoramento
CREATE USER 'exporter'@'%' IDENTIFIED BY 'password';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
FLUSH PRIVILEGES;
```

```promql
# Métricas principais do MySQL
mysql_up                                    # MySQL está UP
mysql_global_status_connections             # Conexões totais
mysql_global_status_threads_connected       # Conexões ativas
mysql_global_status_slow_queries            # Queries lentas
mysql_global_status_innodb_buffer_pool_reads # Leituras do buffer pool
```

### **🐘 PostgreSQL Exporter**

```yaml
# docker-compose.yml
services:
  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:v0.13.2
    container_name: postgres-exporter
    ports:
      - "9187:9187"
    environment:
      DATA_SOURCE_NAME: "postgresql://postgres:password@postgres:5432/postgres?sslmode=disable"
    restart: unless-stopped
```

```promql
# Métricas principais do PostgreSQL
pg_up                                       # PostgreSQL está UP
pg_stat_database_numbackends               # Conexões ativas
pg_stat_database_xact_commit               # Transações commitadas
pg_stat_database_xact_rollback             # Transações com rollback
pg_database_size_bytes                     # Tamanho do banco
```

### **🔴 Redis Exporter**

```yaml
# docker-compose.yml
services:
  redis-exporter:
    image: oliver006/redis_exporter:v1.52.0
    container_name: redis-exporter
    ports:
      - "9121:9121"
    environment:
      REDIS_ADDR: "redis://redis:6379"
    restart: unless-stopped
```

```promql
# Métricas principais do Redis
redis_up                                    # Redis está UP
redis_connected_clients                     # Clientes conectados
redis_used_memory_bytes                     # Memória usada
redis_keyspace_hits_total                   # Cache hits
redis_keyspace_misses_total                 # Cache misses
```

---

## 🎯 INSTRUMENTAÇÃO DE APLICAÇÕES

### **🐍 Python com prometheus_client**

```python
# app.py
from prometheus_client import Counter, Histogram, Gauge, start_http_server
import time
import random
from flask import Flask, request

app = Flask(__name__)

# Métricas
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint']
)

ACTIVE_CONNECTIONS = Gauge(
    'active_connections',
    'Number of active connections'
)

ERROR_COUNT = Counter(
    'application_errors_total',
    'Total application errors',
    ['error_type']
)

@app.before_request
def before_request():
    request.start_time = time.time()
    ACTIVE_CONNECTIONS.inc()

@app.after_request
def after_request(response):
    # Latência
    request_latency = time.time() - request.start_time
    REQUEST_LATENCY.labels(
        method=request.method,
        endpoint=request.endpoint or 'unknown'
    ).observe(request_latency)
    
    # Contador de requisições
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.endpoint or 'unknown',
        status=response.status_code
    ).inc()
    
    ACTIVE_CONNECTIONS.dec()
    return response

@app.route('/')
def hello():
    # Simular processamento
    time.sleep(random.uniform(0.1, 0.5))
    return 'Hello World!'

@app.route('/error')
def error():
    ERROR_COUNT.labels(error_type='simulated').inc()
    return 'Error!', 500

@app.route('/health')
def health():
    return 'OK'

if __name__ == '__main__':
    # Iniciar servidor de métricas na porta 8000
    start_http_server(8000)
    
    # Iniciar aplicação na porta 5000
    app.run(host='0.0.0.0', port=5000)
```

### **☕ Java com Micrometer**

```java
// Application.java
@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @Bean
    public MeterRegistry meterRegistry() {
        return new PrometheusMeterRegistry(PrometheusConfig.DEFAULT);
    }
}

// Controller.java
@RestController
public class ApiController {
    
    private final Counter requestCounter;
    private final Timer requestTimer;
    private final Gauge activeConnections;
    
    public ApiController(MeterRegistry meterRegistry) {
        this.requestCounter = Counter.builder("http_requests_total")
            .description("Total HTTP requests")
            .tag("application", "demo")
            .register(meterRegistry);
            
        this.requestTimer = Timer.builder("http_request_duration_seconds")
            .description("HTTP request duration")
            .register(meterRegistry);
            
        this.activeConnections = Gauge.builder("active_connections")
            .description("Active connections")
            .register(meterRegistry, this, ApiController::getActiveConnections);
    }
    
    @GetMapping("/api/data")
    public ResponseEntity<String> getData() {
        return requestTimer.recordCallable(() -> {
            requestCounter.increment(Tags.of("endpoint", "/api/data", "method", "GET"));
            
            // Simular processamento
            Thread.sleep(100);
            
            return ResponseEntity.ok("Data");
        });
    }
    
    private double getActiveConnections() {
        // Lógica para contar conexões ativas
        return 42.0;
    }
}
```

### **🟨 Node.js com prom-client**

```javascript
// app.js
const express = require('express');
const client = require('prom-client');

const app = express();

// Criar registry
const register = new client.Registry();

// Métricas padrão
client.collectDefaultMetrics({ register });

// Métricas customizadas
const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status'],
  registers: [register]
});

const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route'],
  buckets: [0.1, 0.5, 1, 2, 5],
  registers: [register]
});

const activeConnections = new client.Gauge({
  name: 'active_connections',
  help: 'Number of active connections',
  registers: [register]
});

// Middleware para métricas
app.use((req, res, next) => {
  const start = Date.now();
  
  activeConnections.inc();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    
    httpRequestsTotal
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .inc();
    
    httpRequestDuration
      .labels(req.method, req.route?.path || req.path)
      .observe(duration);
    
    activeConnections.dec();
  });
  
  next();
});

// Rotas
app.get('/', (req, res) => {
  res.send('Hello World!');
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.listen(3000, () => {
  console.log('App listening on port 3000');
});
```

---

## 🎓 RESUMO DO MÓDULO

### **Conceitos Aprendidos:**
- ✅ **Tipos de métricas:** Counter, Gauge, Histogram, Summary
- ✅ **Node Exporter:** Métricas de sistema operacional
- ✅ **cAdvisor:** Métricas de containers
- ✅ **Blackbox Exporter:** Monitoramento de endpoints
- ✅ **Exporters especializados:** MySQL, PostgreSQL, Redis
- ✅ **Instrumentação:** Python, Java, Node.js

### **Próximos Passos:**
1. 🔍 **[Módulo 05: PromQL Básico](05-promql-basico.md)** - Linguagem de consulta
2. 🔍 **[Módulo 06: PromQL Avançado](06-promql-avancado.md)** - Funções complexas
3. 🚨 **[Módulo 07: Regras de Alerta](07-regras-alerta.md)** - Alertas eficazes

---

**📚 Módulo Anterior:** [03 - Arquivo de Configuração](03-arquivo-config.md)  
**📚 Próximo Módulo:** [05 - PromQL Básico](05-promql-basico.md)  
**🏠 Voltar ao:** [README Principal](README.md)

---

*Módulo criado pela comunidade DevOps*  
*Última atualização: Janeiro 2025*