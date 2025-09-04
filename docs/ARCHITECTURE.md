# Arquitetura da Stack de Observabilidade

## Visão Geral

Esta stack de observabilidade implementa uma solução completa de monitoramento baseada em Prometheus, Grafana e Alertmanager, com suporte a múltiplos exporters para coleta de métricas de infraestrutura, aplicações e dispositivos de rede. A arquitetura foi projetada para ser escalável, confiável e fácil de manter.

## Diagrama de Arquitetura Geral

```mermaid
graph TB
    subgraph "Fontes de Dados"
        HOST["🖥️ Sistema Host<br/>(Node Exporter)"]
        CONTAINERS["🐳 Containers<br/>(cAdvisor)"]
        NETWORK["🌐 Dispositivos de Rede<br/>(SNMP)"]
        APPS["📱 Aplicações<br/>(Custom Metrics)"]
    end
    
    subgraph "Stack de Observabilidade"
        PROMETHEUS["📊 Prometheus<br/>:9090"]
        GRAFANA["📈 Grafana<br/>:3000"]
        ALERTMANAGER["🚨 Alertmanager<br/>:9093"]
        
        subgraph "Exporters"
            NODE_EXP["📊 Node Exporter<br/>:9100"]
            CADVISOR["🐳 cAdvisor<br/>:8080"]
            SNMP_EXP["🌐 SNMP Exporter<br/>:9116"]
        end
    end
    
    subgraph "Notificações"
        EMAIL["📧 Email"]
        SLACK["💬 Slack"]
        WEBHOOK["🔗 Webhooks<br/>(n8n)"]
    end
    
    subgraph "Armazenamento"
        PROM_DATA[("📊 Prometheus Data<br/>(TSDB)")]
        GRAFANA_DATA[("📈 Grafana Data<br/>(SQLite)")]
        ALERT_DATA[("🚨 Alertmanager Data<br/>(Silences)")]
    end
    
    %% Coleta de Dados
    HOST --> NODE_EXP
    CONTAINERS --> CADVISOR
    NETWORK --> SNMP_EXP
    APPS --> PROMETHEUS
    
    %% Scraping
    NODE_EXP --> PROMETHEUS
    CADVISOR --> PROMETHEUS
    SNMP_EXP --> PROMETHEUS
    
    %% Alertas
    PROMETHEUS --> ALERTMANAGER
    ALERTMANAGER --> EMAIL
    ALERTMANAGER --> SLACK
    ALERTMANAGER --> WEBHOOK
    
    %% Visualização
    PROMETHEUS --> GRAFANA
    ALERTMANAGER --> GRAFANA
    
    %% Armazenamento
    PROMETHEUS --> PROM_DATA
    GRAFANA --> GRAFANA_DATA
    ALERTMANAGER --> ALERT_DATA
    
    %% Estilos
    classDef prometheus fill:#e6522c,stroke:#333,stroke-width:2px,color:#fff
    classDef grafana fill:#f46800,stroke:#333,stroke-width:2px,color:#fff
    classDef alertmanager fill:#e6522c,stroke:#333,stroke-width:2px,color:#fff
    classDef exporter fill:#326ce5,stroke:#333,stroke-width:2px,color:#fff
    classDef storage fill:#4caf50,stroke:#333,stroke-width:2px,color:#fff
    classDef notification fill:#9c27b0,stroke:#333,stroke-width:2px,color:#fff
    
    class PROMETHEUS prometheus
    class GRAFANA grafana
    class ALERTMANAGER alertmanager
    class NODE_EXP,CADVISOR,SNMP_EXP exporter
    class PROM_DATA,GRAFANA_DATA,ALERT_DATA storage
    class EMAIL,SLACK,WEBHOOK notification
```

## Fluxo de Dados Detalhado

```mermaid
sequenceDiagram
    participant Apps as 📱 Aplicações
    participant NodeExp as 📊 Node Exporter
    participant cAdvisor as 🐳 cAdvisor
    participant SNMPExp as 🌐 SNMP Exporter
    participant Prometheus as 📊 Prometheus
    participant Alertmanager as 🚨 Alertmanager
    participant Grafana as 📈 Grafana
    participant Notifications as 📧 Notificações
    
    %% Coleta de Métricas
    loop A cada 15 segundos
        Prometheus->>NodeExp: GET /metrics
        NodeExp-->>Prometheus: Métricas do sistema
        
        Prometheus->>cAdvisor: GET /metrics
        cAdvisor-->>Prometheus: Métricas de containers
        
        Prometheus->>SNMPExp: GET /snmp?target=device
        SNMPExp->>Apps: SNMP Query
        Apps-->>SNMPExp: SNMP Response
        SNMPExp-->>Prometheus: Métricas SNMP
        
        Apps->>Prometheus: POST /metrics (push)
    end
    
    %% Avaliação de Regras
    loop A cada 15 segundos
        Prometheus->>Prometheus: Avaliar regras de alerta
        alt Alerta disparado
            Prometheus->>Alertmanager: POST /api/v1/alerts
        end
    end
    
    %% Processamento de Alertas
    loop Conforme configuração
        Alertmanager->>Alertmanager: Agrupar e processar alertas
        alt Condições atendidas
            Alertmanager->>Notifications: Enviar notificação
        end
    end
    
    %% Visualização
    loop Conforme uso
        Grafana->>Prometheus: PromQL Query
        Prometheus-->>Grafana: Dados de métricas
        Grafana->>Alertmanager: GET /api/v1/alerts
        Alertmanager-->>Grafana: Status de alertas
    end
```

## Componentes da Arquitetura

### 1. Prometheus (Servidor Central de Métricas)

```mermaid
graph LR
    subgraph "Prometheus Core"
        SCRAPER["🔄 Scraper<br/>(Coleta)"] 
        TSDB["💾 TSDB<br/>(Armazenamento)"]
        RULES["📋 Rules Engine<br/>(Alertas)"]
        API["🔌 HTTP API<br/>(Queries)"]
        WEB["🌐 Web UI<br/>(Interface)"]
    end
    
    subgraph "Configuração"
        CONFIG["⚙️ prometheus.yml"]
        RULE_FILES["📄 Rules Files"]
    end
    
    subgraph "Targets"
        TARGETS["🎯 Service Discovery<br/>Static Configs"]
    end
    
    CONFIG --> SCRAPER
    RULE_FILES --> RULES
    TARGETS --> SCRAPER
    SCRAPER --> TSDB
    RULES --> API
    TSDB --> API
    API --> WEB
    
    classDef core fill:#e6522c,stroke:#333,stroke-width:2px,color:#fff
    classDef config fill:#ffc107,stroke:#333,stroke-width:2px,color:#000
    
    class SCRAPER,TSDB,RULES,API,WEB core
    class CONFIG,RULE_FILES,TARGETS config
```

**Características:**
- **Modelo Pull**: Coleta ativa de métricas dos targets
- **TSDB**: Banco de dados otimizado para séries temporais
- **PromQL**: Linguagem de query poderosa e flexível
- **Service Discovery**: Descoberta automática de targets
- **Alerting**: Engine integrado para avaliação de regras

**Configurações Críticas:**
- **Retenção**: 15 dias (configurável)
- **Scrape Interval**: 15 segundos (balanceado)
- **Evaluation Interval**: 15 segundos (alertas)
- **Storage**: Volume persistente para dados

### 2. Grafana (Visualização e Dashboards)

```mermaid
graph TB
    subgraph "Grafana Architecture"
        WEB_UI["🌐 Web Interface"]
        DATASOURCES["🔌 Data Sources"]
        DASHBOARDS["📊 Dashboards"]
        ALERTS["🚨 Alerting"]
        USERS["👥 User Management"]
        PLUGINS["🔧 Plugins"]
    end
    
    subgraph "Data Sources"
        PROM_DS["📊 Prometheus"]
        ALERT_DS["🚨 Alertmanager"]
        LOKI_DS["📝 Loki (Opcional)"]
    end
    
    subgraph "Storage"
        SQLITE["💾 SQLite DB"]
        DASHBOARDS_DIR["📁 Dashboards"]
        PROVISIONING["⚙️ Provisioning"]
    end
    
    WEB_UI --> DATASOURCES
    WEB_UI --> DASHBOARDS
    WEB_UI --> ALERTS
    WEB_UI --> USERS
    
    DATASOURCES --> PROM_DS
    DATASOURCES --> ALERT_DS
    DATASOURCES --> LOKI_DS
    
    DASHBOARDS --> SQLITE
    DASHBOARDS --> DASHBOARDS_DIR
    PROVISIONING --> DATASOURCES
    PROVISIONING --> DASHBOARDS
    
    classDef grafana fill:#f46800,stroke:#333,stroke-width:2px,color:#fff
    classDef storage fill:#4caf50,stroke:#333,stroke-width:2px,color:#fff
    
    class WEB_UI,DATASOURCES,DASHBOARDS,ALERTS,USERS,PLUGINS grafana
    class SQLITE,DASHBOARDS_DIR,PROVISIONING storage
```

**Características:**
- **Multi-Datasource**: Suporte a múltiplas fontes de dados
- **Provisioning**: Configuração automática via arquivos
- **Alerting**: Sistema de alertas integrado (complementar)
- **Plugins**: Extensibilidade via plugins
- **RBAC**: Controle de acesso baseado em roles

**Configurações Importantes:**
- **Admin Password**: Configurável via variável de ambiente
- **Plugins**: Instalação automática via GF_INSTALL_PLUGINS
- **Provisioning**: Datasources e dashboards automáticos
- **Persistence**: Volume para dados e configurações

### 3. Alertmanager (Gerenciamento de Alertas)

```mermaid
graph TB
    subgraph "Alertmanager Core"
        RECEIVER["📥 Alert Receiver"]
        ROUTER["🔀 Router"]
        GROUPER["📦 Grouper"]
        INHIBITOR["🚫 Inhibitor"]
        SILENCER["🔇 Silencer"]
        NOTIFIER["📤 Notifier"]
    end
    
    subgraph "Configuration"
        CONFIG_AM["⚙️ alertmanager.yml"]
        TEMPLATES["📄 Templates"]
    end
    
    subgraph "Receivers"
        EMAIL_R["📧 Email"]
        SLACK_R["💬 Slack"]
        WEBHOOK_R["🔗 Webhook"]
        PAGER_R["📟 PagerDuty"]
    end
    
    subgraph "Storage"
        SILENCES_DB["🔇 Silences DB"]
        NOTIFICATIONS_LOG["📋 Notifications Log"]
    end
    
    RECEIVER --> ROUTER
    ROUTER --> GROUPER
    GROUPER --> INHIBITOR
    INHIBITOR --> SILENCER
    SILENCER --> NOTIFIER
    
    CONFIG_AM --> ROUTER
    TEMPLATES --> NOTIFIER
    
    NOTIFIER --> EMAIL_R
    NOTIFIER --> SLACK_R
    NOTIFIER --> WEBHOOK_R
    NOTIFIER --> PAGER_R
    
    SILENCER --> SILENCES_DB
    NOTIFIER --> NOTIFICATIONS_LOG
    
    classDef alertmanager fill:#e6522c,stroke:#333,stroke-width:2px,color:#fff
    classDef config fill:#ffc107,stroke:#333,stroke-width:2px,color:#000
    classDef receiver fill:#9c27b0,stroke:#333,stroke-width:2px,color:#fff
    classDef storage fill:#4caf50,stroke:#333,stroke-width:2px,color:#fff
    
    class RECEIVER,ROUTER,GROUPER,INHIBITOR,SILENCER,NOTIFIER alertmanager
    class CONFIG_AM,TEMPLATES config
    class EMAIL_R,SLACK_R,WEBHOOK_R,PAGER_R receiver
    class SILENCES_DB,NOTIFICATIONS_LOG storage
```

**Características:**
- **Routing**: Roteamento inteligente baseado em labels
- **Grouping**: Agrupamento de alertas relacionados
- **Inhibition**: Supressão de alertas redundantes
- **Silencing**: Silenciamento manual de alertas
- **Templates**: Personalização de mensagens

**Fluxo de Processamento:**
1. **Recepção**: Alertas do Prometheus
2. **Roteamento**: Baseado em labels e regras
3. **Agrupamento**: Por critérios configuráveis
4. **Inibição**: Supressão de alertas relacionados
5. **Silenciamento**: Verificação de silêncios ativos
6. **Notificação**: Envio para receivers configurados

### 4. Exporters (Coletores de Métricas)

#### Node Exporter

```mermaid
graph LR
    subgraph "Sistema Host"
        CPU["💻 CPU"]
        MEMORY["🧠 Memory"]
        DISK["💾 Disk"]
        NETWORK["🌐 Network"]
        PROCESSES["⚙️ Processes"]
    end
    
    subgraph "Node Exporter"
        COLLECTORS["📊 Collectors"]
        METRICS_EP["🔌 /metrics"]
    end
    
    CPU --> COLLECTORS
    MEMORY --> COLLECTORS
    DISK --> COLLECTORS
    NETWORK --> COLLECTORS
    PROCESSES --> COLLECTORS
    
    COLLECTORS --> METRICS_EP
    
    classDef system fill:#2196f3,stroke:#333,stroke-width:2px,color:#fff
    classDef exporter fill:#326ce5,stroke:#333,stroke-width:2px,color:#fff
    
    class CPU,MEMORY,DISK,NETWORK,PROCESSES system
    class COLLECTORS,METRICS_EP exporter
```

**Coletores Principais:**
- **cpu**: Uso de CPU por core e modo
- **memory**: Memória total, disponível, buffers, cache
- **filesystem**: Uso de disco por ponto de montagem
- **network**: Estatísticas de interfaces de rede
- **loadavg**: Load average do sistema
- **systemd**: Status de serviços systemd

#### cAdvisor

```mermaid
graph LR
    subgraph "Docker Engine"
        CONTAINERS_D["🐳 Containers"]
        DOCKER_API["🔌 Docker API"]
    end
    
    subgraph "cAdvisor"
        CONTAINER_MONITOR["📊 Container Monitor"]
        RESOURCE_MONITOR["📈 Resource Monitor"]
        METRICS_EP_C["🔌 /metrics"]
    end
    
    CONTAINERS_D --> DOCKER_API
    DOCKER_API --> CONTAINER_MONITOR
    CONTAINER_MONITOR --> RESOURCE_MONITOR
    RESOURCE_MONITOR --> METRICS_EP_C
    
    classDef docker fill:#0db7ed,stroke:#333,stroke-width:2px,color:#fff
    classDef cadvisor fill:#326ce5,stroke:#333,stroke-width:2px,color:#fff
    
    class CONTAINERS_D,DOCKER_API docker
    class CONTAINER_MONITOR,RESOURCE_MONITOR,METRICS_EP_C cadvisor
```

**Métricas Principais:**
- **container_cpu_usage_seconds_total**: Uso de CPU por container
- **container_memory_usage_bytes**: Uso de memória
- **container_network_***: Estatísticas de rede
- **container_fs_***: Uso de filesystem
- **container_last_seen**: Última vez visto

#### SNMP Exporter

```mermaid
graph LR
    subgraph "Dispositivos de Rede"
        ROUTER["🌐 Router"]
        SWITCH["🔀 Switch"]
        AP["📡 Access Point"]
        FIREWALL["🛡️ Firewall"]
    end
    
    subgraph "SNMP Exporter"
        SNMP_CLIENT["📡 SNMP Client"]
        MODULE_CONFIG["⚙️ Module Config"]
        OID_WALKER["🚶 OID Walker"]
        METRICS_EP_S["🔌 /snmp"]
    end
    
    ROUTER -.->|SNMP v2c/v3| SNMP_CLIENT
    SWITCH -.->|SNMP v2c/v3| SNMP_CLIENT
    AP -.->|SNMP v2c/v3| SNMP_CLIENT
    FIREWALL -.->|SNMP v2c/v3| SNMP_CLIENT
    
    MODULE_CONFIG --> OID_WALKER
    SNMP_CLIENT --> OID_WALKER
    OID_WALKER --> METRICS_EP_S
    
    classDef network fill:#ff9800,stroke:#333,stroke-width:2px,color:#fff
    classDef snmp fill:#326ce5,stroke:#333,stroke-width:2px,color:#fff
    
    class ROUTER,SWITCH,AP,FIREWALL network
    class SNMP_CLIENT,MODULE_CONFIG,OID_WALKER,METRICS_EP_S snmp
```

**Módulos Configurados:**
- **if_mib**: Interfaces de rede padrão
- **unifi_ap**: Access Points UniFi
- **pfsense**: Firewall pfSense
- **cisco_switch**: Switches Cisco
- **mikrotik**: Dispositivos MikroTik

## Rede e Conectividade

```mermaid
graph TB
    subgraph "Rede Docker: monitoring (172.20.0.0/16)"
        subgraph "Serviços Core"
            PROM_NET["prometheus:9090"]
            GRAF_NET["grafana:3000"]
            ALERT_NET["alertmanager:9093"]
        end
        
        subgraph "Exporters"
            NODE_NET["node-exporter:9100"]
            CAD_NET["cadvisor:8080"]
            SNMP_NET["snmp-exporter:9116"]
        end
    end
    
    subgraph "Host Network"
        HOST_PORTS["Portas Expostas<br/>9090, 3000, 9093<br/>9100, 8080, 9116"]
    end
    
    subgraph "External Network"
        SNMP_DEVICES["Dispositivos SNMP<br/>192.168.1.x"]
        USERS["👥 Usuários"]
    end
    
    PROM_NET <--> NODE_NET
    PROM_NET <--> CAD_NET
    PROM_NET <--> SNMP_NET
    PROM_NET <--> ALERT_NET
    GRAF_NET <--> PROM_NET
    GRAF_NET <--> ALERT_NET
    
    HOST_PORTS <--> PROM_NET
    HOST_PORTS <--> GRAF_NET
    HOST_PORTS <--> ALERT_NET
    
    SNMP_NET -.->|SNMP Queries| SNMP_DEVICES
    USERS -->|HTTP/HTTPS| HOST_PORTS
    
    classDef core fill:#e6522c,stroke:#333,stroke-width:2px,color:#fff
    classDef exporter fill:#326ce5,stroke:#333,stroke-width:2px,color:#fff
    classDef external fill:#9e9e9e,stroke:#333,stroke-width:2px,color:#fff
    
    class PROM_NET,GRAF_NET,ALERT_NET core
    class NODE_NET,CAD_NET,SNMP_NET exporter
    class HOST_PORTS,SNMP_DEVICES,USERS external
```

**Características da Rede:**
- **Rede Isolada**: Subnet dedicada 172.20.0.0/16
- **Service Discovery**: Resolução por nome de container
- **Port Mapping**: Exposição seletiva de portas
- **Firewall**: Controle de acesso via iptables/Docker

## Armazenamento e Persistência

```mermaid
graph TB
    subgraph "Volumes Docker"
        PROM_VOL["📊 prometheus_data<br/>(TSDB)"]
        GRAF_VOL["📈 grafana_data<br/>(SQLite + Config)"]
        ALERT_VOL["🚨 alertmanager_data<br/>(Silences)"]
    end
    
    subgraph "Bind Mounts"
        PROM_CONFIG["📄 ./prometheus.yml"]
        ALERT_CONFIG["📄 ./alertmanager/"]
        GRAF_CONFIG["📄 ./grafana/"]
        SNMP_CONFIG["📄 ./snmp_exporter/"]
        RULES_CONFIG["📄 ./rules/"]
    end
    
    subgraph "Containers"
        PROM_C["📊 Prometheus"]
        GRAF_C["📈 Grafana"]
        ALERT_C["🚨 Alertmanager"]
        SNMP_C["🌐 SNMP Exporter"]
    end
    
    PROM_VOL --> PROM_C
    GRAF_VOL --> GRAF_C
    ALERT_VOL --> ALERT_C
    
    PROM_CONFIG --> PROM_C
    ALERT_CONFIG --> ALERT_C
    GRAF_CONFIG --> GRAF_C
    SNMP_CONFIG --> SNMP_C
    RULES_CONFIG --> PROM_C
    
    classDef volume fill:#4caf50,stroke:#333,stroke-width:2px,color:#fff
    classDef config fill:#ffc107,stroke:#333,stroke-width:2px,color:#000
    classDef container fill:#2196f3,stroke:#333,stroke-width:2px,color:#fff
    
    class PROM_VOL,GRAF_VOL,ALERT_VOL volume
    class PROM_CONFIG,ALERT_CONFIG,GRAF_CONFIG,SNMP_CONFIG,RULES_CONFIG config
    class PROM_C,GRAF_C,ALERT_C,SNMP_C container
```

**Estratégia de Armazenamento:**
- **Volumes Nomeados**: Para dados que precisam persistir
- **Bind Mounts**: Para configurações editáveis
- **Backup Strategy**: Volumes podem ser facilmente backupeados
- **Performance**: Volumes locais otimizados

## Fluxo de Alertas

```mermaid
flowchart TD
    START(["🎯 Métrica Coletada"]) --> EVAL{"📊 Avaliação de Regra"}
    EVAL -->|Condição Atendida| FIRE["🔥 Alerta Disparado"]
    EVAL -->|Condição Normal| NORMAL["✅ Estado Normal"]
    
    FIRE --> ROUTE{"🔀 Roteamento"}
    ROUTE -->|Severidade Critical| CRITICAL["🚨 Rota Crítica"]
    ROUTE -->|Team Infrastructure| INFRA["🏗️ Rota Infraestrutura"]
    ROUTE -->|Team Application| APP["💻 Rota Aplicação"]
    ROUTE -->|Default| DEFAULT["📧 Rota Padrão"]
    
    CRITICAL --> GROUP_C["📦 Agrupamento<br/>(0s wait)"]
    INFRA --> GROUP_I["📦 Agrupamento<br/>(30s wait)"]
    APP --> GROUP_A["📦 Agrupamento<br/>(1m wait)"]
    DEFAULT --> GROUP_D["📦 Agrupamento<br/>(10s wait)"]
    
    GROUP_C --> INHIBIT{"🚫 Inibição"}
    GROUP_I --> INHIBIT
    GROUP_A --> INHIBIT
    GROUP_D --> INHIBIT
    
    INHIBIT -->|Não Inibido| SILENCE{"🔇 Silenciamento"}
    INHIBIT -->|Inibido| SUPPRESS["🚫 Suprimido"]
    
    SILENCE -->|Não Silenciado| NOTIFY["📤 Notificação"]
    SILENCE -->|Silenciado| MUTE["🔇 Silenciado"]
    
    NOTIFY --> EMAIL_N["📧 Email"]
    NOTIFY --> SLACK_N["💬 Slack"]
    NOTIFY --> WEBHOOK_N["🔗 Webhook"]
    
    NORMAL --> RESOLVE{"✅ Resolução"}
    RESOLVE -->|Alerta Ativo| RESOLVE_NOTIFY["📤 Notificação de Resolução"]
    RESOLVE -->|Sem Alerta| END(["🏁 Fim"])
    
    RESOLVE_NOTIFY --> END
    EMAIL_N --> END
    SLACK_N --> END
    WEBHOOK_N --> END
    SUPPRESS --> END
    MUTE --> END
    
    classDef start fill:#4caf50,stroke:#333,stroke-width:2px,color:#fff
    classDef decision fill:#ff9800,stroke:#333,stroke-width:2px,color:#fff
    classDef process fill:#2196f3,stroke:#333,stroke-width:2px,color:#fff
    classDef notification fill:#9c27b0,stroke:#333,stroke-width:2px,color:#fff
    classDef end fill:#f44336,stroke:#333,stroke-width:2px,color:#fff
    
    class START,END start
    class EVAL,ROUTE,INHIBIT,SILENCE,RESOLVE decision
    class FIRE,CRITICAL,INFRA,APP,DEFAULT,GROUP_C,GROUP_I,GROUP_A,GROUP_D,NOTIFY,RESOLVE_NOTIFY process
    class EMAIL_N,SLACK_N,WEBHOOK_N notification
    class NORMAL,SUPPRESS,MUTE end
```

## Segurança e Controle de Acesso

```mermaid
graph TB
    subgraph "Camadas de Segurança"
        subgraph "Rede"
            FIREWALL_S["🛡️ Firewall Host"]
            DOCKER_NET["🐳 Docker Network"]
            PORT_EXPOSE["🔌 Port Exposure"]
        end
        
        subgraph "Aplicação"
            GRAFANA_AUTH["🔐 Grafana Auth"]
            PROM_API["🔒 Prometheus API"]
            ALERT_API["🔒 Alertmanager API"]
        end
        
        subgraph "Dados"
            VOLUME_PERM["📁 Volume Permissions"]
            CONFIG_PERM["⚙️ Config Permissions"]
            ENV_VARS["🔑 Environment Variables"]
        end
    end
    
    subgraph "Controles de Acesso"
        USERS_S["👥 Usuários"]
        ROLES["👤 Roles"]
        PERMISSIONS["✅ Permissões"]
    end
    
    FIREWALL_S --> DOCKER_NET
    DOCKER_NET --> PORT_EXPOSE
    PORT_EXPOSE --> GRAFANA_AUTH
    PORT_EXPOSE --> PROM_API
    PORT_EXPOSE --> ALERT_API
    
    GRAFANA_AUTH --> USERS_S
    USERS_S --> ROLES
    ROLES --> PERMISSIONS
    
    VOLUME_PERM --> CONFIG_PERM
    CONFIG_PERM --> ENV_VARS
    
    classDef security fill:#f44336,stroke:#333,stroke-width:2px,color:#fff
    classDef access fill:#9c27b0,stroke:#333,stroke-width:2px,color:#fff
    
    class FIREWALL_S,DOCKER_NET,PORT_EXPOSE,GRAFANA_AUTH,PROM_API,ALERT_API,VOLUME_PERM,CONFIG_PERM,ENV_VARS security
    class USERS_S,ROLES,PERMISSIONS access
```

**Medidas de Segurança:**
- **Network Isolation**: Rede Docker isolada
- **Port Control**: Exposição mínima necessária
- **Authentication**: Grafana com autenticação obrigatória
- **Authorization**: Controle de acesso baseado em roles
- **Secrets Management**: Variáveis de ambiente para credenciais
- **File Permissions**: Controle de acesso a arquivos de configuração

## Escalabilidade e Alta Disponibilidade

```mermaid
graph TB
    subgraph "Estratégias de Escalabilidade"
        subgraph "Horizontal Scaling"
            PROM_CLUSTER["📊 Prometheus Cluster<br/>(Federation)"]
            ALERT_CLUSTER["🚨 Alertmanager Cluster<br/>(Gossip Protocol)"]
            GRAF_CLUSTER["📈 Grafana Cluster<br/>(Load Balancer)"]
        end
        
        subgraph "Vertical Scaling"
            RESOURCE_LIMITS["💾 Resource Limits"]
            STORAGE_EXPANSION["📈 Storage Expansion"]
            PERFORMANCE_TUNING["⚡ Performance Tuning"]
        end
        
        subgraph "Data Management"
            RETENTION["🗓️ Data Retention"]
            COMPRESSION["🗜️ Compression"]
            ARCHIVAL["📦 Long-term Storage"]
        end
    end
    
    subgraph "Monitoring da Stack"
        SELF_MONITORING["🔍 Self Monitoring"]
        HEALTH_CHECKS["❤️ Health Checks"]
        PERFORMANCE_METRICS["📊 Performance Metrics"]
    end
    
    PROM_CLUSTER --> SELF_MONITORING
    ALERT_CLUSTER --> HEALTH_CHECKS
    GRAF_CLUSTER --> PERFORMANCE_METRICS
    
    RESOURCE_LIMITS --> PERFORMANCE_TUNING
    STORAGE_EXPANSION --> RETENTION
    RETENTION --> COMPRESSION
    COMPRESSION --> ARCHIVAL
    
    classDef scaling fill:#4caf50,stroke:#333,stroke-width:2px,color:#fff
    classDef monitoring fill:#2196f3,stroke:#333,stroke-width:2px,color:#fff
    
    class PROM_CLUSTER,ALERT_CLUSTER,GRAF_CLUSTER,RESOURCE_LIMITS,STORAGE_EXPANSION,PERFORMANCE_TUNING,RETENTION,COMPRESSION,ARCHIVAL scaling
    class SELF_MONITORING,HEALTH_CHECKS,PERFORMANCE_METRICS monitoring
```

## Considerações de Performance

### 1. Otimizações do Prometheus

- **Scrape Interval**: 15s (balanceado)
- **Retention**: 15 dias (ajustável)
- **Memory**: 1GB limit (escalável)
- **Storage**: SSD recomendado
- **Query Optimization**: Uso eficiente de PromQL

### 2. Otimizações do Grafana

- **Caching**: Cache de queries habilitado
- **Concurrent Queries**: Limitado para evitar sobrecarga
- **Dashboard Optimization**: Queries eficientes
- **Refresh Intervals**: Configurados adequadamente

### 3. Otimizações de Rede

- **SNMP Timeouts**: Configurados por tipo de dispositivo
- **Scrape Timeouts**: Balanceados com intervals
- **Network Isolation**: Reduz latência interna
- **DNS Resolution**: Otimizado via Docker

## Manutenção e Operação

### 1. Backup Strategy

```bash
# Backup de volumes
docker run --rm -v prometheus_data:/data -v $(pwd):/backup alpine tar czf /backup/prometheus_backup.tar.gz -C /data .

# Backup de configurações
tar czf config_backup.tar.gz prometheus.yml alertmanager/ grafana/ snmp_exporter/ rules/
```

### 2. Monitoring da Stack

- **Self-monitoring**: Prometheus monitora a si mesmo
- **Health checks**: Verificações automáticas de saúde
- **Alertas meta**: Alertas sobre a própria stack
- **Performance metrics**: Métricas de performance dos componentes

### 3. Atualizações

- **Rolling updates**: Atualizações sem downtime
- **Version pinning**: Controle de versões específicas
- **Testing**: Ambiente de teste para validação
- **Rollback**: Estratégia de rollback rápido

Esta arquitetura fornece uma base sólida para observabilidade, com foco em confiabilidade, escalabilidade e facilidade de manutenção.