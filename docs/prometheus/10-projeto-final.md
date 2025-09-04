# 🚀 MÓDULO 10: PROJETO FINAL

> **Objetivo:** Implementar um projeto completo de monitoramento com Prometheus  
> **Duração:** 3-4 horas  
> **Nível:** Avançado

---

## 🎯 VISÃO GERAL DO PROJETO

### **🏗️ Arquitetura do Projeto**

Vamos criar um **Sistema de Monitoramento Completo** para uma aplicação web fictícia com:

```mermaid
graph TB
    subgraph "Application Stack"
        APP["Web Application<br/>(Node.js + Express)"]
        DB["Database<br/>(PostgreSQL)"]
        REDIS["Cache<br/>(Redis)"]
        NGINX["Load Balancer<br/>(Nginx)"]
    end
    
    subgraph "Monitoring Stack"
        PROM["Prometheus<br/>(Metrics Collection)"]
        GRAF["Grafana<br/>(Visualization)"]
        ALERT["Alertmanager<br/>(Notifications)"]
    end
    
    subgraph "Exporters"
        NODE["Node Exporter<br/>(System Metrics)"]
        POSTGRES["Postgres Exporter<br/>(DB Metrics)"]
        REDIS_EXP["Redis Exporter<br/>(Cache Metrics)"]
        NGINX_EXP["Nginx Exporter<br/>(Web Metrics)"]
    end
    
    APP --> PROM
    DB --> POSTGRES
    REDIS --> REDIS_EXP
    NGINX --> NGINX_EXP
    NODE --> PROM
    POSTGRES --> PROM
    REDIS_EXP --> PROM
    NGINX_EXP --> PROM
    
    PROM --> GRAF
    PROM --> ALERT
```

### **📋 Requisitos do Projeto**

```yaml
functional_requirements:
  monitoring:
    - "Coletar métricas de sistema (CPU, RAM, Disk, Network)"
    - "Monitorar aplicação web (requests, errors, latency)"
    - "Acompanhar banco de dados (connections, queries, locks)"
    - "Observar cache Redis (memory, hits, misses)"
    - "Supervisionar load balancer (upstream status)"
  
  alerting:
    - "Alertas críticos para downtime"
    - "Alertas de performance (high CPU, memory)"
    - "Alertas de aplicação (error rate, slow queries)"
    - "Notificações via Slack e email"
  
  visualization:
    - "Dashboard executivo (overview)"
    - "Dashboard técnico (detailed metrics)"
    - "Dashboard de troubleshooting"
    - "SLA/SLO tracking"

non_functional_requirements:
  performance:
    - "Retenção de dados: 30 dias"
    - "Scrape interval: 15s"
    - "Query timeout: 60s"
  
  reliability:
    - "Alta disponibilidade do Prometheus"
    - "Backup automático de configurações"
    - "Disaster recovery procedures"
  
  security:
    - "Autenticação básica"
    - "TLS/SSL para comunicação"
    - "Network segmentation"
```

---

## 🏗️ IMPLEMENTAÇÃO PASSO A PASSO

### **📁 Estrutura do Projeto**

```bash
# Criar estrutura completa
mkdir -p monitoring-project/{app,monitoring,configs,scripts,docs}
cd monitoring-project

# Estrutura final:
# monitoring-project/
# ├── app/                     # Aplicação de exemplo
# │   ├── src/
# │   ├── package.json
# │   └── Dockerfile
# ├── monitoring/              # Stack de monitoramento
# │   ├── prometheus/
# │   ├── grafana/
# │   ├── alertmanager/
# │   └── exporters/
# ├── configs/                 # Configurações
# │   ├── nginx/
# │   ├── postgres/
# │   └── redis/
# ├── scripts/                 # Scripts de automação
# │   ├── setup.sh
# │   ├── backup.sh
# │   └── health-check.sh
# ├── docs/                    # Documentação
# │   ├── README.md
# │   ├── ARCHITECTURE.md
# │   └── RUNBOOK.md
# └── docker-compose.yml       # Orquestração completa
```

### **🐳 Docker Compose Principal**

```yaml
# docker-compose.yml
version: '3.8'

networks:
  monitoring:
    driver: bridge
  app:
    driver: bridge

volumes:
  prometheus_data:
  grafana_data:
  postgres_data:
  redis_data:

services:
  # === APPLICATION STACK ===
  app:
    build: ./app
    container_name: web-app
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=postgres
      - REDIS_HOST=redis
    depends_on:
      - postgres
      - redis
    networks:
      - app
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  postgres:
    image: postgres:15-alpine
    container_name: postgres-db
    environment:
      POSTGRES_DB: webapp
      POSTGRES_USER: webapp
      POSTGRES_PASSWORD: webapp123
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./configs/postgres/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U webapp"]
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    image: redis:7-alpine
    container_name: redis-cache
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - app
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  nginx:
    image: nginx:alpine
    container_name: nginx-lb
    ports:
      - "80:80"
      - "8080:8080"  # Status page
    volumes:
      - ./configs/nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./configs/nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - app
    networks:
      - app
      - monitoring
    restart: unless-stopped

  # === MONITORING STACK ===
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./monitoring/prometheus/rules:/etc/prometheus/rules
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
      - '--log.level=info'
    networks:
      - monitoring
      - app
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9090/-/healthy"]
      interval: 30s
      timeout: 10s
      retries: 3

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-worldmap-panel,grafana-clock-panel
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards
    depends_on:
      - prometheus
    networks:
      - monitoring
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./monitoring/alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://localhost:9093'
      - '--log.level=info'
    networks:
      - monitoring
    restart: unless-stopped

  # === EXPORTERS ===
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    command:
      - '--path.rootfs=/host'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - '/:/host:ro,rslave'
    networks:
      - monitoring
    restart: unless-stopped

  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:latest
    container_name: postgres-exporter
    ports:
      - "9187:9187"
    environment:
      DATA_SOURCE_NAME: "postgresql://webapp:webapp123@postgres:5432/webapp?sslmode=disable"
    depends_on:
      - postgres
    networks:
      - monitoring
      - app
    restart: unless-stopped

  redis-exporter:
    image: oliver006/redis_exporter:latest
    container_name: redis-exporter
    ports:
      - "9121:9121"
    environment:
      REDIS_ADDR: "redis://redis:6379"
    depends_on:
      - redis
    networks:
      - monitoring
      - app
    restart: unless-stopped

  nginx-exporter:
    image: nginx/nginx-prometheus-exporter:latest
    container_name: nginx-exporter
    ports:
      - "9113:9113"
    command:
      - '-nginx.scrape-uri=http://nginx:8080/nginx_status'
    depends_on:
      - nginx
    networks:
      - monitoring
    restart: unless-stopped
```

### **🎯 Aplicação de Exemplo (Node.js)**

```javascript
// app/src/app.js
const express = require('express');
const prometheus = require('prom-client');
const { Pool } = require('pg');
const redis = require('redis');

const app = express();
const port = process.env.PORT || 3000;

// === PROMETHEUS METRICS ===
const register = new prometheus.Registry();
prometheus.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new prometheus.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10]
});

const httpRequestsTotal = new prometheus.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status']
});

const activeConnections = new prometheus.Gauge({
  name: 'active_connections',
  help: 'Number of active connections'
});

const businessMetrics = new prometheus.Counter({
  name: 'business_transactions_total',
  help: 'Total business transactions',
  labelNames: ['type', 'status']
});

register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestsTotal);
register.registerMetric(activeConnections);
register.registerMetric(businessMetrics);

// === DATABASE CONNECTION ===
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: 5432,
  database: 'webapp',
  user: 'webapp',
  password: 'webapp123',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// === REDIS CONNECTION ===
const redisClient = redis.createClient({
  host: process.env.REDIS_HOST || 'localhost',
  port: 6379
});

redisClient.on('error', (err) => {
  console.error('Redis error:', err);
});

// === MIDDLEWARE ===
app.use(express.json());

// Metrics middleware
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;
    
    httpRequestDuration
      .labels(req.method, route, res.statusCode)
      .observe(duration);
    
    httpRequestsTotal
      .labels(req.method, route, res.statusCode)
      .inc();
  });
  
  next();
});

// === ROUTES ===

// Health check
app.get('/health', async (req, res) => {
  try {
    // Check database
    await pool.query('SELECT 1');
    
    // Check Redis
    await redisClient.ping();
    
    res.json({ 
      status: 'healthy', 
      timestamp: new Date().toISOString(),
      services: {
        database: 'up',
        cache: 'up'
      }
    });
  } catch (error) {
    res.status(503).json({ 
      status: 'unhealthy', 
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// API endpoints
app.get('/api/users', async (req, res) => {
  try {
    const result = await pool.query('SELECT id, name, email FROM users LIMIT 10');
    
    // Cache result
    await redisClient.setex('users:list', 300, JSON.stringify(result.rows));
    
    businessMetrics.labels('user_query', 'success').inc();
    res.json(result.rows);
  } catch (error) {
    businessMetrics.labels('user_query', 'error').inc();
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/users', async (req, res) => {
  try {
    const { name, email } = req.body;
    
    if (!name || !email) {
      return res.status(400).json({ error: 'Name and email are required' });
    }
    
    const result = await pool.query(
      'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
      [name, email]
    );
    
    // Invalidate cache
    await redisClient.del('users:list');
    
    businessMetrics.labels('user_creation', 'success').inc();
    res.status(201).json(result.rows[0]);
  } catch (error) {
    businessMetrics.labels('user_creation', 'error').inc();
    res.status(500).json({ error: error.message });
  }
});

// Simulate load endpoint
app.get('/api/load/:duration', (req, res) => {
  const duration = parseInt(req.params.duration) || 1000;
  const start = Date.now();
  
  // Simulate CPU intensive task
  while (Date.now() - start < duration) {
    Math.random() * Math.random();
  }
  
  res.json({ 
    message: `Load simulation completed`,
    duration: duration,
    timestamp: new Date().toISOString()
  });
});

// Error simulation endpoint
app.get('/api/error/:rate', (req, res) => {
  const errorRate = parseFloat(req.params.rate) || 0.1;
  
  if (Math.random() < errorRate) {
    res.status(500).json({ error: 'Simulated error' });
  } else {
    res.json({ message: 'Success' });
  }
});

// === SERVER STARTUP ===
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
  
  // Update active connections metric
  setInterval(() => {
    activeConnections.set(Math.floor(Math.random() * 100));
  }, 5000);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  pool.end();
  redisClient.quit();
  process.exit(0);
});
```

```json
// app/package.json
{
  "name": "monitoring-demo-app",
  "version": "1.0.0",
  "description": "Demo application for Prometheus monitoring",
  "main": "src/app.js",
  "scripts": {
    "start": "node src/app.js",
    "dev": "nodemon src/app.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "express": "^4.18.2",
    "prom-client": "^14.2.0",
    "pg": "^8.11.0",
    "redis": "^4.6.7"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  },
  "engines": {
    "node": ">=16.0.0"
  }
}
```

```dockerfile
# app/Dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY src/ ./src/

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# Change ownership
RUN chown -R nodejs:nodejs /app
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))"

# Start application
CMD ["npm", "start"]
```

### **⚙️ Configuração do Prometheus**

```yaml
# monitoring/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'monitoring-demo'
    environment: 'production'

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
    scrape_interval: 30s
    metrics_path: /metrics

  # Application
  - job_name: 'web-application'
    static_configs:
      - targets: ['app:3000']
    scrape_interval: 15s
    metrics_path: /metrics
    scrape_timeout: 10s

  # System metrics
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
    scrape_interval: 15s

  # Database metrics
  - job_name: 'postgres-exporter'
    static_configs:
      - targets: ['postgres-exporter:9187']
    scrape_interval: 30s

  # Cache metrics
  - job_name: 'redis-exporter'
    static_configs:
      - targets: ['redis-exporter:9121']
    scrape_interval: 30s

  # Load balancer metrics
  - job_name: 'nginx-exporter'
    static_configs:
      - targets: ['nginx-exporter:9113']
    scrape_interval: 30s

  # Alertmanager
  - job_name: 'alertmanager'
    static_configs:
      - targets: ['alertmanager:9093']
    scrape_interval: 30s

  # Grafana
  - job_name: 'grafana'
    static_configs:
      - targets: ['grafana:3000']
    scrape_interval: 30s
    metrics_path: /metrics
```

### **🚨 Regras de Alerta Completas**

```yaml
# monitoring/prometheus/rules/application.yml
groups:
  - name: application.rules
    rules:
      # === APPLICATION HEALTH ===
      - alert: ApplicationDown
        expr: up{job="web-application"} == 0
        for: 1m
        labels:
          severity: critical
          team: backend
          service: web-app
        annotations:
          summary: "Application {{ $labels.instance }} is down"
          description: "Application has been down for more than 1 minute."
          runbook_url: "https://wiki.company.com/runbooks/app-down"

      - alert: HighErrorRate
        expr: |
          (
            sum(rate(http_requests_total{job="web-application",status=~"5.."}[5m]))
            /
            sum(rate(http_requests_total{job="web-application"}[5m]))
          ) * 100 > 5
        for: 5m
        labels:
          severity: warning
          team: backend
          service: web-app
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }}% for the last 5 minutes."

      - alert: HighLatency
        expr: |
          histogram_quantile(0.95, 
            sum(rate(http_request_duration_seconds_bucket{job="web-application"}[5m])) by (le)
          ) > 2
        for: 10m
        labels:
          severity: warning
          team: backend
          service: web-app
        annotations:
          summary: "High latency detected"
          description: "95th percentile latency is {{ $value }}s for the last 10 minutes."

      # === BUSINESS METRICS ===
      - alert: LowTransactionRate
        expr: |
          sum(rate(business_transactions_total{type="user_creation",status="success"}[10m])) < 0.1
        for: 15m
        labels:
          severity: warning
          team: product
          service: web-app
        annotations:
          summary: "Low user registration rate"
          description: "User registration rate is {{ $value }} per second."

  - name: infrastructure.rules
    rules:
      # === SYSTEM RESOURCES ===
      - alert: HighCPUUsage
        expr: |
          100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 10m
        labels:
          severity: warning
          team: infrastructure
          service: system
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ $value }}% for the last 10 minutes."

      - alert: HighMemoryUsage
        expr: |
          (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
          team: infrastructure
          service: system
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is {{ $value }}% for the last 5 minutes."

      - alert: DiskSpaceLow
        expr: |
          (1 - (node_filesystem_free_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100 > 90
        for: 5m
        labels:
          severity: critical
          team: infrastructure
          service: system
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Disk usage is {{ $value }}% on {{ $labels.mountpoint }}."

  - name: database.rules
    rules:
      # === DATABASE HEALTH ===
      - alert: PostgreSQLDown
        expr: pg_up == 0
        for: 1m
        labels:
          severity: critical
          team: database
          service: postgresql
        annotations:
          summary: "PostgreSQL is down"
          description: "PostgreSQL database is not responding."

      - alert: HighDatabaseConnections
        expr: |
          (pg_stat_database_numbackends / pg_settings_max_connections) * 100 > 80
        for: 5m
        labels:
          severity: warning
          team: database
          service: postgresql
        annotations:
          summary: "High database connection usage"
          description: "Database connection usage is {{ $value }}%."

      - alert: SlowQueries
        expr: |
          rate(pg_stat_database_tup_fetched[5m]) / rate(pg_stat_database_tup_returned[5m]) < 0.1
        for: 10m
        labels:
          severity: warning
          team: database
          service: postgresql
        annotations:
          summary: "Slow database queries detected"
          description: "Query efficiency is low: {{ $value }}."

  - name: cache.rules
    rules:
      # === REDIS HEALTH ===
      - alert: RedisDown
        expr: redis_up == 0
        for: 1m
        labels:
          severity: critical
          team: infrastructure
          service: redis
        annotations:
          summary: "Redis is down"
          description: "Redis cache server is not responding."

      - alert: HighRedisMemoryUsage
        expr: |
          (redis_memory_used_bytes / redis_memory_max_bytes) * 100 > 90
        for: 5m
        labels:
          severity: warning
          team: infrastructure
          service: redis
        annotations:
          summary: "High Redis memory usage"
          description: "Redis memory usage is {{ $value }}%."

      - alert: LowCacheHitRate
        expr: |
          (rate(redis_keyspace_hits_total[5m]) / (rate(redis_keyspace_hits_total[5m]) + rate(redis_keyspace_misses_total[5m]))) * 100 < 80
        for: 10m
        labels:
          severity: warning
          team: backend
          service: redis
        annotations:
          summary: "Low cache hit rate"
          description: "Cache hit rate is {{ $value }}% for the last 10 minutes."
```

### **📧 Configuração do Alertmanager**

```yaml
# monitoring/alertmanager/alertmanager.yml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@company.com'
  smtp_auth_username: 'alerts@company.com'
  smtp_auth_password: 'your-app-password'

templates:
  - '/etc/alertmanager/templates/*.tmpl'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'default'
  routes:
    # Critical alerts go to multiple channels
    - match:
        severity: critical
      receiver: 'critical-alerts'
      group_wait: 5s
      repeat_interval: 30m
    
    # Team-specific routing
    - match:
        team: backend
      receiver: 'backend-team'
    
    - match:
        team: infrastructure
      receiver: 'infrastructure-team'
    
    - match:
        team: database
      receiver: 'database-team'
    
    # Business hours vs off-hours
    - match:
        severity: warning
      receiver: 'business-hours'
      active_time_intervals:
        - business-hours
    
    - match:
        severity: warning
      receiver: 'off-hours'
      active_time_intervals:
        - off-hours

time_intervals:
  - name: business-hours
    time_intervals:
      - times:
          - start_time: '09:00'
            end_time: '18:00'
        weekdays: ['monday:friday']
        location: 'America/Sao_Paulo'
  
  - name: off-hours
    time_intervals:
      - times:
          - start_time: '18:01'
            end_time: '08:59'
        weekdays: ['monday:friday']
        location: 'America/Sao_Paulo'
      - weekdays: ['saturday', 'sunday']
        location: 'America/Sao_Paulo'

receivers:
  - name: 'default'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#alerts'
        title: '🚨 {{ .GroupLabels.alertname }}'
        text: |
          {{ range .Alerts }}
          *Alert:* {{ .Annotations.summary }}
          *Description:* {{ .Annotations.description }}
          *Severity:* {{ .Labels.severity }}
          *Service:* {{ .Labels.service }}
          {{ end }}
        send_resolved: true

  - name: 'critical-alerts'
    email_configs:
      - to: 'oncall@company.com'
        subject: '🚨 CRITICAL: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Severity: {{ .Labels.severity }}
          Service: {{ .Labels.service }}
          Instance: {{ .Labels.instance }}
          
          Runbook: {{ .Annotations.runbook_url }}
          {{ end }}
    
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#critical-alerts'
        title: '🚨 CRITICAL: {{ .GroupLabels.alertname }}'
        text: |
          <!channel>
          {{ range .Alerts }}
          *Alert:* {{ .Annotations.summary }}
          *Description:* {{ .Annotations.description }}
          *Severity:* {{ .Labels.severity }}
          *Service:* {{ .Labels.service }}
          *Runbook:* {{ .Annotations.runbook_url }}
          {{ end }}
        send_resolved: true

  - name: 'backend-team'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#backend-alerts'
        title: '⚠️ Backend Alert: {{ .GroupLabels.alertname }}'
        send_resolved: true

  - name: 'infrastructure-team'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#infrastructure-alerts'
        title: '🔧 Infrastructure Alert: {{ .GroupLabels.alertname }}'
        send_resolved: true

  - name: 'database-team'
    email_configs:
      - to: 'dba@company.com'
        subject: '🗄️ Database Alert: {{ .GroupLabels.alertname }}'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#database-alerts'
        title: '🗄️ Database Alert: {{ .GroupLabels.alertname }}'
        send_resolved: true

  - name: 'business-hours'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#alerts'
        title: '⚠️ {{ .GroupLabels.alertname }}'
        send_resolved: true

  - name: 'off-hours'
    email_configs:
      - to: 'oncall@company.com'
        subject: '⚠️ Off-Hours Alert: {{ .GroupLabels.alertname }}'

inhibit_rules:
  # Inhibit warning alerts when critical alerts are firing
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']
  
  # Inhibit application alerts when system is down
  - source_match:
      alertname: 'ApplicationDown'
    target_match_re:
      alertname: '(HighErrorRate|HighLatency)'
    equal: ['instance']
```

---

## 📊 DASHBOARDS COMPLETOS

### **🎯 Dashboard Executivo**

```json
{
  "dashboard": {
    "id": null,
    "title": "Executive Dashboard - System Overview",
    "tags": ["executive", "overview", "sla"],
    "timezone": "browser",
    "refresh": "1m",
    "time": {
      "from": "now-24h",
      "to": "now"
    },
    "templating": {
      "list": [
        {
          "name": "environment",
          "type": "custom",
          "query": "production,staging,development",
          "current": {
            "value": "production",
            "text": "production"
          }
        }
      ]
    },
    "panels": [
      {
        "title": "System Health Score",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "avg(up) * 100",
            "legendFormat": "Health Score"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100,
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "yellow", "value": 95},
                {"color": "green", "value": 99}
              ]
            }
          }
        }
      },
      {
        "title": "Active Alerts",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 6, "y": 0},
        "targets": [
          {
            "expr": "count(ALERTS{alertstate=\"firing\"})",
            "legendFormat": "Active Alerts"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                {"color": "green", "value": 0},
                {"color": "yellow", "value": 1},
                {"color": "red", "value": 5}
              ]
            }
          }
        }
      },
      {
        "title": "Request Rate",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m]))",
            "legendFormat": "Requests/sec"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "reqps"
          }
        }
      },
      {
        "title": "Error Rate",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 18, "y": 0},
        "targets": [
          {
            "expr": "(sum(rate(http_requests_total{status=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m]))) * 100",
            "legendFormat": "Error Rate"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "thresholds": {
              "steps": [
                {"color": "green", "value": 0},
                {"color": "yellow", "value": 1},
                {"color": "red", "value": 5}
              ]
            }
          }
        }
      },
      {
        "title": "Service Availability (24h)",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "avg_over_time(up{job=\"web-application\"}[1h]) * 100",
            "legendFormat": "Web Application"
          },
          {
            "expr": "avg_over_time(pg_up[1h]) * 100",
            "legendFormat": "Database"
          },
          {
            "expr": "avg_over_time(redis_up[1h]) * 100",
            "legendFormat": "Cache"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 95,
            "max": 100
          }
        }
      },
      {
        "title": "Business Metrics",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
        "targets": [
          {
            "expr": "sum(rate(business_transactions_total{type=\"user_creation\",status=\"success\"}[5m])) * 3600",
            "legendFormat": "User Registrations/hour"
          },
          {
            "expr": "sum(rate(business_transactions_total{type=\"user_query\",status=\"success\"}[5m])) * 3600",
            "legendFormat": "User Queries/hour"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "short"
          }
        }
      }
    ]
  }
}
```

---

## 🧪 TESTES E VALIDAÇÃO

### **🔍 Scripts de Teste**

```bash
#!/bin/bash
# scripts/test-monitoring.sh

echo "🧪 Testing Monitoring Stack..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test functions
test_service() {
    local service_name=$1
    local url=$2
    local expected_status=$3
    
    echo -n "Testing $service_name... "
    
    status_code=$(curl -s -o /dev/null -w "%{http_code}" $url)
    
    if [ $status_code -eq $expected_status ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        return 0
    else
        echo -e "${RED}✗ FAIL (Status: $status_code)${NC}"
        return 1
    fi
}

test_metrics() {
    local service_name=$1
    local url=$2
    local metric_name=$3
    
    echo -n "Testing $service_name metrics... "
    
    if curl -s $url | grep -q $metric_name; then
        echo -e "${GREEN}✓ PASS${NC}"
        return 0
    else
        echo -e "${RED}✗ FAIL (Metric not found)${NC}"
        return 1
    fi
}

# === BASIC CONNECTIVITY TESTS ===
echo "\n📡 Basic Connectivity Tests"
test_service "Prometheus" "http://localhost:9090/-/healthy" 200
test_service "Grafana" "http://localhost:3001/api/health" 200
test_service "Alertmanager" "http://localhost:9093/-/healthy" 200
test_service "Application" "http://localhost:3000/health" 200
test_service "Node Exporter" "http://localhost:9100/metrics" 200

# === METRICS TESTS ===
echo "\n📊 Metrics Availability Tests"
test_metrics "Application" "http://localhost:3000/metrics" "http_requests_total"
test_metrics "Application" "http://localhost:3000/metrics" "business_transactions_total"
test_metrics "Node Exporter" "http://localhost:9100/metrics" "node_cpu_seconds_total"
test_metrics "Postgres Exporter" "http://localhost:9187/metrics" "pg_up"
test_metrics "Redis Exporter" "http://localhost:9121/metrics" "redis_up"

# === PROMETHEUS TARGETS ===
echo "\n🎯 Prometheus Targets Test"
targets_up=$(curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | map(select(.health == "up")) | length')
targets_total=$(curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length')

echo "Targets UP: $targets_up/$targets_total"

if [ $targets_up -eq $targets_total ]; then
    echo -e "${GREEN}✓ All targets are UP${NC}"
else
    echo -e "${YELLOW}⚠ Some targets are DOWN${NC}"
fi

# === ALERT RULES ===
echo "\n🚨 Alert Rules Test"
rules_loaded=$(curl -s http://localhost:9090/api/v1/rules | jq '.data.groups | length')
echo "Alert rule groups loaded: $rules_loaded"

if [ $rules_loaded -gt 0 ]; then
    echo -e "${GREEN}✓ Alert rules loaded${NC}"
else
    echo -e "${RED}✗ No alert rules loaded${NC}"
fi

# === LOAD TEST ===
echo "\n🔥 Load Test"
echo "Generating load for 30 seconds..."

for i in {1..30}; do
    curl -s http://localhost:3000/api/users > /dev/null &
    curl -s http://localhost:3000/api/load/100 > /dev/null &
    sleep 1
done

wait
echo -e "${GREEN}✓ Load test completed${NC}"

# === ALERT TEST ===
echo "\n⚠️ Alert Test"
echo "Triggering error simulation..."

for i in {1..20}; do
    curl -s http://localhost:3000/api/error/0.8 > /dev/null
    sleep 1
done

echo -e "${YELLOW}⚠ Check Alertmanager for fired alerts${NC}"

echo "\n🎉 Monitoring stack test completed!"
echo "\n📊 Access points:"
echo "  - Prometheus: http://localhost:9090"
echo "  - Grafana: http://localhost:3001 (admin/admin123)"
echo "  - Alertmanager: http://localhost:9093"
echo "  - Application: http://localhost:3000"
```

### **📈 Teste de Carga**

```bash
#!/bin/bash
# scripts/load-test.sh

echo "🔥 Starting comprehensive load test..."

# Configuration
DURATION=300  # 5 minutes
CONCURRENCY=10
APP_URL="http://localhost:3000"

# Function to generate load
generate_load() {
    local endpoint=$1
    local requests=$2
    local delay=$3
    
    for i in $(seq 1 $requests); do
        curl -s "$APP_URL$endpoint" > /dev/null
        sleep $delay
    done
}

echo "Starting load generation..."
echo "Duration: ${DURATION}s"
echo "Concurrency: ${CONCURRENCY}"
echo "Target: $APP_URL"

# Start background load generators
for i in $(seq 1 $CONCURRENCY); do
    {
        while true; do
            # Normal requests
            generate_load "/api/users" 5 0.2
            
            # Create users
            curl -s -X POST "$APP_URL/api/users" \
                -H "Content-Type: application/json" \
                -d '{"name":"User'$i'","email":"user'$i'@test.com"}' > /dev/null
            
            # Load simulation
            generate_load "/api/load/500" 1 1
            
            # Error simulation (10% error rate)
            generate_load "/api/error/0.1" 3 0.5
            
            sleep 1
        done
    } &
done

echo "Load generators started (PID: $!)..."
echo "Running for ${DURATION} seconds..."

# Wait for specified duration
sleep $DURATION

# Kill all background jobs
kill $(jobs -p) 2>/dev/null

echo "\n🎉 Load test completed!"
echo "\n📊 Check these metrics in Grafana:"
echo "  - Request rate: sum(rate(http_requests_total[5m]))"
echo "  - Error rate: sum(rate(http_requests_total{status=~\"5..\"}[5m]))"
echo "  - Latency: histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))"
echo "  - System resources: CPU, Memory, Disk usage"
```

---

## 🚀 DEPLOYMENT E EXECUÇÃO

### **📋 Checklist de Deploy**

```bash
#!/bin/bash
# scripts/deploy.sh

echo "🚀 Deploying Monitoring Stack..."

# Pre-deployment checks
echo "\n🔍 Pre-deployment checks..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker."
    exit 1
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose not found. Please install Docker Compose."
    exit 1
fi

# Check required files
required_files=(
    "docker-compose.yml"
    "monitoring/prometheus/prometheus.yml"
    "monitoring/alertmanager/alertmanager.yml"
    "app/package.json"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Required file not found: $file"
        exit 1
    fi
done

echo "✅ Pre-deployment checks passed"

# Create necessary directories
echo "\n📁 Creating directories..."
mkdir -p {\
    monitoring/{prometheus/rules,grafana/{provisioning/{datasources,dashboards},dashboards},alertmanager},\
    configs/{nginx,postgres,redis},\
    scripts,\
    docs\
}

# Set permissions
echo "\n🔐 Setting permissions..."
sudo chown -R 472:472 monitoring/grafana/  # Grafana user
sudo chown -R 65534:65534 monitoring/prometheus/  # Nobody user

# Build application
echo "\n🏗️ Building application..."
docker-compose build app

# Start services
echo "\n🚀 Starting services..."
docker-compose up -d

# Wait for services to be ready
echo "\n⏳ Waiting for services to be ready..."
sleep 30

# Health checks
echo "\n🏥 Running health checks..."
./scripts/test-monitoring.sh

# Import Grafana dashboards
echo "\n📊 Importing Grafana dashboards..."
# This would typically involve API calls to Grafana

echo "\n🎉 Deployment completed!"
echo "\n📊 Access URLs:"
echo "  - Prometheus: http://localhost:9090"
echo "  - Grafana: http://localhost:3001 (admin/admin123)"
echo "  - Alertmanager: http://localhost:9093"
echo "  - Application: http://localhost:3000"
echo "  - Application Health: http://localhost:3000/health"

echo "\n📚 Next steps:"
echo "  1. Configure Slack/Email notifications in Alertmanager"
echo "  2. Import custom dashboards in Grafana"
echo "  3. Run load tests: ./scripts/load-test.sh"
echo "  4. Review alert rules and thresholds"
echo "  5. Set up backup procedures"
```

### **🔧 Script de Manutenção**

```bash
#!/bin/bash
# scripts/maintenance.sh

echo "🔧 Monitoring Stack Maintenance"

show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  status      Show service status"
    echo "  logs        Show service logs"
    echo "  backup      Backup configurations and data"
    echo "  restore     Restore from backup"
    echo "  update      Update all services"
    echo "  cleanup     Clean up old data"
    echo "  restart     Restart all services"
    echo "  help        Show this help"
}

show_status() {
    echo "\n📊 Service Status:"
    docker-compose ps
    
    echo "\n🎯 Prometheus Targets:"
    curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.labels.job): \(.health)"'
    
    echo "\n🚨 Active Alerts:"
    curl -s http://localhost:9090/api/v1/alerts | jq -r '.data.alerts[] | "\(.labels.alertname): \(.state)"'
}

show_logs() {
    echo "\n📋 Recent logs:"
    docker-compose logs --tail=50 --timestamps
}

backup_data() {
    echo "\n💾 Creating backup..."
    
    backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup configurations
    cp -r monitoring/ "$backup_dir/"
    cp -r configs/ "$backup_dir/"
    cp docker-compose.yml "$backup_dir/"
    
    # Backup Prometheus data
    docker run --rm -v monitoring-project_prometheus_data:/data -v "$(pwd)/$backup_dir":/backup alpine tar czf /backup/prometheus_data.tar.gz -C /data .
    
    # Backup Grafana data
    docker run --rm -v monitoring-project_grafana_data:/data -v "$(pwd)/$backup_dir":/backup alpine tar czf /backup/grafana_data.tar.gz -C /data .
    
    echo "✅ Backup created: $backup_dir"
}

update_services() {
    echo "\n🔄 Updating services..."
    
    docker-compose pull
    docker-compose up -d
    
    echo "✅ Services updated"
}

cleanup_data() {
    echo "\n🧹 Cleaning up old data..."
    
    # Clean old backups (keep last 7 days)
    find backups/ -type d -mtime +7 -exec rm -rf {} +
    
    # Clean Docker
    docker system prune -f
    
    echo "✅ Cleanup completed"
}

restart_services() {
    echo "\n🔄 Restarting services..."
    
    docker-compose restart
    
    echo "✅ Services restarted"
}

# Main script logic
case "$1" in
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    backup)
        backup_data
        ;;
    update)
        update_services
        ;;
    cleanup)
        cleanup_data
        ;;
    restart)
        restart_services
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        show_help
        exit 1
        ;;
esac
```

---

## 🎓 ENTREGÁVEIS DO PROJETO

### **📋 Checklist Final**

```markdown
# 🎯 Projeto Final - Checklist de Entrega

## ✅ Infraestrutura
- [ ] Docker Compose configurado com todos os serviços
- [ ] Aplicação de exemplo funcionando
- [ ] Prometheus coletando métricas de todos os componentes
- [ ] Grafana com dashboards configurados
- [ ] Alertmanager com notificações funcionais
- [ ] Todos os exporters operacionais

## ✅ Monitoramento
- [ ] Métricas de sistema (CPU, RAM, Disk, Network)
- [ ] Métricas de aplicação (requests, errors, latency)
- [ ] Métricas de banco de dados (connections, queries)
- [ ] Métricas de cache (memory, hits, misses)
- [ ] Métricas de negócio (transactions, users)

## ✅ Alertas
- [ ] Alertas críticos (downtime, high error rate)
- [ ] Alertas de performance (CPU, memory, disk)
- [ ] Alertas de aplicação (slow queries, cache issues)
- [ ] Notificações configuradas (Slack/Email)
- [ ] Routing de alertas por equipe/severidade

## ✅ Dashboards
- [ ] Dashboard executivo (overview, SLA)
- [ ] Dashboard técnico (detailed metrics)
- [ ] Dashboard de troubleshooting
- [ ] Variáveis e templating funcionais
- [ ] Visualizações apropriadas para cada métrica

## ✅ Automação
- [ ] Scripts de deploy automatizado
- [ ] Scripts de teste e validação
- [ ] Scripts de backup e restore
- [ ] Scripts de manutenção
- [ ] Health checks automatizados

## ✅ Documentação
- [ ] README com instruções de setup
- [ ] Arquitetura documentada
- [ ] Runbooks para troubleshooting
- [ ] Procedimentos de backup/restore
- [ ] Guia de manutenção

## ✅ Testes
- [ ] Testes de conectividade
- [ ] Testes de métricas
- [ ] Testes de alertas
- [ ] Testes de carga
- [ ] Testes de failover
```

### **📚 Documentação Obrigatória**

```markdown
# README.md

# 🚀 Monitoring Stack - Projeto Final

## 📋 Visão Geral

Este projeto implementa um stack completo de monitoramento usando Prometheus, Grafana e Alertmanager para uma aplicação web Node.js com PostgreSQL e Redis.

## 🏗️ Arquitetura

- **Aplicação:** Node.js + Express
- **Banco de Dados:** PostgreSQL
- **Cache:** Redis
- **Load Balancer:** Nginx
- **Monitoramento:** Prometheus + Grafana + Alertmanager
- **Exporters:** Node, Postgres, Redis, Nginx

## 🚀 Quick Start

```bash
# 1. Clone o repositório
git clone <repository-url>
cd monitoring-project

# 2. Execute o deploy
./scripts/deploy.sh

# 3. Acesse os serviços
# - Prometheus: http://localhost:9090
# - Grafana: http://localhost:3001 (admin/admin123)
# - Alertmanager: http://localhost:9093
# - Aplicação: http://localhost:3000
```

## 📊 Dashboards Disponíveis

1. **Executive Dashboard** - Visão executiva com SLA/SLO
2. **Technical Dashboard** - Métricas detalhadas por componente
3. **Troubleshooting Dashboard** - Debug e análise de problemas

## 🚨 Alertas Configurados

- **Críticos:** Downtime, High Error Rate, Disk Full
- **Warning:** High CPU/Memory, Slow Queries, Low Cache Hit Rate
- **Info:** Deployment notifications, Maintenance windows

## 🔧 Manutenção

```bash
# Status dos serviços
./scripts/maintenance.sh status

# Backup
./scripts/maintenance.sh backup

# Logs
./scripts/maintenance.sh logs

# Restart
./scripts/maintenance.sh restart
```

## 📞 Suporte

- **Documentação:** [docs/](docs/)
- **Runbooks:** [docs/runbooks/](docs/runbooks/)
- **Issues:** [GitHub Issues](link)
```

---

## 🎯 EXERCÍCIOS DE VALIDAÇÃO

### **🧪 Exercício 1: Implementação Básica**

```yaml
task: "Implementar o stack básico"
requirements:
  - "Deploy completo com docker-compose"
  - "Todos os serviços funcionando"
  - "Métricas sendo coletadas"
  - "Dashboards básicos criados"
  - "Alertas básicos configurados"

validation:
  - "Todos os targets UP no Prometheus"
  - "Dashboards carregando dados"
  - "Alertas sendo avaliados"
  - "Health checks passando"

deliverables:
  - "docker-compose.yml funcional"
  - "Configurações do Prometheus"
  - "Dashboard básico no Grafana"
  - "Regras de alerta funcionais"
```

### **🧪 Exercício 2: Customização Avançada**

```yaml
task: "Customizar para caso de uso específico"
requirements:
  - "Adicionar métricas de negócio específicas"
  - "Criar dashboards personalizados"
  - "Configurar alertas inteligentes"
  - "Implementar SLA/SLO tracking"
  - "Adicionar automação"

validation:
  - "Métricas de negócio sendo coletadas"
  - "Dashboards refletem KPIs importantes"
  - "Alertas reduzem false positives"
  - "SLA/SLO calculados corretamente"

deliverables:
  - "Métricas customizadas na aplicação"
  - "Dashboards executivos"
  - "Alertas contextuais"
  - "Scripts de automação"
```

### **🧪 Exercício 3: Produção Ready**

```yaml
task: "Preparar para produção"
requirements:
  - "Implementar alta disponibilidade"
  - "Configurar backup/restore"
  - "Adicionar segurança (TLS, auth)"
  - "Otimizar performance"
  - "Documentar procedimentos"

validation:
  - "Sistema resiliente a falhas"
  - "Backups funcionais"
  - "Comunicação segura"
  - "Performance adequada"
  - "Documentação completa"

deliverables:
  - "Configuração HA"
  - "Procedimentos de backup"
  - "Configurações de segurança"
  - "Documentação operacional"
```

---

## 🏆 CRITÉRIOS DE AVALIAÇÃO

### **📊 Rubrica de Avaliação**

```yaml
funcionalidade: # 40 pontos
  excelente: # 36-40 pontos
    - "Todos os componentes funcionando perfeitamente"
    - "Métricas completas e precisas"
    - "Alertas inteligentes e úteis"
    - "Dashboards informativos e bem organizados"
  
  bom: # 28-35 pontos
    - "Maioria dos componentes funcionando"
    - "Métricas básicas implementadas"
    - "Alertas funcionais com alguns ajustes necessários"
    - "Dashboards básicos mas funcionais"
  
  satisfatorio: # 20-27 pontos
    - "Componentes básicos funcionando"
    - "Algumas métricas implementadas"
    - "Alertas básicos configurados"
    - "Dashboards simples"
  
  insatisfatorio: # 0-19 pontos
    - "Muitos componentes não funcionando"
    - "Métricas incompletas ou incorretas"
    - "Alertas não funcionais"
    - "Dashboards não informativos"

qualidade_tecnica: # 30 pontos
  excelente: # 27-30 pontos
    - "Código limpo e bem estruturado"
    - "Configurações otimizadas"
    - "Boas práticas seguidas"
    - "Performance adequada"
  
  bom: # 21-26 pontos
    - "Código organizado"
    - "Configurações funcionais"
    - "Algumas boas práticas aplicadas"
    - "Performance aceitável"
  
  satisfatorio: # 15-20 pontos
    - "Código funcional mas desorganizado"
    - "Configurações básicas"
    - "Poucas boas práticas"
    - "Performance limitada"
  
  insatisfatorio: # 0-14 pontos
    - "Código mal estruturado"
    - "Configurações inadequadas"
    - "Boas práticas ignoradas"
    - "Performance ruim"

documentacao: # 20 pontos
  excelente: # 18-20 pontos
    - "Documentação completa e clara"
    - "Instruções detalhadas"
    - "Runbooks úteis"
    - "Diagramas e exemplos"
  
  bom: # 14-17 pontos
    - "Documentação adequada"
    - "Instruções básicas"
    - "Alguns procedimentos documentados"
    - "Exemplos simples"
  
  satisfatorio: # 10-13 pontos
    - "Documentação mínima"
    - "Instruções básicas de setup"
    - "Poucos procedimentos"
    - "Exemplos limitados"
  
  insatisfatorio: # 0-9 pontos
    - "Documentação inadequada ou ausente"
    - "Instruções confusas"
    - "Procedimentos não documentados"
    - "Sem exemplos"

inovacao: # 10 pontos
  excelente: # 9-10 pontos
    - "Implementações criativas"
    - "Automação avançada"
    - "Métricas inovadoras"
    - "Soluções elegantes"
  
  bom: # 7-8 pontos
    - "Algumas implementações criativas"
    - "Automação básica"
    - "Métricas interessantes"
    - "Soluções funcionais"
  
  satisfatorio: # 5-6 pontos
    - "Implementação padrão"
    - "Pouca automação"
    - "Métricas básicas"
    - "Soluções simples"
  
  insatisfatorio: # 0-4 pontos
    - "Implementação básica demais"
    - "Sem automação"
    - "Métricas mínimas"
    - "Soluções inadequadas"
```

---

## 🎓 RESUMO DO MÓDULO

### **Conceitos Implementados:**
- ✅ **Arquitetura:** Stack completo de monitoramento
- ✅ **Aplicação:** Node.js com métricas customizadas
- ✅ **Infraestrutura:** Docker Compose orquestrado
- ✅ **Monitoramento:** Prometheus multi-target
- ✅ **Visualização:** Dashboards Grafana avançados
- ✅ **Alertas:** Alertmanager com routing inteligente
- ✅ **Automação:** Scripts de deploy e manutenção
- ✅ **Testes:** Validação e load testing
- ✅ **Documentação:** Procedimentos operacionais

### **Habilidades Desenvolvidas:**
1. 🏗️ **Arquitetura:** Design de sistemas observáveis
2. 🔧 **Implementação:** Deploy de stack completo
3. 📊 **Visualização:** Criação de dashboards eficazes
4. 🚨 **Alertas:** Configuração de notificações inteligentes
5. 🧪 **Testes:** Validação e troubleshooting
6. 📚 **Documentação:** Procedimentos operacionais
7. 🚀 **Automação:** Scripts de manutenção
8. 🔍 **Troubleshooting:** Análise e resolução de problemas

### **Próximos Passos:**
1. 🚀 **Produção:** Implementar em ambiente real
2. 📈 **Escala:** Adaptar para múltiplos serviços
3. 🔒 **Segurança:** Implementar autenticação e TLS
4. 🌐 **Distribuição:** Monitoramento multi-cluster
5. 🤖 **ML/AI:** Detecção de anomalias avançada

---

**📚 Módulo Anterior:** [09 - Integração Grafana](09-integracao-grafana.md)  
**🏠 Voltar ao:** [README Principal](README.md)

---

*Projeto Final criado pela comunidade DevOps*  
*Última atualização: Janeiro 2025*

**🎉 PARABÉNS! Você completou o curso completo de Prometheus!**

*Agora você tem todas as habilidades necessárias para implementar monitoramento profissional em produção.*