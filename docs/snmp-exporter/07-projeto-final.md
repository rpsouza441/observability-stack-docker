# 🚀 MÓDULO 07: PROJETO FINAL

> **Implementação completa de um sistema de monitoramento SNMP para infraestrutura de rede**

## 🎯 Objetivos do Projeto

Ao final deste projeto, você terá implementado:

- ✅ **Sistema completo** de monitoramento SNMP
- ✅ **Descoberta automática** de dispositivos de rede
- ✅ **Dashboards especializados** por tipo de dispositivo
- ✅ **Alertas inteligentes** e escalonamento
- ✅ **Documentação técnica** completa
- ✅ **Ambiente de produção** robusto

---

## 🏗️ Arquitetura do Projeto

### Visão Geral

```
┌─────────────────────────────────────────────────────────────┐
│                    REDE CORPORATIVA                        │
├─────────────────────────────────────────────────────────────┤
│  Core Switch     Access Switches      Roteadores           │
│  192.168.1.10    192.168.1.11-15     192.168.1.1-2        │
│       │               │                    │               │
│       └───────────────┼────────────────────┘               │
│                       │                                    │
│              ┌────────▼────────┐                           │
│              │  SNMP Exporter  │                           │
│              │   (Port 9116)   │                           │
│              └────────┬────────┘                           │
│                       │                                    │
│              ┌────────▼────────┐                           │
│              │   Prometheus    │                           │
│              │   (Port 9090)   │                           │
│              └────────┬────────┘                           │
│                       │                                    │
│       ┌───────────────┼───────────────┐                   │
│       │               │               │                   │
│ ┌─────▼─────┐ ┌───────▼───────┐ ┌─────▼─────┐             │
│ │  Grafana  │ │ Alertmanager  │ │   Logs    │             │
│ │(Port 3000)│ │ (Port 9093)   │ │ (ELK/Loki)│             │
│ └───────────┘ └───────────────┘ └───────────┘             │
└─────────────────────────────────────────────────────────────┘
```

### Componentes do Sistema

1. **SNMP Exporter**: Coleta métricas SNMP dos dispositivos
2. **Prometheus**: Armazena e processa métricas
3. **Grafana**: Visualização e dashboards
4. **Alertmanager**: Gerenciamento de alertas
5. **Node Exporter**: Métricas do servidor de monitoramento
6. **Blackbox Exporter**: Testes de conectividade

---

## 📋 Requisitos do Projeto

### Funcionais

- **RF01**: Descobrir automaticamente dispositivos SNMP na rede
- **RF02**: Monitorar switches, roteadores e dispositivos de rede
- **RF03**: Coletar métricas de interface, CPU, memória e temperatura
- **RF04**: Gerar alertas para falhas e degradação de performance
- **RF05**: Prover dashboards específicos por tipo de dispositivo
- **RF06**: Manter histórico de métricas por 90 dias
- **RF07**: Suportar autenticação SNMPv3
- **RF08**: Implementar backup automático de configurações

### Não Funcionais

- **RNF01**: Tempo de resposta < 30s para coleta de métricas
- **RNF02**: Disponibilidade > 99.5%
- **RNF03**: Suportar até 100 dispositivos simultâneos
- **RNF04**: Interface web responsiva
- **RNF05**: Logs estruturados e auditáveis
- **RNF06**: Segurança com HTTPS e autenticação

---

## 🛠️ Implementação Passo a Passo

### Passo 1: Estrutura do Projeto

```bash
# Criar estrutura de diretórios
mkdir -p network-monitoring/{config,dashboards,scripts,docs,backup}
cd network-monitoring

# Estrutura final
network-monitoring/
├── docker-compose.yml
├── .env
├── config/
│   ├── snmp.yml
│   ├── prometheus.yml
│   ├── alertmanager.yml
│   └── alerts/
│       ├── network.yml
│       ├── devices.yml
│       └── infrastructure.yml
├── dashboards/
│   ├── network-overview.json
│   ├── switch-details.json
│   ├── router-details.json
│   └── device-health.json
├── scripts/
│   ├── discovery.sh
│   ├── backup.sh
│   ├── health-check.sh
│   └── deploy.sh
├── docs/
│   ├── README.md
│   ├── INSTALL.md
│   ├── MAINTENANCE.md
│   └── TROUBLESHOOTING.md
└── backup/
    ├── configs/
    └── data/
```

### Passo 2: Configuração do Ambiente

#### .env
```bash
# Configurações do ambiente
COMPOSE_PROJECT_NAME=network-monitoring

# Versões dos containers
PROMETHEUS_VERSION=v2.45.0
GRAFANA_VERSION=10.0.0
SNMP_EXPORTER_VERSION=v0.21.0
ALERTMANAGER_VERSION=v0.25.0
NODE_EXPORTER_VERSION=v1.6.0
BLACKBOX_EXPORTER_VERSION=v0.24.0

# Configurações de rede
NETWORK_SUBNET=192.168.1.0/24
SNMP_COMMUNITY=public
SNMP_V3_USER=admin
SNMP_V3_PASS=SecurePass123

# Configurações de retenção
PROMETHEUS_RETENTION=90d
GRAFANA_ADMIN_PASSWORD=admin123

# Configurações de alertas
SMTP_SERVER=smtp.company.com
SMTP_PORT=587
SMTP_USER=alerts@company.com
SMTP_PASS=AlertPass123
ALERT_EMAIL=network-team@company.com
```

#### docker-compose.yml
```yaml
version: '3.8'

services:
  # SNMP Exporter
  snmp-exporter:
    image: prom/snmp-exporter:${SNMP_EXPORTER_VERSION}
    container_name: snmp-exporter
    ports:
      - "9116:9116"
    volumes:
      - ./config/snmp.yml:/etc/snmp_exporter/snmp.yml:ro
    command:
      - '--config.file=/etc/snmp_exporter/snmp.yml'
      - '--log.level=info'
      - '--log.format=json'
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9116/"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - monitoring
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # Prometheus
  prometheus:
    image: prom/prometheus:${PROMETHEUS_VERSION}
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./config/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./config/alerts:/etc/prometheus/alerts:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=${PROMETHEUS_RETENTION}'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
      - '--log.level=info'
      - '--log.format=json'
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9090/-/healthy"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - monitoring
    depends_on:
      - snmp-exporter

  # Grafana
  grafana:
    image: grafana/grafana:${GRAFANA_VERSION}
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./dashboards:/var/lib/grafana/dashboards:ro
      - ./config/grafana/provisioning:/etc/grafana/provisioning:ro
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_SECURITY_ALLOW_EMBEDDING=true
      - GF_AUTH_ANONYMOUS_ENABLED=false
      - GF_LOG_MODE=console,file
      - GF_LOG_LEVEL=info
      - GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH=/var/lib/grafana/dashboards/network-overview.json
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:3000/api/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - monitoring
    depends_on:
      - prometheus

  # Alertmanager
  alertmanager:
    image: prom/alertmanager:${ALERTMANAGER_VERSION}
    container_name: alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./config/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
      - alertmanager_data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://localhost:9093'
      - '--log.level=info'
      - '--log.format=json'
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9093/-/healthy"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - monitoring

  # Node Exporter (para monitorar o servidor)
  node-exporter:
    image: prom/node-exporter:${NODE_EXPORTER_VERSION}
    container_name: node-exporter
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
      - '--log.level=info'
    restart: unless-stopped
    networks:
      - monitoring

  # Blackbox Exporter (para testes de conectividade)
  blackbox-exporter:
    image: prom/blackbox-exporter:${BLACKBOX_EXPORTER_VERSION}
    container_name: blackbox-exporter
    ports:
      - "9115:9115"
    volumes:
      - ./config/blackbox.yml:/etc/blackbox_exporter/config.yml:ro
    command:
      - '--config.file=/etc/blackbox_exporter/config.yml'
      - '--log.level=info'
    restart: unless-stopped
    networks:
      - monitoring

  # Nginx (proxy reverso e SSL)
  nginx:
    image: nginx:alpine
    container_name: nginx-proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./config/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./config/nginx/ssl:/etc/nginx/ssl:ro
    restart: unless-stopped
    networks:
      - monitoring
    depends_on:
      - grafana
      - prometheus
      - alertmanager

volumes:
  prometheus_data:
  grafana_data:
  alertmanager_data:

networks:
  monitoring:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### Passo 3: Configuração do SNMP Exporter

#### config/snmp.yml
```yaml
# Configuração completa do SNMP Exporter
auths:
  # SNMPv2c
  public_v2:
    community: public
    version: 2
  
  private_v2:
    community: private
    version: 2
  
  # SNMPv3
  secure_v3:
    username: admin
    security_level: authPriv
    password: SecurePass123
    auth_protocol: SHA
    priv_protocol: AES
    priv_password: SecurePass123
    version: 3
  
  readonly_v3:
    username: readonly
    security_level: authNoPriv
    password: ReadOnlyPass123
    auth_protocol: SHA
    version: 3

modules:
  # Módulo genérico para switches
  switch_generic:
    walk:
      # System Information
      - 1.3.6.1.2.1.1.1.0     # sysDescr
      - 1.3.6.1.2.1.1.3.0     # sysUpTime
      - 1.3.6.1.2.1.1.5.0     # sysName
      - 1.3.6.1.2.1.1.6.0     # sysLocation
      
      # Interface Statistics
      - 1.3.6.1.2.1.2.2.1.2   # ifDescr
      - 1.3.6.1.2.1.2.2.1.3   # ifType
      - 1.3.6.1.2.1.2.2.1.5   # ifSpeed
      - 1.3.6.1.2.1.2.2.1.7   # ifAdminStatus
      - 1.3.6.1.2.1.2.2.1.8   # ifOperStatus
      - 1.3.6.1.2.1.2.2.1.10  # ifInOctets
      - 1.3.6.1.2.1.2.2.1.11  # ifInUcastPkts
      - 1.3.6.1.2.1.2.2.1.13  # ifInDiscards
      - 1.3.6.1.2.1.2.2.1.14  # ifInErrors
      - 1.3.6.1.2.1.2.2.1.16  # ifOutOctets
      - 1.3.6.1.2.1.2.2.1.17  # ifOutUcastPkts
      - 1.3.6.1.2.1.2.2.1.19  # ifOutDiscards
      - 1.3.6.1.2.1.2.2.1.20  # ifOutErrors
      
      # High Capacity Counters
      - 1.3.6.1.2.1.31.1.1.1.1  # ifName
      - 1.3.6.1.2.1.31.1.1.1.6  # ifHCInOctets
      - 1.3.6.1.2.1.31.1.1.1.10 # ifHCOutOctets
      - 1.3.6.1.2.1.31.1.1.1.15 # ifHighSpeed
      - 1.3.6.1.2.1.31.1.1.1.18 # ifAlias
      
    lookups:
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.2.2.1.2  # ifDescr
        drop_source_indexes: false
      - source_indexes: [ciscoMemoryPoolType]
        lookup: 1.3.6.1.4.1.9.9.48.1.1.1.2  # ciscoMemoryPoolName
        drop_source_indexes: false
      - source_indexes: [ciscoEnvMonTemperatureStatusIndex]
        lookup: 1.3.6.1.4.1.9.9.13.1.3.1.2  # ciscoEnvMonTemperatureDescr
        drop_source_indexes: false
        
    overrides:
      ifAdminStatus:
        type: gauge
      ifOperStatus:
        type: gauge
      cpmCPUTotal5minRev:
        type: gauge
      cpmCPUTotal1minRev:
        type: gauge
      ciscoMemoryPoolUsed:
        type: gauge
      ciscoMemoryPoolFree:
        type: gauge
      ciscoEnvMonTemperatureValue:
        type: gauge
      ciscoEnvMonTemperatureState:
        type: gauge
        
    walk_params:
      timeout: 15s
      retries: 3
      max_repetitions: 25

  # Módulo para roteadores
  router_generic:
    walk:
      # System Information
      - 1.3.6.1.2.1.1.1.0     # sysDescr
      - 1.3.6.1.2.1.1.3.0     # sysUpTime
      - 1.3.6.1.2.1.1.5.0     # sysName
      
      # Interface Information
      - 1.3.6.1.2.1.2.2.1.2   # ifDescr
      - 1.3.6.1.2.1.2.2.1.7   # ifAdminStatus
      - 1.3.6.1.2.1.2.2.1.8   # ifOperStatus
      - 1.3.6.1.2.1.31.1.1.1.6  # ifHCInOctets
      - 1.3.6.1.2.1.31.1.1.1.10 # ifHCOutOctets
      
      # IP Routing
      - 1.3.6.1.2.1.4.1.0     # ipForwarding
      - 1.3.6.1.2.1.4.3.0     # ipInReceives
      - 1.3.6.1.2.1.4.9.0     # ipInDiscards
      - 1.3.6.1.2.1.4.10.0    # ipOutRequests
      - 1.3.6.1.2.1.4.11.0    # ipOutDiscards
      
      # BGP (se disponível)
      - 1.3.6.1.2.1.15.3.1.2  # bgpPeerState
      - 1.3.6.1.2.1.15.3.1.7  # bgpPeerInUpdates
      - 1.3.6.1.2.1.15.3.1.8  # bgpPeerOutUpdates
      
    lookups:
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.2.2.1.2  # ifDescr
        drop_source_indexes: false
        
    overrides:
      ifAdminStatus:
        type: gauge
      ifOperStatus:
        type: gauge
      ipForwarding:
        type: gauge
      bgpPeerState:
        type: gauge
        
    walk_params:
      timeout: 20s
      retries: 3
      max_repetitions: 25

  # Módulo básico para descoberta
  discovery:
    walk:
      - 1.3.6.1.2.1.1.1.0     # sysDescr
      - 1.3.6.1.2.1.1.2.0     # sysObjectID
      - 1.3.6.1.2.1.1.3.0     # sysUpTime
      - 1.3.6.1.2.1.1.5.0     # sysName
      - 1.3.6.1.2.1.1.6.0     # sysLocation
      - 1.3.6.1.2.1.1.4.0     # sysContact
      
    walk_params:
      timeout: 5s
      retries: 2
      max_repetitions: 10
```

### Passo 4: Configuração do Prometheus

#### config/prometheus.yml
```yaml
global:
  scrape_interval: 30s
  evaluation_interval: 30s
  external_labels:
    cluster: 'network-monitoring'
    environment: 'production'

rule_files:
  - "/etc/prometheus/alerts/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  # SNMP Exporter - Switches
  - job_name: 'snmp-switches'
    static_configs:
      - targets:
        - 192.168.1.10  # Core Switch
        - 192.168.1.11  # Access Switch 1
        - 192.168.1.12  # Access Switch 2
        - 192.168.1.13  # Access Switch 3
        - 192.168.1.14  # Access Switch 4
        - 192.168.1.15  # Access Switch 5
    metrics_path: /snmp
    params:
      auth: [public_v2]
      module: [switch_generic]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116
      - source_labels: [instance]
        target_label: device_type
        replacement: 'switch'
    scrape_interval: 60s
    scrape_timeout: 30s

  # SNMP Exporter - Roteadores
  - job_name: 'snmp-routers'
    static_configs:
      - targets:
        - 192.168.1.1   # Router Principal
        - 192.168.1.2   # Router Backup
    metrics_path: /snmp
    params:
      auth: [public_v2]
      module: [router_generic]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116
      - source_labels: [instance]
        target_label: device_type
        replacement: 'router'
    scrape_interval: 60s
    scrape_timeout: 30s

  # SNMP Exporter - Dispositivos Cisco
  - job_name: 'snmp-cisco'
    static_configs:
      - targets:
        - 192.168.1.20  # Cisco Switch
        - 192.168.1.21  # Cisco Router
    metrics_path: /snmp
    params:
      auth: [secure_v3]
      module: [cisco_advanced]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116
      - source_labels: [instance]
        target_label: device_type
        replacement: 'cisco'
      - source_labels: [instance]
        target_label: vendor
        replacement: 'cisco'
    scrape_interval: 60s
    scrape_timeout: 45s

  # SNMP Exporter Health
  - job_name: 'snmp-exporter'
    static_configs:
      - targets: ['snmp-exporter:9116']
    scrape_interval: 15s
    metrics_path: /metrics

  # Prometheus Self-Monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
    scrape_interval: 15s

  # Node Exporter (servidor de monitoramento)
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
    scrape_interval: 15s

  # Blackbox Exporter - Conectividade
  - job_name: 'blackbox-icmp'
    metrics_path: /probe
    params:
      module: [icmp]
    static_configs:
      - targets:
        - 192.168.1.1   # Gateway
        - 192.168.1.10  # Core Switch
        - 8.8.8.8       # DNS Externo
        - 1.1.1.1       # DNS Cloudflare
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115
    scrape_interval: 30s

  # Blackbox Exporter - HTTP
  - job_name: 'blackbox-http'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - http://192.168.1.10  # Switch Web Interface
        - https://www.google.com
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115
    scrape_interval: 60s

  # Descoberta automática via file_sd
  - job_name: 'snmp-discovery'
    file_sd_configs:
      - files:
        - '/etc/prometheus/discovery/*.json'
        refresh_interval: 5m
    metrics_path: /snmp
    params:
      auth: [public_v2]
      module: [discovery]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116
    scrape_interval: 300s
    scrape_timeout: 60s
```

### Passo 5: Configuração de Alertas

#### config/alertmanager.yml
```yaml
global:
  smtp_smarthost: '${SMTP_SERVER}:${SMTP_PORT}'
  smtp_from: '${SMTP_USER}'
  smtp_auth_username: '${SMTP_USER}'
  smtp_auth_password: '${SMTP_PASS}'
  smtp_require_tls: true

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'network-team'
  routes:
    # Alertas críticos - notificação imediata
    - match:
        severity: critical
      receiver: 'critical-alerts'
      group_wait: 0s
      repeat_interval: 15m
    
    # Alertas de warning - agrupados
    - match:
        severity: warning
      receiver: 'warning-alerts'
      group_wait: 30s
      repeat_interval: 2h
    
    # Alertas informativos
    - match:
        severity: info
      receiver: 'info-alerts'
      group_wait: 5m
      repeat_interval: 12h

receivers:
  - name: 'network-team'
    email_configs:
      - to: '${ALERT_EMAIL}'
        subject: '[NETWORK] {{ .GroupLabels.alertname }} - {{ .Status | toUpper }}'
        body: |
          {{ range .Alerts }}
          **Alert:** {{ .Annotations.summary }}
          **Description:** {{ .Annotations.description }}
          **Severity:** {{ .Labels.severity }}
          **Instance:** {{ .Labels.instance }}
          **Time:** {{ .StartsAt.Format "2006-01-02 15:04:05" }}
          {{ end }}

  - name: 'critical-alerts'
    email_configs:
      - to: '${ALERT_EMAIL}'
        subject: '🚨 [CRITICAL] {{ .GroupLabels.alertname }}'
        body: |
          **ALERTA CRÍTICO DE REDE**
          
          {{ range .Alerts }}
          **Alert:** {{ .Annotations.summary }}
          **Description:** {{ .Annotations.description }}
          **Instance:** {{ .Labels.instance }}
          **Device Type:** {{ .Labels.device_type }}
          **Time:** {{ .StartsAt.Format "2006-01-02 15:04:05" }}
          **Dashboard:** http://grafana:3000/d/network-overview
          {{ end }}
    slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#network-alerts'
        title: '🚨 Critical Network Alert'
        text: |
          {{ range .Alerts }}
          *{{ .Annotations.summary }}*
          Instance: {{ .Labels.instance }}
          {{ .Annotations.description }}
          {{ end }}

  - name: 'warning-alerts'
    email_configs:
      - to: '${ALERT_EMAIL}'
        subject: '⚠️ [WARNING] {{ .GroupLabels.alertname }}'
        body: |
          **ALERTA DE WARNING**
          
          {{ range .Alerts }}
          **Alert:** {{ .Annotations.summary }}
          **Description:** {{ .Annotations.description }}
          **Instance:** {{ .Labels.instance }}
          **Time:** {{ .StartsAt.Format "2006-01-02 15:04:05" }}
          {{ end }}

  - name: 'info-alerts'
    email_configs:
      - to: '${ALERT_EMAIL}'
        subject: 'ℹ️ [INFO] {{ .GroupLabels.alertname }}'
        body: |
          **ALERTA INFORMATIVO**
          
          {{ range .Alerts }}
          **Alert:** {{ .Annotations.summary }}
          **Description:** {{ .Annotations.description }}
          **Instance:** {{ .Labels.instance }}
          **Time:** {{ .StartsAt.Format "2006-01-02 15:04:05" }}
          {{ end }}

inhibit_rules:
  # Inibir alertas de interface quando dispositivo está down
  - source_match:
      alertname: 'DeviceDown'
    target_match:
      alertname: 'InterfaceDown'
    equal: ['instance']
  
  # Inibir alertas de CPU quando dispositivo está down
  - source_match:
      alertname: 'DeviceDown'
    target_match:
      alertname: 'HighCPUUsage'
    equal: ['instance']
```

#### config/alerts/network.yml
```yaml
groups:
  - name: network.rules
    rules:
      # Device Down
      - alert: DeviceDown
        expr: up{job=~"snmp-.*"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Dispositivo de rede {{ $labels.instance }} está inacessível"
          description: "O dispositivo {{ $labels.instance }} não responde há mais de 2 minutos."

      # Interface Down
      - alert: InterfaceDown
        expr: ifOperStatus{ifAdminStatus="1"} == 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Interface {{ $labels.ifDescr }} no dispositivo {{ $labels.instance }} está down"
          description: "A interface {{ $labels.ifDescr }} está administrativamente up mas operacionalmente down há mais de 5 minutos."

      # High Interface Utilization
      - alert: HighInterfaceUtilization
        expr: |
          (
            rate(ifHCInOctets[5m]) * 8 / ifHighSpeed / 1000000 * 100 > 80
            or
            rate(ifHCOutOctets[5m]) * 8 / ifHighSpeed / 1000000 * 100 > 80
          )
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Alta utilização na interface {{ $labels.ifDescr }} do dispositivo {{ $labels.instance }}"
          description: "A interface {{ $labels.ifDescr }} está com utilização acima de 80% há mais de 10 minutos. Valor atual: {{ $value }}%"

      # Interface Errors
      - alert: InterfaceErrors
        expr: |
          (
            rate(ifInErrors[5m]) > 10
            or
            rate(ifOutErrors[5m]) > 10
          )
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Erros detectados na interface {{ $labels.ifDescr }} do dispositivo {{ $labels.instance }}"
          description: "A interface {{ $labels.ifDescr }} está apresentando mais de 10 erros por segundo há mais de 5 minutos."

      # High CPU Usage (Cisco)
      - alert: HighCPUUsage
        expr: cpmCPUTotal5minRev > 80
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Alto uso de CPU no dispositivo {{ $labels.instance }}"
          description: "O dispositivo {{ $labels.instance }} está com CPU acima de 80% há mais de 15 minutos. Valor atual: {{ $value }}%"

      # Critical CPU Usage (Cisco)
      - alert: CriticalCPUUsage
        expr: cpmCPUTotal5minRev > 95
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Uso crítico de CPU no dispositivo {{ $labels.instance }}"
          description: "O dispositivo {{ $labels.instance }} está com CPU acima de 95% há mais de 5 minutos. Valor atual: {{ $value }}%"

      # High Memory Usage (Cisco)
      - alert: HighMemoryUsage
        expr: |
          (
            ciscoMemoryPoolUsed / (ciscoMemoryPoolUsed + ciscoMemoryPoolFree) * 100 > 85
          )
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Alto uso de memória no dispositivo {{ $labels.instance }}"
          description: "O dispositivo {{ $labels.instance }} está com memória acima de 85% há mais de 15 minutos. Pool: {{ $labels.ciscoMemoryPoolName }}"

      # High Temperature (Cisco)
      - alert: HighTemperature
        expr: ciscoEnvMonTemperatureValue > 70
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Temperatura alta no dispositivo {{ $labels.instance }}"
          description: "O sensor {{ $labels.ciscoEnvMonTemperatureDescr }} no dispositivo {{ $labels.instance }} está reportando {{ $value }}°C há mais de 10 minutos."

      # Critical Temperature (Cisco)
      - alert: CriticalTemperature
        expr: ciscoEnvMonTemperatureValue > 80
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Temperatura crítica no dispositivo {{ $labels.instance }}"
          description: "O sensor {{ $labels.ciscoEnvMonTemperatureDescr }} no dispositivo {{ $labels.instance }} está reportando {{ $value }}°C há mais de 2 minutos."

      # SNMP Scrape Duration
      - alert: SlowSNMPScrape
        expr: snmp_scrape_duration_seconds > 30
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Coleta SNMP lenta para {{ $labels.instance }}"
          description: "A coleta SNMP para {{ $labels.instance }} está demorando mais de 30 segundos há mais de 5 minutos."

      # SNMP Scrape Failures
      - alert: SNMPScrapeFailure
        expr: up{job=~"snmp-.*"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Falha na coleta SNMP para {{ $labels.instance }}"
          description: "Não foi possível coletar métricas SNMP de {{ $labels.instance }} há mais de 2 minutos."
```

---

## 📊 Scripts de Automação

### Script de Descoberta Automática

#### scripts/discovery.sh
```bash
#!/bin/bash

# Script de descoberta automática de dispositivos SNMP
# Autor: Network Monitoring Team
# Versão: 1.0

set -euo pipefail

# Configurações
NETWORK_RANGE="192.168.1.0/24"
SNMP_COMMUNITY="public"
SNMP_VERSION="2c"
OUTPUT_DIR="/etc/prometheus/discovery"
LOG_FILE="/var/log/snmp-discovery.log"
TIMEOUT=5

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função de log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Função para verificar dependências
check_dependencies() {
    local deps=("nmap" "snmpget" "jq")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log "ERROR: $dep não está instalado"
            exit 1
        fi
    done
    
    log "INFO: Todas as dependências estão instaladas"
}

# Função para descobrir hosts ativos
discover_hosts() {
    log "INFO: Iniciando descoberta de hosts na rede $NETWORK_RANGE"
    
    # Usar nmap para descobrir hosts ativos
    nmap -sn "$NETWORK_RANGE" 2>/dev/null | \
        grep "Nmap scan report" | \
        awk '{print $5}' | \
        grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' > /tmp/active_hosts.txt
    
    local host_count
    host_count=$(wc -l < /tmp/active_hosts.txt)
    log "INFO: Encontrados $host_count hosts ativos"
}

# Função para testar SNMP
test_snmp() {
    local host=$1
    local community=$2
    local version=$3
    
    # Testar sysDescr (1.3.6.1.2.1.1.1.0)
    if timeout "$TIMEOUT" snmpget -v"$version" -c"$community" "$host" 1.3.6.1.2.1.1.1.0 &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Função para obter informações do dispositivo
get_device_info() {
    local host=$1
    local community=$2
    local version=$3
    
    local sys_descr
    local sys_name
    local sys_object_id
    local device_type="unknown"
    local vendor="unknown"
    
    # Obter sysDescr
    sys_descr=$(timeout "$TIMEOUT" snmpget -v"$version" -c"$community" -Oqv "$host" 1.3.6.1.2.1.1.1.0 2>/dev/null | tr -d '"' || echo "unknown")
    
    # Obter sysName
    sys_name=$(timeout "$TIMEOUT" snmpget -v"$version" -c"$community" -Oqv "$host" 1.3.6.1.2.1.1.5.0 2>/dev/null | tr -d '"' || echo "unknown")
    
    # Obter sysObjectID
    sys_object_id=$(timeout "$TIMEOUT" snmpget -v"$version" -c"$community" -Oqv "$host" 1.3.6.1.2.1.1.2.0 2>/dev/null || echo "unknown")
    
    # Determinar tipo de dispositivo e vendor baseado no sysDescr e sysObjectID
    case "$sys_descr" in
        *"Cisco"*)
            vendor="cisco"
            if [[ "$sys_descr" == *"Switch"* ]]; then
                device_type="switch"
            elif [[ "$sys_descr" == *"Router"* ]]; then
                device_type="router"
            fi
            ;;
        *"HP"*|*"HPE"*)
            vendor="hp"
            device_type="switch"
            ;;
        *"Juniper"*)
            vendor="juniper"
            if [[ "$sys_descr" == *"EX"* ]]; then
                device_type="switch"
            elif [[ "$sys_descr" == *"MX"*|*"SRX"* ]]; then
                device_type="router"
            fi
            ;;
        *"Linux"*)
            vendor="linux"
            device_type="server"
            ;;
    esac
    
    # Retornar informações em formato JSON
    cat << EOF
{
  "targets": ["$host"],
  "labels": {
    "device_type": "$device_type",
    "vendor": "$vendor",
    "sys_name": "$sys_name",
    "sys_descr": "$sys_descr",
    "sys_object_id": "$sys_object_id",
    "discovered_at": "$(date -Iseconds)"
  }
}
EOF
}

# Função principal de descoberta SNMP
discover_snmp_devices() {
    log "INFO: Iniciando descoberta SNMP"
    
    local discovered_devices=()
    local total_hosts
    local current=0
    
    total_hosts=$(wc -l < /tmp/active_hosts.txt)
    
    while IFS= read -r host; do
        current=$((current + 1))
        printf "\r${BLUE}Testando SNMP: %d/%d - %s${NC}" "$current" "$total_hosts" "$host"
        
        if test_snmp "$host" "$SNMP_COMMUNITY" "$SNMP_VERSION"; then
            printf "\n${GREEN}✓ SNMP ativo em %s${NC}\n" "$host"
            
            # Obter informações do dispositivo
            local device_info
            device_info=$(get_device_info "$host" "$SNMP_COMMUNITY" "$SNMP_VERSION")
            
            # Adicionar à lista de dispositivos descobertos
            discovered_devices+=("$device_info")
            
            log "INFO: Dispositivo SNMP descoberto: $host"
        else
            printf "\n${YELLOW}✗ SNMP não disponível em %s${NC}\n" "$host"
        fi
    done < /tmp/active_hosts.txt
    
    printf "\n"
    log "INFO: Descoberta SNMP concluída. Encontrados ${#discovered_devices[@]} dispositivos"
    
    # Gerar arquivo de descoberta para Prometheus
    generate_prometheus_discovery "${discovered_devices[@]}"
}

# Função para gerar arquivo de descoberta do Prometheus
generate_prometheus_discovery() {
    local devices=("$@")
    local output_file="$OUTPUT_DIR/snmp_devices.json"
    
    # Criar diretório se não existir
    mkdir -p "$OUTPUT_DIR"
    
    # Gerar arquivo JSON
    {
        echo "["
        for i in "${!devices[@]}"; do
            echo "  ${devices[i]}"
            if [[ $i -lt $((${#devices[@]} - 1)) ]]; then
                echo ","
            fi
        done
        echo "]"
    } > "$output_file"
    
    log "INFO: Arquivo de descoberta gerado: $output_file"
    
    # Validar JSON
    if jq empty "$output_file" 2>/dev/null; then
        log "INFO: Arquivo JSON válido"
    else
        log "ERROR: Arquivo JSON inválido"
        return 1
    fi
}

# Função para gerar relatório
generate_report() {
    local report_file="/tmp/discovery_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=== RELATÓRIO DE DESCOBERTA SNMP ==="
        echo "Data: $(date)"
        echo "Rede: $NETWORK_RANGE"
        echo "Community: $SNMP_COMMUNITY"
        echo "Versão SNMP: $SNMP_VERSION"
        echo ""
        
        if [[ -f "$OUTPUT_DIR/snmp_devices.json" ]]; then
            echo "Dispositivos descobertos:"
            jq -r '.[] | "\(.targets[0]) - \(.labels.vendor) \(.labels.device_type) (\(.labels.sys_name))"' "$OUTPUT_DIR/snmp_devices.json"
            echo ""
            echo "Total de dispositivos: $(jq length "$OUTPUT_DIR/snmp_devices.json")"
        else
            echo "Nenhum dispositivo descoberto"
        fi
        
        echo ""
        echo "=== ESTATÍSTICAS POR VENDOR ==="
        if [[ -f "$OUTPUT_DIR/snmp_devices.json" ]]; then
            jq -r '.[] | .labels.vendor' "$OUTPUT_DIR/snmp_devices.json" | sort | uniq -c
        fi
        
        echo ""
        echo "=== ESTATÍSTICAS POR TIPO ==="
        if [[ -f "$OUTPUT_DIR/snmp_devices.json" ]]; then
            jq -r '.[] | .labels.device_type' "$OUTPUT_DIR/snmp_devices.json" | sort | uniq -c
        fi
    } > "$report_file"
    
    log "INFO: Relatório gerado: $report_file"
    cat "$report_file"
}

# Função principal
main() {
    log "INFO: Iniciando descoberta automática de dispositivos SNMP"
    
    # Verificar dependências
    check_dependencies
    
    # Descobrir hosts ativos
    discover_hosts
    
    # Descobrir dispositivos SNMP
    discover_snmp_devices
    
    # Gerar relatório
    generate_report
    
    # Limpeza
    rm -f /tmp/active_hosts.txt
    
    log "INFO: Descoberta concluída com sucesso"
}

# Verificar se está sendo executado como script principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### Script de Backup

#### scripts/backup.sh
```bash
#!/bin/bash

# Script de backup para Network Monitoring
# Autor: Network Monitoring Team
# Versão: 1.0

set -euo pipefail

# Configurações
BACKUP_DIR="/opt/network-monitoring/backup"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30
COMPRESS=true

# Diretórios e arquivos para backup
CONFIG_DIRS=(
    "/opt/network-monitoring/config"
    "/opt/network-monitoring/dashboards"
    "/opt/network-monitoring/scripts"
)

DATA_DIRS=(
    "prometheus_data"
    "grafana_data"
    "alertmanager_data"
)

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Função de log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Criar diretório de backup
create_backup_dir() {
    local backup_path="$BACKUP_DIR/$DATE"
    mkdir -p "$backup_path/configs"
    mkdir -p "$backup_path/data"
    echo "$backup_path"
}

# Backup de configurações
backup_configs() {
    local backup_path=$1
    
    log "INFO: Iniciando backup de configurações"
    
    for config_dir in "${CONFIG_DIRS[@]}"; do
        if [[ -d "$config_dir" ]]; then
            local dir_name
            dir_name=$(basename "$config_dir")
            log "INFO: Backup de $config_dir"
            cp -r "$config_dir" "$backup_path/configs/$dir_name"
        else
            log "WARNING: Diretório $config_dir não encontrado"
        fi
    done
}

# Backup de dados
backup_data() {
    local backup_path=$1
    
    log "INFO: Iniciando backup de dados"
    
    # Parar containers temporariamente para backup consistente
    log "INFO: Parando containers para backup consistente"
    docker-compose stop prometheus grafana alertmanager
    
    # Backup dos volumes Docker
    for volume in "${DATA_DIRS[@]}"; do
        if docker volume inspect "network-monitoring_$volume" &>/dev/null; then
            log "INFO: Backup do volume $volume"
            docker run --rm \
                -v "network-monitoring_$volume:/data:ro" \
                -v "$backup_path/data:/backup" \
                alpine:latest \
                tar czf "/backup/$volume.tar.gz" -C /data .
        else
            log "WARNING: Volume $volume não encontrado"
        fi
    done
    
    # Reiniciar containers
    log "INFO: Reiniciando containers"
    docker-compose start prometheus grafana alertmanager
}

# Backup de metadados
backup_metadata() {
    local backup_path=$1
    
    log "INFO: Criando arquivo de metadados"
    
    cat > "$backup_path/metadata.json" << EOF
{
  "backup_date": "$(date -Iseconds)",
  "backup_version": "1.0",
  "hostname": "$(hostname)",
  "docker_compose_version": "$(docker-compose version --short)",
  "containers": [
EOF
    
    # Listar containers e suas versões
    docker-compose ps --format json | jq -s '.' >> "$backup_path/metadata.json"
    
    echo "  ]" >> "$backup_path/metadata.json"
    echo "}" >> "$backup_path/metadata.json"
}

# Comprimir backup
compress_backup() {
    local backup_path=$1
    
    if [[ "$COMPRESS" == "true" ]]; then
        log "INFO: Comprimindo backup"
        
        cd "$BACKUP_DIR"
        tar czf "$DATE.tar.gz" "$DATE/"
        
        if [[ -f "$DATE.tar.gz" ]]; then
            rm -rf "$DATE"
            log "INFO: Backup comprimido: $BACKUP_DIR/$DATE.tar.gz"
        else
            log "ERROR: Falha na compressão"
            return 1
        fi
    fi
}

# Limpeza de backups antigos
cleanup_old_backups() {
    log "INFO: Limpando backups antigos (>$RETENTION_DAYS dias)"
    
    find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete
    find "$BACKUP_DIR" -maxdepth 1 -type d -mtime +$RETENTION_DAYS -exec rm -rf {} +
    
    log "INFO: Limpeza concluída"
}

# Verificar integridade do backup
verify_backup() {
    local backup_file="$BACKUP_DIR/$DATE.tar.gz"
    
    if [[ -f "$backup_file" ]]; then
        log "INFO: Verificando integridade do backup"
        
        if tar tzf "$backup_file" >/dev/null 2>&1; then
            log "INFO: Backup íntegro"
            return 0
        else
            log "ERROR: Backup corrompido"
            return 1
        fi
    else
        log "ERROR: Arquivo de backup não encontrado"
        return 1
    fi
}

# Gerar relatório de backup
generate_report() {
    local backup_path=$1
    local backup_size
    
    if [[ "$COMPRESS" == "true" ]]; then
        backup_size=$(du -h "$BACKUP_DIR/$DATE.tar.gz" | cut -f1)
    else
        backup_size=$(du -sh "$backup_path" | cut -f1)
    fi
    
    cat << EOF

${GREEN}=== RELATÓRIO DE BACKUP ===${NC}
Data: $(date)
Diretório: $BACKUP_DIR
Tamanho: $backup_size
Compressão: $COMPRESS
Retenção: $RETENTION_DAYS dias

${GREEN}Arquivos incluídos:${NC}
EOF
    
    if [[ "$COMPRESS" == "true" ]]; then
        tar tzf "$BACKUP_DIR/$DATE.tar.gz" | head -20
        echo "..."
    else
        find "$backup_path" -type f | head -20
        echo "..."
    fi
    
    echo ""
    echo "${GREEN}Backup concluído com sucesso!${NC}"
}

# Função principal
main() {
    log "INFO: Iniciando backup do Network Monitoring"
    
    # Verificar se Docker está rodando
    if ! docker info >/dev/null 2>&1; then
        log "ERROR: Docker não está rodando"
        exit 1
    fi
    
    # Criar diretório de backup
    local backup_path
    backup_path=$(create_backup_dir)
    
    # Executar backups
    backup_configs "$backup_path"
    backup_data "$backup_path"
    backup_metadata "$backup_path"
    
    # Comprimir se solicitado
    if [[ "$COMPRESS" == "true" ]]; then
        compress_backup "$backup_path"
        verify_backup
    fi
    
    # Limpeza
    cleanup_old_backups
    
    # Relatório
    generate_report "$backup_path"
    
    log "INFO: Backup concluído com sucesso"
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

---

## 🎯 Exercícios Práticos

### Exercício 1: Implementação Básica

**Objetivo**: Implementar o ambiente básico de monitoramento

**Tarefas**:
1. Criar a estrutura de diretórios do projeto
2. Configurar o arquivo `.env` com suas variáveis
3. Implementar o `docker-compose.yml`
4. Configurar o SNMP Exporter com módulos básicos
5. Testar a conectividade com um dispositivo

**Critérios de Avaliação**:
- ✅ Ambiente sobe sem erros
- ✅ SNMP Exporter coleta métricas
- ✅ Prometheus armazena dados
- ✅ Grafana exibe dashboards

### Exercício 2: Descoberta Automática

**Objetivo**: Implementar descoberta automática de dispositivos

**Tarefas**:
1. Adaptar o script de descoberta para sua rede
2. Configurar file_sd_configs no Prometheus
3. Executar descoberta e validar resultados
4. Configurar cron job para execução automática

**Critérios de Avaliação**:
- ✅ Script descobre dispositivos automaticamente
- ✅ Prometheus carrega novos targets
- ✅ Métricas são coletadas dos novos dispositivos

### Exercício 3: Alertas Avançados

**Objetivo**: Configurar sistema completo de alertas

**Tarefas**:
1. Implementar todas as regras de alerta
2. Configurar Alertmanager com múltiplos canais
3. Testar alertas simulando falhas
4. Configurar inibição e agrupamento

**Critérios de Avaliação**:
- ✅ Alertas são disparados corretamente
- ✅ Notificações chegam nos canais configurados
- ✅ Inibição funciona adequadamente
- ✅ Escalação está configurada

### Exercício 4: Dashboards Personalizados

**Objetivo**: Criar dashboards específicos por tipo de dispositivo

**Tarefas**:
1. Criar dashboard para switches
2. Criar dashboard para roteadores
3. Criar dashboard de visão geral da rede
4. Implementar variáveis e filtros

**Critérios de Avaliação**:
- ✅ Dashboards são informativos e bem organizados
- ✅ Variáveis funcionam corretamente
- ✅ Métricas são relevantes para cada tipo
- ✅ Interface é intuitiva

### Exercício 5: Otimização e Tuning

**Objetivo**: Otimizar performance do sistema

**Tarefas**:
1. Analisar performance das coletas
2. Otimizar configurações do SNMP Exporter
3. Ajustar intervalos de scrape
4. Implementar métricas de monitoramento do próprio sistema

**Critérios de Avaliação**:
- ✅ Tempo de coleta < 30s
- ✅ CPU e memória otimizados
- ✅ Sem timeouts ou erros
- ✅ Sistema monitora a si mesmo

---

## 📋 Checklist de Entrega

### Documentação
- [ ] README.md completo com instruções de instalação
- [ ] Documentação de arquitetura
- [ ] Manual de operação
- [ ] Guia de troubleshooting
- [ ] Documentação de APIs e endpoints

### Código e Configurações
- [ ] docker-compose.yml funcional
- [ ] Configurações do SNMP Exporter
- [ ] Configurações do Prometheus
- [ ] Regras de alerta implementadas
- [ ] Scripts de automação
- [ ] Dashboards do Grafana

### Testes
- [ ] Testes de conectividade SNMP
- [ ] Testes de coleta de métricas
- [ ] Testes de alertas
- [ ] Testes de failover
- [ ] Testes de performance

### Operação
- [ ] Backup automático configurado
- [ ] Monitoramento do próprio sistema
- [ ] Logs estruturados
- [ ] Métricas de saúde do sistema
- [ ] Procedimentos de recuperação

### Segurança
- [ ] SNMPv3 configurado onde possível
- [ ] Credenciais em variáveis de ambiente
- [ ] HTTPS configurado
- [ ] Firewall rules documentadas
- [ ] Auditoria de acesso

---

## 🎓 Critérios de Avaliação

### Funcionalidade (40%)
- Sistema coleta métricas corretamente
- Alertas funcionam adequadamente
- Dashboards são informativos
- Descoberta automática funciona
- Backup e restore funcionais

### Qualidade Técnica (30%)
- Código bem estruturado e documentado
- Configurações otimizadas
- Tratamento de erros adequado
- Performance satisfatória
- Segurança implementada

### Documentação (20%)
- Documentação completa e clara
- Diagramas de arquitetura
- Procedimentos operacionais
- Guias de troubleshooting
- Comentários no código

### Inovação e Extras (10%)
- Funcionalidades adicionais
- Automações inteligentes
- Interface melhorada
- Integrações extras
- Contribuições para a comunidade

---

## 🚀 Próximos Passos

Após concluir este projeto, você estará preparado para:

1. **Implementar em Produção**
   - Adaptar para ambiente corporativo
   - Configurar alta disponibilidade
   - Implementar disaster recovery

2. **Expandir Funcionalidades**
   - Adicionar mais tipos de dispositivos
   - Integrar com ITSM
   - Implementar machine learning

3. **Especializar-se**
   - Certificações em monitoramento
   - Contribuir para projetos open source
   - Desenvolver soluções customizadas

4. **Compartilhar Conhecimento**
   - Documentar lições aprendidas
   - Apresentar em eventos
   - Mentorear outros profissionais

---

## 📚 Recursos Adicionais

### Documentação Oficial
- [SNMP Exporter Documentation](https://github.com/prometheus/snmp_exporter)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)

### Ferramentas Úteis
- [SNMP MIB Browser](http://www.ireasoning.com/mibbrowser.shtml)
- [OID Repository](http://oid-info.com/)
- [Prometheus Configuration Generator](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)
- [Grafana Dashboard Library](https://grafana.com/grafana/dashboards/)

### Comunidade
- [Prometheus Community](https://prometheus.io/community/)
- [Grafana Community](https://community.grafana.com/)
- [Reddit r/networking](https://www.reddit.com/r/networking/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/prometheus)

---

## 📞 Suporte

Para dúvidas sobre este projeto:

- **Email**: network-monitoring@company.com
- **Slack**: #network-monitoring
- **Wiki**: https://wiki.company.com/network-monitoring
- **Issues**: https://github.com/company/network-monitoring/issues

---

## 📄 Licença

Este projeto está licenciado sob a MIT License - veja o arquivo [LICENSE](LICENSE) para detalhes.

---

## ✨ Agradecimentos

Agradecimentos especiais a:

- Equipe de Infraestrutura de Rede
- Comunidade Prometheus
- Contribuidores do SNMP Exporter
- Time de DevOps

---

**🎯 Boa sorte com seu projeto final!**

*"O monitoramento não é apenas sobre coletar métricas, é sobre entender sua infraestrutura e antecipar problemas antes que eles afetem seus usuários."*

---

## 🔗 Navegação

- [← Módulo Anterior: Troubleshooting](06-troubleshooting.md)
- [🏠 Voltar ao Início](README.md)

---

*Última atualização: $(date '+%Y-%m-%d')*source_indexes: false
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.31.1.1.1.1  # ifName
        drop_source_indexes: false
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.31.1.1.1.18  # ifAlias
        drop_source_indexes: false
        
    overrides:
      ifType:
        type: gauge
      ifAdminStatus:
        type: gauge
      ifOperStatus:
        type: gauge
      ifHighSpeed:
        type: gauge
        
    walk_params:
      timeout: 10s
      retries: 3
      max_repetitions: 25

  # Módulo específico Cisco
  cisco_advanced:
    walk:
      # System Information
      - 1.3.6.1.2.1.1.1.0     # sysDescr
      - 1.3.6.1.2.1.1.3.0     # sysUpTime
      - 1.3.6.1.2.1.1.5.0     # sysName
      
      # Interface Information
      - 1.3.6.1.2.1.2.2.1.2   # ifDescr
      - 1.3.6.1.2.1.2.2.1.7   # ifAdminStatus
      - 1.3.6.1.2.1.2.2.1.8   # ifOperStatus
      - 1.3.6.1.2.1.31.1.1.1.6  # ifHCInOctets
      - 1.3.6.1.2.1.31.1.1.1.10 # ifHCOutOctets
      
      # Cisco CPU
      - 1.3.6.1.4.1.9.9.109.1.1.1.1.7  # cpmCPUTotal5minRev
      - 1.3.6.1.4.1.9.9.109.1.1.1.1.8  # cpmCPUTotal1minRev
      
      # Cisco Memory
      - 1.3.6.1.4.1.9.9.48.1.1.1.2   # ciscoMemoryPoolName
      - 1.3.6.1.4.1.9.9.48.1.1.1.5   # ciscoMemoryPoolUsed
      - 1.3.6.1.4.1.9.9.48.1.1.1.6   # ciscoMemoryPoolFree
      
      # Cisco Temperature
      - 1.3.6.1.4.1.9.9.13.1.3.1.2   # ciscoEnvMonTemperatureDescr
      - 1.3.6.1.4.1.9.9.13.1.3.1.3   # ciscoEnvMonTemperatureValue
      - 1.3.6.1.4.1.9.9.13.1.3.1.6   # ciscoEnvMonTemperatureState
      
    lookups:
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.2.2.1.2  # ifDescr
        drop_