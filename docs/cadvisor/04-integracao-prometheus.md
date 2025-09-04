# Módulo 04: Integração com Prometheus

> **Integração completa cAdvisor + Prometheus** - Scraping, alertas, dashboards e automação

## 📋 Objetivos do Módulo

Ao final deste módulo, você será capaz de:
- ✅ Configurar Prometheus para coletar métricas do cAdvisor
- ✅ Implementar service discovery automático
- ✅ Criar alertas inteligentes para containers
- ✅ Desenvolver dashboards avançados no Grafana
- ✅ Automatizar a integração completa

## 🎯 Configuração do Prometheus

### Configuração Básica de Scraping

```yaml
# prometheus.yml - Configuração básica para cAdvisor
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/cadvisor_alerts.yml"
  - "rules/container_alerts.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  # cAdvisor - Monitoramento de containers
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
    scrape_interval: 30s
    scrape_timeout: 10s
    metrics_path: '/metrics'
    params:
      format: ['prometheus']
    relabel_configs:
      # Adicionar labels customizados
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: cadvisor:8080
    metric_relabel_configs:
      # Filtrar métricas desnecessárias
      - source_labels: [__name__]
        regex: 'container_tasks_state|container_memory_failures_total'
        action: drop
      # Renomear labels para padronização
      - source_labels: [container_label_com_docker_compose_service]
        target_label: service_name
      - source_labels: [container_label_com_docker_compose_project]
        target_label: project_name

  # cAdvisor com service discovery (Docker)
  - job_name: 'cadvisor-docker-sd'
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 30s
        filters:
          - name: label
            values: ["prometheus.scrape=true"]
    relabel_configs:
      # Manter apenas containers com label de scraping
      - source_labels: [__meta_docker_container_label_prometheus_scrape]
        action: keep
        regex: true
      # Usar porta customizada se especificada
      - source_labels: [__meta_docker_container_label_prometheus_port]
        action: replace
        target_label: __address__
        regex: (.+)
        replacement: ${1}
      # Usar path customizado se especificado
      - source_labels: [__meta_docker_container_label_prometheus_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
        replacement: ${1}
      # Adicionar nome do container como label
      - source_labels: [__meta_docker_container_name]
        target_label: container_name
      # Adicionar imagem como label
      - source_labels: [__meta_docker_container_image]
        target_label: container_image

  # Node Exporter para métricas do host
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
    scrape_interval: 30s

  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

### Configuração Avançada com Kubernetes

```yaml
# prometheus-k8s.yml - Service Discovery para Kubernetes
scrape_configs:
  # cAdvisor via Kubernetes API
  - job_name: 'kubernetes-cadvisor'
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    kubernetes_sd_configs:
    - role: node
    relabel_configs:
    - action: labelmap
      regex: __meta_kubernetes_node_label_(.+)
    - target_label: __address__
      replacement: kubernetes.default.svc:443
    - source_labels: [__meta_kubernetes_node_name]
      regex: (.+)
      target_label: __metrics_path__
      replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor
    metric_relabel_configs:
    # Adicionar namespace e pod labels
    - source_labels: [container_label_io_kubernetes_pod_namespace]
      target_label: kubernetes_namespace
    - source_labels: [container_label_io_kubernetes_pod_name]
      target_label: kubernetes_pod_name
    - source_labels: [container_label_io_kubernetes_container_name]
      target_label: kubernetes_container_name
    # Filtrar containers do sistema
    - source_labels: [kubernetes_namespace]
      regex: 'kube-system|kube-public|kube-node-lease'
      action: drop

  # Pods com anotações de scraping
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
    - role: pod
    relabel_configs:
    # Manter apenas pods com anotação de scraping
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
      action: keep
      regex: true
    # Usar porta da anotação
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_port]
      action: replace
      target_label: __address__
      regex: (.+)
      replacement: ${1}
    # Usar path da anotação
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
      action: replace
      target_label: __metrics_path__
      regex: (.+)
      replacement: ${1}
    # Adicionar labels do Kubernetes
    - action: labelmap
      regex: __meta_kubernetes_pod_label_(.+)
    - source_labels: [__meta_kubernetes_namespace]
      target_label: kubernetes_namespace
    - source_labels: [__meta_kubernetes_pod_name]
      target_label: kubernetes_pod_name
```

## 🚨 Configuração de Alertas

### Regras de Alerta para Containers

```yaml
# rules/cadvisor_alerts.yml - Alertas para cAdvisor
groups:
- name: cadvisor.rules
  rules:
  # Container Down
  - alert: ContainerDown
    expr: up{job="cadvisor"} == 0
    for: 1m
    labels:
      severity: critical
      service: monitoring
    annotations:
      summary: "cAdvisor is down"
      description: "cAdvisor has been down for more than 1 minute on {{ $labels.instance }}"

  # Alto uso de CPU por container
  - alert: ContainerHighCpuUsage
    expr: |
      (
        rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100
      ) > 80
    for: 5m
    labels:
      severity: warning
      component: container
    annotations:
      summary: "High CPU usage detected in container"
      description: |
        Container {{ $labels.name }} on {{ $labels.instance }} has been using 
        {{ $value | humanizePercentage }} CPU for more than 5 minutes.
        
        Current usage: {{ $value | humanizePercentage }}
        Container: {{ $labels.name }}
        Image: {{ $labels.image }}

  # Alto uso de memória por container
  - alert: ContainerHighMemoryUsage
    expr: |
      (
        container_memory_working_set_bytes{name!=""} / 
        container_spec_memory_limit_bytes{name!=""} * 100
      ) > 85
    for: 3m
    labels:
      severity: warning
      component: container
    annotations:
      summary: "High memory usage detected in container"
      description: |
        Container {{ $labels.name }} on {{ $labels.instance }} is using 
        {{ $value | humanizePercentage }} of its memory limit.
        
        Current usage: {{ $value | humanizePercentage }}
        Memory limit: {{ query "container_spec_memory_limit_bytes{name='" }}{{ $labels.name }}{{ "'}" | first | value | humanizeBytes }}
        Container: {{ $labels.name }}

  # Container próximo do limite de memória
  - alert: ContainerNearMemoryLimit
    expr: |
      (
        container_memory_working_set_bytes{name!=""} / 
        container_spec_memory_limit_bytes{name!=""} * 100
      ) > 95
    for: 1m
    labels:
      severity: critical
      component: container
    annotations:
      summary: "Container near memory limit"
      description: |
        Container {{ $labels.name }} on {{ $labels.instance }} is using 
        {{ $value | humanizePercentage }} of its memory limit and may be killed soon.
        
        Current usage: {{ $value | humanizePercentage }}
        Container: {{ $labels.name }}
        Action required: Increase memory limit or optimize application

  # Container reiniciando frequentemente
  - alert: ContainerRestartingFrequently
    expr: |
      rate(container_start_time_seconds{name!=""}[15m]) * 60 * 15 > 5
    for: 5m
    labels:
      severity: warning
      component: container
    annotations:
      summary: "Container restarting frequently"
      description: |
        Container {{ $labels.name }} on {{ $labels.instance }} has restarted 
        {{ $value | humanize }} times in the last 15 minutes.
        
        Container: {{ $labels.name }}
        Image: {{ $labels.image }}
        Investigation needed: Check container logs and resource limits

  # Throttling de CPU
  - alert: ContainerCpuThrottling
    expr: |
      (
        rate(container_cpu_cfs_throttled_seconds_total{name!=""}[5m]) /
        rate(container_cpu_cfs_periods_total{name!=""}[5m]) * 100
      ) > 50
    for: 5m
    labels:
      severity: warning
      component: container
    annotations:
      summary: "Container CPU throttling detected"
      description: |
        Container {{ $labels.name }} on {{ $labels.instance }} is being 
        CPU throttled {{ $value | humanizePercentage }} of the time.
        
        Throttling rate: {{ $value | humanizePercentage }}
        Container: {{ $labels.name }}
        Recommendation: Consider increasing CPU limits

  # Alto uso de rede
  - alert: ContainerHighNetworkUsage
    expr: |
      (
        rate(container_network_transmit_bytes_total{name!=""}[5m]) +
        rate(container_network_receive_bytes_total{name!=""}[5m])
      ) > 100 * 1024 * 1024  # 100 MB/s
    for: 5m
    labels:
      severity: info
      component: container
    annotations:
      summary: "High network usage detected in container"
      description: |
        Container {{ $labels.name }} on {{ $labels.instance }} is using 
        {{ $value | humanizeBytes }}/s of network bandwidth.
        
        Network usage: {{ $value | humanizeBytes }}/s
        Container: {{ $labels.name }}

  # Filesystem quase cheio
  - alert: ContainerFilesystemNearFull
    expr: |
      (
        container_fs_usage_bytes{name!=""} / 
        container_fs_limit_bytes{name!=""} * 100
      ) > 85
    for: 5m
    labels:
      severity: warning
      component: container
    annotations:
      summary: "Container filesystem usage high"
      description: |
        Container {{ $labels.name }} filesystem on {{ $labels.device }} 
        is {{ $value | humanizePercentage }} full.
        
        Usage: {{ $value | humanizePercentage }}
        Device: {{ $labels.device }}
        Container: {{ $labels.name }}
```

### Alertas Específicos por Aplicação

```yaml
# rules/application_alerts.yml - Alertas específicos
groups:
- name: application.rules
  rules:
  # Web servers (Nginx, Apache)
  - alert: WebServerHighErrorRate
    expr: |
      (
        rate(container_cpu_usage_seconds_total{image=~".*nginx.*|.*apache.*"}[5m]) > 0.8
      ) and (
        rate(container_network_receive_errors_total{image=~".*nginx.*|.*apache.*"}[5m]) > 10
      )
    for: 3m
    labels:
      severity: warning
      service: web
    annotations:
      summary: "Web server showing signs of stress"
      description: |
        Web server container {{ $labels.name }} is showing high CPU usage 
        and network errors, indicating potential issues.

  # Databases
  - alert: DatabaseHighMemoryPressure
    expr: |
      (
        container_memory_working_set_bytes{image=~".*mysql.*|.*postgres.*|.*redis.*"} /
        container_spec_memory_limit_bytes{image=~".*mysql.*|.*postgres.*|.*redis.*"} * 100
      ) > 90
    for: 2m
    labels:
      severity: critical
      service: database
    annotations:
      summary: "Database container under memory pressure"
      description: |
        Database container {{ $labels.name }} is using {{ $value | humanizePercentage }} 
        of its memory limit. Performance degradation expected.

  # Microservices
  - alert: MicroserviceUnhealthy
    expr: |
      (
        rate(container_cpu_usage_seconds_total{container_label_service_type="microservice"}[5m]) < 0.01
      ) and (
        container_memory_working_set_bytes{container_label_service_type="microservice"} > 0
      )
    for: 10m
    labels:
      severity: warning
      service: microservice
    annotations:
      summary: "Microservice appears to be idle or stuck"
      description: |
        Microservice {{ $labels.name }} has very low CPU usage but is consuming memory, 
        which may indicate it's stuck or not processing requests.
```

## 📊 Docker Compose Completo

### Stack de Monitoramento Integrada

```yaml
# docker-compose.monitoring.yml - Stack completa
version: '3.8'

networks:
  monitoring:
    driver: bridge

volumes:
  prometheus_data:
  grafana_data:
  alertmanager_data:

services:
  # cAdvisor - Monitoramento de containers
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.47.0
    container_name: cadvisor
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
      - '--housekeeping_interval=30s'
      - '--max_housekeeping_interval=35s'
      - '--event_storage_event_limit=default=0'
      - '--event_storage_age_limit=default=0'
      - '--disable_metrics=percpu,sched,tcp,udp'
      - '--docker_only=true'
      - '--store_container_labels=false'
      - '--whitelisted_container_labels=prometheus.scrape,service.name,service.version'
    labels:
      - "prometheus.scrape=true"
      - "prometheus.port=8080"
      - "prometheus.path=/metrics"
    networks:
      - monitoring

  # Node Exporter - Métricas do sistema
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    labels:
      - "prometheus.scrape=true"
      - "prometheus.port=9100"
    networks:
      - monitoring

  # Prometheus - Coleta e armazenamento
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=15d'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
    depends_on:
      - cadvisor
      - node-exporter
    labels:
      - "prometheus.scrape=true"
      - "prometheus.port=9090"
    networks:
      - monitoring

  # Alertmanager - Gerenciamento de alertas
  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    restart: unless-stopped
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager:/etc/alertmanager
      - alertmanager_data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://localhost:9093'
    networks:
      - monitoring

  # Grafana - Visualização
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-worldmap-panel
    depends_on:
      - prometheus
    networks:
      - monitoring

  # Aplicações de exemplo para monitorar
  nginx-app:
    image: nginx:alpine
    container_name: nginx-app
    restart: unless-stopped
    ports:
      - "80:80"
    labels:
      - "prometheus.scrape=false"  # Nginx não expõe métricas por padrão
      - "service.name=nginx"
      - "service.version=1.0.0"
      - "monitor=true"
    networks:
      - monitoring

  redis-app:
    image: redis:alpine
    container_name: redis-app
    restart: unless-stopped
    ports:
      - "6379:6379"
    labels:
      - "service.name=redis"
      - "service.version=7.0"
      - "monitor=true"
    networks:
      - monitoring

  # Aplicação com métricas customizadas
  app-with-metrics:
    image: prom/prometheus:latest  # Usando como exemplo
    container_name: app-with-metrics
    restart: unless-stopped
    ports:
      - "8081:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.listen-address=0.0.0.0:9090'
    labels:
      - "prometheus.scrape=true"
      - "prometheus.port=9090"
      - "prometheus.path=/metrics"
      - "service.name=custom-app"
      - "service.version=2.1.0"
    networks:
      - monitoring
```

## 🎨 Dashboards do Grafana

### Dashboard Principal de Containers

```json
{
  "dashboard": {
    "id": null,
    "title": "Container Monitoring - cAdvisor",
    "tags": ["cadvisor", "containers", "docker"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Container CPU Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(rate(container_cpu_usage_seconds_total{name!=''}[5m])) by (name) * 100",
            "legendFormat": "{{name}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 50},
                {"color": "red", "value": 80}
              ]
            }
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Container Memory Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(container_memory_working_set_bytes{name!=''}) by (name)",
            "legendFormat": "{{name}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "bytes",
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 536870912},
                {"color": "red", "value": 1073741824}
              ]
            }
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      },
      {
        "id": 3,
        "title": "Container Network I/O",
        "type": "timeseries",
        "targets": [
          {
            "expr": "sum(rate(container_network_receive_bytes_total{name!=''}[5m])) by (name)",
            "legendFormat": "{{name}} - RX"
          },
          {
            "expr": "sum(rate(container_network_transmit_bytes_total{name!=''}[5m])) by (name)",
            "legendFormat": "{{name}} - TX"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "Bps"
          }
        },
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
      },
      {
        "id": 4,
        "title": "Container Filesystem Usage",
        "type": "bargauge",
        "targets": [
          {
            "expr": "(container_fs_usage_bytes{name!=''} / container_fs_limit_bytes{name!=''}) * 100",
            "legendFormat": "{{name}} - {{device}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "max": 100,
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 70},
                {"color": "red", "value": 85}
              ]
            }
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

### Script de Automação

```bash
#!/bin/bash
# setup-prometheus-cadvisor.sh - Automação completa

set -e

# Configurações
PROJECT_DIR="./prometheus-cadvisor-stack"
PROMETHEUS_VERSION="latest"
GRAFANA_VERSION="latest"
CADVISOR_VERSION="v0.47.0"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_section() {
    echo -e "${BLUE}[SECTION]${NC} $1"
}

# Criar estrutura de diretórios
setup_directories() {
    log_section "Setting up directory structure..."
    
    mkdir -p $PROJECT_DIR/{prometheus,grafana/{provisioning/{datasources,dashboards},dashboards},alertmanager}
    
    log_info "Directory structure created"
}

# Configurar Prometheus
setup_prometheus_config() {
    log_section "Setting up Prometheus configuration..."
    
    cat > $PROJECT_DIR/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "cadvisor_alerts.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
    scrape_interval: 30s
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'container_tasks_state|container_memory_failures_total'
        action: drop

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

    # Criar regras de alerta
    cat > $PROJECT_DIR/prometheus/cadvisor_alerts.yml << 'EOF'
groups:
- name: cadvisor.rules
  rules:
  - alert: ContainerDown
    expr: up{job="cadvisor"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "cAdvisor is down"
      description: "cAdvisor has been down for more than 1 minute"

  - alert: ContainerHighCpuUsage
    expr: rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100 > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage in container {{ $labels.name }}"
      description: "Container {{ $labels.name }} CPU usage is {{ $value }}%"

  - alert: ContainerHighMemoryUsage
    expr: (container_memory_working_set_bytes{name!=""} / container_spec_memory_limit_bytes{name!=""}) * 100 > 85
    for: 3m
    labels:
      severity: warning
    annotations:
      summary: "High memory usage in container {{ $labels.name }}"
      description: "Container {{ $labels.name }} memory usage is {{ $value }}%"
EOF

    log_info "Prometheus configuration created"
}

# Configurar Grafana
setup_grafana_config() {
    log_section "Setting up Grafana configuration..."
    
    # Datasource
    cat > $PROJECT_DIR/grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

    # Dashboard provisioning
    cat > $PROJECT_DIR/grafana/provisioning/dashboards/dashboards.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
EOF

    log_info "Grafana configuration created"
}

# Configurar Alertmanager
setup_alertmanager_config() {
    log_section "Setting up Alertmanager configuration..."
    
    cat > $PROJECT_DIR/alertmanager/alertmanager.yml << 'EOF'
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alertmanager@example.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
- name: 'web.hook'
  webhook_configs:
  - url: 'http://127.0.0.1:5001/'
    
- name: 'email'
  email_configs:
  - to: 'admin@example.com'
    subject: 'Alert: {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      {{ end }}
EOF

    log_info "Alertmanager configuration created"
}

# Criar dashboard do Grafana
create_grafana_dashboard() {
    log_section "Creating Grafana dashboard..."
    
    cat > $PROJECT_DIR/grafana/dashboards/cadvisor-dashboard.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "cAdvisor Container Monitoring",
    "tags": ["cadvisor", "containers"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Running Containers",
        "type": "stat",
        "targets": [
          {
            "expr": "count(container_last_seen{name!=\"\"})",
            "legendFormat": "Containers"
          }
        ],
        "gridPos": {"h": 4, "w": 6, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Total CPU Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(rate(container_cpu_usage_seconds_total{name!=\"\"}[5m])) * 100",
            "legendFormat": "CPU %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent"
          }
        },
        "gridPos": {"h": 4, "w": 6, "x": 6, "y": 0}
      },
      {
        "id": 3,
        "title": "Total Memory Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(container_memory_working_set_bytes{name!=\"\"})",
            "legendFormat": "Memory"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "bytes"
          }
        },
        "gridPos": {"h": 4, "w": 6, "x": 12, "y": 0}
      },
      {
        "id": 4,
        "title": "Network I/O",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(rate(container_network_receive_bytes_total{name!=\"\"}[5m])) + sum(rate(container_network_transmit_bytes_total{name!=\"\"}[5m]))",
            "legendFormat": "Network"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "Bps"
          }
        },
        "gridPos": {"h": 4, "w": 6, "x": 18, "y": 0}
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
EOF

    log_info "Grafana dashboard created"
}

# Criar docker-compose
create_docker_compose() {
    log_section "Creating Docker Compose file..."
    
    cat > $PROJECT_DIR/docker-compose.yml << EOF
version: '3.8'

networks:
  monitoring:
    driver: bridge

volumes:
  prometheus_data:
  grafana_data:
  alertmanager_data:

services:
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:$CADVISOR_VERSION
    container_name: cadvisor
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
      - '--housekeeping_interval=30s'
      - '--disable_metrics=percpu,sched,tcp,udp'
      - '--docker_only=true'
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)(\$\$|/)'
    networks:
      - monitoring

  prometheus:
    image: prom/prometheus:$PROMETHEUS_VERSION
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=15d'
      - '--web.enable-lifecycle'
    depends_on:
      - cadvisor
      - node-exporter
    networks:
      - monitoring

  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    restart: unless-stopped
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager:/etc/alertmanager
      - alertmanager_data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:$GRAFANA_VERSION
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    depends_on:
      - prometheus
    networks:
      - monitoring

  # Aplicação de exemplo
  nginx:
    image: nginx:alpine
    container_name: nginx-example
    restart: unless-stopped
    ports:
      - "80:80"
    networks:
      - monitoring
EOF

    log_info "Docker Compose file created"
}

# Criar scripts de gerenciamento
create_management_scripts() {
    log_section "Creating management scripts..."
    
    # Script de deploy
    cat > $PROJECT_DIR/deploy.sh << 'EOF'
#!/bin/bash
set -e

echo "🚀 Deploying Prometheus + cAdvisor stack..."

# Parar stack existente
docker-compose down -v 2>/dev/null || true

# Iniciar stack
docker-compose up -d

# Aguardar serviços ficarem prontos
echo "⏳ Waiting for services to be ready..."
sleep 30

# Verificar saúde dos serviços
echo "🏥 Checking service health..."
services=("cadvisor:8080" "prometheus:9090" "grafana:3000" "alertmanager:9093")

for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)
    
    if curl -s -f "http://localhost:$port" > /dev/null; then
        echo "✅ $name is healthy"
    else
        echo "❌ $name is not responding"
    fi
done

echo
echo "📊 Access URLs:"
echo "   cAdvisor:     http://localhost:8080"
echo "   Prometheus:   http://localhost:9090"
echo "   Grafana:      http://localhost:3000 (admin/admin123)"
echo "   Alertmanager: http://localhost:9093"
echo "   Node Exporter: http://localhost:9100"
EOF

    # Script de teste
    cat > $PROJECT_DIR/test.sh << 'EOF'
#!/bin/bash
set -e

echo "🧪 Testing Prometheus + cAdvisor integration..."

# Testar métricas do cAdvisor
echo "📊 Testing cAdvisor metrics..."
if curl -s "http://localhost:8080/metrics" | grep -q "container_cpu_usage_seconds_total"; then
    echo "✅ cAdvisor metrics are available"
else
    echo "❌ cAdvisor metrics not found"
    exit 1
fi

# Testar se Prometheus está coletando
echo "📈 Testing Prometheus scraping..."
if curl -s "http://localhost:9090/api/v1/query?query=up{job='cadvisor'}" | grep -q '"value":\[.*,"1"\]'; then
    echo "✅ Prometheus is scraping cAdvisor"
else
    echo "❌ Prometheus is not scraping cAdvisor properly"
    exit 1
fi

# Testar alertas
echo "🚨 Testing alert rules..."
if curl -s "http://localhost:9090/api/v1/rules" | grep -q "cadvisor.rules"; then
    echo "✅ Alert rules are loaded"
else
    echo "❌ Alert rules not found"
    exit 1
fi

echo "✅ All tests passed!"
EOF

    # Tornar scripts executáveis
    chmod +x $PROJECT_DIR/deploy.sh
    chmod +x $PROJECT_DIR/test.sh
    
    log_info "Management scripts created"
}

# Função principal
main() {
    log_info "🚀 Setting up complete Prometheus + cAdvisor monitoring stack..."
    
    setup_directories
    setup_prometheus_config
    setup_grafana_config
    setup_alertmanager_config
    create_grafana_dashboard
    create_docker_compose
    create_management_scripts
    
    log_info "✅ Setup completed successfully!"
    echo
    echo "📁 Project created in: $PROJECT_DIR"
    echo "🚀 To deploy: cd $PROJECT_DIR && ./deploy.sh"
    echo "🧪 To test: cd $PROJECT_DIR && ./test.sh"
    echo
    echo "📊 After deployment, access:"
    echo "   - cAdvisor: http://localhost:8080"
    echo "   - Prometheus: http://localhost:9090"
    echo "   - Grafana: http://localhost:3000 (admin/admin123)"
    echo "   - Alertmanager: http://localhost:9093"
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## 🚀 Exercício Prático

### Objetivo
Implementar integração completa entre cAdvisor e Prometheus com alertas e dashboards.

### Parte 1: Setup Automático

1. **Executar setup:**
```bash
# Criar stack completa
chmod +x setup-prometheus-cadvisor.sh
./setup-prometheus-cadvisor.sh
```

2. **Deploy da stack:**
```bash
# Navegar para o projeto
cd prometheus-cadvisor-stack

# Fazer deploy
./deploy.sh
```

### Parte 2: Verificação e Testes

1. **Executar testes:**
```bash
# Testar integração
./test.sh
```

2. **Verificar métricas:**
```bash
# Acessar Prometheus
open http://localhost:9090

# Testar queries
# - up{job="cadvisor"}
# - container_cpu_usage_seconds_total
# - rate(container_cpu_usage_seconds_total[5m])
```

### Parte 3: Configuração de Alertas

1. **Verificar alertas no Prometheus:**
   - Acessar http://localhost:9090/alerts
   - Verificar regras carregadas

2. **Testar Alertmanager:**
   - Acessar http://localhost:9093
   - Verificar configuração

### Parte 4: Dashboards no Grafana

1. **Acessar Grafana:**
   - URL: http://localhost:3000
   - Login: admin/admin123

2. **Verificar datasource e dashboard:**
   - Datasource Prometheus configurado
   - Dashboard cAdvisor disponível

### Validação
- [ ] Stack completa executando
- [ ] Prometheus coletando métricas do cAdvisor
- [ ] Alertas configurados e funcionando
- [ ] Grafana exibindo métricas
- [ ] Dashboards responsivos
- [ ] Testes automatizados passando

## 📚 Resumo do Módulo

### Conceitos Aprendidos
- ✅ **Configuração:** Prometheus scraping cAdvisor
- ✅ **Service Discovery:** Automático para Docker/Kubernetes
- ✅ **Alertas:** Regras inteligentes para containers
- ✅ **Dashboards:** Visualizações avançadas
- ✅ **Automação:** Scripts completos de deploy

### Próximos Passos
- **[Módulo 05: Troubleshooting](05-troubleshooting-performance.md)** - Diagnóstico avançado
- **[Módulo 06: Projeto Final](06-projeto-final.md)** - Implementação completa

---

## Navegação

- [← Módulo 03: Métricas e Coleta](03-metricas-coleta.md)
- [🏠 Página Principal](README.md)
- [➡️ Próximo: Troubleshooting](05-troubleshooting-performance.md)

---

**Fantástico!** 🎉 Você dominou a integração completa entre cAdvisor e Prometheus. Agora você tem um sistema de monitoramento robusto e automatizado!