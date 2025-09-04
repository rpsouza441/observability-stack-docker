# 🎯 Módulo 10: Projeto Final - Sistema Completo de Alertas

## 📋 Visão Geral

Neste módulo final, você implementará um **sistema completo de alertas** que integra todos os conceitos aprendidos nos módulos anteriores. O projeto simula um ambiente de produção real com múltiplas aplicações, equipes e cenários de alerta.

### 🎯 Objetivos do Projeto

- ✅ Implementar arquitetura multi-tenant
- ✅ Configurar roteamento inteligente de alertas
- ✅ Criar templates personalizados
- ✅ Implementar escalation automática
- ✅ Integrar com múltiplos canais de notificação
- ✅ Configurar high availability
- ✅ Implementar monitoramento e troubleshooting

---

## 🏗️ ARQUITETURA DO PROJETO

### 🎨 Diagrama da Arquitetura

```mermaid
graph TB
    subgraph "Aplicações"
        APP1["🌐 Web App"]
        APP2["📊 API Service"]
        APP3["🗄️ Database"]
        APP4["🔄 Background Jobs"]
    end
    
    subgraph "Monitoramento"
        PROM["📈 Prometheus"]
        NODE["💻 Node Exporter"]
        CADV["🐳 cAdvisor"]
    end
    
    subgraph "Alertmanager Cluster"
        AM1["🚨 Alertmanager 1"]
        AM2["🚨 Alertmanager 2"]
        AM3["🚨 Alertmanager 3"]
        LB["⚖️ Load Balancer"]
    end
    
    subgraph "Notificações"
        EMAIL["📧 Email"]
        SLACK["💬 Slack"]
        PD["📟 PagerDuty"]
        WH["🔗 Webhook"]
        SMS["📱 SMS"]
    end
    
    subgraph "Equipes"
        DEV["👨‍💻 Dev Team"]
        OPS["🔧 Ops Team"]
        DBA["🗄️ DBA Team"]
        EXEC["👔 Executive"]
    end
    
    APP1 --> PROM
    APP2 --> PROM
    APP3 --> PROM
    APP4 --> PROM
    NODE --> PROM
    CADV --> PROM
    
    PROM --> LB
    LB --> AM1
    LB --> AM2
    LB --> AM3
    
    AM1 -.-> AM2
    AM2 -.-> AM3
    AM3 -.-> AM1
    
    AM1 --> EMAIL
    AM1 --> SLACK
    AM1 --> PD
    AM1 --> WH
    AM1 --> SMS
    
    EMAIL --> DEV
    EMAIL --> OPS
    EMAIL --> DBA
    EMAIL --> EXEC
    
    SLACK --> DEV
    SLACK --> OPS
    
    PD --> OPS
    PD --> EXEC
```

### 🏢 Cenário da Empresa

**TechCorp Solutions** - Empresa de tecnologia com:
- **3 equipes** (Desenvolvimento, Operações, DBA)
- **4 aplicações críticas**
- **Ambiente 24/7** com SLA rigoroso
- **Múltiplos canais** de comunicação
- **Escalation automática** para executivos

---

## 🚀 IMPLEMENTAÇÃO PASSO A PASSO

### 1️⃣ ESTRUTURA DO PROJETO

#### 📁 Organização de Arquivos
```bash
project-final/
├── docker-compose.yml              # Orquestração principal
├── .env                           # Variáveis de ambiente
├── prometheus/
│   ├── prometheus.yml             # Configuração do Prometheus
│   └── rules/
│       ├── web-app.yml           # Regras para aplicação web
│       ├── api-service.yml       # Regras para API
│       ├── database.yml          # Regras para banco de dados
│       └── infrastructure.yml    # Regras de infraestrutura
├── alertmanager/
│   ├── alertmanager.yml          # Configuração principal
│   ├── templates/
│   │   ├── email.tmpl           # Template de email
│   │   ├── slack.tmpl           # Template do Slack
│   │   └── webhook.tmpl         # Template de webhook
│   └── receivers.d/
│       ├── dev-team.yml         # Receivers da equipe dev
│       ├── ops-team.yml         # Receivers da equipe ops
│       └── dba-team.yml         # Receivers da equipe DBA
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   └── dashboards/
│   └── dashboards/
│       ├── alertmanager.json    # Dashboard do Alertmanager
│       └── alerts-overview.json # Visão geral dos alertas
├── webhooks/
│   ├── escalation-service.py    # Serviço de escalation
│   ├── ticket-integration.py    # Integração com tickets
│   └── requirements.txt
└── scripts/
    ├── setup.sh                 # Script de configuração
    ├── test-alerts.sh          # Script de teste
    └── backup.sh               # Script de backup
```

### 2️⃣ CONFIGURAÇÃO DO AMBIENTE

#### 🔧 Arquivo .env
```bash
# .env
# Configurações gerais
COMPOSE_PROJECT_NAME=techcorp-monitoring
TIMEZONE=America/Sao_Paulo

# Prometheus
PROMETHEUS_PORT=9090
PROMETHEUS_RETENTION=30d

# Alertmanager
ALERTMANAGER_PORT_1=9093
ALERTMANAGER_PORT_2=9094
ALERTMANAGER_PORT_3=9095
ALERTMANAGER_WEB_PORT=9096

# Grafana
GRAFANA_PORT=3000
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=techcorp2024

# Email Configuration
SMTP_HOST=smtp.techcorp.com
SMTP_PORT=587
SMTP_USER=alerts@techcorp.com
SMTP_PASSWORD=your-smtp-password
SMTP_FROM=alerts@techcorp.com

# Slack Configuration
SLACK_WEBHOOK_DEV=https://hooks.slack.com/services/DEV/WEBHOOK/URL
SLACK_WEBHOOK_OPS=https://hooks.slack.com/services/OPS/WEBHOOK/URL
SLACK_WEBHOOK_DBA=https://hooks.slack.com/services/DBA/WEBHOOK/URL
SLACK_WEBHOOK_EXEC=https://hooks.slack.com/services/EXEC/WEBHOOK/URL

# PagerDuty Configuration
PAGERDUTY_KEY_OPS=your-ops-integration-key
PAGERDUTY_KEY_EXEC=your-exec-integration-key

# Webhook URLs
WEBHOOK_ESCALATION=http://escalation-service:5000/escalate
WEBHOOK_TICKETS=http://ticket-service:5001/create-ticket

# Database
POSTGRES_DB=techcorp_monitoring
POSTGRES_USER=monitoring
POSTGRES_PASSWORD=secure-password
```

#### 🐳 Docker Compose Principal
```yaml
# docker-compose.yml
version: '3.8'

services:
  # Prometheus
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=${PROMETHEUS_RETENTION}'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
    volumes:
      - ./prometheus:/etc/prometheus
      - prometheus-data:/prometheus
    ports:
      - "${PROMETHEUS_PORT}:9090"
    networks:
      - monitoring
    restart: unless-stopped
    depends_on:
      - alertmanager-1
      - alertmanager-2
      - alertmanager-3

  # Alertmanager Cluster
  alertmanager-1:
    image: prom/alertmanager:latest
    container_name: alertmanager-1
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://alertmanager.techcorp.local'
      - '--web.listen-address=0.0.0.0:9093'
      - '--cluster.listen-address=0.0.0.0:9094'
      - '--cluster.peer=alertmanager-2:9094'
      - '--cluster.peer=alertmanager-3:9094'
      - '--cluster.advertise-address=alertmanager-1:9094'
      - '--log.level=debug'
    volumes:
      - ./alertmanager:/etc/alertmanager
      - alertmanager-1-data:/alertmanager
    ports:
      - "${ALERTMANAGER_PORT_1}:9093"
    networks:
      - monitoring
    restart: unless-stopped
    environment:
      - TZ=${TIMEZONE}

  alertmanager-2:
    image: prom/alertmanager:latest
    container_name: alertmanager-2
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://alertmanager.techcorp.local'
      - '--web.listen-address=0.0.0.0:9093'
      - '--cluster.listen-address=0.0.0.0:9094'
      - '--cluster.peer=alertmanager-1:9094'
      - '--cluster.peer=alertmanager-3:9094'
      - '--cluster.advertise-address=alertmanager-2:9094'
      - '--log.level=debug'
    volumes:
      - ./alertmanager:/etc/alertmanager
      - alertmanager-2-data:/alertmanager
    ports:
      - "${ALERTMANAGER_PORT_2}:9093"
    networks:
      - monitoring
    restart: unless-stopped
    environment:
      - TZ=${TIMEZONE}

  alertmanager-3:
    image: prom/alertmanager:latest
    container_name: alertmanager-3
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://alertmanager.techcorp.local'
      - '--web.listen-address=0.0.0.0:9093'
      - '--cluster.listen-address=0.0.0.0:9094'
      - '--cluster.peer=alertmanager-1:9094'
      - '--cluster.peer=alertmanager-2:9094'
      - '--cluster.advertise-address=alertmanager-3:9094'
      - '--log.level=debug'
    volumes:
      - ./alertmanager:/etc/alertmanager
      - alertmanager-3-data:/alertmanager
    ports:
      - "${ALERTMANAGER_PORT_3}:9093"
    networks:
      - monitoring
    restart: unless-stopped
    environment:
      - TZ=${TIMEZONE}

  # Load Balancer para Alertmanager
  alertmanager-lb:
    image: nginx:alpine
    container_name: alertmanager-lb
    volumes:
      - ./nginx/alertmanager.conf:/etc/nginx/nginx.conf
    ports:
      - "${ALERTMANAGER_WEB_PORT}:80"
    depends_on:
      - alertmanager-1
      - alertmanager-2
      - alertmanager-3
    networks:
      - monitoring
    restart: unless-stopped

  # Grafana
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
      - grafana-data:/var/lib/grafana
    ports:
      - "${GRAFANA_PORT}:3000"
    networks:
      - monitoring
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_USER=${GRAFANA_ADMIN_USER}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
      - GF_INSTALL_PLUGINS=grafana-piechart-panel

  # Node Exporter
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    command:
      - '--path.rootfs=/host'
    volumes:
      - '/:/host:ro,rslave'
    ports:
      - "9100:9100"
    networks:
      - monitoring
    restart: unless-stopped

  # cAdvisor
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    ports:
      - "8080:8080"
    networks:
      - monitoring
    restart: unless-stopped
    privileged: true
    devices:
      - /dev/kmsg

  # Aplicações de Exemplo
  web-app:
    image: nginx:alpine
    container_name: web-app
    volumes:
      - ./apps/web-app/nginx.conf:/etc/nginx/nginx.conf
      - ./apps/web-app/html:/usr/share/nginx/html
    ports:
      - "8081:80"
    networks:
      - monitoring
    restart: unless-stopped
    labels:
      - "team=development"
      - "service=web-app"
      - "environment=production"

  api-service:
    image: python:3.9-slim
    container_name: api-service
    working_dir: /app
    volumes:
      - ./apps/api-service:/app
    command: python app.py
    ports:
      - "8082:5000"
    networks:
      - monitoring
    restart: unless-stopped
    labels:
      - "team=development"
      - "service=api-service"
      - "environment=production"

  # Database
  postgres:
    image: postgres:13
    container_name: postgres
    volumes:
      - postgres-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    networks:
      - monitoring
    restart: unless-stopped
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    labels:
      - "team=dba"
      - "service=database"
      - "environment=production"

  # Postgres Exporter
  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:latest
    container_name: postgres-exporter
    ports:
      - "9187:9187"
    networks:
      - monitoring
    restart: unless-stopped
    environment:
      - DATA_SOURCE_NAME=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}?sslmode=disable
    depends_on:
      - postgres

  # Serviços de Webhook
  escalation-service:
    build: ./webhooks
    container_name: escalation-service
    volumes:
      - ./webhooks:/app
    ports:
      - "5000:5000"
    networks:
      - monitoring
    restart: unless-stopped
    environment:
      - ALERTMANAGER_URL=http://alertmanager-lb
      - FLASK_ENV=production

  ticket-service:
    build: ./webhooks
    container_name: ticket-service
    volumes:
      - ./webhooks:/app
    ports:
      - "5001:5001"
    networks:
      - monitoring
    restart: unless-stopped
    environment:
      - DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
      - FLASK_ENV=production

volumes:
  prometheus-data:
  alertmanager-1-data:
  alertmanager-2-data:
  alertmanager-3-data:
  grafana-data:
  postgres-data:

networks:
  monitoring:
    driver: bridge
```

### 3️⃣ CONFIGURAÇÃO DO PROMETHEUS

#### 📊 Prometheus Configuration
```yaml
# prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'techcorp-production'
    region: 'us-east-1'
    environment: 'production'

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager-lb:80
      path_prefix: /
      scheme: http

scrape_configs:
  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
    scrape_interval: 5s
    relabel_configs:
      - target_label: team
        replacement: 'operations'
      - target_label: service
        replacement: 'prometheus'

  # Alertmanager cluster
  - job_name: 'alertmanager'
    static_configs:
      - targets: 
        - 'alertmanager-1:9093'
        - 'alertmanager-2:9093'
        - 'alertmanager-3:9093'
    scrape_interval: 5s
    relabel_configs:
      - target_label: team
        replacement: 'operations'
      - target_label: service
        replacement: 'alertmanager'

  # Node Exporter
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
    scrape_interval: 5s
    relabel_configs:
      - target_label: team
        replacement: 'operations'
      - target_label: service
        replacement: 'node-exporter'

  # cAdvisor
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
    scrape_interval: 5s
    relabel_configs:
      - target_label: team
        replacement: 'operations'
      - target_label: service
        replacement: 'cadvisor'

  # Web Application
  - job_name: 'web-app'
    static_configs:
      - targets: ['web-app:80']
    scrape_interval: 10s
    metrics_path: '/metrics'
    relabel_configs:
      - target_label: team
        replacement: 'development'
      - target_label: service
        replacement: 'web-app'
      - target_label: tier
        replacement: 'frontend'

  # API Service
  - job_name: 'api-service'
    static_configs:
      - targets: ['api-service:5000']
    scrape_interval: 10s
    metrics_path: '/metrics'
    relabel_configs:
      - target_label: team
        replacement: 'development'
      - target_label: service
        replacement: 'api-service'
      - target_label: tier
        replacement: 'backend'

  # PostgreSQL
  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']
    scrape_interval: 10s
    relabel_configs:
      - target_label: team
        replacement: 'dba'
      - target_label: service
        replacement: 'postgresql'
      - target_label: tier
        replacement: 'database'

  # Webhook Services
  - job_name: 'webhook-services'
    static_configs:
      - targets: 
        - 'escalation-service:5000'
        - 'ticket-service:5001'
    scrape_interval: 15s
    relabel_configs:
      - target_label: team
        replacement: 'operations'
      - target_label: service
        replacement: 'webhook-service'
```

### 4️⃣ REGRAS DE ALERTA

#### 🌐 Web Application Rules
```yaml
# prometheus/rules/web-app.yml
groups:
- name: web-app.rules
  rules:
  # High HTTP Error Rate
  - alert: WebAppHighErrorRate
    expr: |
      (
        rate(nginx_http_requests_total{job="web-app",status=~"5.."}[5m]) /
        rate(nginx_http_requests_total{job="web-app"}[5m])
      ) * 100 > 5
    for: 2m
    labels:
      severity: critical
      team: development
      service: web-app
      tier: frontend
      category: availability
    annotations:
      summary: "High HTTP error rate on {{ $labels.instance }}"
      description: |
        Web application is experiencing {{ $value | humanizePercentage }} error rate
        for more than 2 minutes.
        
        Current error rate: {{ $value | humanizePercentage }}
        Threshold: 5%
        
        Troubleshooting steps:
        1. Check application logs
        2. Verify database connectivity
        3. Check resource utilization
      runbook_url: "https://wiki.techcorp.com/runbooks/web-app-errors"
      dashboard_url: "http://grafana:3000/d/web-app/web-application"

  # High Response Time
  - alert: WebAppHighResponseTime
    expr: |
      histogram_quantile(0.95, 
        rate(nginx_http_request_duration_seconds_bucket{job="web-app"}[5m])
      ) > 2
    for: 5m
    labels:
      severity: warning
      team: development
      service: web-app
      tier: frontend
      category: performance
    annotations:
      summary: "High response time on {{ $labels.instance }}"
      description: |
        95th percentile response time is {{ $value }}s, above 2s threshold.
        
        This may indicate:
        - Database performance issues
        - High server load
        - Network latency
      runbook_url: "https://wiki.techcorp.com/runbooks/web-app-performance"

  # Service Down
  - alert: WebAppDown
    expr: up{job="web-app"} == 0
    for: 1m
    labels:
      severity: critical
      team: development
      service: web-app
      tier: frontend
      category: availability
      escalation: "immediate"
    annotations:
      summary: "Web application is down"
      description: |
        Web application {{ $labels.instance }} has been down for more than 1 minute.
        
        Immediate action required:
        1. Check container status
        2. Verify network connectivity
        3. Check resource availability
      runbook_url: "https://wiki.techcorp.com/runbooks/web-app-down"
      pager: "true"

  # High Memory Usage
  - alert: WebAppHighMemoryUsage
    expr: |
      (
        container_memory_usage_bytes{name="web-app"} / 
        container_spec_memory_limit_bytes{name="web-app"}
      ) * 100 > 80
    for: 10m
    labels:
      severity: warning
      team: development
      service: web-app
      tier: frontend
      category: resource
    annotations:
      summary: "High memory usage on web application"
      description: |
        Memory usage is {{ $value | humanizePercentage }} of the limit.
        
        Current usage: {{ $value | humanizePercentage }}
        Threshold: 80%
```

#### 📊 API Service Rules
```yaml
# prometheus/rules/api-service.yml
groups:
- name: api-service.rules
  rules:
  # API High Error Rate
  - alert: APIHighErrorRate
    expr: |
      (
        rate(flask_http_request_exceptions_total{job="api-service"}[5m]) /
        rate(flask_http_request_total{job="api-service"}[5m])
      ) * 100 > 3
    for: 3m
    labels:
      severity: critical
      team: development
      service: api-service
      tier: backend
      category: availability
    annotations:
      summary: "High API error rate on {{ $labels.instance }}"
      description: |
        API service error rate is {{ $value | humanizePercentage }}
        
        This indicates potential issues with:
        - Database connections
        - External service dependencies
        - Application logic errors
      runbook_url: "https://wiki.techcorp.com/runbooks/api-errors"

  # API Slow Response
  - alert: APISlowResponse
    expr: |
      histogram_quantile(0.95,
        rate(flask_http_request_duration_seconds_bucket{job="api-service"}[5m])
      ) > 1
    for: 5m
    labels:
      severity: warning
      team: development
      service: api-service
      tier: backend
      category: performance
    annotations:
      summary: "API response time is slow"
      description: |
        95th percentile API response time: {{ $value }}s
        Threshold: 1s
        
        Possible causes:
        - Database query performance
        - External API latency
        - Resource constraints

  # High Request Rate
  - alert: APIHighRequestRate
    expr: rate(flask_http_request_total{job="api-service"}[5m]) > 100
    for: 2m
    labels:
      severity: warning
      team: development
      service: api-service
      tier: backend
      category: traffic
    annotations:
      summary: "High API request rate"
      description: |
        API is receiving {{ $value }} requests per second.
        
        Monitor for:
        - Potential DDoS attack
        - Unusual traffic patterns
        - Need for scaling

  # Database Connection Pool Exhaustion
  - alert: APIDBConnectionPoolExhausted
    expr: |
      flask_db_connection_pool_active{job="api-service"} /
      flask_db_connection_pool_size{job="api-service"} > 0.9
    for: 2m
    labels:
      severity: critical
      team: development
      service: api-service
      tier: backend
      category: resource
    annotations:
      summary: "Database connection pool nearly exhausted"
      description: |
        Connection pool utilization: {{ $value | humanizePercentage }}
        
        Actions needed:
        1. Check for connection leaks
        2. Review slow queries
        3. Consider pool size increase
```

#### 🗄️ Database Rules
```yaml
# prometheus/rules/database.yml
groups:
- name: database.rules
  rules:
  # Database Down
  - alert: PostgreSQLDown
    expr: pg_up{job="postgres"} == 0
    for: 1m
    labels:
      severity: critical
      team: dba
      service: postgresql
      tier: database
      category: availability
      escalation: "immediate"
    annotations:
      summary: "PostgreSQL database is down"
      description: |
        PostgreSQL instance {{ $labels.instance }} is not responding.
        
        Critical impact:
        - All applications affected
        - Data unavailable
        - Service degradation
        
        Immediate actions:
        1. Check database process
        2. Verify disk space
        3. Check system resources
      runbook_url: "https://wiki.techcorp.com/runbooks/postgres-down"
      pager: "true"

  # High Connection Usage
  - alert: PostgreSQLHighConnections
    expr: |
      (
        pg_stat_database_numbackends{job="postgres"} /
        pg_settings_max_connections{job="postgres"}
      ) * 100 > 80
    for: 5m
    labels:
      severity: warning
      team: dba
      service: postgresql
      tier: database
      category: resource
    annotations:
      summary: "High PostgreSQL connection usage"
      description: |
        Connection usage: {{ $value | humanizePercentage }}
        
        Current connections: {{ $labels.numbackends }}
        Max connections: {{ $labels.max_connections }}
        
        Actions:
        1. Identify long-running connections
        2. Check for connection leaks
        3. Consider connection pooling

  # Slow Queries
  - alert: PostgreSQLSlowQueries
    expr: |
      rate(pg_stat_database_tup_returned{job="postgres"}[5m]) /
      rate(pg_stat_database_tup_fetched{job="postgres"}[5m]) < 0.1
    for: 10m
    labels:
      severity: warning
      team: dba
      service: postgresql
      tier: database
      category: performance
    annotations:
      summary: "PostgreSQL has slow queries"
      description: |
        Query efficiency ratio: {{ $value | humanizePercentage }}
        
        This indicates:
        - Inefficient queries
        - Missing indexes
        - Lock contention
        
        Investigation needed:
        1. Check pg_stat_statements
        2. Analyze slow query log
        3. Review execution plans

  # High Disk Usage
  - alert: PostgreSQLHighDiskUsage
    expr: |
      (
        pg_database_size_bytes{job="postgres"} /
        (node_filesystem_size_bytes{mountpoint="/var/lib/postgresql/data"} * 0.8)
      ) * 100 > 85
    for: 5m
    labels:
      severity: critical
      team: dba
      service: postgresql
      tier: database
      category: resource
    annotations:
      summary: "PostgreSQL disk usage is high"
      description: |
        Database disk usage: {{ $value | humanizePercentage }}
        
        Urgent actions needed:
        1. Archive old data
        2. Clean up temporary files
        3. Expand storage if necessary
      runbook_url: "https://wiki.techcorp.com/runbooks/postgres-disk-full"

  # Replication Lag
  - alert: PostgreSQLReplicationLag
    expr: |
      pg_stat_replication_replay_lag{job="postgres"} > 300
    for: 2m
    labels:
      severity: warning
      team: dba
      service: postgresql
      tier: database
      category: replication
    annotations:
      summary: "PostgreSQL replication lag is high"
      description: |
        Replication lag: {{ $value }}s
        Threshold: 300s (5 minutes)
        
        Potential causes:
        - Network issues
        - High write load
        - Replica performance issues
```

#### 🖥️ Infrastructure Rules
```yaml
# prometheus/rules/infrastructure.yml
groups:
- name: infrastructure.rules
  rules:
  # High CPU Usage
  - alert: HighCPUUsage
    expr: |
      (
        100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
      ) > 80
    for: 10m
    labels:
      severity: warning
      team: operations
      service: node
      category: resource
    annotations:
      summary: "High CPU usage on {{ $labels.instance }}"
      description: |
        CPU usage: {{ $value | humanizePercentage }}
        
        Investigation steps:
        1. Identify top processes
        2. Check for runaway processes
        3. Consider scaling

  # High Memory Usage
  - alert: HighMemoryUsage
    expr: |
      (
        (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) /
        node_memory_MemTotal_bytes
      ) * 100 > 85
    for: 10m
    labels:
      severity: warning
      team: operations
      service: node
      category: resource
    annotations:
      summary: "High memory usage on {{ $labels.instance }}"
      description: |
        Memory usage: {{ $value | humanizePercentage }}
        
        Actions:
        1. Check memory-intensive processes
        2. Look for memory leaks
        3. Consider adding more memory

  # Disk Space Low
  - alert: DiskSpaceLow
    expr: |
      (
        (node_filesystem_size_bytes - node_filesystem_free_bytes) /
        node_filesystem_size_bytes
      ) * 100 > 85
    for: 5m
    labels:
      severity: critical
      team: operations
      service: node
      category: resource
    annotations:
      summary: "Low disk space on {{ $labels.instance }}"
      description: |
        Disk usage: {{ $value | humanizePercentage }}
        Filesystem: {{ $labels.mountpoint }}
        
        Urgent actions:
        1. Clean up old files
        2. Archive logs
        3. Expand storage
      runbook_url: "https://wiki.techcorp.com/runbooks/disk-space"

  # High Load Average
  - alert: HighLoadAverage
    expr: node_load15 > (count by (instance) (node_cpu_seconds_total{mode="idle"}) * 0.8)
    for: 10m
    labels:
      severity: warning
      team: operations
      service: node
      category: performance
    annotations:
      summary: "High load average on {{ $labels.instance }}"
      description: |
        15-minute load average: {{ $value }}
        CPU cores: {{ $labels.cpu_count }}
        
        This indicates system stress from:
        - High CPU usage
        - I/O wait
        - Process contention

  # Container High Memory
  - alert: ContainerHighMemoryUsage
    expr: |
      (
        container_memory_usage_bytes{name!=""} /
        container_spec_memory_limit_bytes{name!=""}
      ) * 100 > 80
    for: 5m
    labels:
      severity: warning
      team: operations
      service: docker
      category: resource
    annotations:
      summary: "Container {{ $labels.name }} high memory usage"
      description: |
        Memory usage: {{ $value | humanizePercentage }}
        Container: {{ $labels.name }}
        
        Actions:
        1. Check application memory leaks
        2. Review memory limits
        3. Consider container restart

  # Container Restart
  - alert: ContainerRestarted
    expr: increase(container_start_time_seconds{name!=""}[5m]) > 0
    for: 0m
    labels:
      severity: warning
      team: operations
      service: docker
      category: availability
    annotations:
      summary: "Container {{ $labels.name }} restarted"
      description: |
        Container {{ $labels.name }} has restarted.
        
        Check:
        1. Container logs
        2. Exit codes
        3. Resource constraints
        4. Health check failures
```

### 5️⃣ CONFIGURAÇÃO DO ALERTMANAGER

#### 🚨 Configuração Principal
```yaml
# alertmanager/alertmanager.yml
global:
  # SMTP Configuration
  smtp_smarthost: '${SMTP_HOST}:${SMTP_PORT}'
  smtp_from: '${SMTP_FROM}'
  smtp_auth_username: '${SMTP_USER}'
  smtp_auth_password: '${SMTP_PASSWORD}'
  smtp_require_tls: true
  
  # Global settings
  resolve_timeout: 5m
  http_config:
    tls_config:
      insecure_skip_verify: true

# Templates
templates:
  - '/etc/alertmanager/templates/*.tmpl'

# Main routing tree
route:
  group_by: ['cluster', 'alertname', 'team']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
  receiver: 'default-receiver'
  
  routes:
  # Critical alerts - immediate escalation
  - match:
      severity: critical
    receiver: 'critical-alerts'
    group_wait: 0s
    repeat_interval: 5m
    routes:
    # Development team critical alerts
    - match:
        team: development
      receiver: 'dev-critical'
      continue: true
    # Operations team critical alerts
    - match:
        team: operations
      receiver: 'ops-critical'
      continue: true
    # DBA team critical alerts
    - match:
        team: dba
      receiver: 'dba-critical'
      continue: true
    # Escalation after 15 minutes
    - match:
        escalation: immediate
      receiver: 'executive-escalation'
      group_wait: 0s
      repeat_interval: 15m
  
  # Development team alerts
  - match:
      team: development
    receiver: 'dev-team'
    group_by: ['alertname', 'service', 'instance']
    routes:
    # Frontend alerts
    - match:
        tier: frontend
      receiver: 'dev-frontend'
    # Backend alerts
    - match:
        tier: backend
      receiver: 'dev-backend'
  
  # Operations team alerts
  - match:
      team: operations
    receiver: 'ops-team'
    group_by: ['alertname', 'instance']
    routes:
    # Infrastructure alerts
    - match:
        category: resource
      receiver: 'ops-infrastructure'
    # Performance alerts
    - match:
        category: performance
      receiver: 'ops-performance'
  
  # DBA team alerts
  - match:
      team: dba
    receiver: 'dba-team'
    group_by: ['alertname', 'service']
    routes:
    # Database availability
    - match:
        category: availability
      receiver: 'dba-availability'
    # Database performance
    - match:
        category: performance
      receiver: 'dba-performance'
  
  # Maintenance window - silence all non-critical
  - match:
      maintenance: 'true'
    receiver: 'maintenance-receiver'
    group_wait: 1h
    repeat_interval: 24h

# Inhibition rules
inhibit_rules:
# Inhibit warning alerts when critical alerts are firing
- source_match:
    severity: 'critical'
  target_match:
    severity: 'warning'
  equal: ['alertname', 'instance', 'service']

# Inhibit individual service alerts when entire node is down
- source_match:
    alertname: 'NodeDown'
  target_match_re:
    alertname: '.*'
  equal: ['instance']

# Inhibit database connection alerts when database is down
- source_match:
    alertname: 'PostgreSQLDown'
  target_match:
    alertname: 'APIDBConnectionPoolExhausted'
  equal: ['instance']

# Receivers configuration
receivers:
# Default receiver
- name: 'default-receiver'
  email_configs:
  - to: 'alerts@techcorp.com'
    subject: '[TECHCORP] {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      {{ end }}

# Critical alerts - multiple channels
- name: 'critical-alerts'
  email_configs:
  - to: 'critical@techcorp.com,oncall@techcorp.com'
    subject: '🔴 [CRITICAL] {{ .GroupLabels.alertname }}'
    html: '{{ template "email.critical.html" . }}'
  slack_configs:
  - api_url: '${SLACK_WEBHOOK_OPS}'
    channel: '#critical-alerts'
    title: '🔴 CRITICAL ALERT'
    text: '{{ template "slack.critical" . }}'
    actions:
    - type: button
      text: 'Acknowledge'
      url: 'http://alertmanager.techcorp.local:9096/#/alerts'
    - type: button
      text: 'Silence 1h'
      url: 'http://alertmanager.techcorp.local:9096/#/silences/new'
  pagerduty_configs:
  - routing_key: '${PAGERDUTY_KEY_OPS}'
    description: '{{ .GroupLabels.alertname }}: {{ .GroupLabels.instance }}'
    severity: 'critical'

# Development team receivers
- name: 'dev-team'
  email_configs:
  - to: 'dev-team@techcorp.com'
    subject: '[DEV] {{ .GroupLabels.alertname }}'
    html: '{{ template "email.dev.html" . }}'
  slack_configs:
  - api_url: '${SLACK_WEBHOOK_DEV}'
    channel: '#dev-alerts'
    title: '{{ .GroupLabels.alertname }}'
    text: '{{ template "slack.dev" . }}'

- name: 'dev-critical'
  email_configs:
  - to: 'dev-team@techcorp.com,dev-lead@techcorp.com'
    subject: '🔴 [DEV-CRITICAL] {{ .GroupLabels.alertname }}'
    html: '{{ template "email.critical.html" . }}'
  slack_configs:
  - api_url: '${SLACK_WEBHOOK_DEV}'
    channel: '#dev-critical'
    title: '🔴 CRITICAL: Development Alert'
    text: '{{ template "slack.critical" . }}'
  webhook_configs:
  - url: '${WEBHOOK_ESCALATION}'
    http_config:
      basic_auth:
        username: 'alertmanager'
        password: 'webhook-secret'

- name: 'dev-frontend'
  slack_configs:
  - api_url: '${SLACK_WEBHOOK_DEV}'
    channel: '#frontend-alerts'
    title: '🌐 Frontend Alert'
    text: '{{ template "slack.frontend" . }}'

- name: 'dev-backend'
  slack_configs:
  - api_url: '${SLACK_WEBHOOK_DEV}'
    channel: '#backend-alerts'
    title: '⚙️ Backend Alert'
    text: '{{ template "slack.backend" . }}'

# Operations team receivers
- name: 'ops-team'
  email_configs:
  - to: 'ops-team@techcorp.com'
    subject: '[OPS] {{ .GroupLabels.alertname }}'
    html: '{{ template "email.ops.html" . }}'
  slack_configs:
  - api_url: '${SLACK_WEBHOOK_OPS}'
    channel: '#ops-alerts'
    title: '🔧 Operations Alert'
    text: '{{ template "slack.ops" . }}'

- name: 'ops-critical'
  email_configs:
  - to: 'ops-team@techcorp.com,ops-manager@techcorp.com'
    subject: '🔴 [OPS-CRITICAL] {{ .GroupLabels.alertname }}'
    html: '{{ template "email.critical.html" . }}'
  slack_configs:
  - api_url: '${SLACK_WEBHOOK_OPS}'
    channel: '#ops-critical'
    title: '🔴 CRITICAL: Operations Alert'
    text: '{{ template "slack.critical" . }}'
  pagerduty_configs:
  - routing_key: '${PAGERDUTY_KEY_OPS}'
    description: '{{ .GroupLabels.alertname }}: {{ .GroupLabels.instance }}'

- name: 'ops-infrastructure'
  slack_configs:
  - api_url: '${SLACK_WEBHOOK_OPS}'
    channel: '#infrastructure-alerts'
    title: '🖥️ Infrastructure Alert'
    text: '{{ template "slack.infrastructure" . }}'

- name: 'ops-performance'
  slack_configs:
  - api_url: '${SLACK_WEBHOOK_OPS}'
    channel: '#performance-alerts'
    title: '📊 Performance Alert'
    text: '{{ template "slack.performance" . }}'

# DBA team receivers
- name: 'dba-team'
  email_configs:
  - to: 'dba-team@techcorp.com'
    subject: '[DBA] {{ .GroupLabels.alertname }}'
    html: '{{ template "email.dba.html" . }}'
  slack_configs:
  - api_url: '${SLACK_WEBHOOK_DBA}'
    channel: '#dba-alerts'
    title: '🗄️ Database Alert'
    text: '{{ template "slack.dba" . }}'

- name: 'dba-critical'
  email_configs:
  - to: 'dba-team@techcorp.com,dba-lead@techcorp.com'
    subject: '🔴 [DBA-CRITICAL] {{ .GroupLabels.alertname }}'
    html: '{{ template "email.critical.html" . }}'
  slack_configs:
  - api_url: '${SLACK_WEBHOOK_DBA}'
    channel: '#dba-critical'
    title: '🔴 CRITICAL: Database Alert'
    text: '{{ template "slack.critical" . }}'
  pagerduty_configs:
  - routing_key: '${PAGERDUTY_KEY_OPS}'
    description: 'Database Critical: {{ .GroupLabels.alertname }}'

- name: 'dba-availability'
  slack_configs:
  - api_url: '${SLACK_WEBHOOK_DBA}'
    channel: '#db-availability'
    title: '🚨 Database Availability'
    text: '{{ template "slack.db.availability" . }}'

- name: 'dba-performance'
  slack_configs:
  - api_url: '${SLACK_WEBHOOK_DBA}'
    channel: '#db-performance'
    title: '⚡ Database Performance'
    text: '{{ template "slack.db.performance" . }}'

# Executive escalation
- name: 'executive-escalation'
  email_configs:
  - to: 'cto@techcorp.com,vp-engineering@techcorp.com'
    subject: '🚨 [EXECUTIVE] Critical System Alert'
    html: '{{ template "email.executive.html" . }}'
  slack_configs:
  - api_url: '${SLACK_WEBHOOK_EXEC}'
    channel: '#executive-alerts'
    title: '🚨 EXECUTIVE ESCALATION'
    text: '{{ template "slack.executive" . }}'
  pagerduty_configs:
  - routing_key: '${PAGERDUTY_KEY_EXEC}'
    description: 'Executive Escalation: {{ .GroupLabels.alertname }}'
    severity: 'critical'

# Maintenance receiver
- name: 'maintenance-receiver'
  email_configs:
  - to: 'maintenance@techcorp.com'
    subject: '[MAINTENANCE] {{ .GroupLabels.alertname }}'
    body: 'Alert during maintenance window: {{ .GroupLabels.alertname }}'
```

### 6️⃣ TEMPLATES PERSONALIZADOS

#### 📧 Email Templates
```html
<!-- alertmanager/templates/email.tmpl -->
{{ define "email.critical.html" }}
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Critical Alert - TechCorp</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background-color: #dc3545; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; }
        .alert-box { background-color: #f8f9fa; border-left: 4px solid #dc3545; padding: 15px; margin: 15px 0; }
        .alert-title { font-size: 18px; font-weight: bold; color: #dc3545; margin-bottom: 10px; }
        .alert-details { margin: 10px 0; }
        .label { font-weight: bold; color: #495057; }
        .value { color: #6c757d; }
        .footer { background-color: #f8f9fa; padding: 15px; text-align: center; font-size: 12px; color: #6c757d; }
        .button { display: inline-block; padding: 10px 20px; background-color: #007bff; color: white; text-decoration: none; border-radius: 4px; margin: 5px; }
        .button:hover { background-color: #0056b3; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔴 CRITICAL ALERT</h1>
            <p>TechCorp Monitoring System</p>
        </div>
        
        <div class="content">
            <p><strong>Alert Summary:</strong> {{ len .Alerts }} critical alert(s) detected</p>
            <p><strong>Time:</strong> {{ .CommonAnnotations.timestamp | date "2006-01-02 15:04:05 MST" }}</p>
            
            {{ range .Alerts }}
            <div class="alert-box">
                <div class="alert-title">{{ .Annotations.summary }}</div>
                
                <div class="alert-details">
                    <p><span class="label">Service:</span> <span class="value">{{ .Labels.service }}</span></p>
                    <p><span class="label">Instance:</span> <span class="value">{{ .Labels.instance }}</span></p>
                    <p><span class="label">Team:</span> <span class="value">{{ .Labels.team }}</span></p>
                    <p><span class="label">Severity:</span> <span class="value">{{ .Labels.severity }}</span></p>
                    {{ if .Labels.category }}
                    <p><span class="label">Category:</span> <span class="value">{{ .Labels.category }}</span></p>
                    {{ end }}
                </div>
                
                {{ if .Annotations.description }}
                <div style="margin-top: 15px;">
                    <strong>Description:</strong>
                    <pre style="background-color: #f8f9fa; padding: 10px; border-radius: 4px; white-space: pre-wrap;">{{ .Annotations.description }}</pre>
                </div>
                {{ end }}
                
                {{ if .Annotations.runbook_url }}
                <p><a href="{{ .Annotations.runbook_url }}" class="button">📖 Runbook</a></p>
                {{ end }}
                
                {{ if .Annotations.dashboard_url }}
                <p><a href="{{ .Annotations.dashboard_url }}" class="button">📊 Dashboard</a></p>
                {{ end }}
            </div>
            {{ end }}
            
            <div style="text-align: center; margin-top: 20px;">
                <a href="http://alertmanager.techcorp.local:9096" class="button">🚨 View in Alertmanager</a>
                <a href="http://grafana.techcorp.local:3000" class="button">📈 Open Grafana</a>
            </div>
        </div>
        
        <div class="footer">
            <p>TechCorp Monitoring System | Generated at {{ now | date "2006-01-02 15:04:05 MST" }}</p>
            <p>This is an automated message. Please do not reply to this email.</p>
        </div>
    </div>
</body>
</html>
{{ end }}

{{ define "email.dev.html" }}
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Development Alert - TechCorp</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background-color: #17a2b8; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; }
        .alert-box { background-color: #f8f9fa; border-left: 4px solid #17a2b8; padding: 15px; margin: 15px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>👨‍💻 Development Team Alert</h1>
        </div>
        <div class="content">
            {{ range .Alerts }}
            <div class="alert-box">
                <h3>{{ .Annotations.summary }}</h3>
                <p><strong>Service:</strong> {{ .Labels.service }}</p>
                <p><strong>Instance:</strong> {{ .Labels.instance }}</p>
                {{ if .Annotations.description }}
                <p><strong>Description:</strong></p>
                <pre>{{ .Annotations.description }}</pre>
                {{ end }}
            </div>
            {{ end }}
        </div>
    </div>
</body>
</html>
{{ end }}

{{ define "email.ops.html" }}
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Operations Alert - TechCorp</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background-color: #28a745; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; }
        .alert-box { background-color: #f8f9fa; border-left: 4px solid #28a745; padding: 15px; margin: 15px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔧 Operations Team Alert</h1>
        </div>
        <div class="content">
            {{ range .Alerts }}
            <div class="alert-box">
                <h3>{{ .Annotations.summary }}</h3>
                <p><strong>Instance:</strong> {{ .Labels.instance }}</p>
                <p><strong>Category:</strong> {{ .Labels.category }}</p>
                {{ if .Annotations.description }}
                <p><strong>Description:</strong></p>
                <pre>{{ .Annotations.description }}</pre>
                {{ end }}
            </div>
            {{ end }}
        </div>
    </div>
</body>
</html>
{{ end }}

{{ define "email.dba.html" }}
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Database Alert - TechCorp</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background-color: #6f42c1; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; }
        .alert-box { background-color: #f8f9fa; border-left: 4px solid #6f42c1; padding: 15px; margin: 15px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🗄️ Database Team Alert</h1>
        </div>
        <div class="content">
            {{ range .Alerts }}
            <div class="alert-box">
                <h3>{{ .Annotations.summary }}</h3>
                <p><strong>Database:</strong> {{ .Labels.service }}</p>
                <p><strong>Instance:</strong> {{ .Labels.instance }}</p>
                {{ if .Annotations.description }}
                <p><strong>Description:</strong></p>
                <pre>{{ .Annotations.description }}</pre>
                {{ end }}
            </div>
            {{ end }}
        </div>
    </div>
</body>
</html>
{{ end }}

{{ define "email.executive.html" }}
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Executive Escalation - TechCorp</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background-color: #dc3545; color: white; padding: 20px; text-align: center; }
        .urgent { background-color: #fff3cd; border: 2px solid #ffc107; padding: 15px; margin: 15px 0; border-radius: 4px; }
        .content { padding: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚨 EXECUTIVE ESCALATION</h1>
            <p>Critical System Alert Requiring Immediate Attention</p>
        </div>
        <div class="content">
            <div class="urgent">
                <h2>⚠️ URGENT ACTION REQUIRED</h2>
                <p>This alert has been escalated to executive level due to:</p>
                <ul>
                    <li>Critical severity level</li>
                    <li>Extended duration without resolution</li>
                    <li>Potential business impact</li>
                </ul>
            </div>
            
            {{ range .Alerts }}
            <div style="background-color: #f8f9fa; border-left: 4px solid #dc3545; padding: 15px; margin: 15px 0;">
                <h3>{{ .Annotations.summary }}</h3>
                <p><strong>Service:</strong> {{ .Labels.service }}</p>
                <p><strong>Team:</strong> {{ .Labels.team }}</p>
                <p><strong>Duration:</strong> {{ .StartsAt | since }}</p>
                {{ if .Annotations.description }}
                <p><strong>Impact:</strong></p>
                <pre>{{ .Annotations.description }}</pre>
                {{ end }}
            </div>
            {{ end }}
            
            <div style="text-align: center; margin-top: 20px;">
                <p><strong>Immediate escalation contacts:</strong></p>
                <p>Operations Manager: +1-555-0123</p>
                <p>On-call Engineer: +1-555-0456</p>
            </div>
        </div>
    </div>
</body>
</html>
{{ end }}
```

#### 💬 Slack Templates
```go
// alertmanager/templates/slack.tmpl
{{ define "slack.critical" }}
🔴 *CRITICAL ALERT*

{{ range .Alerts }}
*Alert:* {{ .Annotations.summary }}
*Service:* {{ .Labels.service }}
*Instance:* {{ .Labels.instance }}
*Team:* {{ .Labels.team }}
*Duration:* {{ .StartsAt | since }}

{{ if .Annotations.description }}
*Description:*
```
{{ .Annotations.description }}
```
{{ end }}

{{ if .Annotations.runbook_url }}
📖 <{{ .Annotations.runbook_url }}|Runbook>
{{ end }}
{{ if .Annotations.dashboard_url }}
📊 <{{ .Annotations.dashboard_url }}|Dashboard>
{{ end }}

---
{{ end }}

🚨 <http://alertmanager.techcorp.local:9096|View in Alertmanager>
{{ end }}

{{ define "slack.dev" }}
👨‍💻 *Development Team Alert*

{{ range .Alerts }}
*{{ .Annotations.summary }}*
• Service: {{ .Labels.service }}
• Instance: {{ .Labels.instance }}
• Tier: {{ .Labels.tier }}
• Severity: {{ .Labels.severity }}

{{ if .Annotations.description }}
```
{{ .Annotations.description }}
```
{{ end }}
{{ end }}
{{ end }}

{{ define "slack.frontend" }}
🌐 *Frontend Alert*

{{ range .Alerts }}
*{{ .Annotations.summary }}*
• Service: {{ .Labels.service }}
• Instance: {{ .Labels.instance }}
• Category: {{ .Labels.category }}

{{ if .Annotations.description }}
```
{{ .Annotations.description }}
```
{{ end }}
{{ end }}
{{ end }}

{{ define "slack.backend" }}
⚙️ *Backend Alert*

{{ range .Alerts }}
*{{ .Annotations.summary }}*
• Service: {{ .Labels.service }}
• Instance: {{ .Labels.instance }}
• Category: {{ .Labels.category }}

{{ if .Annotations.description }}
```
{{ .Annotations.description }}
```
{{ end }}
{{ end }}
{{ end }}

{{ define "slack.ops" }}
🔧 *Operations Alert*

{{ range .Alerts }}
*{{ .Annotations.summary }}*
• Instance: {{ .Labels.instance }}
• Category: {{ .Labels.category }}
• Severity: {{ .Labels.severity }}

{{ if .Annotations.description }}
```
{{ .Annotations.description }}
```
{{ end }}
{{ end }}
{{ end }}

{{ define "slack.infrastructure" }}
🖥️ *Infrastructure Alert*

{{ range .Alerts }}
*{{ .Annotations.summary }}*
• Instance: {{ .Labels.instance }}
• Resource: {{ .Labels.category }}

{{ if .Annotations.description }}
```
{{ .Annotations.description }}
```
{{ end }}
{{ end }}
{{ end }}

{{ define "slack.performance" }}
📊 *Performance Alert*

{{ range .Alerts }}
*{{ .Annotations.summary }}*
• Instance: {{ .Labels.instance }}
• Metric: {{ .Labels.alertname }}

{{ if .Annotations.description }}
```
{{ .Annotations.description }}
```
{{ end }}
{{ end }}
{{ end }}

{{ define "slack.dba" }}
🗄️ *Database Alert*

{{ range .Alerts }}
*{{ .Annotations.summary }}*
• Database: {{ .Labels.service }}
• Instance: {{ .Labels.instance }}
• Category: {{ .Labels.category }}

{{ if .Annotations.description }}
```
{{ .Annotations.description }}
```
{{ end }}
{{ end }}
{{ end }}

{{ define "slack.db.availability" }}
🚨 *Database Availability Alert*

{{ range .Alerts }}
*{{ .Annotations.summary }}*
• Database: {{ .Labels.service }}
• Instance: {{ .Labels.instance }}
• Status: {{ .Labels.severity }}

⚠️ *IMMEDIATE ACTION REQUIRED*

{{ if .Annotations.description }}
```
{{ .Annotations.description }}
```
{{ end }}
{{ end }}
{{ end }}

{{ define "slack.db.performance" }}
⚡ *Database Performance Alert*

{{ range .Alerts }}
*{{ .Annotations.summary }}*
• Database: {{ .Labels.service }}
• Instance: {{ .Labels.instance }}
• Metric: {{ .Labels.alertname }}

{{ if .Annotations.description }}
```
{{ .Annotations.description }}
```
{{ end }}
{{ end }}
{{ end }}

{{ define "slack.executive" }}
🚨 *EXECUTIVE ESCALATION*

⚠️ *CRITICAL SYSTEM ALERT - IMMEDIATE ATTENTION REQUIRED*

{{ range .Alerts }}
*Alert:* {{ .Annotations.summary }}
*Service:* {{ .Labels.service }}
*Team:* {{ .Labels.team }}
*Duration:* {{ .StartsAt | since }}
*Severity:* CRITICAL

*Business Impact:* Potential service disruption affecting customers

{{ if .Annotations.description }}
*Technical Details:*
```
{{ .Annotations.description }}
```
{{ end }}

---
{{ end }}

*Escalation Contacts:*
• Operations Manager: +1-555-0123
• On-call Engineer: +1-555-0456

🚨 <http://alertmanager.techcorp.local:9096|View in Alertmanager>
{{ end }}
```

### 7️⃣ SERVIÇOS DE WEBHOOK

#### 🤖 Escalation Service
```python
#!/usr/bin/env python3
# webhooks/escalation_service.py

import os
import time
import json
import requests
from datetime import datetime, timedelta
from flask import Flask, request, jsonify
from threading import Thread, Lock
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
ALERTMANAGER_URL = os.getenv('ALERTMANAGER_URL', 'http://alertmanager-lb')
ESCALATION_RULES = {
    'critical': {
        'initial_delay': 900,  # 15 minutes
        'escalation_levels': [
            {'delay': 900, 'label': 'level-2'},   # After 15 min
            {'delay': 600, 'label': 'level-3'},   # After 25 min total
            {'delay': 300, 'label': 'executive'}  # After 30 min total
        ]
    },
    'warning': {
        'initial_delay': 3600,  # 1 hour
        'escalation_levels': [
            {'delay': 1800, 'label': 'level-2'}  # After 1.5 hours total
        ]
    }
}

# Global state
active_escalations = {}
escalation_lock = Lock()

class EscalationManager:
    def __init__(self):
        self.escalations = {}
        self.lock = Lock()
    
    def start_escalation(self, alert_data):
        """Start escalation process for an alert"""
        alert_key = self.get_alert_key(alert_data)
        severity = alert_data.get('labels', {}).get('severity', 'info')
        
        if severity not in ESCALATION_RULES:
            logger.info(f"No escalation rules for severity: {severity}")
            return
        
        with self.lock:
            if alert_key in self.escalations:
                logger.info(f"Escalation already active for {alert_key}")
                return
            
            escalation_config = ESCALATION_RULES[severity]
            
            # Schedule escalation levels
            total_delay = escalation_config['initial_delay']
            
            for level in escalation_config['escalation_levels']:
                timer = Thread(
                    target=self.schedule_escalation,
                    args=(alert_key, level['label'], total_delay, alert_data)
                )
                timer.daemon = True
                timer.start()
                
                total_delay += level['delay']
            
            self.escalations[alert_key] = {
                'alert': alert_data,
                'started_at': datetime.utcnow(),
                'severity': severity,
                'timers': []
            }
            
            logger.info(f"Started escalation for {alert_key} (severity: {severity})")
    
    def schedule_escalation(self, alert_key, escalation_level, delay_seconds, original_alert):
        """Schedule escalation after delay"""
        logger.info(f"Scheduling escalation for {alert_key} to {escalation_level} in {delay_seconds}s")
        time.sleep(delay_seconds)
        
        with self.lock:
            if alert_key in self.escalations:
                self.escalate_alert(alert_key, escalation_level, original_alert)
    
    def escalate_alert(self, alert_key, escalation_level, original_alert):
        """Escalate alert by adding escalation label"""
        logger.info(f"Escalating {alert_key} to {escalation_level}")
        
        # Create escalated alert
        escalated_alert = original_alert.copy()
        escalated_alert['labels']['escalation'] = escalation_level
        escalated_alert['annotations']['escalation_time'] = datetime.utcnow().isoformat()
        escalated_alert['annotations']['escalation_level'] = escalation_level
        
        # Add escalation context to description
        original_desc = escalated_alert.get('annotations', {}).get('description', '')
        escalation_note = f"\n\n🚨 ESCALATED TO {escalation_level.upper()} at {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}"
        escalated_alert['annotations']['description'] = original_desc + escalation_note
        
        # Send escalated alert
        success = self.send_alert_to_alertmanager([escalated_alert])
        
        if success:
            logger.info(f"Successfully escalated {alert_key} to {escalation_level}")
        else:
            logger.error(f"Failed to escalate {alert_key} to {escalation_level}")
    
    def stop_escalation(self, alert_data):
        """Stop escalation when alert is resolved"""
        alert_key = self.get_alert_key(alert_data)
        
        with self.lock:
            if alert_key in self.escalations:
                del self.escalations[alert_key]
                logger.info(f"Stopped escalation for {alert_key}")
    
    def get_alert_key(self, alert_data):
        """Generate unique key for alert"""
        labels = alert_data.get('labels', {})
        return f"{labels.get('alertname', 'unknown')}_{labels.get('instance', 'unknown')}"
    
    def send_alert_to_alertmanager(self, alerts):
        """Send alert to Alertmanager"""
        try:
            url = f"{ALERTMANAGER_URL}/api/v1/alerts"
            headers = {'Content-Type': 'application/json'}
            
            response = requests.post(url, json=alerts, headers=headers, timeout=10)
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Error sending alert to Alertmanager: {e}")
            return False
    
    def get_status(self):
        """Get current escalation status"""
        with self.lock:
            return {
                'active_escalations': len(self.escalations),
                'escalations': {
                    key: {
                        'started_at': data['started_at'].isoformat(),
                        'severity': data['severity'],
                        'alert_name': data['alert']['labels'].get('alertname')
                    }
                    for key, data in self.escalations.items()
                }
            }

# Global escalation manager
escalation_manager = EscalationManager()

@app.route('/escalate', methods=['POST'])
def handle_escalation_webhook():
    """Handle escalation webhook from Alertmanager"""
    try:
        data = request.get_json()
        
        if not data or 'alerts' not in data:
            return jsonify({'error': 'Invalid webhook data'}), 400
        
        logger.info(f"Received escalation webhook with {len(data['alerts'])} alerts")
        
        for alert in data['alerts']:
            status = alert.get('status', 'unknown')
            
            if status == 'firing':
                escalation_manager.start_escalation(alert)
            elif status == 'resolved':
                escalation_manager.stop_escalation(alert)
        
        return jsonify({'status': 'success', 'processed': len(data['alerts'])})
    
    except Exception as e:
        logger.error(f"Error processing escalation webhook: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/status', methods=['GET'])
def get_escalation_status():
    """Get current escalation status"""
    return jsonify(escalation_manager.get_status())

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'active_escalations': len(escalation_manager.escalations)
    })

if __name__ == '__main__':
    logger.info("Starting Escalation Service")
    logger.info(f"Alertmanager URL: {ALERTMANAGER_URL}")
    app.run(host='0.0.0.0', port=5000, debug=False)
```

#### 🎫 Ticket Integration Service
```python
#!/usr/bin/env python3
# webhooks/ticket_integration.py

import os
import json
import requests
from datetime import datetime
from flask import Flask, request, jsonify
import logging
import hashlib

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
JIRA_URL = os.getenv('JIRA_URL', 'https://techcorp.atlassian.net')
JIRA_USERNAME = os.getenv('JIRA_USERNAME', 'alerts@techcorp.com')
JIRA_API_TOKEN = os.getenv('JIRA_API_TOKEN', 'your-api-token')
JIRA_PROJECT_KEY = os.getenv('JIRA_PROJECT_KEY', 'OPS')

SLACK_WEBHOOK_URL = os.getenv('SLACK_WEBHOOK_TICKETS', '')

# Ticket templates by team
TICKET_TEMPLATES = {
    'development': {
        'project': 'DEV',
        'issue_type': 'Bug',
        'priority': 'High',
        'components': ['Application'],
        'labels': ['monitoring', 'alert', 'development']
    },
    'operations': {
        'project': 'OPS',
        'issue_type': 'Incident',
        'priority': 'Critical',
        'components': ['Infrastructure'],
        'labels': ['monitoring', 'alert', 'operations']
    },
    'dba': {
        'project': 'DBA',
        'issue_type': 'Incident',
        'priority': 'High',
        'components': ['Database'],
        'labels': ['monitoring', 'alert', 'database']
    }
}

class TicketManager:
    def __init__(self):
        self.created_tickets = {}
    
    def create_ticket(self, alert_data):
        """Create ticket for alert"""
        try:
            # Generate unique ticket key
            ticket_key = self.generate_ticket_key(alert_data)
            
            # Check if ticket already exists
            if ticket_key in self.created_tickets:
                logger.info(f"Ticket already exists for {ticket_key}")
                return self.created_tickets[ticket_key]
            
            # Get alert details
            labels = alert_data.get('labels', {})
            annotations = alert_data.get('annotations', {})
            
            team = labels.get('team', 'operations')
            severity = labels.get('severity', 'warning')
            service = labels.get('service', 'unknown')
            instance = labels.get('instance', 'unknown')
            
            # Get template for team
            template = TICKET_TEMPLATES.get(team, TICKET_TEMPLATES['operations'])
            
            # Create ticket data
            ticket_data = {
                'fields': {
                    'project': {'key': template['project']},
                    'summary': f"[ALERT] {annotations.get('summary', labels.get('alertname', 'Unknown Alert'))}",
                    'description': self.format_ticket_description(alert_data),
                    'issuetype': {'name': template['issue_type']},
                    'priority': {'name': self.map_severity_to_priority(severity)},
                    'labels': template['labels'] + [severity, service],
                    'customfield_10001': service,  # Service field
                    'customfield_10002': instance,  # Instance field
                }
            }
            
            # Add components if available
            if template.get('components'):
                ticket_data['fields']['components'] = [
                    {'name': comp} for comp in template['components']
                ]
            
            # Create ticket in Jira
            jira_response = self.create_jira_ticket(ticket_data)
            
            if jira_response:
                ticket_info = {
                    'ticket_key': jira_response['key'],
                    'ticket_url': f"{JIRA_URL}/browse/{jira_response['key']}",
                    'created_at': datetime.utcnow().isoformat(),
                    'alert_key': ticket_key,
                    'team': team,
                    'severity': severity
                }
                
                self.created_tickets[ticket_key] = ticket_info
                
                # Send Slack notification
                self.send_slack_notification(ticket_info, alert_data)
                
                logger.info(f"Created ticket {jira_response['key']} for alert {ticket_key}")
                return ticket_info
            
        except Exception as e:
            logger.error(f"Error creating ticket: {e}")
            return None
    
    def generate_ticket_key(self, alert_data):
        """Generate unique key for ticket"""
        labels = alert_data.get('labels', {})
        key_string = f"{labels.get('alertname', '')}_{labels.get('instance', '')}_{labels.get('service', '')}"
        return hashlib.md5(key_string.encode()).hexdigest()[:8]
    
    def format_ticket_description(self, alert_data):
        """Format ticket description"""
        labels = alert_data.get('labels', {})
        annotations = alert_data.get('annotations', {})
        
        description = f"""h2. Alert Details

*Alert Name:* {labels.get('alertname', 'Unknown')}
*Service:* {labels.get('service', 'Unknown')}
*Instance:* {labels.get('instance', 'Unknown')}
*Team:* {labels.get('team', 'Unknown')}
*Severity:* {labels.get('severity', 'Unknown')}
*Category:* {labels.get('category', 'Unknown')}

h2. Description

{code}
{annotations.get('description', 'No description available')}
{code}

h2. Additional Information

*Started At:* {alert_data.get('startsAt', 'Unknown')}
*Generator URL:* {alert_data.get('generatorURL', 'Not available')}

"""
        
        # Add runbook link if available
        if annotations.get('runbook_url'):
            description += f"\n*Runbook:* {annotations['runbook_url']}"
        
        # Add dashboard link if available
        if annotations.get('dashboard_url'):
            description += f"\n*Dashboard:* {annotations['dashboard_url']}"
        
        description += "\n\nh2. Labels\n\n"
        for key, value in labels.items():
            description += f"*{key}:* {value}\n"
        
        return description
    
    def map_severity_to_priority(self, severity):
        """Map alert severity to Jira priority"""
        mapping = {
            'critical': 'Critical',
            'warning': 'High',
            'info': 'Medium'
        }
        return mapping.get(severity, 'Medium')
    
    def create_jira_ticket(self, ticket_data):
        """Create ticket in Jira"""
        try:
            url = f"{JIRA_URL}/rest/api/2/issue"
            auth = (JIRA_USERNAME, JIRA_API_TOKEN)
            headers = {'Content-Type': 'application/json'}
            
            response = requests.post(
                url, 
                json=ticket_data, 
                auth=auth, 
                headers=headers,
                timeout=30
            )
            
            if response.status_code == 201:
                return response.json()
            else:
                logger.error(f"Failed to create Jira ticket: {response.status_code} - {response.text}")
                return None
                
        except Exception as e:
            logger.error(f"Error creating Jira ticket: {e}")
            return None
    
    def send_slack_notification(self, ticket_info, alert_data):
        """Send Slack notification about ticket creation"""
        if not SLACK_WEBHOOK_URL:
            return
        
        try:
            labels = alert_data.get('labels', {})
            annotations = alert_data.get('annotations', {})
            
            message = {
                "text": f"🎫 Ticket created for alert",
                "attachments": [
                    {
                        "color": "good",
                        "fields": [
                            {
                                "title": "Ticket",
                                "value": f"<{ticket_info['ticket_url']}|{ticket_info['ticket_key']}>",
                                "short": True
                            },
                            {
                                "title": "Alert",
                                "value": labels.get('alertname', 'Unknown'),
                                "short": True
                            },
                            {
                                "title": "Service",
                                "value": labels.get('service', 'Unknown'),
                                "short": True
                            },
                            {
                                "title": "Team",
                                "value": labels.get('team', 'Unknown'),
                                "short": True
                            }
                        ],
                        "footer": "TechCorp Ticket Integration",
                        "ts": int(datetime.utcnow().timestamp())
                    }
                ]
            }
            
            response = requests.post(SLACK_WEBHOOK_URL, json=message, timeout=10)
            
            if response.status_code == 200:
                logger.info(f"Sent Slack notification for ticket {ticket_info['ticket_key']}")
            else:
                logger.error(f"Failed to send Slack notification: {response.status_code}")
                
        except Exception as e:
            logger.error(f"Error sending Slack notification: {e}")
    
    def get_ticket_status(self, alert_key):
        """Get ticket status for alert"""
        return self.created_tickets.get(alert_key)
    
    def list_tickets(self):
        """List all created tickets"""
        return list(self.created_tickets.values())

# Global ticket manager
ticket_manager = TicketManager()

@app.route('/create-ticket', methods=['POST'])
def handle_ticket_webhook():
    """Handle ticket creation webhook from Alertmanager"""
    try:
        data = request.get_json()
        
        if not data or 'alerts' not in data:
            return jsonify({'error': 'Invalid webhook data'}), 400
        
        logger.info(f"Received ticket webhook with {len(data['alerts'])} alerts")
        
        created_tickets = []
        
        for alert in data['alerts']:
            # Only create tickets for firing alerts
            if alert.get('status') == 'firing':
                # Only create tickets for critical alerts or specific labels
                labels = alert.get('labels', {})
                severity = labels.get('severity', '')
                create_ticket = labels.get('create_ticket', 'false').lower() == 'true'
                
                if severity == 'critical' or create_ticket:
                    ticket_info = ticket_manager.create_ticket(alert)
                    if ticket_info:
                        created_tickets.append(ticket_info)
        
        return jsonify({
            'status': 'success',
            'processed': len(data['alerts']),
            'tickets_created': len(created_tickets),
            'tickets': created_tickets
        })
    
    except Exception as e:
        logger.error(f"Error processing ticket webhook: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/tickets', methods=['GET'])
def list_tickets():
    """List all created tickets"""
    return jsonify({
        'tickets': ticket_manager.list_tickets(),
        'total': len(ticket_manager.created_tickets)
    })

@app.route('/tickets/<alert_key>', methods=['GET'])
def get_ticket(alert_key):
    """Get ticket for specific alert"""
    ticket = ticket_manager.get_ticket_status(alert_key)
    if ticket:
        return jsonify(ticket)
    else:
        return jsonify({'error': 'Ticket not found'}), 404

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'tickets_created': len(ticket_manager.created_tickets)
    })

if __name__ == '__main__':
    logger.info("Starting Ticket Integration Service")
    logger.info(f"Jira URL: {JIRA_URL}")
    app.run(host='0.0.0.0', port=5001, debug=False)
```

#### 📦 Requirements for Webhook Services
```txt
# webhooks/requirements.txt
Flask==2.3.3
requests==2.31.0
Werkzeug==2.3.7
Jinja2==3.1.2
MarkupSafe==2.1.3
click==8.1.7
itsdangerous==2.1.2
certifi==2023.7.22
charset-normalizer==3.3.0
idna==3.4
urllib3==2.0.7
```

#### 🐳 Dockerfile for Webhook Services
```dockerfile
# webhooks/Dockerfile
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY *.py ./

# Create non-root user
RUN useradd -m -u 1000 webhook && chown -R webhook:webhook /app
USER webhook

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

EXPOSE 5000 5001

CMD ["python", "escalation_service.py"]
```

### 8️⃣ SCRIPTS DE AUTOMAÇÃO

#### 🔧 Script de Deploy Automatizado
```bash
#!/bin/bash
# scripts/deploy.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="techcorp-monitoring"
ENV_FILE=".env"
COMPOSE_FILE="docker-compose.yml"
BACKUP_DIR="backups"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    # Check environment file
    if [ ! -f "$ENV_FILE" ]; then
        log_error "Environment file $ENV_FILE not found"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

validate_configs() {
    log_info "Validating configurations..."
    
    # Validate Prometheus config
    if [ -f "prometheus/prometheus.yml" ]; then
        docker run --rm -v "$(pwd)/prometheus:/etc/prometheus" \
            prom/prometheus:latest \
            promtool check config /etc/prometheus/prometheus.yml
        
        if [ $? -eq 0 ]; then
            log_success "Prometheus configuration is valid"
        else
            log_error "Prometheus configuration is invalid"
            exit 1
        fi
    fi
    
    # Validate Alertmanager config
    if [ -f "alertmanager/alertmanager.yml" ]; then
        docker run --rm -v "$(pwd)/alertmanager:/etc/alertmanager" \
            prom/alertmanager:latest \
            amtool check-config /etc/alertmanager/alertmanager.yml
        
        if [ $? -eq 0 ]; then
            log_success "Alertmanager configuration is valid"
        else
            log_error "Alertmanager configuration is invalid"
            exit 1
        fi
    fi
    
    # Validate alert rules
    if [ -d "prometheus/rules" ]; then
        for rule_file in prometheus/rules/*.yml; do
            if [ -f "$rule_file" ]; then
                docker run --rm -v "$(pwd)/prometheus:/etc/prometheus" \
                    prom/prometheus:latest \
                    promtool check rules "/etc/prometheus/rules/$(basename $rule_file)"
                
                if [ $? -eq 0 ]; then
                    log_success "Rule file $(basename $rule_file) is valid"
                else
                    log_error "Rule file $(basename $rule_file) is invalid"
                    exit 1
                fi
            fi
        done
    fi
}

backup_data() {
    log_info "Creating backup..."
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Backup timestamp
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"
    
    # Create backup
    tar -czf "$BACKUP_FILE" \
        --exclude="$BACKUP_DIR" \
        --exclude=".git" \
        --exclude="*.log" \
        --exclude="data/prometheus" \
        --exclude="data/grafana" \
        .
    
    log_success "Backup created: $BACKUP_FILE"
}

deploy_stack() {
    log_info "Deploying monitoring stack..."
    
    # Pull latest images
    log_info "Pulling latest images..."
    docker-compose pull
    
    # Stop existing containers
    log_info "Stopping existing containers..."
    docker-compose down
    
    # Start new containers
    log_info "Starting containers..."
    docker-compose up -d
    
    # Wait for services to be ready
    log_info "Waiting for services to be ready..."
    sleep 30
    
    # Check service health
    check_service_health
}

check_service_health() {
    log_info "Checking service health..."
    
    # Check Prometheus
    if curl -sf http://localhost:9090/-/healthy > /dev/null; then
        log_success "Prometheus is healthy"
    else
        log_error "Prometheus health check failed"
        return 1
    fi
    
    # Check Alertmanager
    if curl -sf http://localhost:9093/-/healthy > /dev/null; then
        log_success "Alertmanager is healthy"
    else
        log_error "Alertmanager health check failed"
        return 1
    fi
    
    # Check Grafana
    if curl -sf http://localhost:3000/api/health > /dev/null; then
        log_success "Grafana is healthy"
    else
        log_error "Grafana health check failed"
        return 1
    fi
    
    log_success "All services are healthy"
}

run_tests() {
    log_info "Running integration tests..."
    
    # Test Prometheus targets
    log_info "Testing Prometheus targets..."
    TARGETS_UP=$(curl -s http://localhost:9090/api/v1/query?query=up | jq -r '.data.result | length')
    
    if [ "$TARGETS_UP" -gt 0 ]; then
        log_success "Prometheus has $TARGETS_UP active targets"
    else
        log_warning "No active Prometheus targets found"
    fi
    
    # Test alert rules
    log_info "Testing alert rules..."
    RULES_COUNT=$(curl -s http://localhost:9090/api/v1/rules | jq -r '.data.groups | length')
    
    if [ "$RULES_COUNT" -gt 0 ]; then
        log_success "Loaded $RULES_COUNT rule groups"
    else
        log_warning "No alert rules loaded"
    fi
    
    # Test Alertmanager config
    log_info "Testing Alertmanager configuration..."
    if curl -sf http://localhost:9093/api/v1/status > /dev/null; then
        log_success "Alertmanager API is responding"
    else
        log_error "Alertmanager API test failed"
        return 1
    fi
    
    # Test webhook services
    if [ "$(docker-compose ps -q webhook-escalation)" ]; then
        log_info "Testing escalation webhook..."
        if curl -sf http://localhost:5000/health > /dev/null; then
            log_success "Escalation webhook is healthy"
        else
            log_warning "Escalation webhook health check failed"
        fi
    fi
    
    if [ "$(docker-compose ps -q webhook-tickets)" ]; then
        log_info "Testing ticket webhook..."
        if curl -sf http://localhost:5001/health > /dev/null; then
            log_success "Ticket webhook is healthy"
        else
            log_warning "Ticket webhook health check failed"
        fi
    fi
}

show_status() {
    log_info "Deployment Status:"
    echo
    echo "🔗 Service URLs:"
    echo "   Prometheus:    http://localhost:9090"
    echo "   Alertmanager:  http://localhost:9093"
    echo "   Grafana:       http://localhost:3000 (admin/admin)"
    echo "   Node Exporter: http://localhost:9100"
    echo
    echo "🐳 Container Status:"
    docker-compose ps
    echo
    echo "📊 Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
}

# Main execution
main() {
    log_info "Starting TechCorp Monitoring Stack Deployment"
    echo
    
    # Parse command line arguments
    case "${1:-deploy}" in
        "deploy")
            check_prerequisites
            validate_configs
            backup_data
            deploy_stack
            run_tests
            show_status
            log_success "Deployment completed successfully!"
            ;;
        "validate")
            check_prerequisites
            validate_configs
            log_success "Configuration validation completed!"
            ;;
        "backup")
            backup_data
            log_success "Backup completed!"
            ;;
        "test")
            run_tests
            log_success "Tests completed!"
            ;;
        "status")
            show_status
            ;;
        "help")
            echo "Usage: $0 [deploy|validate|backup|test|status|help]"
            echo
            echo "Commands:"
            echo "  deploy   - Full deployment (default)"
            echo "  validate - Validate configurations only"
            echo "  backup   - Create backup only"
            echo "  test     - Run tests only"
            echo "  status   - Show current status"
            echo "  help     - Show this help"
            ;;
        *)
            log_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
```

#### 🧪 Script de Testes de Integração
```python
#!/usr/bin/env python3
# scripts/integration_tests.py

import requests
import json
import time
import sys
from datetime import datetime, timedelta
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Configuration
PROMETHEUS_URL = 'http://localhost:9090'
ALERTMANAGER_URL = 'http://localhost:9093'
GRAFANA_URL = 'http://localhost:3000'
WEBHOOK_ESCALATION_URL = 'http://localhost:5000'
WEBHOOK_TICKETS_URL = 'http://localhost:5001'

class MonitoringStackTester:
    def __init__(self):
        self.test_results = []
        self.failed_tests = 0
        self.passed_tests = 0
    
    def run_test(self, test_name, test_func):
        """Run a single test and record results"""
        logger.info(f"Running test: {test_name}")
        try:
            result = test_func()
            if result:
                logger.info(f"✅ PASSED: {test_name}")
                self.passed_tests += 1
                self.test_results.append({'test': test_name, 'status': 'PASSED', 'message': 'OK'})
            else:
                logger.error(f"❌ FAILED: {test_name}")
                self.failed_tests += 1
                self.test_results.append({'test': test_name, 'status': 'FAILED', 'message': 'Test returned False'})
        except Exception as e:
            logger.error(f"❌ FAILED: {test_name} - {str(e)}")
            self.failed_tests += 1
            self.test_results.append({'test': test_name, 'status': 'FAILED', 'message': str(e)})
    
    def test_prometheus_health(self):
        """Test Prometheus health endpoint"""
        response = requests.get(f"{PROMETHEUS_URL}/-/healthy", timeout=10)
        return response.status_code == 200
    
    def test_prometheus_targets(self):
        """Test Prometheus targets are up"""
        response = requests.get(f"{PROMETHEUS_URL}/api/v1/targets", timeout=10)
        if response.status_code != 200:
            return False
        
        data = response.json()
        active_targets = data.get('data', {}).get('activeTargets', [])
        
        # Check if we have at least some targets
        if len(active_targets) == 0:
            raise Exception("No active targets found")
        
        # Check if at least 80% of targets are up
        up_targets = [t for t in active_targets if t.get('health') == 'up']
        up_percentage = len(up_targets) / len(active_targets) * 100
        
        logger.info(f"Targets status: {len(up_targets)}/{len(active_targets)} up ({up_percentage:.1f}%)")
        
        return up_percentage >= 80
    
    def test_prometheus_rules(self):
        """Test Prometheus alert rules are loaded"""
        response = requests.get(f"{PROMETHEUS_URL}/api/v1/rules", timeout=10)
        if response.status_code != 200:
            return False
        
        data = response.json()
        groups = data.get('data', {}).get('groups', [])
        
        if len(groups) == 0:
            raise Exception("No rule groups loaded")
        
        total_rules = sum(len(group.get('rules', [])) for group in groups)
        logger.info(f"Loaded {len(groups)} rule groups with {total_rules} total rules")
        
        return total_rules > 0
    
    def test_alertmanager_health(self):
        """Test Alertmanager health"""
        response = requests.get(f"{ALERTMANAGER_URL}/-/healthy", timeout=10)
        return response.status_code == 200
    
    def test_alertmanager_config(self):
        """Test Alertmanager configuration"""
        response = requests.get(f"{ALERTMANAGER_URL}/api/v1/status", timeout=10)
        if response.status_code != 200:
            return False
        
        data = response.json()
        config = data.get('data', {}).get('configYAML', '')
        
        # Check if config contains expected sections
        required_sections = ['global:', 'route:', 'receivers:']
        for section in required_sections:
            if section not in config:
                raise Exception(f"Missing required section: {section}")
        
        return True
    
    def test_grafana_health(self):
        """Test Grafana health"""
        response = requests.get(f"{GRAFANA_URL}/api/health", timeout=10)
        if response.status_code != 200:
            return False
        
        data = response.json()
        return data.get('database') == 'ok'
    
    def test_grafana_datasources(self):
        """Test Grafana datasources"""
        # Use default admin credentials
        auth = ('admin', 'admin')
        response = requests.get(f"{GRAFANA_URL}/api/datasources", auth=auth, timeout=10)
        
        if response.status_code != 200:
            return False
        
        datasources = response.json()
        prometheus_ds = [ds for ds in datasources if ds.get('type') == 'prometheus']
        
        if len(prometheus_ds) == 0:
            raise Exception("No Prometheus datasource found")
        
        logger.info(f"Found {len(prometheus_ds)} Prometheus datasource(s)")
        return True
    
    def test_webhook_escalation_health(self):
        """Test escalation webhook health"""
        try:
            response = requests.get(f"{WEBHOOK_ESCALATION_URL}/health", timeout=5)
            return response.status_code == 200
        except requests.exceptions.ConnectionError:
            logger.warning("Escalation webhook service not running (optional)")
            return True  # Optional service
    
    def test_webhook_tickets_health(self):
        """Test ticket webhook health"""
        try:
            response = requests.get(f"{WEBHOOK_TICKETS_URL}/health", timeout=5)
            return response.status_code == 200
        except requests.exceptions.ConnectionError:
            logger.warning("Ticket webhook service not running (optional)")
            return True  # Optional service
    
    def test_alert_simulation(self):
        """Test alert simulation by sending test alert"""
        # Create a test alert
        test_alert = {
            "alerts": [
                {
                    "labels": {
                        "alertname": "TestAlert",
                        "instance": "test-instance",
                        "service": "test-service",
                        "team": "development",
                        "severity": "warning"
                    },
                    "annotations": {
                        "summary": "Test alert for integration testing",
                        "description": "This is a test alert generated by integration tests"
                    },
                    "startsAt": datetime.utcnow().isoformat() + "Z",
                    "endsAt": (datetime.utcnow() + timedelta(minutes=5)).isoformat() + "Z",
                    "generatorURL": "http://test-generator"
                }
            ]
        }
        
        # Send test alert to Alertmanager
        response = requests.post(
            f"{ALERTMANAGER_URL}/api/v1/alerts",
            json=test_alert['alerts'],
            headers={'Content-Type': 'application/json'},
            timeout=10
        )
        
        if response.status_code != 200:
            raise Exception(f"Failed to send test alert: {response.status_code}")
        
        # Wait a bit for alert to be processed
        time.sleep(2)
        
        # Check if alert appears in Alertmanager
        response = requests.get(f"{ALERTMANAGER_URL}/api/v1/alerts", timeout=10)
        if response.status_code != 200:
            return False
        
        alerts = response.json()
        test_alerts = [a for a in alerts if a.get('labels', {}).get('alertname') == 'TestAlert']
        
        if len(test_alerts) == 0:
            raise Exception("Test alert not found in Alertmanager")
        
        logger.info("Test alert successfully processed by Alertmanager")
        return True
    
    def test_metrics_collection(self):
        """Test that metrics are being collected"""
        # Query for some basic metrics
        test_queries = [
            'up',  # Basic up metric
            'prometheus_config_last_reload_successful',  # Prometheus internal metric
            'alertmanager_config_last_reload_successful'  # Alertmanager internal metric
        ]
        
        for query in test_queries:
            response = requests.get(
                f"{PROMETHEUS_URL}/api/v1/query",
                params={'query': query},
                timeout=10
            )
            
            if response.status_code != 200:
                raise Exception(f"Failed to query metric: {query}")
            
            data = response.json()
            results = data.get('data', {}).get('result', [])
            
            if len(results) == 0:
                logger.warning(f"No results for metric: {query}")
            else:
                logger.info(f"Metric {query}: {len(results)} series")
        
        return True
    
    def run_all_tests(self):
        """Run all integration tests"""
        logger.info("Starting TechCorp Monitoring Stack Integration Tests")
        logger.info("=" * 60)
        
        # Core service health tests
        self.run_test("Prometheus Health", self.test_prometheus_health)
        self.run_test("Alertmanager Health", self.test_alertmanager_health)
        self.run_test("Grafana Health", self.test_grafana_health)
        
        # Configuration tests
        self.run_test("Prometheus Targets", self.test_prometheus_targets)
        self.run_test("Prometheus Rules", self.test_prometheus_rules)
        self.run_test("Alertmanager Config", self.test_alertmanager_config)
        self.run_test("Grafana Datasources", self.test_grafana_datasources)
        
        # Webhook services tests (optional)
        self.run_test("Escalation Webhook Health", self.test_webhook_escalation_health)
        self.run_test("Ticket Webhook Health", self.test_webhook_tickets_health)
        
        # Functional tests
        self.run_test("Metrics Collection", self.test_metrics_collection)
        self.run_test("Alert Simulation", self.test_alert_simulation)
        
        # Print summary
        logger.info("=" * 60)
        logger.info("TEST SUMMARY")
        logger.info(f"Total tests: {self.passed_tests + self.failed_tests}")
        logger.info(f"Passed: {self.passed_tests}")
        logger.info(f"Failed: {self.failed_tests}")
        
        if self.failed_tests > 0:
            logger.error("\nFailed tests:")
            for result in self.test_results:
                if result['status'] == 'FAILED':
                    logger.error(f"  - {result['test']}: {result['message']}")
            return False
        else:
            logger.info("\n🎉 All tests passed!")
            return True

def main():
    tester = MonitoringStackTester()
    success = tester.run_all_tests()
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
```

### 9️⃣ VALIDAÇÃO E TESTES

#### ✅ Checklist de Validação

**📋 Pré-Deploy:**
- [ ] Arquivo `.env` configurado com todas as variáveis
- [ ] Configurações do Prometheus validadas com `promtool`
- [ ] Configurações do Alertmanager validadas com `amtool`
- [ ] Templates de notificação testados
- [ ] Regras de alerta validadas
- [ ] Webhooks configurados e testados

**🚀 Pós-Deploy:**
- [ ] Todos os serviços estão rodando (`docker-compose ps`)
- [ ] Health checks passando para todos os serviços
- [ ] Targets do Prometheus estão UP
- [ ] Regras de alerta carregadas corretamente
- [ ] Grafana acessível e datasources configurados
- [ ] Notificações de teste enviadas com sucesso
- [ ] Webhooks respondendo corretamente

**🧪 Testes Funcionais:**
- [ ] Simulação de alerta crítico
- [ ] Teste de escalação automática
- [ ] Teste de criação de tickets
- [ ] Teste de silenciamento de alertas
- [ ] Teste de inibição de alertas
- [ ] Validação de templates de notificação

#### 🔍 Script de Validação Completa
```bash
#!/bin/bash
# scripts/validate_deployment.sh

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Validation functions
validate_environment() {
    log_info "Validating environment..."
    
    required_vars=(
        "SMTP_HOST" "SMTP_PORT" "SMTP_FROM" "SMTP_USER" "SMTP_PASSWORD"
        "SLACK_WEBHOOK_OPS" "SLACK_WEBHOOK_DEV" "SLACK_WEBHOOK_DBA"
        "PAGERDUTY_KEY_OPS" "GRAFANA_ADMIN_PASSWORD"
    )
    
    missing_vars=()
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "Missing required environment variables:"
        printf '%s\n' "${missing_vars[@]}"
        return 1
    fi
    
    log_success "Environment validation passed"
}

validate_services() {
    log_info "Validating services..."
    
    services=("prometheus" "alertmanager" "grafana" "node-exporter")
    
    for service in "${services[@]}"; do
        if docker-compose ps "$service" | grep -q "Up"; then
            log_success "$service is running"
        else
            log_error "$service is not running"
            return 1
        fi
    done
}

validate_endpoints() {
    log_info "Validating endpoints..."
    
    endpoints=(
        "http://localhost:9090/-/healthy:Prometheus"
        "http://localhost:9093/-/healthy:Alertmanager"
        "http://localhost:3000/api/health:Grafana"
        "http://localhost:9100/metrics:Node Exporter"
    )
    
    for endpoint_info in "${endpoints[@]}"; do
        IFS=':' read -r url name <<< "$endpoint_info"
        
        if curl -sf "$url" > /dev/null; then
            log_success "$name endpoint is healthy"
        else
            log_error "$name endpoint is not responding"
            return 1
        fi
    done
}

validate_prometheus_targets() {
    log_info "Validating Prometheus targets..."
    
    targets_json=$(curl -s http://localhost:9090/api/v1/targets)
    up_targets=$(echo "$targets_json" | jq -r '.data.activeTargets[] | select(.health == "up") | .scrapeUrl' | wc -l)
    total_targets=$(echo "$targets_json" | jq -r '.data.activeTargets | length')
    
    if [ "$up_targets" -gt 0 ]; then
        log_success "$up_targets/$total_targets Prometheus targets are UP"
    else
        log_error "No Prometheus targets are UP"
        return 1
    fi
}

validate_alert_rules() {
    log_info "Validating alert rules..."
    
    rules_json=$(curl -s http://localhost:9090/api/v1/rules)
    rule_groups=$(echo "$rules_json" | jq -r '.data.groups | length')
    total_rules=$(echo "$rules_json" | jq -r '[.data.groups[].rules | length] | add')
    
    if [ "$rule_groups" -gt 0 ] && [ "$total_rules" -gt 0 ]; then
        log_success "Loaded $rule_groups rule groups with $total_rules total rules"
    else
        log_error "No alert rules loaded"
        return 1
    fi
}

send_test_alert() {
    log_info "Sending test alert..."
    
    test_alert='[
        {
            "labels": {
                "alertname": "ValidationTestAlert",
                "instance": "validation-test",
                "service": "validation",
                "team": "operations",
                "severity": "warning"
            },
            "annotations": {
                "summary": "Validation test alert",
                "description": "This alert was generated during deployment validation"
            },
            "startsAt": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
            "endsAt": "'$(date -u -d '+5 minutes' +%Y-%m-%dT%H:%M:%S.%3NZ)'"
        }
    ]'
    
    if curl -sf -X POST \
        -H "Content-Type: application/json" \
        -d "$test_alert" \
        http://localhost:9093/api/v1/alerts > /dev/null; then
        log_success "Test alert sent successfully"
        
        # Wait and check if alert appears
        sleep 3
        alerts_json=$(curl -s http://localhost:9093/api/v1/alerts)
        if echo "$alerts_json" | jq -r '.[].labels.alertname' | grep -q "ValidationTestAlert"; then
            log_success "Test alert processed by Alertmanager"
        else
            log_error "Test alert not found in Alertmanager"
            return 1
        fi
    else
        log_error "Failed to send test alert"
        return 1
    fi
}

# Main validation
main() {
    log_info "Starting TechCorp Monitoring Stack Validation"
    echo
    
    # Source environment variables
    if [ -f ".env" ]; then
        set -a
        source .env
        set +a
    fi
    
    # Run validations
    validate_environment
    validate_services
    validate_endpoints
    validate_prometheus_targets
    validate_alert_rules
    send_test_alert
    
    log_success "All validations passed! 🎉"
    echo
    echo "📊 Access URLs:"
    echo "   Prometheus:   http://localhost:9090"
    echo "   Alertmanager: http://localhost:9093"
    echo "   Grafana:      http://localhost:3000"
    echo
}

main "$@"
```

### 🔟 DOCUMENTAÇÃO FINAL

#### 📚 Guia de Operação

**🚀 Comandos Essenciais:**
```bash
# Deploy completo
./scripts/deploy.sh

# Validar configurações
./scripts/deploy.sh validate

# Executar testes
python3 scripts/integration_tests.py

# Verificar status
docker-compose ps
docker-compose logs -f

# Backup
./scripts/deploy.sh backup

# Restart serviços
docker-compose restart

# Atualizar configurações
docker-compose up -d --force-recreate
```

**🔧 Troubleshooting:**

1. **Serviço não inicia:**
   ```bash
   docker-compose logs [service-name]
   docker-compose down && docker-compose up -d
   ```

2. **Alertas não chegam:**
   ```bash
   # Verificar configuração
   amtool config show
   
   # Testar roteamento
   amtool config routes test --config.file=alertmanager/alertmanager.yml
   
   # Verificar logs
   docker-compose logs alertmanager
   ```

3. **Targets down no Prometheus:**
   ```bash
   # Verificar conectividade
   docker-compose exec prometheus wget -O- http://node-exporter:9100/metrics
   
   # Verificar configuração
   promtool check config prometheus/prometheus.yml
   ```

**📈 Monitoramento da Stack:**

- **Métricas importantes:**
  - `up{job="prometheus"}` - Status do Prometheus
  - `alertmanager_config_last_reload_successful` - Config do Alertmanager
  - `prometheus_rule_group_rules` - Regras carregadas
  - `alertmanager_alerts_received_total` - Alertas recebidos

- **Dashboards recomendados:**
  - Prometheus Stats (ID: 3662)
  - Alertmanager Overview (ID: 9578)
  - Node Exporter Full (ID: 1860)

#### 🎯 Objetivos Alcançados

✅ **Sistema de Alertas Completo:**
- Configuração modular e escalável
- Roteamento inteligente por equipe
- Templates personalizados para cada canal
- Escalação automática para alertas críticos
- Integração com sistemas de tickets

✅ **Automação e Operação:**
- Scripts de deploy automatizado
- Testes de integração abrangentes
- Validação de configurações
- Backup automático
- Monitoramento da própria stack

✅ **Documentação e Treinamento:**
- Guias educacionais completos
- Exemplos práticos e casos de uso
- Troubleshooting detalhado
- Melhores práticas implementadas

#### 🚀 Próximos Passos

1. **Expansão:**
   - Adicionar mais exporters (MySQL, Redis, etc.)
   - Implementar service discovery
   - Configurar alta disponibilidade

2. **Melhorias:**
   - Implementar métricas customizadas
   - Adicionar mais integrações (Teams, Discord)
   - Criar dashboards específicos por equipe

3. **Segurança:**
   - Implementar TLS/SSL
   - Configurar autenticação LDAP
   - Adicionar controle de acesso granular

---

## 🎉 CONCLUSÃO

Parabéns! Você completou com sucesso o **Projeto Final do Alertmanager**. 

Este projeto implementa um sistema de monitoramento e alertas de nível empresarial, com:

- **Configuração modular** e facilmente extensível
- **Roteamento inteligente** baseado em equipes e severidade
- **Templates personalizados** para diferentes canais de notificação
- **Automação completa** com escalação e criação de tickets
- **Testes abrangentes** e validação automatizada
- **Documentação detalhada** para operação e manutenção

O sistema está pronto para uso em produção e pode ser adaptado para diferentes necessidades organizacionais.

---

## 🔗 Links Relacionados

- **[Anterior: Integração Avançada](09-integracao-avancada.md)**
- **[Voltar ao Índice](README.md)**